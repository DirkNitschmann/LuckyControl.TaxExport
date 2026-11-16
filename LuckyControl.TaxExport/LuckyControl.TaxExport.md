# LuckyControl.TaxExport — Technische Dokumentation

Zielgruppe: KI-Assistent (Claude), der innerhalb der **LuckyControl**-Suite eine neue WinForms-App entwickeln soll, die die Funktionalität des bisherigen `TaxExport`-WinForms-Tools auf Basis dieser Library ablöst.

Diese Library ist **reine Datenzugriffs- und Domänenschicht** — kein UI, keine API, kein ausführbares Programm. Sie liest Verkaufsbelege, Rechnungskorrekturen und Lieferantenbestellungen aus einer **JTL Wawi**-SQL-Server-Datenbank und liefert sie als flache `DocumentPosition`-Liste zurück (eine Zeile = eine Belegposition, denormalisiert für Steuer-/Buchhaltungsexport im DATEV-Stil).

---

## 1. Was die WinForms-App leisten muss

Die App ersetzt das alte `TaxExport.exe` (WinForms). Funktional muss sie:

1. **JTL-Wawi-Datenbank wählen / Verbindung herstellen** (SQL-Server-Connection-String, Datenbankname).
2. **Drei Belegarten** abrufen können:
   - Verkaufsrechnungen (`ReadSalesInvoicePositionsAsync`)
   - Gutschriften / Rechnungskorrekturen (`ReadSalesCreditNotePositionsAsync`)
   - Lieferantenbestellungen (`ReadPurchaseOrdersAsync`)
3. **Filter** dem Anwender bereitstellen — siehe Abschnitt 6.
4. **Ergebnis als Grid** darstellen (DataGridView o. Ä.) und nach **CSV/Excel** exportieren bzw. an die DATEV-/Buchhaltungs-Exportlogik der LuckyControl-Suite weiterreichen.
5. **Lange Laufzeiten** sauber behandeln — die SQL-Skripte sind groß und können auf großen DBs Minuten dauern (CommandTimeout: 600 s). UI darf nicht blockieren → die Service-Methoden sind `async` und akzeptieren `CancellationToken`.

> Die eigentliche Steuer-/DATEV-Buchungslogik (Differenzbesteuerungs-Splits, Reverse-Charge-Verarbeitung, DATEV-Mappings) findet bereits **im SQL** statt. Die App muss diese Felder nur darstellen und exportieren — nicht erneut berechnen.

---

## 2. Projekt-Eckdaten

| | |
|---|---|
| Solution | `LuckyControl.TaxExport.slnx` (XML-Format) |
| Projekt | `LuckyControl.TaxExport.csproj` |
| Target Framework | `net10.0` |
| `Nullable` | enabled |
| `ImplicitUsings` | enabled |
| Wichtige Abhängigkeit | `Microsoft.Data.SqlClient` 6.0.2 |
| Test-Konsumentenprojekt | `..\LuckyControl.TaxExport.Tests\` (einfaches Konsolen-Smoke-Test) |
| Sprache der Domäne | Deutsch (JTL Wawi, DATEV, deutsches UStG) |

Build:

```powershell
dotnet build LuckyControl.TaxExport.csproj
```

Es gibt **keinen** Entry-Point in dieser Library. Die WinForms-App wird ein **eigenes** Projekt (im LuckyControl-Repo), das diese Library als Project-Reference einbindet.

---

## 3. Architektur (zwei dünne Schichten)

```
LuckyControl.TaxExport/
├── Domain/
│   ├── Entities/
│   │   └── DocumentPosition.cs        // 100+ Properties, eine pro Belegzeile
│   └── Queries/
│       ├── SalesInvoiceQuery.cs       // Filter-DTO für Sales/Credit
│       └── PurchaseOrderQuery.cs      // Filter-DTO für Einkauf
├── Infrastructure/
│   └── Services/
│       └── DocumentService.cs         // Public API — 3 Methoden
├── Properties/
│   ├── Resources.resx                 // bindet die 4 SQL-Dateien als string-Resources
│   └── Resources.Designer.cs          // AUTO-GENERIERT — nicht von Hand editieren
└── Resources/
    ├── Sql_ReadSalesInvoicesJtlWawi16xx.sql   // Wawi 1.6.x – 1.11.x
    ├── Sql_ReadSalesInvoicesJtlWawi20xx.sql   // Wawi 2.0.x
    ├── Sql_ReadSalesCreditNotesWawi16xx.sql   // alle Versionen (kein 2.0-Variant)
    └── Sql_ReadPurchaseOrders.sql             // alle Versionen
