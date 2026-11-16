using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Data.SqlClient;

namespace LuckyControl.TaxExport.Infrastructure.Data {
    // Die EINE Stelle, an der TaxExport Datenbank-Ergebnisse liest (HUB 5608, Vorfall Nesatec 12.11.2026).
    //
    // Ein SqlDataReader ist ein laufender Datenstrom auf dem SQL Server. Brach die Auswertung einer Zeile mitten in der
    // Schleife ab (oder wurde das CancellationToken ausgeloest), holte das Dispose des Readers erst den GANZEN Rest des
    // Ergebnisses ab - bei einem Export ueber Jahre und 600 s Timeout lange Zeit, in der die Abfrage ihre Sperren hielt.
    //
    // Zusagen:
    //   - Phase 1 "Abholen": im offenen Reader wird nur kopiert (DbRow), nichts gedeutet. Bricht das Abholen ab,
    //     wird die Abfrage zuerst abgebrochen (Cancel) und erst dann geschlossen.
    //   - Phase 2 "Auswerten": erst wenn der Reader zu ist.
    //   - ALLES ODER NICHTS: ein Steuer-Export mit fehlender Position ist falsch, nicht "fast richtig". Scheitert eine
    //     Zeile, wirft ListAsync eine DbReadException mit allen fehlerhaften Zeilen (bisher warf die erste Zeile).
    // Ein Waechter-Test verbietet ExecuteReader ausserhalb dieser Datei.
    internal static class DbRead {
        public static async Task<List<T>> ListAsync<T>(SqlConnection connection, string sql, Action<SqlParameterCollection>? bind,
                                                       Func<DbRow, T> map, string what, int timeoutSeconds,
                                                       CancellationToken cancellationToken) {
            List<DbRow> rows = await FetchAsync(connection, sql, bind, timeoutSeconds, cancellationToken, null);
            return Evaluate(rows, map, what);
        }

        // Einzelobjekt: erste Zeile oder default (nicht gefunden).
        public static async Task<T?> FirstOrDefaultAsync<T>(SqlConnection connection, string sql, Action<SqlParameterCollection>? bind,
                                                             Func<DbRow, T> map, string what, int timeoutSeconds,
                                                             CancellationToken cancellationToken) where T : class {
            List<DbRow> rows = await FetchAsync(connection, sql, bind, timeoutSeconds, cancellationToken, null);
            return rows.Count == 0 ? null : Evaluate(rows.GetRange(0, 1), map, what)[0];
        }

        // Phase 2 getrennt aufrufbar (Tests ohne Datenbank).
        internal static List<T> Evaluate<T>(IReadOnlyList<DbRow> rows, Func<DbRow, T> map, string what) {
            var items = new List<T>(rows.Count);
            var errors = new List<string>();
            foreach (DbRow row in rows) {
                try { items.Add(map(row)); }
                catch (Exception ex) { errors.Add(row.Describe() + ": " + ex.Message); }
            }
            if (errors.Count > 0) throw new DbReadException(what, errors);
            return items;
        }

        // onRowCopied: nur fuer Tests, simuliert einen Abbruch mitten im Abholen.
        internal static async Task<List<DbRow>> FetchAsync(SqlConnection connection, string sql, Action<SqlParameterCollection>? bind,
                                                           int timeoutSeconds, CancellationToken cancellationToken, Action<int>? onRowCopied) {
            var rows = new List<DbRow>();
            await using var command = new SqlCommand(sql, connection) { CommandTimeout = timeoutSeconds };
            bind?.Invoke(command.Parameters);
            bool completed = false;
            SqlDataReader reader = await command.ExecuteReaderAsync(cancellationToken);
            try {
                DbRow.Columns columns = DbRow.Columns.From(reader);
                while (await reader.ReadAsync(cancellationToken)) {
                    rows.Add(DbRow.Copy(reader, columns));
                    onRowCopied?.Invoke(rows.Count);
                }
                completed = true;
            }
            finally {
                // Reihenfolge ist wichtig: erst abbrechen, dann schliessen (siehe Kopf).
                if (!completed) {
                    try { command.Cancel(); } catch { /* Schliessen folgt trotzdem */ }
                }
                await reader.DisposeAsync();
            }
            return rows;
        }
    }

    // Unvollstaendig gelesen: der Export wird nicht mit fehlenden Positionen geliefert.
    public sealed class DbReadException : InvalidOperationException {
        public IReadOnlyList<string> RowErrors { get; }
        public DbReadException(string what, IReadOnlyList<string> rowErrors)
            : base($"{what}: {rowErrors.Count} Datensatz/Datensaetze nicht lesbar - Ergebnis waere unvollstaendig. " + string.Join(" | ", System.Linq.Enumerable.Take(rowErrors, 10)) + (rowErrors.Count > 10 ? " | ... (gekuerzt, alle in RowErrors)" : "")) {
            RowErrors = rowErrors;
        }
    }
}
