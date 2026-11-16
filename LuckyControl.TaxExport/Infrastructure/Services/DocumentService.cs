using System;
using System.Collections.Generic;
using System.Data;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using LuckyControl.TaxExport.Domain.Entities;
using LuckyControl.TaxExport.Domain.Queries;
using LuckyControl.TaxExport.Infrastructure.Data;
using LuckyControl.TaxExport.Properties;
using Microsoft.Data.SqlClient;

namespace LuckyControl.TaxExport.Infrastructure.Services {
    public class DocumentService {
        // Reasonable upper bound: the SQL is heavy on big DBs.
        private const int CommandTimeoutSeconds = 600;

        private const string DefaultDatabaseName = "eazybusiness";

        private static readonly IReadOnlyList<int> DefaultPlatformTypes = new[] { 1, 2, 3, 4, 5, 6, 7, 8, 9 };
        private static readonly Regex DatabaseNamePattern = new(@"^[A-Za-z_][A-Za-z0-9_]*$", RegexOptions.Compiled);

        public async Task<List<DocumentPosition>> ReadSalesInvoicePositionsAsync(
            SalesInvoiceQuery query,
            string databaseName = DefaultDatabaseName,
            CancellationToken cancellationToken = default) {
            ArgumentNullException.ThrowIfNull(query);
            EnsureValidDatabaseName(databaseName);

            await using var connection = new SqlConnection(query.ConnectionString);
            await connection.OpenAsync(cancellationToken);
            connection.ChangeDatabase(databaseName);

            var wawiVersion = await ReadWawiVersionAsync(connection, databaseName, cancellationToken);
            var sqlTemplate = SelectSqlTemplate(wawiVersion);
            return await ExecuteTemplateAsync(connection, sqlTemplate, databaseName, query, cancellationToken);
        }

        // Credit notes (Gutschriften / Rechnungskorrekturen) only have a 1.6.x-style template;
        // there is no 2.0.x variant, so the Wawi version probe is skipped.
        public async Task<List<DocumentPosition>> ReadSalesCreditNotePositionsAsync(
            SalesInvoiceQuery query,
            string databaseName = DefaultDatabaseName,
            CancellationToken cancellationToken = default) {
            ArgumentNullException.ThrowIfNull(query);
            EnsureValidDatabaseName(databaseName);

            await using var connection = new SqlConnection(query.ConnectionString);
            await connection.OpenAsync(cancellationToken);
            connection.ChangeDatabase(databaseName);

            return await ExecuteTemplateAsync(connection, Resources.Sql_ReadSalesCreditNotesWawi16xx, databaseName, query, cancellationToken);
        }

        // Purchase orders (Lieferantenbestellungen) — uses its own placeholder set and inlines
        // filter values via string substitution because the underlying SQL builds dynamic SQL via sp_executesql.
        public async Task<List<DocumentPosition>> ReadPurchaseOrdersAsync(
            PurchaseOrderQuery query,
            string databaseName = DefaultDatabaseName,
            CancellationToken cancellationToken = default) {
            ArgumentNullException.ThrowIfNull(query);
            EnsureValidDatabaseName(databaseName);

            await using var connection = new SqlConnection(query.ConnectionString);
            await connection.OpenAsync(cancellationToken);
            connection.ChangeDatabase(databaseName);

            var sql = ApplyPurchasePlaceholders(Resources.Sql_ReadPurchaseOrders, databaseName, query);
            return await DbRead.ListAsync(connection, sql, null, MapPosition, "DocumentService.ReadPurchaseOrders", CommandTimeoutSeconds, cancellationToken);

        }

        private static void EnsureValidDatabaseName(string databaseName) {
            if (string.IsNullOrWhiteSpace(databaseName) || !DatabaseNamePattern.IsMatch(databaseName)) {
                throw new ArgumentException($"Invalid database name: '{databaseName}'.", nameof(databaseName));
            }
        }

        private static async Task<List<DocumentPosition>> ExecuteTemplateAsync(
            SqlConnection connection,
            string sqlTemplate,
            string databaseName,
            SalesInvoiceQuery query,
            CancellationToken cancellationToken) {
            var sql = ApplyPlaceholders(sqlTemplate, databaseName, query);

            return await DbRead.ListAsync(connection, sql, p => AddParameters(p, query), MapPosition, "DocumentService.ReadDocumentPositions", CommandTimeoutSeconds, cancellationToken);

        }

        private static async Task<string> ReadWawiVersionAsync(
            SqlConnection connection, string databaseName, CancellationToken cancellationToken) {
            var sql = $"SELECT TOP 1 cVersion FROM [{databaseName}].[dbo].[tVersion]";
            await using var command = new SqlCommand(sql, connection);
            var result = await command.ExecuteScalarAsync(cancellationToken);
            return result?.ToString() ?? string.Empty;
        }