```

**Keine Repository-, UoW-, Mediator-, DI-Layer** dazwischen. Die WinForms-App ruft `DocumentService` direkt. Wenn DI in LuckyControl etabliert ist, kann `DocumentService` problemlos als Singleton/Scoped registriert werden — er ist zustandslos.

---

## 4. Public API

Eine einzige Service-Klasse mit drei Methoden:

```csharp
namespace LuckyControl.TaxExport.Infrastructure.Services;

public class DocumentService {
    public Task<List<DocumentPosition>> ReadSalesInvoicePositionsAsync(
        SalesInvoiceQuery query, CancellationToken cancellationToken = default);

    public Task<List<DocumentPosition>> ReadSalesCreditNotePositionsAsync(
        SalesInvoiceQuery query, CancellationToken cancellationToken = default);

    public Task<List<DocumentPosition>> ReadPurchaseOrdersAsync(
        PurchaseOrderQuery query, CancellationToken cancellationToken = default);
}
```

Alle drei Methoden:

- Öffnen **selbst** die `SqlConnection` aus dem `ConnectionString` in der Query.
- Validieren den `DatabaseName` gegen `^[A-Za-z_][A-Za-z0-9_]*$` — Schutz gegen SQL-Injection im `USE`-Statement. Bei Verstoß: `ArgumentException`.
- Wenden ein **String-Substitutions-System** auf die SQL-Vorlage an (Platzhalter `#cDB#`, `*cPlattformen*` etc. — siehe Abschnitt 7).
- Liefern eine flache `List<DocumentPosition>`. **Eine Liste = ein Belegtyp**. Die App kombiniert ggf. Rechnungen + Gutschriften + Einkäufe selbst.
- `CommandTimeout` = **600 Sekunden** (für große DBs nötig).
- Mapping aus dem `SqlDataReader` läuft über eine interne `ColumnMap`-Klasse, die fehlende Spalten **toleriert** (gibt Defaults zurück). Das ist Absicht: alle drei SQL-Templates befüllen dieselbe `DocumentPosition`, geben aber teilweise unterschiedliche Spalten-Sets aus.

### Wawi-Version-Erkennung (nur Sales Invoices)

`ReadSalesInvoicePositionsAsync` macht **vor** der eigentlichen Abfrage ein:

```sql
SELECT TOP 1 cVersion FROM [<db>].[dbo].[tVersion]
```

und wählt anhand des ersten Zeichens das passende SQL-Template:

- `2…` → `Sql_ReadSalesInvoicesJtlWawi20xx`
- alles andere (`1…`, leer) → `Sql_ReadSalesInvoicesJtlWawi16xx`

Beide Templates liefern **dieselben Spalten** (1:1 auf `DocumentPosition`). Die zugrundeliegende JTL-Wawi-Schema-Generation hat sich aber zwischen 1.x und 2.x stark verändert — daher zwei separate Skripte.

Gutschriften und Einkauf haben **keine** 2.0-Variante (gibt es schlicht nicht — das alte Template funktioniert für beide Schema-Versionen).

---

## 5. `DocumentPosition` — das Rückgabemodell

Die zentrale POCO unter `Domain/Entities/DocumentPosition.cs`. Eine Instanz = eine Belegzeile (denormalisiert).

