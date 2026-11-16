using System;

namespace LuckyControl.TaxExport.Domain.Queries {
    public class PurchaseOrderQuery {
        public required string ConnectionString { get; init; }
        public required DateTime StartDate { get; init; }
        public required DateTime EndDate { get; init; }

        public string? SearchTerm { get; init; }
        public int CompanyId { get; init; }
        public int SupplierId { get; init; }
        public int SearchTemplateId { get; init; }

        public DifferentialTaxationFilter DifferentialTaxation { get; init; } = DifferentialTaxationFilter.All;

        // Sets the per-purchase booking account from the dominant value across positions (vs. per-position).
        public bool BookingAccountFromMass { get; init; }
    }
}
