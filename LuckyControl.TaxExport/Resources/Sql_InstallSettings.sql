/*
Idempotent install script for the LuckyControl.TaxExport settings tables.
Called on every LuckyControl start — creates tables only when missing.
#cVersion# is substituted by the caller with the assembly informational version.
*/

IF NOT EXISTS (SELECT name FROM sys.tables WHERE name = 'em_tEinstellung')
BEGIN
	CREATE TABLE dbo.em_tEinstellung(
		[kEinstellung]  [int] IDENTITY(1,1) NOT NULL,
		[kBenutzer]     [int] NOT NULL,
		[cTyp]          [varchar](64) NOT NULL,
		[cComputername] [varchar](64) NOT NULL,
		[cName]         [varchar](64) NOT NULL,
		[cWert]         [varchar](64) NOT NULL,
		[dErstellt]     [datetime] NOT NULL
	) ON [PRIMARY]

	INSERT INTO dbo.em_tEinstellung
		([kBenutzer], [cTyp], [cComputername], [cName], [cWert], [dErstellt])
	VALUES
		(0, 'Software', 'LuckyControl.TaxExport', 'Programmversion', '#cVersion#', GETDATE())
END

IF NOT EXISTS (SELECT name FROM sys.tables WHERE name = 'em_tSteuerEinstellung')
BEGIN
	CREATE TABLE dbo.em_tSteuerEinstellung(
		[kSteuerEinstellung] [int] IDENTITY(1,1) NOT NULL,
		[cDB]                [varchar](64) NOT NULL,
		[kFirma]             [int] NOT NULL,
		[kSteuerklasse]      [int] NOT NULL,
		[kSteuerschlussel]   [int] NOT NULL,
		[cFirma]             [varchar](64) NULL,
		[cSteuerklasse]      [varchar](64) NULL,
		[cSteuerschlussel]   [varchar](64) NULL,
		[dErstellt]          [datetime] NOT NULL,
		[TaxRate]            [decimal](18,2) NULL
	) ON [PRIMARY]
END

IF NOT EXISTS (SELECT name FROM sys.tables WHERE name = 'em_tExportVorlage')
BEGIN
	CREATE TABLE dbo.em_tExportVorlage(
		[kExportVorlage] [int] IDENTITY(1,1) NOT NULL,
		[nTyp]           [int] NOT NULL,
		[cTyp]           [varchar](255) NOT NULL,
		[cName]          [varchar](255) NOT NULL,
		[cDateiName]     [varchar](255) NOT NULL,
		[cDateiPfad]     [varchar](255) NULL,
		[cFormat]        [varchar](64) NOT NULL,
		[cQuellcode]     [text] NOT NULL,
		[dErstellt]      [datetime] NOT NULL
	) ON [PRIMARY]
END