### Wichtige Felder gruppiert

**Beleg-Identität / Kontext**
- `Type` — `"Invoice"`, `"Stornierte Rechnung"`, `"Externe Rechnung"`, `"Auftrag"`, `"Gutschrift"`, `"PurchaseOrder"` (vom SQL gesetzt; entspricht `cTyp`).
- `SalesOrderId`, `SalesInvoiceId`, `SalesInvoiceCorrectionId`, `CustomerId`, `CompanyId`, `ProductId`, `SakesOrderPositionId` (sic — Tippfehler im Original-Code, **nicht** korrigieren ohne SQL-Mapping anzupassen).
- `SalesOrderNumber`, `ExternalSalesOrderNumber`, `SalesInvoiceNumber`, `SalesInvoiceCorrectionNumber`, `CustomerNumber`, `DebitorNumber`, `VatIdNumber`.
- `PlatformName`, `PaymentMethod`, `ShippingMethod`, `Status`, `Comment1`, `Comment2`.

**Steuer- / Buchhaltungsflags (Kern des Exports!)**
- `BookingAccount` — DATEV-Erlöskonto (Steuerkonto aus `tSteuerschluessel`).
- `BookingAccountPaymentMethod` — DATEV-Gegenkonto (Zahlungsweg-Konto).
- `Currency`, `CurrencyFactor` — Original-Währung + Faktor zur Basiswährung.
- `VatRate` — angewandter MwSt-Satz in Prozent.
- `IsEU` — Rechnungsadresse im EU-Ausland.
- `IsIGL` — innergemeinschaftliche Lieferung (B2B EU mit gültiger USt-ID, steuerfrei).
- `IsReverseCharge` — §13b UStG / EU Reverse Charge (Empfänger schuldet Steuer).
- `IsDifferencialTaxation` — Differenzbesteuerung §25a UStG aktiv (bool).
- `DifferentialTaxationMode` — 0=keine, 1=Einzeldifferenzbesteuerung §25a Abs. 3, 2=Gesamtdifferenzbesteuerung §25a Abs. 4.
- `DepartmentCountry` — Versandland-ISO.

**Mengen / Preise (Einzel- und Gesamtwerte, jeweils auch in Basiswährung)**
- `Quantity`
- `NetPurchasingPrice`, `TotalNetPurchasingPrice` — EK netto.
- `NetPrice`, `TotalNetPrice`, `GrossPrice`, `TotalGrossPrice` — VK Original-Währung.
- `NetPriceInBaseCurrency`, `TotalNetPriceInBaseCurrency`, `GrossPriceInBaseCurrency`, `TotalGrossPriceInBaseCurrency` — VK in Basiswährung.
- `TotalPayd` (sic — Tippfehler, ist `dBezahlt`-Gesamtbetrag).

**Firmen-Stammdaten (zur Belegzeile gejoint)**
- `CompanyName`, `CompanyCeo`, `CompanyStreet`, `CompanyPostalCode`, `CompanyCity`, `CompanyCountry`, `CompanyHomepage`, `CompanyEmail`.
- Bank: `CompanyBankName`, `CompanyAccountNumber`, `CompanyBankCode`, `CompanyIban`, `CompanyBic`.
- `CompanyTaxNumber`, `CompanyCreditorId`.

**Rechnungs- und Lieferadresse (zwei komplette Adressblöcke)**
- `InvoiceAddress*` (Salutation, CompanyName, FirstName, LastName, Street, PostalCode, City, FederalState, Country, Phone, Fax, Mobile, Email).
- `ShippingAddress*` + zusätzlich `ShippingAddressCountryIso`.

**Position-Detail**
- `Sku`, `Name`, `PositionTypeId`, `SortNumber`, `SerialNumbers`, `BatchNumbers`, `PositionComment`.