        private static string SelectSqlTemplate(string wawiVersion) {
            // JTL-Wawi 1.6.x to 1.11.x share one schema; 2.0.x is a different schema.
            var firstChar = wawiVersion.Length > 0 ? wawiVersion[0] : '\0';
            return firstChar == '2'
                ? Resources.Sql_ReadSalesInvoicesJtlWawi20xx
                : Resources.Sql_ReadSalesInvoicesJtlWawi16xx;
        }

        private static string ApplyPlaceholders(string sql, string databaseName, SalesInvoiceQuery query) {
            var platforms = query.PlatformTypes is { Count: > 0 } ? query.PlatformTypes : DefaultPlatformTypes;
            var platformsCsv = string.Join(",", platforms);

            return sql
                .Replace("#cDB#", $"[{databaseName}]")
                .Replace("*cPlattformen*", platformsCsv)
                .Replace("#nTypeIN#", string.Empty)
                .Replace("#nDifferenz#", string.Empty);
        }

        private static string ApplyPurchasePlaceholders(string sql, string databaseName, PurchaseOrderQuery query) {
            // #cDBraw# yields the raw db name for use inside string-literal contexts (e.g. Steuerdaten.cDB = '...').
            // #cDB# yields the bracketed identifier used everywhere else.
            return sql
                .Replace("#cDB#", $"[{databaseName}]")
                .Replace("#cDBraw#", databaseName)
                .Replace("#nBuchungskontoVersandkostenPositionAusMasse#", query.BookingAccountFromMass ? "1" : "0")
                .Replace("#nPosition#", ((int)query.DifferentialTaxation).ToString())
                .Replace("#kFirma#", query.CompanyId.ToString())
                .Replace("#kLieferant#", query.SupplierId.ToString())
                .Replace("#kSuchvorlage#", query.SearchTemplateId.ToString())
                .Replace("#dDatumStart#", query.StartDate.ToString("yyyy-MM-dd"))
                .Replace("#dDatumEnde#", query.EndDate.ToString("yyyy-MM-dd"))
                .Replace("#cSuchbegriff#", (query.SearchTerm ?? string.Empty).Replace("'", "''"));
        }

        private static void AddParameters(SqlParameterCollection parameters, SalesInvoiceQuery query) {
            // Date range — SQL casts via CONVERT(DATE, ..., 105). DateTime parameters work regardless of locale.
            parameters.Add("@dDatumStart", SqlDbType.DateTime).Value = query.StartDate;
            parameters.Add("@dDatumEnde", SqlDbType.DateTime).Value = query.EndDate.Date.AddDays(1).AddTicks(-1);

            parameters.Add("@nZahldatum", SqlDbType.Int).Value = query.FilterByPaymentDate ? 1 : 0;
            parameters.Add("@cSuchbegriff", SqlDbType.NVarChar, 255).Value = query.SearchTerm ?? string.Empty;
            parameters.Add("@nRegion", SqlDbType.Int).Value = (int)query.Region;
            parameters.Add("@nPosition", SqlDbType.Int).Value = (int)query.DifferentialTaxation;
            parameters.Add("@kFirma", SqlDbType.Int).Value = query.CompanyId;
            parameters.Add("@fMwSt", SqlDbType.Float).Value = query.VatRate.HasValue ? (object)(double)query.VatRate.Value : -1d;

            // Post-processing flags — sensible defaults for a generic export.
            parameters.Add("@nBuchungskontoVersandkostenPositionAusMasse", SqlDbType.Int).Value = 0;
            parameters.Add("@nEKSteucklistenKomponentenAnwenden", SqlDbType.Int).Value = 0;
            parameters.Add("@nNullEuroPositionen", SqlDbType.Int).Value = 0;
            parameters.Add("@nStuecklistenfilter", SqlDbType.Int).Value = 0;
        }

