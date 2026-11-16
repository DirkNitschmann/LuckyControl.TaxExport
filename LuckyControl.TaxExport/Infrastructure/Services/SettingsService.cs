using System;
using System.Collections.Generic;
using System.Data;
using System.Reflection;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using LuckyControl.TaxExport.Domain.Entities;
using LuckyControl.TaxExport.Infrastructure.Data;
using LuckyControl.TaxExport.Properties;
using Microsoft.Data.SqlClient;

namespace LuckyControl.TaxExport.Infrastructure.Services {
    public class SettingsService {
        private const string DefaultDatabaseName = "eazybusiness";
        private const int CommandTimeoutSeconds = 120;

        private static readonly Regex DatabaseNamePattern = new(@"^[A-Za-z_][A-Za-z0-9_]*$", RegexOptions.Compiled);

        private readonly string? _defaultConnectionString;

        public SettingsService(string? defaultConnectionString = null) {
            _defaultConnectionString = defaultConnectionString;
        }

        // ----- Install -----

        // Idempotent: runs the CREATE TABLE IF NOT EXISTS blocks on every call.
        // Designed to be invoked once on every LuckyControl startup.
        public async Task InstallAsync(
            string? connectionString = null,
            string databaseName = DefaultDatabaseName,
            CancellationToken cancellationToken = default) {
            await using var connection = await OpenConnectionAsync(connectionString, databaseName, cancellationToken);
            var sql = Resources.Sql_InstallSettings.Replace("#cVersion#", EscapeSqlLiteral(ResolveAssemblyVersion()));
            await using var command = new SqlCommand(sql, connection) { CommandTimeout = CommandTimeoutSeconds };
            await command.ExecuteNonQueryAsync(cancellationToken);
        }

        // ----- Aggregate read -----

        public async Task<Settings> ReadSettingsAsync(
            string? connectionString = null,
            string databaseName = DefaultDatabaseName,
            CancellationToken cancellationToken = default) {
            await using var connection = await OpenConnectionAsync(connectionString, databaseName, cancellationToken);
            return new Settings {
                baseSettings = await ReadBaseSettingsCoreAsync(connection, cancellationToken),
                taxSettings = await ReadTaxSettingsCoreAsync(connection, cancellationToken),
                exportTemplates = await ReadExportTemplatesCoreAsync(connection, cancellationToken)
            };
        }

        // ----- BaseSetting CRUD -----

        public async Task<List<BaseSetting>> ReadBaseSettingsAsync(
            string? connectionString = null,
            string databaseName = DefaultDatabaseName,
            CancellationToken cancellationToken = default) {
            await using var connection = await OpenConnectionAsync(connectionString, databaseName, cancellationToken);
            return await ReadBaseSettingsCoreAsync(connection, cancellationToken);
        }

        public async Task<BaseSetting?> ReadBaseSettingAsync(
            int id,
            string? connectionString = null,
            string databaseName = DefaultDatabaseName,
            CancellationToken cancellationToken = default) {
            await using var connection = await OpenConnectionAsync(connectionString, databaseName, cancellationToken);
            return await DbRead.FirstOrDefaultAsync(connection,
                @"SELECT kEinstellung, kBenutzer, cTyp, cComputername, cName, cWert, dErstellt
                  FROM dbo.em_tEinstellung WHERE kEinstellung = @id",
                p => p.Add("@id", SqlDbType.Int).Value = id, MapBase, "SettingsService.ReadBaseSetting", CommandTimeoutSeconds, cancellationToken);
        }

        public async Task<int> CreateBaseSettingAsync(
            BaseSetting setting,
            string? connectionString = null,
            string databaseName = DefaultDatabaseName,
            CancellationToken cancellationToken = default) {
            ArgumentNullException.ThrowIfNull(setting);
            await using var connection = await OpenConnectionAsync(connectionString, databaseName, cancellationToken);
            await using var command = new SqlCommand(
                @"INSERT INTO dbo.em_tEinstellung (kBenutzer, cTyp, cComputername, cName, cWert, dErstellt)
                  OUTPUT INSERTED.kEinstellung
                  VALUES (@userId, @type, @computerName, @name, @value, @createdAt)",
                connection) { CommandTimeout = CommandTimeoutSeconds };
            BindBaseParameters(command, setting);
            var newId = Convert.ToInt32(await command.ExecuteScalarAsync(cancellationToken));
            setting.Id = newId;
            return newId;
        }