**Datumsfelder (alle `DateTime?`)**
- `CreatedAt` (nicht nullable — Default falls fehlend), `SalesOrderDate`, `SalesInvoiceDate`, `ShippedAt`, `PaydAt`, `ShppingDate` (sic — Tippfehler).

**Einkaufsspezifisch (nur bei `Type == "PurchaseOrder"` befüllt)**
- `PurchaseOrderId`, `SupplierId`, `PurchaseOrderNumber`, `PurchaseReferenceOrderNumber`, `PurchaseExternalDocumentNumber`.
- `SupplierNumber`, `SupplierCompanyName`, `SupplierCompanyNameAddition`, `SupplierSalutation`, `SupplierFirstName`, `SupplierLastName`, `SupplierStreet`, `SupplierPostalCode`, `SupplierCity`, `SupplierFederalState`, `SupplierCountry`, `SupplierPhone`, `SupplierFax`, `SupplierEmail`, `SupplierHomepage`, `SupplierVatIdNumber`.

> **Tippfehler in den Property-Namen** (`SakesOrderPositionId`, `TotalPayd`, `ShppingDate`, `IsDifferencialTaxation`) sind absichtlich erhalten — sie matchen 1:1 die SQL-Aliasnamen (`AS SakesOrderPositionId` etc.). Korrektur müsste in beiden SQL-Templates + im Mapper synchron erfolgen.

---

## 6. Filterparameter (UI-Eingaben)

### `SalesInvoiceQuery` — für Rechnungen und Gutschriften

```csharp
public class SalesInvoiceQuery {
    public required string ConnectionString { get; init; }
    public required string DatabaseName { get; init; }
    public required DateTime StartDate { get; init; }
    public required DateTime EndDate { get; init; }

    public bool FilterByPaymentDate { get; init; }          // false=Belegdatum, true=Zahldatum
    public string? SearchTerm { get; init; }                 // Substring-Match: RechnungsNr, ArtNr, Artikelname
    public int CompanyId { get; init; }                      // 0 = alle Mandanten
    public decimal? VatRate { get; init; }                   // null = alle, sonst exakt
    public RegionFilter Region { get; init; } = All;         // All | Eu | NonEu
    public DifferentialTaxationFilter DifferentialTaxation
        { get; init; } = All;                                // All | Yes | No

    // JTL-Wawi-Plattformtypen (tPlattform.nTyp) — null = 1..9 (alles)
    public IReadOnlyList<int>? PlatformTypes { get; init; }
}

public enum RegionFilter                  { All=0, Eu=1, NonEu=2 }
public enum DifferentialTaxationFilter    { All=0, Yes=1, No=2 }
```

**UI-Mapping-Vorschlag:**

| UI-Element | Property |
|---|---|
| DB-Connection-Dropdown / -Editor | `ConnectionString`, `DatabaseName` |
| Datepicker "von" / "bis" | `StartDate`, `EndDate` |
| Checkbox "Nach Zahldatum filtern" | `FilterByPaymentDate` |
| Suchfeld | `SearchTerm` |
| Mandanten-Dropdown (`tFirma`) | `CompanyId` (0 = alle) |
| MwSt-Eingabe (frei) | `VatRate` |
| Radio "Alle / EU / Nicht-EU" | `Region` |
| Radio "Alle / Diff.bestg. / Nicht-Diff." | `DifferentialTaxation` |
| Multi-Select "Plattformen" | `PlatformTypes` |

### `PurchaseOrderQuery` — für Lieferantenbestellungen

```csharp
public class PurchaseOrderQuery {
    public required string ConnectionString { get; init; }
    public required string DatabaseName { get; init; }
    public required DateTime StartDate { get; init; }
    public required DateTime EndDate { get; init; }

    public string? SearchTerm { get; init; }
    public int CompanyId { get; init; }
    public int SupplierId { get; init; }
    public int SearchTemplateId { get; init; }     // em_tSuchvorlage — gespeicherte WHERE-Snippets
    public DifferentialTaxationFilter DifferentialTaxation { get; init; } = All;
    public bool BookingAccountFromMass { get; init; }   // Buchungskonto pro Bestellung aus dominantem Wert
}
```

