using System.Text.RegularExpressions;
using LuckyControl.TaxExport.Infrastructure.Data;
using Microsoft.Data.SqlClient;
using Newtonsoft.Json.Linq;
using Xunit;

namespace LuckyControl.TaxExport.UnitTests {
    // HUB 5608: die Lese-Klasse von TaxExport (Vorfall Nesatec 12.11.2026).
    public class DbReadTests {
        private static DbRow Row(params (string name, object? value)[] values)
            => DbRow.ForTest(values.Select(v => new KeyValuePair<string, object?>(v.name, v.value)).ToList());

        // Nachsichtig per Name wie der fruehere ColumnMap: fehlende Spalte oder NULL -> Ersatzwert.
        [Fact]
        public void ByName_MissingOrNull_GivesDefaults() {
            DbRow row = Row(("Type", "R"), ("VatRate", DBNull.Value), ("CreatedAt", DBNull.Value));
            Assert.Equal("R", row.StringOrEmpty("type"));
            Assert.Equal(string.Empty, row.StringOrEmpty("Fehlt"));
            Assert.Equal(0m, row.DecimalOrZero("VatRate"));
            Assert.Equal(0, row.Int32OrZero("Fehlt"));
            Assert.Null(row.DateTimeOrNull("CreatedAt"));
        }

        // Streng per Index wie reader.GetString(i): NULL ist ein Fehler des Datensatzes.
        [Fact]
        public void ByIndex_NullIsAnError() {
            DbRow row = Row(("kEinstellung", 1), ("cName", DBNull.Value));
            Assert.Equal(1, row.Int32(0));
            Assert.Equal(string.Empty, row.StringOrEmpty(1));
            Assert.Throws<InvalidOperationException>(() => row.String(1));
            Assert.Throws<InvalidOperationException>(() => row.Int32(5));
        }

        // Alles oder nichts: ein Steuer-Export mit fehlender Position waere falsch - alle fehlerhaften Zeilen im Fehler.
        [Fact]
        public void Evaluate_AnyBadRow_ThrowsWithAllBadRows() {
            var rows = new List<DbRow> { Row(("Id", 1), ("Name", "a")), Row(("Id", 2), ("Name", DBNull.Value)), Row(("Id", 3), ("Name", DBNull.Value)) };
            var ex = Assert.Throws<DbReadException>(() => DbRead.Evaluate(rows, r => r.String(1), "Test"));
            Assert.Equal(2, ex.RowErrors.Count);
            Assert.Contains("Id=2", ex.RowErrors[0]);
            Assert.Equal(new[] { "a" }, DbRead.Evaluate(rows.Take(1).ToList(), r => r.String(1), "Test"));
        }

        // Waechter: ExecuteReader nur in DbRead.cs.
        [Fact]
        public void ExecuteReader_OnlyInDbRead() {
            string? root = AppContext.BaseDirectory;
            while (root != null && !Directory.Exists(Path.Combine(root, "LuckyControl.TaxExport", "Infrastructure"))) root = Path.GetDirectoryName(root);
            Assert.NotNull(root);
            var call = new Regex(@"\b(?:Begin)?ExecuteReader(?:Async)?\s*\(");
            var hits = Directory.GetFiles(Path.Combine(root!, "LuckyControl.TaxExport"), "*.cs", SearchOption.AllDirectories)
                .Where(f => !f.Contains($"{Path.DirectorySeparatorChar}obj{Path.DirectorySeparatorChar}") && !f.EndsWith("DbRead.cs"))
                .Where(f => File.ReadAllLines(f).Any(l => !l.TrimStart().StartsWith("//") && call.IsMatch(l)))
                .ToList();
            Assert.True(hits.Count == 0, "ExecuteReader ausserhalb von DbRead: " + string.Join(", ", hits));
        }

        // Nachbau des Vorfalls: Abbruch mitten im Abholen unter REPEATABLE READ - die Sperren sind sofort frei.
        [SkippableFact]
        public async Task Abort_ReleasesLocks() {
            string? cs = LocalConnectionString(out string? reason);
            Skip.If(cs == null, reason);
            cs = new SqlConnectionStringBuilder(cs) { Pooling = false }.ConnectionString;
            string table = "##dbread_" + Guid.NewGuid().ToString("N");
            await using var owner = new SqlConnection(cs);
            await owner.OpenAsync();
            await Exec(owner, $"CREATE TABLE {table} (id int NOT NULL PRIMARY KEY, pad char(800) NOT NULL); " +
                              $"INSERT INTO {table} SELECT TOP (100000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)), 'x' FROM sys.all_objects a CROSS JOIN sys.all_objects b;");
            try {
                await using var reader = new SqlConnection(cs);
                await reader.OpenAsync();
                await Exec(reader, "SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;");
                await Assert.ThrowsAnyAsync<InvalidOperationException>(() =>
                    DbRead.FetchAsync(reader, $"SELECT id, pad FROM {table} ORDER BY id", null, 60, CancellationToken.None,
                        n => { if (n == 100) throw new InvalidOperationException("simulierter Abbruch"); }));

                await using var writer = new SqlConnection(cs);
                await writer.OpenAsync();
                await Exec(writer, $"SET LOCK_TIMEOUT 3000; UPDATE {table} SET pad = 'y' WHERE id = 50;");   // wuerde sonst mit 1222 scheitern
            }
            finally { await Exec(owner, $"IF OBJECT_ID('tempdb..{table}') IS NOT NULL DROP TABLE {table};"); }
        }

        private static async Task Exec(SqlConnection c, string sql) {
            await using var cmd = new SqlCommand(sql, c) { CommandTimeout = 60 };
            await cmd.ExecuteNonQueryAsync();
        }

        // Testschutz: nur ein SQL Server auf diesem Rechner.
        private static string? LocalConnectionString(out string? reason) {
            string? dir = AppContext.BaseDirectory;
            while (dir != null && !File.Exists(Path.Combine(dir, "testsettings.local.json"))) dir = Path.GetDirectoryName(dir);
            if (dir == null) { reason = "testsettings.local.json fehlt"; return null; }
            string? cs = (string?)JObject.Parse(File.ReadAllText(Path.Combine(dir, "testsettings.local.json")))["ConnectionString"];
            if (string.IsNullOrWhiteSpace(cs)) { reason = "ConnectionString fehlt"; return null; }
            string host = new SqlConnectionStringBuilder(cs).DataSource.Split('\\', ',')[0].Replace("tcp:", "").Trim();
            bool local = host is "." or "127.0.0.1" or "::1" || host.Equals("(local)", StringComparison.OrdinalIgnoreCase)
                         || host.Equals("localhost", StringComparison.OrdinalIgnoreCase) || host.Equals(Environment.MachineName, StringComparison.OrdinalIgnoreCase);
            reason = local ? null : $"Testschutz: '{host}' ist kein lokaler SQL Server";
            return local ? cs : null;
        }
    }
}