        public async Task<bool> UpdateBaseSettingAsync(
            BaseSetting setting,
            string? connectionString = null,
            string databaseName = DefaultDatabaseName,
            CancellationToken cancellationToken = default) {
            ArgumentNullException.ThrowIfNull(setting);
            await using var connection = await OpenConnectionAsync(connectionString, databaseName, cancellationToken);
            await using var command = new SqlCommand(
                @"UPDATE dbo.em_tEinstellung
                  SET kBenutzer = @userId, cTyp = @type, cComputername = @computerName,
                      cName = @name, cWert = @value, dErstellt = @createdAt
                  WHERE kEinstellung = @id",
                connection) { CommandTimeout = CommandTimeoutSeconds };
            command.Parameters.Add("@id", SqlDbType.Int).Value = setting.Id;
            BindBaseParameters(command, setting);
            return await command.ExecuteNonQueryAsync(cancellationToken) > 0;
        }

        public async Task<bool> DeleteBaseSettingAsync(
            int id,
            string? connectionString = null,
            string databaseName = DefaultDatabaseName,
            CancellationToken cancellationToken = default) {
            await using var connection = await OpenConnectionAsync(connectionString, databaseName, cancellationToken);
            await using var command = new SqlCommand(
                "DELETE FROM dbo.em_tEinstellung WHERE kEinstellung = @id",
                connection) { CommandTimeout = CommandTimeoutSeconds };
            command.Parameters.Add("@id", SqlDbType.Int).Value = id;
            return await command.ExecuteNonQueryAsync(cancellationToken) > 0;
        }

        // ----- TaxSetting CRUD -----

        public async Task<List<TaxSetting>> ReadTaxSettingsAsync(
            string? connectionString = null,
            string databaseName = DefaultDatabaseName,
            CancellationToken cancellationToken = default) {
            await using var connection = await OpenConnectionAsync(connectionString, databaseName, cancellationToken);
            return await ReadTaxSettingsCoreAsync(connection, cancellationToken);
        }

        public async Task<TaxSetting?> ReadTaxSettingAsync(
            int id,
            string? connectionString = null,
            string databaseName = DefaultDatabaseName,
            CancellationToken cancellationToken = default) {
            await using var connection = await OpenConnectionAsync(connectionString, databaseName, cancellationToken);
            return await DbRead.FirstOrDefaultAsync(connection,
                @"SELECT kSteuerEinstellung, cDB, kFirma, kSteuerklasse, kSteuerschlussel,
                         cFirma, cSteuerklasse, cSteuerschlussel, dErstellt
                  FROM dbo.em_tSteuerEinstellung WHERE kSteuerEinstellung = @id",
                p => p.Add("@id", SqlDbType.Int).Value = id, MapTax, "SettingsService.ReadTaxSetting", CommandTimeoutSeconds, cancellationToken);
        }

        public async Task<int> CreateTaxSettingAsync(
            TaxSetting setting,
            string? connectionString = null,
            string databaseName = DefaultDatabaseName,
            CancellationToken cancellationToken = default) {
            ArgumentNullException.ThrowIfNull(setting);
            await using var connection = await OpenConnectionAsync(connectionString, databaseName, cancellationToken);
            await using var command = new SqlCommand(
                @"INSERT INTO dbo.em_tSteuerEinstellung
                      (cDB, kFirma, kSteuerklasse, kSteuerschlussel, cFirma, cSteuerklasse, cSteuerschlussel, dErstellt)
                  OUTPUT INSERTED.kSteuerEinstellung
                  VALUES (@db, @company, @taxClass, @taxKey, @companyName, @taxClassName, @taxKeyName, @createdAt)",
                connection) { CommandTimeout = CommandTimeoutSeconds };
            BindTaxParameters(command, setting);
            var newId = Convert.ToInt32(await command.ExecuteScalarAsync(cancellationToken));
            setting.Id = newId;
            return newId;
        }