**Besonderheiten Einkauf:**

- `SearchTemplateId` referenziert `em_tSuchvorlage`/`em_tSuchvorlageWert` — gespeicherte SQL-WHERE-Snippets, die LuckyControl/Wawi-Anwender vorab konfiguriert haben. Im UI als Dropdown anbieten.
- `BookingAccountFromMass=true` schreibt das pro Position ermittelte Buchungskonto so um, dass eine ganze Bestellung dasselbe Konto bekommt (das in den Positionen am häufigsten / nach VK-Summe dominante). Sinnvoll für Buchhaltungsbelegfluss.

---

## 7. SQL-Templates & Platzhalter

Die SQL-Dateien unter `Resources/` werden über `Resources.resx` als **string-Resources** kompiliert. Pfad-Beispiel:

```csharp
string sql = LuckyControl.TaxExport.Properties.Resources.Sql_ReadSalesInvoicesJtlWawi16xx;
```

Vor dem Ausführen werden Platzhalter durch **String-Replace** ersetzt — diese sind **keine** echten T-SQL-Parameter und dürfen nicht durch `@param` ersetzt werden:

### Sales (Invoices/Credits) — `ApplyPlaceholders` + `AddParameters`

| Platzhalter | Wert | Bedeutung |
|---|---|---|
| `#cDB#` | `[<DatabaseName>]` | Datenbank-Identifier für `USE` und cross-DB JOINs |
| `*cPlattformen*` | `1,2,3,…` CSV | `tPlattform.nTyp IN (…)` |
| `#nTypeIN#` | `""` | reserviert (aktuell leer) |
| `#nDifferenz#` | `""` | reserviert (aktuell leer) |

Echte SQL-Parameter (über `SqlParameterCollection`):

| Parameter | Typ | Quelle |
|---|---|---|
| `@dDatumStart` | DateTime | `query.StartDate` |
| `@dDatumEnde` | DateTime | `query.EndDate` + bis Ende-des-Tages |
| `@nZahldatum` | Int | `FilterByPaymentDate ? 1 : 0` |
| `@cSuchbegriff` | NVarChar(255) | `SearchTerm` |
| `@nRegion` | Int | `(int)Region` |
| `@nPosition` | Int | `(int)DifferentialTaxation` |
| `@kFirma` | Int | `CompanyId` |
| `@fMwSt` | Float | `VatRate ?? -1` (-1 = alle) |
| `@nBuchungskontoVersandkostenPositionAusMasse` | Int | 0 (fix) |
| `@nEKSteucklistenKomponentenAnwenden` | Int | 0 (fix) |
| `@nNullEuroPositionen` | Int | 0 (fix) |
| `@nStuecklistenfilter` | Int | 0 (fix) |

### Purchase Orders — `ApplyPurchasePlaceholders`

Die Einkaufs-SQL nutzt `sp_executesql` intern und braucht daher **inlined** Werte (auch Daten/Suchbegriff):

| Platzhalter | Wert |
|---|---|
| `#cDB#` | `[<DatabaseName>]` |
| `#cDBraw#` | `<DatabaseName>` (für `Steuerdaten.cDB = '…'` String-Literal) |
| `#nBuchungskontoVersandkostenPositionAusMasse#` | `0`/`1` |
| `#nPosition#` | `(int)DifferentialTaxation` |
| `#kFirma#` | `CompanyId` |
| `#kLieferant#` | `SupplierId` |
| `#kSuchvorlage#` | `SearchTemplateId` |
| `#dDatumStart#` | `yyyy-MM-dd` |
| `#dDatumEnde#` | `yyyy-MM-dd` |
| `#cSuchbegriff#` | `SearchTerm` mit doppelten Single Quotes escaped |