        private static DocumentPosition MapPosition(DbRow row) {
            return new DocumentPosition {
                Type = row.StringOrEmpty("Type"),
                SalesOrderId = row.Int32OrZero("SalesOrderId"),
                ExternalSalesOrderId = row.Int32OrZero("ExternalSalesOrderId"),
                SalesInvoiceId = row.Int32OrZero("SalesInvoiceId"),
                SalesInvoiceCorrectionId = row.Int32OrZero("SalesInvoiceCorrectionId"),
                CustomerId = row.Int32OrZero("CustomerId"),
                CompanyId = row.Int32OrZero("CompanyId"),
                ProductId = row.Int32OrZero("ProductId"),
                SakesOrderPositionId = row.Int32OrZero("SakesOrderPositionId"),
                SalesOrderNumber = row.StringOrEmpty("SalesOrderNumber"),
                ExternalSalesOrderNumber = row.StringOrEmpty("ExternalSalesOrderNumber"),
                SalesInvoiceNumber = row.StringOrEmpty("SalesInvoiceNumber"),
                SalesInvoiceCorrectionNumber = row.StringOrEmpty("SalesInvoiceCorrectionNumber"),
                CustomerNumber = row.StringOrEmpty("CustomerNumber"),
                DebitorNumber = row.StringOrEmpty("DebitorNumber"),
                VatIdNumber = row.StringOrEmpty("VatIdNumber"),
                PlatformName = row.StringOrEmpty("PlatformName"),
                PaymentMethod = row.StringOrEmpty("PaymentMethod"),
                ShippingMethod = row.StringOrEmpty("ShippingMethod"),
                Status = row.StringOrEmpty("Status"),
                Comment1 = row.StringOrEmpty("Comment1"),
                Comment2 = row.StringOrEmpty("Comment2"),
                BookingAccount = row.StringOrEmpty("BookingAccount"),
                BookingAccountPaymentMethod = row.StringOrEmpty("BookingAccountPaymentMethod"),
                Currency = row.StringOrEmpty("Currency"),
                DepartmentCountry = row.StringOrEmpty("DepartmentCountry"),
                VatRate = row.DecimalOrZero("VatRate"),
                CurrencyFactor = row.DecimalOrZero("CurrencyFactor"),
                TotalPayd = row.DecimalOrZero("TotalPayd"),
                IsDifferencialTaxation = row.Int32OrZero("IsDifferencialTaxation") == 1,
                IsEU = row.Int32OrZero("IsEU") == 1,
                IsIGL = row.Int32OrZero("IsIGL") == 1,
                PositionTypeId = row.Int32OrZero("PositionTypeId"),
                SortNumber = row.Int32OrZero("SortNumber"),
                Sku = row.StringOrEmpty("Sku"),
                Name = row.StringOrEmpty("Name"),
                Quantity = row.DecimalOrZero("Quantity"),
                NetPurchasingPrice = row.DecimalOrZero("NetPurchasingPrice"),
                TotalNetPurchasingPrice = row.DecimalOrZero("TotalNetPurchasingPrice"),
                NetPrice = row.DecimalOrZero("NetPrice"),
                TotalNetPrice = row.DecimalOrZero("TotalNetPrice"),
                GrossPrice = row.DecimalOrZero("GrossPrice"),
                TotalGrossPrice = row.DecimalOrZero("TotalGrossPrice"),
                NetPriceInBaseCurrency = row.DecimalOrZero("NetPriceInBaseCurrency"),
                TotalNetPriceInBaseCurrency = row.DecimalOrZero("TotalNetPriceInBaseCurrency"),
                GrossPriceInBaseCurrency = row.DecimalOrZero("GrossPriceInBaseCurrency"),
                TotalGrossPriceInBaseCurrency = row.DecimalOrZero("TotalGrossPriceInBaseCurrency"),
                CompanyName = row.StringOrEmpty("CompanyName"),
                CompanyCeo = row.StringOrEmpty("CompanyCeo"),
                CompanyStreet = row.StringOrEmpty("CompanyStreet"),
                CompanyPostalCode = row.StringOrEmpty("CompanyPostalCode"),
                CompanyCity = row.StringOrEmpty("CompanyCity"),
                CompanyCountry = row.StringOrEmpty("CompanyCountry"),
                CompanyHomepage = row.StringOrEmpty("CompanyHomepage"),
                CompanyEmail = row.StringOrEmpty("CompanyEmail"),
                CompanyBankName = row.StringOrEmpty("CompanyBankName"),
                CompanyAccountNumber = row.StringOrEmpty("CompanyAccountNumber"),
                CompanyBankCode = row.StringOrEmpty("CompanyBankCode"),
                CompanyIban = row.StringOrEmpty("CompanyIban"),
                CompanyBic = row.StringOrEmpty("CompanyBic"),
                CompanyTaxNumber = row.StringOrEmpty("CompanyTaxNumber"),
                CompanyCreditorId = row.StringOrEmpty("CompanyCreditorId"),
                InvoiceAddressSalutation = row.StringOrEmpty("InvoiceAddressSalutation"),
                InvoiceAddressCompanyName = row.StringOrEmpty("InvoiceAddressCompanyName"),
                InvoiceAddressFirstName = row.StringOrEmpty("InvoiceAddressFirstName"),
                InvoiceAddressLastName = row.StringOrEmpty("InvoiceAddressLastName"),
                InvoiceAddressStreet = row.StringOrEmpty("InvoiceAddressStreet"),
                InvoiceAddressPostalCode = row.StringOrEmpty("InvoiceAddressPostalCode"),
                InvoiceAddressCity = row.StringOrEmpty("InvoiceAddressCity"),
                InvoiceAddressFederalState = row.StringOrEmpty("InvoiceAddressFederalState"),
                InvoiceAddressCountry = row.StringOrEmpty("InvoiceAddressCountry"),
                InvoiceAddressPhone = row.StringOrEmpty("InvoiceAddressPhone"),
                InvoiceAddressFax = row.StringOrEmpty("InvoiceAddressFax"),
                InvoiceAddressMobile = row.StringOrEmpty("InvoiceAddressMobile"),
                InvoiceAddressEmail = row.StringOrEmpty("InvoiceAddressEmail"),
                ShippingAddressSalutation = row.StringOrEmpty("ShippingAddressSalutation"),
                ShippingAddressCompanyName = row.StringOrEmpty("ShippingAddressCompanyName"),
                ShippingAddressFirstName = row.StringOrEmpty("ShippingAddressFirstName"),
                ShippingAddressLastName = row.StringOrEmpty("ShippingAddressLastName"),
                ShippingAddressStreet = row.StringOrEmpty("ShippingAddressStreet"),
                ShippingAddressPostalCode = row.StringOrEmpty("ShippingAddressPostalCode"),
                ShippingAddressCity = row.StringOrEmpty("ShippingAddressCity"),
                ShippingAddressFederalState = row.StringOrEmpty("ShippingAddressFederalState"),
                ShippingAddressCountry = row.StringOrEmpty("ShippingAddressCountry"),
                ShippingAddressCountryIso = row.StringOrEmpty("ShippingAddressCountryIso"),
                ShippingAddressPhone = row.StringOrEmpty("ShippingAddressPhone"),
                ShippingAddressFax = row.StringOrEmpty("ShippingAddressFax"),
                ShippingAddressMobile = row.StringOrEmpty("ShippingAddressMobile"),
                ShippingAddressEmail = row.StringOrEmpty("ShippingAddressEmail"),
                SerialNumbers = row.StringOrEmpty("SerialNumbers"),
                BatchNumbers = row.StringOrEmpty("BatchNumbers"),
                PositionComment = row.StringOrEmpty("PositionComment"),
                CreatedAt = row.DateTimeOrNull("CreatedAt") ?? default,
                SalesOrderDate = row.DateTimeOrNull("SalesOrderDate"),
                SalesInvoiceDate = row.DateTimeOrNull("SalesInvoiceDate"),
                ShippedAt = row.DateTimeOrNull("ShippedAt"),
                PaydAt = row.DateTimeOrNull("PaydAt"),
                ShppingDate = row.DateTimeOrNull("ShppingDate"),
                IsReverseCharge = row.Int32OrZero("IsReverseCharge") == 1,
                PurchaseOrderId = row.Int32OrZero("PurchaseOrderId"),
                SupplierId = row.Int32OrZero("SupplierId"),
                PurchaseOrderNumber = row.StringOrEmpty("PurchaseOrderNumber"),
                PurchaseReferenceOrderNumber = row.StringOrEmpty("PurchaseReferenceOrderNumber"),
                PurchaseExternalDocumentNumber = row.StringOrEmpty("PurchaseExternalDocumentNumber"),
                SupplierNumber = row.StringOrEmpty("SupplierNumber"),
                SupplierCompanyName = row.StringOrEmpty("SupplierCompanyName"),
                SupplierCompanyNameAddition = row.StringOrEmpty("SupplierCompanyNameAddition"),
                SupplierSalutation = row.StringOrEmpty("SupplierSalutation"),
                SupplierFirstName = row.StringOrEmpty("SupplierFirstName"),
                SupplierLastName = row.StringOrEmpty("SupplierLastName"),
                SupplierStreet = row.StringOrEmpty("SupplierStreet"),
                SupplierPostalCode = row.StringOrEmpty("SupplierPostalCode"),
                SupplierCity = row.StringOrEmpty("SupplierCity"),
                SupplierFederalState = row.StringOrEmpty("SupplierFederalState"),
                SupplierCountry = row.StringOrEmpty("SupplierCountry"),
                SupplierPhone = row.StringOrEmpty("SupplierPhone"),
                SupplierFax = row.StringOrEmpty("SupplierFax"),
                SupplierEmail = row.StringOrEmpty("SupplierEmail"),
                SupplierHomepage = row.StringOrEmpty("SupplierHomepage"),
                SupplierVatIdNumber = row.StringOrEmpty("SupplierVatIdNumber"),
                DifferentialTaxationMode = row.Int32OrZero("DifferentialTaxationMode")
            };
        }
    }
}
