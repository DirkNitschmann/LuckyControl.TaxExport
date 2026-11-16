using System;
using System.Collections.Generic;
using System.Data;
using System.Reflection;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using LuckyControl.TaxExport.Domain.Entities;
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
            await using var command = new SqlCommand(
                @"SELECT kEinstellung, kBenutzer, cTyp, cComputername, cName, cWert, dErstellt
                  FROM dbo.em_tEinstellung WHERE kEinstellung = @id",
                connection) { CommandTimeout = CommandTimeoutSeconds };
            command.Parameters.Add("@id", SqlDbType.Int).Value = id;
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            return await reader.ReadAsync(cancellationToken) ? MapBase(reader) : null;
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
            await using var command = new SqlCommand(
                @"SELECT kSteuerEinstellung, cDB, kFirma, kSteuerklasse, kSteuerschlussel,
                         cFirma, cSteuerklasse, cSteuerschlussel, dErstellt
                  FROM dbo.em_tSteuerEinstellung WHERE kSteuerEinstellung = @id",
                connection) { CommandTimeout = CommandTimeoutSeconds };
            command.Parameters.Add("@id", SqlDbType.Int).Value = id;
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            return await reader.ReadAsync(cancellationToken) ? MapTax(reader) : null;
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
            await using var command = new SqlCommand(
                @"SELECT kExportVorlage, nTyp, cTyp, cName, cDateiName, cDateiPfad, cFormat, cQuellcode, dErstellt
                  FROM dbo.em_tExportVorlage WHERE kExportVorlage = @id",
                connection) { CommandTimeout = CommandTimeoutSeconds };
            command.Parameters.Add("@id", SqlDbType.Int).Value = id;
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            return await reader.ReadAsync(cancellationToken) ? MapTemplate(reader) : null;
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
            await using var command = new SqlCommand(sql, connection) { CommandTimeout = CommandTimeoutSeconds };
            var list = new List<BaseSetting>();
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken)) {
                list.Add(MapBase(reader));
            }
            return list;
        }

        private static async Task<List<TaxSetting>> ReadTaxSettingsCoreAsync(
            SqlConnection connection, CancellationToken cancellationToken) {
            const string sql = @"SELECT kSteuerEinstellung, cDB, kFirma, kSteuerklasse, kSteuerschlussel,
                                        cFirma, cSteuerklasse, cSteuerschlussel, dErstellt
                                 FROM dbo.em_tSteuerEinstellung";
            await using var command = new SqlCommand(sql, connection) { CommandTimeout = CommandTimeoutSeconds };
            var list = new List<TaxSetting>();
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken)) {
                list.Add(MapTax(reader));
            }
            return list;
        }

        private static async Task<List<ExportTemplate>> ReadExportTemplatesCoreAsync(
            SqlConnection connection, CancellationToken cancellationToken) {
            const string sql = @"SELECT kExportVorlage, nTyp, cTyp, cName, cDateiName, cDateiPfad,
                                        cFormat, cQuellcode, dErstellt
                                 FROM dbo.em_tExportVorlage";
            await using var command = new SqlCommand(sql, connection) { CommandTimeout = CommandTimeoutSeconds };
            var list = new List<ExportTemplate>();
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken)) {
                list.Add(MapTemplate(reader));
            }
            return list;
        }

        private static BaseSetting MapBase(SqlDataReader reader) => new() {
            Id = reader.GetInt32(0),
            UserId = reader.GetInt32(1),
            Type = reader.GetString(2),
            ComputerName = reader.GetString(3),
            Name = reader.GetString(4),
            Value = reader.GetString(5),
            CreatedAt = reader.GetDateTime(6)
        };

        private static TaxSetting MapTax(SqlDataReader reader) => new() {
            Id = reader.GetInt32(0),
            DataBaseName = reader.GetString(1),
            CompanyId = reader.GetInt32(2),
            TaxClassId = reader.GetInt32(3),
            TaxKeyId = reader.GetInt32(4),
            CompanyName = reader.IsDBNull(5) ? string.Empty : reader.GetString(5),
            TaxClassName = reader.IsDBNull(6) ? string.Empty : reader.GetString(6),
            TaxKeyName = reader.IsDBNull(7) ? string.Empty : reader.GetString(7),
            CreatedAt = reader.GetDateTime(8)
        };

        private static ExportTemplate MapTemplate(SqlDataReader reader) => new() {
            Id = reader.GetInt32(0),
            TypeId = reader.GetInt32(1),
            Type = reader.GetString(2),
            Name = reader.GetString(3),
            FileName = reader.GetString(4),
            FilePath = reader.IsDBNull(5) ? string.Empty : reader.GetString(5),
            FileExtension = reader.GetString(6),
            TemplateValue = reader.GetString(7),
            CreatedAt = reader.GetDateTime(8)
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