**Wichtig:** Wenn die App neue SQL-Dateien hinzufügt, müssen drei Stellen synchron gepflegt werden:
1. Datei unter `Resources/`.
2. Eintrag in `Properties/Resources.resx` (Typ `System.Resources.ResXFileRef, System.Windows.Forms`).
3. Verwendung im `DocumentService`.

`Resources.Designer.cs` wird **automatisch** regeneriert (ResXFileCodeGenerator) — nicht per Hand bearbeiten.

---

## 8. Deutsche Steuer- und Domänenbegriffe

Die Library spricht in JTL-Wawi-Vokabular (deutsch). Die wichtigsten Begriffe für UI-Labels und Validierung:

| JTL / SQL | DocumentPosition | Bedeutung |
|---|---|---|
| `tBestellung` / `kBestellung` | `SalesOrderId` | Verkaufsauftrag |
| `tRechnung` / `kRechnung` | `SalesInvoiceId` | Ausgangsrechnung |
| `tRechnungskorrektur` | `SalesInvoiceCorrectionId` | Gutschrift / Rechnungskorrektur |
| `tLieferantenBestellung` | `PurchaseOrderId` | Lieferantenbestellung (Einkauf) |
| `tFirma` / `kFirma` | `CompanyId` | Mandant / eigene Firma |
| `tKunde` / `kKunde` | `CustomerId` | Kundennr (JTL-intern, ≠ DATEV-Debitor!) |
| `cDebitorennummer` | `DebitorNumber` | **DATEV-Debitorkonto** |
| `tLand.nEU` | `IsEU` | Land ist EU-Mitglied |
| IGL | `IsIGL` | Innergemeinschaftliche Lieferung (steuerfrei B2B EU) |
| §13b UStG / Reverse Charge | `IsReverseCharge` | Steuerschuldner ist Empfänger |
| §25a UStG / Differenzbesteuerung | `IsDifferencialTaxation`, `DifferentialTaxationMode` | Margenbesteuerung (typisch Wiederverkäufer/Gebrauchtware) |
| `cSteuerkonto` | `BookingAccount` | DATEV-Sachkonto Erlöse |
| `cZahlungsartKonto` | `BookingAccountPaymentMethod` | DATEV-Sachkonto Zahlungs-/Geldkonto |

> Diese Felder treiben den ganzen Sinn des Exports. Wenn eine Mapping-Änderung sie falsch befüllt, sind die DATEV-Buchungen falsch — also bei Änderungen an Mapper oder SQL **diese Felder doppelt prüfen**.

---

## 9. Empfohlene WinForms-UI-Struktur

Die App ist im Kern ein **Filter → Abfrage → Grid → Export**-Tool. Konkrete Empfehlung:

```
MainForm (Tab Control)
├── Tab "Verbindung"
│    Connection-String-Editor, "Verbindung testen"-Button,
│    Mandanten-Liste (lädt aus tFirma)
│
├── Tab "Verkaufsrechnungen"
│    Filter-Panel (Datum, Plattformen, Region, MwSt, Diff., Suche)
│    [ Abfrage starten ]  [ Abbrechen ]  Status / Progress
│    DataGridView (gebunden an List<DocumentPosition>)
│    [ Als CSV exportieren ]  [ Nach DATEV exportieren ]
│
├── Tab "Gutschriften"   (analog, gleicher Query-Typ)
│
└── Tab "Einkauf"        (eigener Query-Typ, Lieferanten-Dropdown statt Plattformen)
```

**Threading-Empfehlung:**

```csharp
private CancellationTokenSource? _cts;

private async void btnRunQuery_Click(object sender, EventArgs e) {
    _cts?.Cancel();
    _cts = new CancellationTokenSource();
    btnCancel.Enabled = true;
    grid.DataSource = null;
    SetBusy(true);
    try {
        var query = BuildQuery();
        var rows = await _service.ReadSalesInvoicePositionsAsync(query, _cts.Token);
        grid.DataSource = rows;
        lblCount.Text = $"{rows.Count} Positionen";
    }
    catch (OperationCanceledException) { /* User-Cancel — nicht melden */ }
    catch (SqlException ex) { ShowError("SQL-Fehler", ex.Message); }
    finally { SetBusy(false); btnCancel.Enabled = false; }
}
```

