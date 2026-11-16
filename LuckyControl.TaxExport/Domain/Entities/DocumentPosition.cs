namespace LuckyControl.TaxExport.Domain.Entities {
    public class DocumentPosition {
        public string Type { get; set; } = "Invoice";
        public int SalesOrderId { get; set; }
        public int ExternalSalesOrderId { get; set; } = 0;
        public int SalesInvoiceId { get; set; }
        public int SalesInvoiceCorrectionId { get; set; }
        public int CustomerId { get; set; }
        public int CompanyId { get; set; }
        public int ProductId { get; set; }
        public int SakesOrderPositionId { get; set; }
        public string SalesOrderNumber { get; set; }
        public string ExternalSalesOrderNumber { get; set; }
        public string SalesInvoiceNumber { get; set; }
        public string SalesInvoiceCorrectionNumber { get; set; }
        public string CustomerNumber { get; set; }
        public string DebitorNumber { get; set; }
        public string VatIdNumber { get; set; }
        public string PlatformName { get; set; }
        public string PaymentMethod { get; set; }
        public string ShippingMethod { get; set; }
        public string Status { get; set; }
        public string Comment1 { get; set; }
        public string Comment2 { get; set; }
        public string BookingAccount { get; set; }
        public string BookingAccountPaymentMethod { get; set; }
        public string Currency { get; set; }
        public string DepartmentCountry { get; set; }
        public decimal VatRate { get; set; } = 0;
        public decimal CurrencyFactor { get; set; } = 1;
        public decimal TotalPayd { get; set; }
        public bool IsDifferencialTaxation { get; set; } = false;
        public bool IsEU { get; set; } = false;
        public bool IsIGL { get; set; } = false;
        public int PositionTypeId { get; set; } = 1;
        public int SortNumber { get; set; } = 0;
        public string Sku { get; set; } = "";
        public string Name { get; set; } = "";
        public decimal Quantity { get; set; } = 0;
        public decimal NetPurchasingPrice { get; set; } = 0;
        public decimal TotalNetPurchasingPrice { get; set; } = 0;
        public decimal NetPrice { get; set; } = 0;
        public decimal TotalNetPrice { get; set; } = 0;
        public decimal GrossPrice { get; set; } = 0;
        public decimal TotalGrossPrice { get; set; } = 0;
        public decimal NetPriceInBaseCurrency { get; set; } = 0;
        public decimal TotalNetPriceInBaseCurrency { get; set; } = 0;
        public decimal GrossPriceInBaseCurrency { get; set; } = 0;
        public decimal TotalGrossPriceInBaseCurrency { get; set; } = 0;
        public string CompanyName { get; set; } = "";
        public string CompanyCeo { get; set; } = "";
        public string CompanyStreet { get; set; } = "";
        public string CompanyPostalCode { get; set; } = "";
        public string CompanyCity { get; set; } = "";
        public string CompanyCountry { get; set; } = "";
        public string CompanyHomepage { get; set; } = "";
        public string CompanyEmail { get; set; } = "";
        public string CompanyBankName { get; set; } = "";
        public string CompanyAccountNumber { get; set; } = "";
        public string CompanyBankCode { get; set; } = "";
        public string CompanyIban { get; set; } = "";
        public string CompanyBic { get; set; } = "";
        public string CompanyTaxNumber { get; set; } = "";
        public string CompanyCreditorId { get; set; } = "";
        public string InvoiceAddressSalutation { get; set; } = "";
        public string InvoiceAddressCompanyName { get; set; } = "";
        public string InvoiceAddressFirstName { get; set; } = "";
        public string InvoiceAddressLastName { get; set; } = "";
        public string InvoiceAddressStreet { get; set; } = "";
        public string InvoiceAddressPostalCode { get; set; } = "";
        public string InvoiceAddressCity { get; set; } = "";
        public string InvoiceAddressFederalState { get; set; } = "";
        public string InvoiceAddressCountry { get; set; } = "";
        public string InvoiceAddressPhone { get; set; } = "";
        public string InvoiceAddressFax { get; set; } = "";
        public string InvoiceAddressMobile { get; set; } = "";
        public string InvoiceAddressEmail { get; set; } = "";
        public string ShippingAddressSalutation { get; set; } = "";
        public string ShippingAddressCompanyName { get; set; } = "";
        public string ShippingAddressFirstName { get; set; } = "";
        public string ShippingAddressLastName { get; set; } = "";
        public string ShippingAddressStreet { get; set; } = "";
        public string ShippingAddressPostalCode { get; set; } = "";
        public string ShippingAddressCity { get; set; } = "";
        public string ShippingAddressFederalState { get; set; } = "";
        public string ShippingAddressCountry { get; set; } = "";
        public string ShippingAddressCountryIso { get; set; } = "";
        public string ShippingAddressPhone { get; set; } = "";
        public string ShippingAddressFax { get; set; } = "";
        public string ShippingAddressMobile { get; set; } = "";
        public string ShippingAddressEmail { get; set; } = "";
        public string SerialNumbers { get; set; } = "";
        public string BatchNumbers { get; set; } = "";
        public string PositionComment { get; set; } = "";
        public DateTime CreatedAt { get; set; }
        public DateTime? SalesOrderDate { get; set; } = null;
        public DateTime? SalesInvoiceDate { get; set; } = null;
        public DateTime? ShippedAt { get; set; } = null;
        public DateTime? PaydAt { get; set; } = null;
        public DateTime? ShppingDate { get; set; } = null;
        public bool IsReverseCharge { get; set; } = false;

        // Purchase order (Lieferantenbestellung) — only populated for Type == "PurchaseOrder".
        public int PurchaseOrderId { get; set; }
        public int SupplierId { get; set; }
        public string PurchaseOrderNumber { get; set; } = "";
        public string PurchaseReferenceOrderNumber { get; set; } = "";
        public string PurchaseExternalDocumentNumber { get; set; } = "";
        public string SupplierNumber { get; set; } = "";
        public string SupplierCompanyName { get; set; } = "";
        public string SupplierCompanyNameAddition { get; set; } = "";
        public string SupplierSalutation { get; set; } = "";
        public string SupplierFirstName { get; set; } = "";
        public string SupplierLastName { get; set; } = "";
        public string SupplierStreet { get; set; } = "";
        public string SupplierPostalCode { get; set; } = "";
        public string SupplierCity { get; set; } = "";
        public string SupplierFederalState { get; set; } = "";
        public string SupplierCountry { get; set; } = "";
        public string SupplierPhone { get; set; } = "";
        public string SupplierFax { get; set; } = "";
        public string SupplierEmail { get; set; } = "";
        public string SupplierHomepage { get; set; } = "";
        public string SupplierVatIdNumber { get; set; } = "";

        // 0 = keine, 1 = Einzeldifferenzbesteuerung (§25a Abs. 3 UStG), 2 = Gesamtdifferenzbesteuerung (§25a Abs. 4 UStG).
        public int DifferentialTaxationMode { get; set; } = 0;
    }
}
