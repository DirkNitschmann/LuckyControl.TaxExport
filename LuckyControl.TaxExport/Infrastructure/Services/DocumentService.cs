using System;
using System.Collections.Generic;
using System.Data;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using LuckyControl.TaxExport.Domain.Entities;
using LuckyControl.TaxExport.Domain.Queries;
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
            await using var command = new SqlCommand(sql, connection) { CommandTimeout = CommandTimeoutSeconds };

            var positions = new List<DocumentPosition>();
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            var map = new ColumnMap(reader);
            while (await reader.ReadAsync(cancellationToken)) {
                positions.Add(MapPosition(reader, map));
            }
            return positions;
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

            await using var command = new SqlCommand(sql, connection) { CommandTimeout = CommandTimeoutSeconds };
            AddParameters(command, query);

            var positions = new List<DocumentPosition>();
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            var map = new ColumnMap(reader);
            while (await reader.ReadAsync(cancellationToken)) {
                positions.Add(MapPosition(reader, map));
            }
            return positions;
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

        private static void AddParameters(SqlCommand command, SalesInvoiceQuery query) {
            // Date range — SQL casts via CONVERT(DATE, ..., 105). DateTime parameters work regardless of locale.
            command.Parameters.Add("@dDatumStart", SqlDbType.DateTime).Value = query.StartDate;
            command.Parameters.Add("@dDatumEnde", SqlDbType.DateTime).Value = query.EndDate.Date.AddDays(1).AddTicks(-1);

            command.Parameters.Add("@nZahldatum", SqlDbType.Int).Value = query.FilterByPaymentDate ? 1 : 0;
            command.Parameters.Add("@cSuchbegriff", SqlDbType.NVarChar, 255).Value = query.SearchTerm ?? string.Empty;
            command.Parameters.Add("@nRegion", SqlDbType.Int).Value = (int)query.Region;
            command.Parameters.Add("@nPosition", SqlDbType.Int).Value = (int)query.DifferentialTaxation;
            command.Parameters.Add("@kFirma", SqlDbType.Int).Value = query.CompanyId;
            command.Parameters.Add("@fMwSt", SqlDbType.Float).Value = query.VatRate.HasValue ? (object)(double)query.VatRate.Value : -1d;

            // Post-processing flags — sensible defaults for a generic export.
            command.Parameters.Add("@nBuchungskontoVersandkostenPositionAusMasse", SqlDbType.Int).Value = 0;
            command.Parameters.Add("@nEKSteucklistenKomponentenAnwenden", SqlDbType.Int).Value = 0;
            command.Parameters.Add("@nNullEuroPositionen", SqlDbType.Int).Value = 0;
            command.Parameters.Add("@nStuecklistenfilter", SqlDbType.Int).Value = 0;
        }

        private static DocumentPosition MapPosition(SqlDataReader reader, ColumnMap map) {
            return new DocumentPosition {
                Type = map.GetString(reader, "Type"),
                SalesOrderId = map.GetInt32(reader, "SalesOrderId"),
                ExternalSalesOrderId = map.GetInt32(reader, "ExternalSalesOrderId"),
                SalesInvoiceId = map.GetInt32(reader, "SalesInvoiceId"),
                SalesInvoiceCorrectionId = map.GetInt32(reader, "SalesInvoiceCorrectionId"),
                CustomerId = map.GetInt32(reader, "CustomerId"),
                CompanyId = map.GetInt32(reader, "CompanyId"),
                ProductId = map.GetInt32(reader, "ProductId"),
                SakesOrderPositionId = map.GetInt32(reader, "SakesOrderPositionId"),
                SalesOrderNumber = map.GetString(reader, "SalesOrderNumber"),
                ExternalSalesOrderNumber = map.GetString(reader, "ExternalSalesOrderNumber"),
                SalesInvoiceNumber = map.GetString(reader, "SalesInvoiceNumber"),
                SalesInvoiceCorrectionNumber = map.GetString(reader, "SalesInvoiceCorrectionNumber"),
                CustomerNumber = map.GetString(reader, "CustomerNumber"),
                DebitorNumber = map.GetString(reader, "DebitorNumber"),
                VatIdNumber = map.GetString(reader, "VatIdNumber"),
                PlatformName = map.GetString(reader, "PlatformName"),
                PaymentMethod = map.GetString(reader, "PaymentMethod"),
                ShippingMethod = map.GetString(reader, "ShippingMethod"),
                Status = map.GetString(reader, "Status"),
                Comment1 = map.GetString(reader, "Comment1"),
                Comment2 = map.GetString(reader, "Comment2"),
                BookingAccount = map.GetString(reader, "BookingAccount"),
                BookingAccountPaymentMethod = map.GetString(reader, "BookingAccountPaymentMethod"),
                Currency = map.GetString(reader, "Currency"),
                DepartmentCountry = map.GetString(reader, "DepartmentCountry"),
                VatRate = map.GetDecimal(reader, "VatRate"),
                CurrencyFactor = map.GetDecimal(reader, "CurrencyFactor"),
                TotalPayd = map.GetDecimal(reader, "TotalPayd"),
                IsDifferencialTaxation = map.GetInt32(reader, "IsDifferencialTaxation") == 1,
                IsEU = map.GetInt32(reader, "IsEU") == 1,
                IsIGL = map.GetInt32(reader, "IsIGL") == 1,
                PositionTypeId = map.GetInt32(reader, "PositionTypeId"),
                SortNumber = map.GetInt32(reader, "SortNumber"),
                Sku = map.GetString(reader, "Sku"),
                Name = map.GetString(reader, "Name"),
                Quantity = map.GetDecimal(reader, "Quantity"),
                NetPurchasingPrice = map.GetDecimal(reader, "NetPurchasingPrice"),
                TotalNetPurchasingPrice = map.GetDecimal(reader, "TotalNetPurchasingPrice"),
                NetPrice = map.GetDecimal(reader, "NetPrice"),
                TotalNetPrice = map.GetDecimal(reader, "TotalNetPrice"),
                GrossPrice = map.GetDecimal(reader, "GrossPrice"),
                TotalGrossPrice = map.GetDecimal(reader, "TotalGrossPrice"),
                NetPriceInBaseCurrency = map.GetDecimal(reader, "NetPriceInBaseCurrency"),
                TotalNetPriceInBaseCurrency = map.GetDecimal(reader, "TotalNetPriceInBaseCurrency"),
                GrossPriceInBaseCurrency = map.GetDecimal(reader, "GrossPriceInBaseCurrency"),
                TotalGrossPriceInBaseCurrency = map.GetDecimal(reader, "TotalGrossPriceInBaseCurrency"),
                CompanyName = map.GetString(reader, "CompanyName"),
                CompanyCeo = map.GetString(reader, "CompanyCeo"),
                CompanyStreet = map.GetString(reader, "CompanyStreet"),
                CompanyPostalCode = map.GetString(reader, "CompanyPostalCode"),
                CompanyCity = map.GetString(reader, "CompanyCity"),
                CompanyCountry = map.GetString(reader, "CompanyCountry"),
                CompanyHomepage = map.GetString(reader, "CompanyHomepage"),
                CompanyEmail = map.GetString(reader, "CompanyEmail"),
                CompanyBankName = map.GetString(reader, "CompanyBankName"),
                CompanyAccountNumber = map.GetString(reader, "CompanyAccountNumber"),
                CompanyBankCode = map.GetString(reader, "CompanyBankCode"),
                CompanyIban = map.GetString(reader, "CompanyIban"),
                CompanyBic = map.GetString(reader, "CompanyBic"),
                CompanyTaxNumber = map.GetString(reader, "CompanyTaxNumber"),
                CompanyCreditorId = map.GetString(reader, "CompanyCreditorId"),
                InvoiceAddressSalutation = map.GetString(reader, "InvoiceAddressSalutation"),
                InvoiceAddressCompanyName = map.GetString(reader, "InvoiceAddressCompanyName"),
                InvoiceAddressFirstName = map.GetString(reader, "InvoiceAddressFirstName"),
                InvoiceAddressLastName = map.GetString(reader, "InvoiceAddressLastName"),
                InvoiceAddressStreet = map.GetString(reader, "InvoiceAddressStreet"),
                InvoiceAddressPostalCode = map.GetString(reader, "InvoiceAddressPostalCode"),
                InvoiceAddressCity = map.GetString(reader, "InvoiceAddressCity"),
                InvoiceAddressFederalState = map.GetString(reader, "InvoiceAddressFederalState"),
                InvoiceAddressCountry = map.GetString(reader, "InvoiceAddressCountry"),
                InvoiceAddressPhone = map.GetString(reader, "InvoiceAddressPhone"),
                InvoiceAddressFax = map.GetString(reader, "InvoiceAddressFax"),
                InvoiceAddressMobile = map.GetString(reader, "InvoiceAddressMobile"),
                InvoiceAddressEmail = map.GetString(reader, "InvoiceAddressEmail"),
                ShippingAddressSalutation = map.GetString(reader, "ShippingAddressSalutation"),
                ShippingAddressCompanyName = map.GetString(reader, "ShippingAddressCompanyName"),
                ShippingAddressFirstName = map.GetString(reader, "ShippingAddressFirstName"),
                ShippingAddressLastName = map.GetString(reader, "ShippingAddressLastName"),
                ShippingAddressStreet = map.GetString(reader, "ShippingAddressStreet"),
                ShippingAddressPostalCode = map.GetString(reader, "ShippingAddressPostalCode"),
                ShippingAddressCity = map.GetString(reader, "ShippingAddressCity"),
                ShippingAddressFederalState = map.GetString(reader, "ShippingAddressFederalState"),
                ShippingAddressCountry = map.GetString(reader, "ShippingAddressCountry"),
                ShippingAddressCountryIso = map.GetString(reader, "ShippingAddressCountryIso"),
                ShippingAddressPhone = map.GetString(reader, "ShippingAddressPhone"),
                ShippingAddressFax = map.GetString(reader, "ShippingAddressFax"),
                ShippingAddressMobile = map.GetString(reader, "ShippingAddressMobile"),
                ShippingAddressEmail = map.GetString(reader, "ShippingAddressEmail"),
                SerialNumbers = map.GetString(reader, "SerialNumbers"),
                BatchNumbers = map.GetString(reader, "BatchNumbers"),
                PositionComment = map.GetString(reader, "PositionComment"),
                CreatedAt = map.GetDateTime(reader, "CreatedAt") ?? default,
                SalesOrderDate = map.GetDateTime(reader, "SalesOrderDate"),
                SalesInvoiceDate = map.GetDateTime(reader, "SalesInvoiceDate"),
                ShippedAt = map.GetDateTime(reader, "ShippedAt"),
                PaydAt = map.GetDateTime(reader, "PaydAt"),
                ShppingDate = map.GetDateTime(reader, "ShppingDate"),
                IsReverseCharge = map.GetInt32(reader, "IsReverseCharge") == 1,
                PurchaseOrderId = map.GetInt32(reader, "PurchaseOrderId"),
                SupplierId = map.GetInt32(reader, "SupplierId"),
                PurchaseOrderNumber = map.GetString(reader, "PurchaseOrderNumber"),
                PurchaseReferenceOrderNumber = map.GetString(reader, "PurchaseReferenceOrderNumber"),
                PurchaseExternalDocumentNumber = map.GetString(reader, "PurchaseExternalDocumentNumber"),
                SupplierNumber = map.GetString(reader, "SupplierNumber"),
                SupplierCompanyName = map.GetString(reader, "SupplierCompanyName"),
                SupplierCompanyNameAddition = map.GetString(reader, "SupplierCompanyNameAddition"),
                SupplierSalutation = map.GetString(reader, "SupplierSalutation"),
                SupplierFirstName = map.GetString(reader, "SupplierFirstName"),
                SupplierLastName = map.GetString(reader, "SupplierLastName"),
                SupplierStreet = map.GetString(reader, "SupplierStreet"),
                SupplierPostalCode = map.GetString(reader, "SupplierPostalCode"),
                SupplierCity = map.GetString(reader, "SupplierCity"),
                SupplierFederalState = map.GetString(reader, "SupplierFederalState"),
                SupplierCountry = map.GetString(reader, "SupplierCountry"),
                SupplierPhone = map.GetString(reader, "SupplierPhone"),
                SupplierFax = map.GetString(reader, "SupplierFax"),
                SupplierEmail = map.GetString(reader, "SupplierEmail"),
                SupplierHomepage = map.GetString(reader, "SupplierHomepage"),
                SupplierVatIdNumber = map.GetString(reader, "SupplierVatIdNumber"),
                DifferentialTaxationMode = map.GetInt32(reader, "DifferentialTaxationMode")
            };
        }

        // Caches column ordinals so we resolve column names once per result set, not per row.
        private sealed class ColumnMap {
            private readonly Dictionary<string, int> _ordinals;

            public ColumnMap(SqlDataReader reader) {
                _ordinals = new Dictionary<string, int>(reader.FieldCount, StringComparer.OrdinalIgnoreCase);
                for (var i = 0; i < reader.FieldCount; i++) {
                    _ordinals[reader.GetName(i)] = i;
                }
            }

            // Missing-column lookups return defaults rather than throwing — the same DocumentPosition
            // model is populated from differently-shaped SQL templates (sales / credit notes / purchase),
            // and not every template emits every column.
            public string GetString(SqlDataReader reader, string column) {
                if (!_ordinals.TryGetValue(column, out var ordinal)) return string.Empty;
                return reader.IsDBNull(ordinal) ? string.Empty : reader.GetValue(ordinal).ToString() ?? string.Empty;
            }

            public int GetInt32(SqlDataReader reader, string column) {
                if (!_ordinals.TryGetValue(column, out var ordinal)) return 0;
                return reader.IsDBNull(ordinal) ? 0 : Convert.ToInt32(reader.GetValue(ordinal));
            }

            public decimal GetDecimal(SqlDataReader reader, string column) {
                if (!_ordinals.TryGetValue(column, out var ordinal)) return 0m;
                return reader.IsDBNull(ordinal) ? 0m : Convert.ToDecimal(reader.GetValue(ordinal));
            }

            public DateTime? GetDateTime(SqlDataReader reader, string column) {
                if (!_ordinals.TryGetValue(column, out var ordinal)) return null;
                return reader.IsDBNull(ordinal) ? null : reader.GetDateTime(ordinal);
            }
        }
    }
}