        public async Task<bool> UpdateTaxSettingAsync(
            TaxSetting setting,
            string? connectionString = null,
            string databaseName = DefaultDatabaseName,
            CancellationToken cancellationToken = default) {
            ArgumentNullException.ThrowIfNull(setting);
            await using var connection = await OpenConnectionAsync(connectionString, databaseName, cancellationToken);
            await using var command = new SqlCommand(
                @"UPDATE dbo.em_tSteuerEinstellung
                  SET cDB = @db, kFirma = @company, kSteuerklasse = @taxClass, kSteuerschlussel = @taxKey,
                      cFirma = @companyName, cSteuerklasse = @taxClassName, cSteuerschlussel = @taxKeyName,
                      dErstellt = @createdAt
                  WHERE kSteuerEinstellung = @id",
                connection) { CommandTimeout = CommandTimeoutSeconds };
            command.Parameters.Add("@id", SqlDbType.Int).Value = setting.Id;
            BindTaxParameters(command, setting);
            return await command.ExecuteNonQueryAsync(cancellationToken) > 0;
        }

        public async Task<bool> DeleteTaxSettingAsync(
            int id,
            string? connectionString = null,
            string databaseName = DefaultDatabaseName,
            CancellationToken cancellationToken = default) {
            await using var connection = await OpenConnectionAsync(connectionString, databaseName, cancellationToken);
            await using var command = new SqlCommand(
                "DELETE FROM dbo.em_tSteuerEinstellung WHERE kSteuerEinstellung = @id",
                connection) { CommandTimeout = CommandTimeoutSeconds };
            command.Parameters.Add("@id", SqlDbType.Int).Value = id;
            return await command.ExecuteNonQueryAsync(cancellationToken) > 0;
        }

        // ----- ExportTemplate CRUD -----

        public async Task<List<ExportTemplate>> ReadExportTemplatesAsync(
            string? connectionString = null,
            string databaseName = DefaultDatabaseName,
            CancellationToken cancellationToken = default) {
            await using var connection = await OpenConnectionAsync(connectionString, databaseName, cancellationToken);
            return await ReadExportTemplatesCoreAsync(connection, cancellationToken);
        }

        public async Task<ExportTemplate?> ReadExportTemplateAsync(
            int id,
            string? connectionString = null,
            string databaseName = DefaultDatabaseName,
            CancellationToken cancellationToken = default) {
            await using var connection = await OpenConnectionAsync(connectionString, databaseName, cancellationToken);
            return await DbRead.FirstOrDefaultAsync(connection,
                @"SELECT kExportVorlage, nTyp, cTyp, cName, cDateiName, cDateiPfad, cFormat, cQuellcode, dErstellt
                  FROM dbo.em_tExportVorlage WHERE kExportVorlage = @id",
                p => p.Add("@id", SqlDbType.Int).Value = id, MapTemplate, "SettingsService.ReadExportTemplate", CommandTimeoutSeconds, cancellationToken);
        }

        public async Task<int> CreateExportTemplateAsync(
            ExportTemplate template,
            string? connectionString = null,
            string databaseName = DefaultDatabaseName,
            CancellationToken cancellationToken = default) {
            ArgumentNullException.ThrowIfNull(template);
            await using var connection = await OpenConnectionAsync(connectionString, databaseName, cancellationToken);
            await using var command = new SqlCommand(
                @"INSERT INTO dbo.em_tExportVorlage
                      (nTyp, cTyp, cName, cDateiName, cDateiPfad, cFormat, cQuellcode, dErstellt)
                  OUTPUT INSERTED.kExportVorlage
                  VALUES (@typeId, @type, @name, @fileName, @filePath, @fileExtension, @templateValue, @createdAt)",
                connection) { CommandTimeout = CommandTimeoutSeconds };
            BindTemplateParameters(command, template);
            var newId = Convert.ToInt32(await command.ExecuteScalarAsync(cancellationToken));
            template.Id = newId;
            return newId;
        }

