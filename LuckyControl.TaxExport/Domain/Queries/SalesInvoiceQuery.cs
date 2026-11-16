using System;
using System.Collections.Generic;

namespace LuckyControl.TaxExport.Domain.Queries {
    public enum RegionFilter {
        All = 0,
        Eu = 1,
        NonEu = 2
    }

    public enum DifferentialTaxationFilter {
        All = 0,
        Yes = 1,
        No = 2
    }

    public class SalesInvoiceQuery {
        public required string ConnectionString { get; init; }
        public required DateTime StartDate { get; init; }
        public required DateTime EndDate { get; init; }

        public bool FilterByPaymentDate { get; init; }
        public string? SearchTerm { get; init; }
        public int CompanyId { get; init; }
        public decimal? VatRate { get; init; }
        public RegionFilter Region { get; init; } = RegionFilter.All;
        public DifferentialTaxationFilter DifferentialTaxation { get; init; } = DifferentialTaxationFilter.All;

        /// JTL-Wawi platform types (tPlattform.nTyp) to include. null = all known types (1-9).
        public IReadOnlyList<int>? PlatformTypes { get; init; }
    }
}
