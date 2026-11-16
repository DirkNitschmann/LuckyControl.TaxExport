namespace LuckyControl.TaxExport.Domain.Entities {
    public class Settings {
        public List<BaseSetting> baseSettings { get; set; } = new List<BaseSetting>();
        public List<TaxSetting> taxSettings { get; set; } = new List<TaxSetting>();
        public List<ExportTemplate> exportTemplates { get; set; } = new List<ExportTemplate>();
    }

    public class BaseSetting { 
        public int Id { get; set; }
        public int UserId { get; set; } = 0;
        public string Type { get; set; }
        public string ComputerName { get; set; } = "";
        public string Name { get; set; }
        public string Value { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }

    public class TaxSetting {
        public int Id { get; set; }
        public string DataBaseName { get; set; }
        public int CompanyId { get; set; }
        public int TaxClassId { get; set; }
        public int TaxKeyId { get; set; }
        public string CompanyName { get; set; }
        public string TaxClassName { get; set; }
        public string TaxKeyName { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }

    public class ExportTemplate {
        public int Id { get; set; }
        public int TypeId { get; set; }
        public string Type { get; set; }
        public string Name { get; set; }
        public string FileName { get; set; }
        public string FilePath { get; set; }
        public string FileExtension { get; set; }
        public string TemplateValue { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }
}