        public async Task<bool> UpdateExportTemplateAsync(
            ExportTemplate template,
            string? connectionString = null,
            string databaseName = DefaultDatabaseName,
            CancellationToken cancellationToken = default) {
            ArgumentNullException.ThrowIfNull(template);
            await using var connection = await OpenConnectionAsync(connectionString, databaseName, cancellationToken);
            await using var command = new SqlCommand(
                @"UPDATE dbo.em_tExportVorlage
                  SET nTyp = @typeId, cTyp = @type, cName = @name, cDateiName = @fileName,
                      cDateiPfad = @filePath, cFormat = @fileExtension, cQuellcode = @templateValue,
                      dErstellt = @createdAt
                  WHERE kExportVorlage = @id",
                connection) { CommandTimeout = CommandTimeoutSeconds };
            command.Parameters.Add("@id", SqlDbType.Int).Value = template.Id;
            BindTemplateParameters(command, template);
            return await command.ExecuteNonQueryAsync(cancellationToken) > 0;
        }

        public async Task<bool> DeleteExportTemplateAsync(
            int id,
            string? connectionString = null,
            string databaseName = DefaultDatabaseName,
            CancellationToken cancellationToken = default) {
            await using var connection = await OpenConnectionAsync(connectionString, databaseName, cancellationToken);
            await using var command = new SqlCommand(
                "DELETE FROM dbo.em_tExportVorlage WHERE kExportVorlage = @id",
                connection) { CommandTimeout = CommandTimeoutSeconds };
            command.Parameters.Add("@id", SqlDbType.Int).Value = id;
            return await command.ExecuteNonQueryAsync(cancellationToken) > 0;
        }

        // ----- Helpers -----

        private async Task<SqlConnection> OpenConnectionAsync(
            string? connectionString, string databaseName, CancellationToken cancellationToken) {
            EnsureValidDatabaseName(databaseName);
            var effective = !string.IsNullOrWhiteSpace(connectionString)
                ? connectionString
                : _defaultConnectionString
                    ?? throw new InvalidOperationException(
                        "No connection string available: pass one to the method or to the SettingsService constructor.");
            var connection = new SqlConnection(effective);
            await connection.OpenAsync(cancellationToken);
            connection.ChangeDatabase(databaseName);
            return connection;
        }

        private static void EnsureValidDatabaseName(string databaseName) {
            if (string.IsNullOrWhiteSpace(databaseName) || !DatabaseNamePattern.IsMatch(databaseName)) {
                throw new ArgumentException($"Invalid database name: '{databaseName}'.", nameof(databaseName));
            }
        }

        private static string ResolveAssemblyVersion() {
            var assembly = typeof(SettingsService).Assembly;
            var info = assembly.GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion;
            return !string.IsNullOrWhiteSpace(info)
                ? info!
                : assembly.GetName().Version?.ToString() ?? "0.0.0.0";
        }

        private static string EscapeSqlLiteral(string value) => value.Replace("'", "''");

        private static async Task<List<BaseSetting>> ReadBaseSettingsCoreAsync(
            SqlConnection connection, CancellationToken cancellationToken) {
            const string sql = @"SELECT kEinstellung, kBenutzer, cTyp, cComputername, cName, cWert, dErstellt
                                 FROM dbo.em_tEinstellung";
            return await DbRead.ListAsync(connection, sql, null, MapBase, "SettingsService.ReadBaseSettings", CommandTimeoutSeconds, cancellationToken);
        }

        private static async Task<List<TaxSetting>> ReadTaxSettingsCoreAsync(
            SqlConnection connection, CancellationToken cancellationToken) {
            const string sql = @"SELECT kSteuerEinstellung, cDB, kFirma, kSteuerklasse, kSteuerschlussel,
                                        cFirma, cSteuerklasse, cSteuerschlussel, dErstellt
                                 FROM dbo.em_tSteuerEinstellung";
            return await DbRead.ListAsync(connection, sql, null, MapTax, "SettingsService.ReadTaxSettings", CommandTimeoutSeconds, cancellationToken);
        }

        private static async Task<List<ExportTemplate>> ReadExportTemplatesCoreAsync(
            SqlConnection connection, CancellationToken cancellationToken) {
            const string sql = @"SELECT kExportVorlage, nTyp, cTyp, cName, cDateiName, cDateiPfad,
                                        cFormat, cQuellcode, dErstellt
                                 FROM dbo.em_tExportVorlage";
            return await DbRead.ListAsync(connection, sql, null, MapTemplate, "SettingsService.ReadExportTemplates", CommandTimeoutSeconds, cancellationToken);
        }