- Service-Aufrufe sind alle `async` — **niemals** `.Result` / `.Wait()` aufrufen (Deadlock-Gefahr in WinForms-Sync-Context).
- Bei großen Ergebnissen (10k+ Zeilen) `DataGridView.VirtualMode` oder eine `BindingSource` mit Paging in Betracht ziehen.

**Export-Empfehlung:**

- CSV mit `;` als Separator (deutsches Excel), UTF-8 mit BOM.
- Zahlen mit Komma-Dezimaltrenner (Kultur `de-DE`).
- Datumsfelder als `yyyy-MM-dd HH:mm:ss` für Werkzeug-Interop oder `dd.MM.yyyy` für menschliche Lesbarkeit.

---

## 10. Konfiguration und Secrets

- Connection-String **nicht** hardcoden — der Smoke-Test (`LuckyControl.TaxExport.Tests/Program.cs`) hat das nur für interne Tests gemacht.
- In der WinForms-App: in `appsettings.json` / Registry / `user.config` / dem zentralen LuckyControl-Settings-Mechanismus speichern; im Verbindungs-Tab eingeben + Test-Button.
- `TrustServerCertificate=true` ist bei JTL-Wawi-Servern üblich (Self-Signed Cert).
- Beispiel-Format: `Server=<host>,<port>\<instance>;User Id=<user>;Password=<pw>;Database=<db>;TrustServerCertificate=true;`

---

## 11. Stolperfallen / Hinweise für die Entwicklung

1. **Mapper ist tolerant gegenüber fehlenden Spalten.** `ColumnMap` gibt Defaults zurück, wenn eine Spalte fehlt. Das ist erwünscht, weil drei verschiedene SQL-Templates dieselbe `DocumentPosition` befüllen. → Wenn ein Feld leer/0 ist, ist die SQL-Quelle die wahrscheinliche Ursache, nicht ein Mapper-Bug.

2. **`#cDB#` ist KEIN echter Parameter.** Es muss vor dem Senden per `String.Replace` ersetzt werden. Niemals als `@dbName` parametrisieren — das funktioniert in `USE` und in cross-DB-JOINs nicht.

3. **`USE [<db>]` schaltet den DB-Kontext der Connection um.** Die Connection ist nach dem Aufruf nicht mehr "neutral" — falls die App parallel andere Queries auf dem Server fährt, dafür eine **eigene** Connection verwenden.

4. **Wawi-Versions-Probe schlägt fehl, wenn `tVersion` leer ist.** Dann wird das 1.6er-Template gewählt (Default). Bei Wawi 2.0 kann das zu Fehlern führen. → Wenn die App selbst eine bessere Versions-Erkennung hat (z. B. Wawi-Connector), kann sie die Template-Auswahl überschreiben (Service müsste dafür um eine Überladung erweitert werden).

5. **SQL-Skripte enthalten deutsche Identifier und Kommentare.** Beim Editieren erhalten — JTL-Wawi-Spalten heißen so.

6. **Tippfehler in Property-Namen sind Teil des Vertrags** (`SakesOrderPositionId`, `TotalPayd`, `ShppingDate`, `IsDifferencialTaxation`) — sie matchen die SQL-`AS`-Aliasnamen. Korrigieren würde Mapping-Brüche verursachen.

7. **Region-/Diff.-Filter sind `CASE`-basiert.** "Alle" = 0 lässt die Werte durch (`x = x`). Das funktioniert nur, wenn das Feld nicht-nullable ist — sonst NULL-Tricks. Bei Erweiterungen drauf achten.

