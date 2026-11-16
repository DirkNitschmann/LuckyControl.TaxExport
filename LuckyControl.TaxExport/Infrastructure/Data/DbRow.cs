using System;
using System.Collections.Generic;
using Microsoft.Data.SqlClient;

namespace LuckyControl.TaxExport.Infrastructure.Data {
    // Eine kopierte Ergebniszeile (Phase 1 von DbRead). Haelt keine Verbindung und keinen Reader.
    //
    // Zwei Zugriffsarten, wie bisher im Code:
    //   - per Name, NACHSICHTIG (wie der fruehere ColumnMap): fehlende Spalte oder NULL -> Ersatzwert. Dieselbe
    //     DocumentPosition wird aus unterschiedlich geformten Abfragen gefuellt, nicht jede liefert jede Spalte.
    //   - per Index, STRENG (wie reader.GetInt32(i)/GetString(i)): NULL ist ein Fehler des Datensatzes.
    public sealed class DbRow {
        private readonly Columns _columns;
        private readonly object?[] _values;

        private DbRow(Columns columns, object?[] values) { _columns = columns; _values = values; }

        internal static DbRow Copy(SqlDataReader reader, Columns columns) {
            var values = new object?[reader.FieldCount];
            reader.GetValues(values!);
            for (int i = 0; i < values.Length; i++)
                if (values[i] is DBNull) values[i] = null;
            return new DbRow(columns, values);
        }

        // Fuer Tests der Auswertung ohne Datenbank.
        internal static DbRow ForTest(IList<KeyValuePair<string, object?>> values) {
            var names = new List<string>();
            var data = new object?[values.Count];
            for (int i = 0; i < values.Count; i++) { names.Add(values[i].Key); data[i] = values[i].Value is DBNull ? null : values[i].Value; }
            return new DbRow(new Columns(names), data);
        }

        // ---- per Name, nachsichtig ----
        public string StringOrEmpty(string column) => TryGet(column, out object? v) && v != null ? Convert.ToString(v) ?? string.Empty : string.Empty;
        public int Int32OrZero(string column) => TryGet(column, out object? v) && v != null ? Convert.ToInt32(v) : 0;
        public decimal DecimalOrZero(string column) => TryGet(column, out object? v) && v != null ? Convert.ToDecimal(v) : 0m;
        public DateTime? DateTimeOrNull(string column) => TryGet(column, out object? v) && v != null ? (DateTime)v : null;

        // ---- per Index, streng ----
        public int Int32(int index) => Convert.ToInt32(Required(index));
        public string String(int index) => (string)Required(index);
        public DateTime DateTime(int index) => (DateTime)Required(index);
        public string StringOrEmpty(int index) => At(index) is string s ? s : string.Empty;

        internal string Describe() => _values.Length == 0 ? "(leer)" : _columns.NameAt(0) + "=" + (Convert.ToString(_values[0]) ?? "NULL");

        private bool TryGet(string column, out object? value) {
            if (_columns.TryGet(column, out int i)) { value = _values[i]; return true; }
            value = null;
            return false;
        }

        private object? At(int index) {
            if (index < 0 || index >= _values.Length) throw new InvalidOperationException("Spalte " + index + " fehlt im Ergebnis");
            return _values[index];
        }

        private object Required(int index) => At(index) ?? throw new InvalidOperationException("Pflichtfeld '" + _columns.NameAt(index) + "' ist leer");

        internal sealed class Columns {
            private readonly Dictionary<string, int> _index = new(StringComparer.OrdinalIgnoreCase);
            private readonly List<string> _names;

            internal Columns(List<string> names) {
                _names = names;
                // Wie der fruehere ColumnMap: bei doppelten Namen gewinnt die LETZTE Spalte.
                for (int i = 0; i < names.Count; i++) _index[names[i]] = i;
            }

            internal static Columns From(SqlDataReader reader) {
                var names = new List<string>(reader.FieldCount);
                for (int i = 0; i < reader.FieldCount; i++) names.Add(reader.GetName(i));
                return new Columns(names);
            }

            internal bool TryGet(string name, out int index) => _index.TryGetValue(name, out index);
            internal string NameAt(int i) => i >= 0 && i < _names.Count ? _names[i] : "#" + i;
        }
    }
}