        // Spalten per Index wie bisher (reader.GetXxx(i)): NULL in einer Pflichtspalte ist ein Fehler des Datensatzes.
        private static BaseSetting MapBase(DbRow row) => new() {
            Id = row.Int32(0),
            UserId = row.Int32(1),
            Type = row.String(2),
            ComputerName = row.String(3),
            Name = row.String(4),
            Value = row.String(5),
            CreatedAt = row.DateTime(6)
        };

        private static TaxSetting MapTax(DbRow row) => new() {
            Id = row.Int32(0),
            DataBaseName = row.String(1),
            CompanyId = row.Int32(2),
            TaxClassId = row.Int32(3),
            TaxKeyId = row.Int32(4),
            CompanyName = row.StringOrEmpty(5),
            TaxClassName = row.StringOrEmpty(6),
            TaxKeyName = row.StringOrEmpty(7),
            CreatedAt = row.DateTime(8)
        };

        private static ExportTemplate MapTemplate(DbRow row) => new() {
            Id = row.Int32(0),
            TypeId = row.Int32(1),
            Type = row.String(2),
            Name = row.String(3),
            FileName = row.String(4),
            FilePath = row.StringOrEmpty(5),
            FileExtension = row.String(6),
            TemplateValue = row.String(7),
            CreatedAt = row.DateTime(8)
        };

        private static void BindBaseParameters(SqlCommand command, BaseSetting setting) {
            command.Parameters.Add("@userId", SqlDbType.Int).Value = setting.UserId;
            command.Parameters.Add("@type", SqlDbType.VarChar, 64).Value = setting.Type ?? string.Empty;
            command.Parameters.Add("@computerName", SqlDbType.VarChar, 64).Value = setting.ComputerName ?? string.Empty;
            command.Parameters.Add("@name", SqlDbType.VarChar, 64).Value = setting.Name ?? string.Empty;
            command.Parameters.Add("@value", SqlDbType.VarChar, 64).Value = setting.Value ?? string.Empty;
            command.Parameters.Add("@createdAt", SqlDbType.DateTime).Value = setting.CreatedAt;
        }

        private static void BindTaxParameters(SqlCommand command, TaxSetting setting) {
            command.Parameters.Add("@db", SqlDbType.VarChar, 64).Value = setting.DataBaseName ?? string.Empty;
            command.Parameters.Add("@company", SqlDbType.Int).Value = setting.CompanyId;
            command.Parameters.Add("@taxClass", SqlDbType.Int).Value = setting.TaxClassId;
            command.Parameters.Add("@taxKey", SqlDbType.Int).Value = setting.TaxKeyId;
            command.Parameters.Add("@companyName", SqlDbType.VarChar, 64).Value = (object?)setting.CompanyName ?? DBNull.Value;
            command.Parameters.Add("@taxClassName", SqlDbType.VarChar, 64).Value = (object?)setting.TaxClassName ?? DBNull.Value;
            command.Parameters.Add("@taxKeyName", SqlDbType.VarChar, 64).Value = (object?)setting.TaxKeyName ?? DBNull.Value;
            command.Parameters.Add("@createdAt", SqlDbType.DateTime).Value = setting.CreatedAt;
        }

        private static void BindTemplateParameters(SqlCommand command, ExportTemplate template) {
            command.Parameters.Add("@typeId", SqlDbType.Int).Value = template.TypeId;
            command.Parameters.Add("@type", SqlDbType.VarChar, 255).Value = template.Type ?? string.Empty;
            command.Parameters.Add("@name", SqlDbType.VarChar, 255).Value = template.Name ?? string.Empty;
            command.Parameters.Add("@fileName", SqlDbType.VarChar, 255).Value = template.FileName ?? string.Empty;
            command.Parameters.Add("@filePath", SqlDbType.VarChar, 255).Value = (object?)template.FilePath ?? DBNull.Value;
            command.Parameters.Add("@fileExtension", SqlDbType.VarChar, 64).Value = template.FileExtension ?? string.Empty;
            command.Parameters.Add("@templateValue", SqlDbType.Text).Value = template.TemplateValue ?? string.Empty;
            command.Parameters.Add("@createdAt", SqlDbType.DateTime).Value = template.CreatedAt;
        }
    }
}