8. **Beleg-Typen-Mischung in Sales:** Das 16xx-Template lädt zuerst Rechnungen, dann Stornos, dann externe Rechnungen/Aufträge — alle in dieselbe Temp-Table. → `DocumentPosition.Type` ist der einzige sichere Diskriminator im Ergebnis.

9. **Differenzbesteuerung produziert mehrere Zeilen pro Position.** §25a-Berechnungen erzeugen ggf. eigene Steuer-Splits. Wenn die App Summen bildet, daran denken: nicht doppelt summieren, sondern auf Belegebene gruppieren.

10. **`CommandTimeout = 600 s`** ist bewusst hoch. Bei wirklich großen DBs (>10 Jahre Daten) reicht auch das nicht — UI sollte fortlaufendes Feedback / Progress / Cancel anbieten.

---

## 12. Minimal-Beispiel "Hello Invoice"

```csharp
using LuckyControl.TaxExport.Domain.Queries;
using LuckyControl.TaxExport.Infrastructure.Services;

var service = new DocumentService();

var rows = await service.ReadSalesInvoicePositionsAsync(new SalesInvoiceQuery {
    ConnectionString = "Server=…;Database=eazybusiness;User Id=…;Password=…;TrustServerCertificate=true;",
    DatabaseName     = "eazybusiness",
    StartDate        = new DateTime(2026, 1, 1),
    EndDate          = new DateTime(2026, 4, 30),
    Region           = RegionFilter.All,
    DifferentialTaxation = DifferentialTaxationFilter.All,
    PlatformTypes    = null   // = alle
});

foreach (var r in rows.Take(5)) {
    Console.WriteLine($"{r.SalesInvoiceNumber} {r.Sku} {r.Quantity}× {r.TotalNetPrice} {r.Currency} "
                    + $"VAT={r.VatRate}% IsEU={r.IsEU} IGL={r.IsIGL} RC={r.IsReverseCharge}");
}
```

---

## 13. Was diese Library NICHT macht (und was die App ggf. ergänzen muss)

- **Kein DATEV-CSV-/Postversand-/ELSTER-Export.** `DocumentPosition` liefert die Daten; das Erzeugen des DATEV-Belegs (Buchungsstapel, CSV nach DATEV-Format) ist Aufgabe der App bzw. eines weiteren LuckyControl-Moduls.
- **Keine Persistenz.** Die App speichert ggf. Filter-Profile, Connection-Settings, Export-Vorlagen selbst.
- **Keine Validierung der Steuerlogik.** Wenn JTL-Wawi inkonsistente Steuerflags liefert (z. B. IGL ohne USt-ID), wird die Zeile genauso zurückgegeben — die App entscheidet, ob sie warnt/blockt.
- **Keine UI-State-Verwaltung, kein Logging, keine Telemetrie.** Setzt die Konsumenten-App auf.
- **Keine Tests.** Nur ein Smoke-Test-Konsumentenprojekt — kein xUnit/NUnit. Bei Bedarf in einem neuen Projekt aufsetzen.

---

## 14. Glossar (für die UI-Texte)

| Kürzel | Lang | Englisch |
|---|---|---|
| UStG | Umsatzsteuergesetz | German VAT Act |
| IGL | Innergemeinschaftliche Lieferung | Intra-EU supply (B2B, VAT-exempt) |
| RC / §13b | Reverse Charge | Reverse charge mechanism |
| Diff.bestg. | Differenzbesteuerung §25a | Margin scheme |
| DATEV | DATEV eG (Buchhaltungs-Standard) | German accounting standard |
| Wawi | Warenwirtschaft (JTL Wawi) | ERP (JTL Wawi) |
| Mandant | Firma in der Wawi | Tenant / Company |
| Debitor | DATEV-Forderungskonto pro Kunde | DATEV debtor account |

---

**Stand:** 2026-05-17. Library Version: initial commit (`a6e883b`). Quelle der Wahrheit ist immer der Code in diesem Repo, nicht diese Doku — bei Abweichungen den Code lesen und die Doku aktualisieren.
