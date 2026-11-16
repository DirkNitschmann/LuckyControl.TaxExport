# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`LuckyControl.TaxExport` is a .NET 10 class library — the tax-export layer for LuckyControl. It reads sales invoice / order data out of a **JTL Wawi** SQL Server database (German ERP / Warenwirtschaft) and projects it into a flat `DocumentPosition` model intended for downstream tax/accounting export (DATEV-style: booking accounts, VAT rate, reverse charge, IGL, differential taxation, creditor/debitor numbers, etc.).

The library is the data-access + domain layer only — there is no executable, no API, no UI. It is consumed by another project in the LuckyControl suite.

## Build / develop

```powershell
dotnet build LuckyControl.TaxExport.csproj
dotnet build -c Release
```

Open `LuckyControl.TaxExport.slnx` in Visual Studio (slnx is the new XML solution format). Project targets `net10.0` with `ImplicitUsings` and `Nullable` enabled.

There is currently **no test project** and **no executable entry point**. Don't invent `dotnet test` / `dotnet run` workflows — they will fail. If adding tests, create a sibling `LuckyControl.TaxExport.Tests` project and add it to the slnx.

## Architecture

Two layers, kept deliberately thin:

- **`Domain/Entities/`** — POCOs only. `DocumentPosition` is the single export row model (~100 properties: invoice, customer, company, both addresses, prices in original + base currency, tax flags). One row = one invoice/order line, denormalized.
- **`Infrastructure/Services/`** — DB access. `DocumentService.readSalesInvoicePositions()` is the entry point that should execute the embedded SQL and return `List<DocumentPosition>`. Currently stubbed.

### The SQL is the heart of the project

The real logic lives in two large T-SQL scripts under `Resources/`, exposed as strongly-typed `string` resources via `Properties/Resources.resx` → `Resources.Designer.cs`:

- `Sql_ReadSalesInvoicesJtlWawi16xx` — JTL Wawi schema versions **1.6.x through 1.11.x**
- `Sql_ReadSalesInvoicesJtlWawi20xx` — JTL Wawi schema version **2.0.x** (current)

Both scripts share the same shape and the same output columns (they map 1:1 onto `DocumentPosition`), but the underlying JTL tables differ between schema generations. When `DocumentService` is implemented it must pick the right resource based on the connected Wawi version.

**Important conventions in the SQL templates:**

- `USE #cDB#` — `#cDB#` is a placeholder for the target database name. The caller must string-replace it before executing (it is not a real T-SQL parameter). Do not "fix" it to a parameter.
- The scripts assume JTL Wawi schema (`tLand`, `tBestellung`, `tRechnung`, `tFirma`, `tKunde`, …) and produce results in JTL's German column naming (`kBestellung`, `cRechnungsNr`, `fFaktor`, …) before the C# layer maps them onto the English `DocumentPosition` properties.
- Comments and identifiers in the SQL are German — preserve them when editing.

When adding columns to the export, the change must be made in **three places in lockstep**: both SQL resources + `DocumentPosition`. Forgetting one will cause silent column-mismatch bugs at runtime.

### Resource regeneration

`Properties/Resources.Designer.cs` is auto-generated from `Resources.resx` (set up in the `.csproj` via `ResXFileCodeGenerator`). Do not hand-edit the Designer file. To register new SQL files as resources, add a `<data name="…" type="System.Resources.ResXFileRef, System.Windows.Forms">` entry in `Resources.resx` pointing at the file under `Resources/`, then rebuild.

## Domain vocabulary (German tax context)

The flag fields on `DocumentPosition` encode German VAT scenarios — keep their semantics straight when writing SQL or mapping logic:

- **`IsEU`** — invoice address is in another EU country.
- **`IsIGL`** (innergemeinschaftliche Lieferung) — intra-EU B2B delivery, VAT-exempt, requires valid `VatIdNumber`.
- **`IsReverseCharge`** — recipient owes the VAT (§13b UStG / EU reverse charge).
- **`IsDifferencialTaxation`** (Differenzbesteuerung, §25a UStG) — margin-scheme taxation, typically used resellers.
- **`BookingAccount` / `BookingAccountPaymentMethod`** — DATEV-style chart-of-accounts numbers for the revenue and the payment clearing account.
- **`DebitorNumber`** vs **`CustomerNumber`** — DATEV debitor account vs. JTL customer number. Not the same thing.

These are the fields most likely to be wrong in a careless mapping change — they drive the whole point of the export.
