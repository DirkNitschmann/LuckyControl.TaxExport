
---
/* Wawi 1.6.x.x to Wawi 1.11.x.x */
USE #cDB#

DECLARE @tLand Table(
	cISO VARCHAR(20) NOT NULL,
	cName VARCHAR(100) NOT NULL,
	nEU INT NOT NULL
);

INSERT INTO @tLand SELECT cISO, cName, nEU FROM [dbo].[tLand];

DECLARE @Bestellungen TABLE(
	 kBestellung INT
	,kInetBestellung INT
	,kRechnung INT
	,kKunde INT
	,kFirma INT
	,kZahlungsArt INT
	,kVersandArt INT
	,kRechnungsAdresse INT
	,kLieferAdresse INT
	,nTyp INT
	,cTyp VARCHAR(100)
	,cPlattform VARCHAR(100)
	,cBestellNr VARCHAR(255)
	,cInetBestellNr VARCHAR(255) NULL
	,cRechnungsNr VARCHAR(255)
	,cKundenNr VARCHAR(255)
	,cWaehrung VARCHAR(10)
	,cUstId VARCHAR(255) NULL
	,cVersandlandISO VARCHAR(10)
	,cAnmerkung VARCHAR(4000) NULL
	,fFaktor FLOAT
	,dErstellt DATETIME NOT NULL
	,dErstelltAuftrag DATETIME NULL
	,dBezahlt DATETIME NULL
	,dVersandt DATETIME NULL
	,DocumentType VARCHAR(30) NOT NULL
);

DECLARE @Temp TABLE(
	cTyp VARCHAR(100),--
	kBestellung INT NOT NULL,--
	kInetBestellung INT NOT NULL,--
	kRechnung INT NOT NULL,--
	kKunde INT NOT NULL,--
	kFirma INT NOT NULL,	--
	kArtikel INT NOT NULL,	
	kBestellPos INT NULL,
	kBestellStuckliste INT NULL,
	cBestellNr VARCHAR(255) NOT NULL,
	cInetBestellNr VARCHAR(255) NOT NULL,
	cRechnungsNr VARCHAR(255) NOT NULL,
	cKundenNr VARCHAR(255) NOT NULL,
	cDebitorennummer VARCHAR(255) NOT NULL,
	cUmsatzsteuerID VARCHAR(255) NULL,
	cPlattform VARCHAR(255) NOT NULL,
	cZahlungsart VARCHAR(255) NULL,
	cVersandart VARCHAR(255) NULL,
	cStatus VARCHAR(MAX) NULL,
	cHinweis VARCHAR(MAX) NULL,
	cAnmerkung VARCHAR(4000) NULL,
	cBuchungskonto VARCHAR(255) NULL,
	cBuchungskontoZahlungsart VARCHAR(255) NULL,
	cWaehrung VARCHAR(255) NOT NULL,
	cVersandland VARCHAR(255) NOT NULL,	
	fMwSt FLOAT NOT NULL,
	fFaktor FLOAT NOT NULL,
	fZahlung FLOAT NOT NULL,
	nDifferenzBesteuerung INT NULL,	
	nIstEU INT NOT NULL,	
	nIGL INT NOT NULL,
	nType INT NOT NULL,
	nSortiernummer INT NULL,
	cArtNr VARCHAR(255) NOT NULL,
	cName VARCHAR(255) NOT NULL,
	nAnzahl FLOAT NOT NULL,
	fEKNettoEinzel FLOAT NOT NULL,
	fEKNettoGesamt FLOAT NOT NULL,
	fVKNettoEinzel FLOAT NOT NULL,
	fVKNettoGesamt FLOAT NOT NULL,
	fVKBruttoEinzel FLOAT NOT NULL,
	fVKBruttoGesamt FLOAT NOT NULL,
	fVKNettoEinzelWahrungsFaktor FLOAT NOT NULL,
	fVKNettoGesamtWahrungsFaktor FLOAT NOT NULL,
	fVKBruttoEinzelWahrungsFaktor FLOAT NOT NULL,
	fVKBruttoGesamtWahrungsFaktor FLOAT NOT NULL,
	tFirma_cName VARCHAR(255) NOT NULL,
	tFirma_cUnternehmer VARCHAR(255) NOT NULL,
	tfirma_cStrasse VARCHAR(255) NOT NULL,
	tfirma_cPLZ VARCHAR(255) NOT NULL,
	tfirma_cOrt VARCHAR(255) NOT NULL,
	tfirma_cLand VARCHAR(255) NOT NULL,
	tfirma_cWWW VARCHAR(255) NOT NULL,
	tfirma_cEMail VARCHAR(255) NOT NULL,
	tfirma_cBank VARCHAR(255) NOT NULL,
	tfirma_cKontoNr VARCHAR(255) NOT NULL,
	tfirma_cBLZ VARCHAR(255) NOT NULL,
	tfirma_cIBAN VARCHAR(255) NOT NULL,
	tfirma_cBIC VARCHAR(255) NOT NULL,
	tfirma_cSteuerNr VARCHAR(255) NOT NULL,
	tfirma_cGlaeubigerID VARCHAR(255) NOT NULL,
	cRE_Anrede VARCHAR(255) NOT NULL,
	cRE_Firma VARCHAR(255) NOT NULL,
	cRE_Vorname VARCHAR(255) NOT NULL,
	cRE_Nachname VARCHAR(255) NOT NULL,
	cRE_Strasse VARCHAR(255) NOT NULL,
	cRE_PLZ VARCHAR(255) NOT NULL,
	cRE_Ort VARCHAR(255) NOT NULL,
	cRE_Bundesland VARCHAR(255) NOT NULL,
	cRE_Land VARCHAR(255) NOT NULL,
	cRE_Telefon VARCHAR(255) NOT NULL,
	cRE_Telefax VARCHAR(255) NOT NULL,
	cRE_Mobil VARCHAR(255) NOT NULL,
	cRE_Mail VARCHAR(255) NOT NULL,
	cLA_Anrede VARCHAR(255) NOT NULL,
	cLA_Firma VARCHAR(255) NOT NULL,
	cLA_Vorname VARCHAR(255) NOT NULL,
	cLA_Nachname VARCHAR(255) NOT NULL,
	cLA_Strasse VARCHAR(255) NOT NULL,
	cLA_PLZ VARCHAR(255) NOT NULL,
	cLA_Ort VARCHAR(255) NOT NULL,
	cLA_Bundesland VARCHAR(255) NOT NULL,
	cLA_Land VARCHAR(255) NOT NULL,
	cLA_ISO VARCHAR(10) NOT NULL,
	cLA_Telefon VARCHAR(255) NOT NULL,
	cLA_Telefax VARCHAR(255) NOT NULL,
	cLA_Mobil VARCHAR(255) NOT NULL,
	cLA_Mail VARCHAR(255) NOT NULL,
	cSeriennummer NVARCHAR(MAX) NOT NULL,
	cCharge NVARCHAR(MAX) NOT NULL,
	dErstellt DATETIME NOT NULL,
	dErstelltAuftrag DATETIME NULL,
	dGeliefertAm DATETIME NULL,
	dBezahlt DATETIME NULL,
	dVersand DATETIME NULL
	,IsReverseCharge INT NOT NULL
	,DocumentType VARCHAR(100) NOT NULL
	,DiffTaxRate FLOAT NULL
);

DECLARE @SerialNumbers TABLE(
	 SalesOrderId INT
	,SalesOrderPositionId INT
	,SerialNumber VARCHAR(255)
	,Comment1 VARCHAR(255)
	,Comment2 VARCHAR(255)
);

/* Zuerst alle Rechnungen lesen */
INSERT INTO @Bestellungen
SELECT	 
	 ISNULL(tAuftrag.kAuftrag, 0)
	,ISNULL(tAuftrag.kShopAuftrag, 0)
	,trechnung.kRechnung
	,ISNULL(trechnung.kKunde, 0)
	,tFirmaHistory.kFirma
	,trechnung.kZahlungsArt 
	,trechnung.kVersandArt 
	,0 --kRechnungsAdresse
	,0 --kLieferAdresse
	,tPlattform.nTyp
	,'Rechnung'
	,tPlattform.cName
	,ISNULL(tAuftrag.cAuftragsNr, '') 
	,ISNULL(trechnung.cExterneAuftragsnummer, '')
	,ISNULL(trechnung.cRechnungsNr, '')
	,ISNULL(trechnung.cKundenNr, '')
	,trechnung.cWaehrung
	,ISNULL(trechnung.cUstId, '')	
	,trechnung.cVersandlandISO
	,'' --cAnmerkung
	,trechnung.fWaehrungsfaktor
	,trechnung.dErstellt
	,NULL
	,tRechnungEckdaten.dBezahlt
	,trechnung.dLeistungsdatum
	,'INVOICE'

FROM [Rechnung].[tRechnung]
JOIN [Rechnung].[tRechnungEckdaten] ON tRechnungEckdaten.kRechnung = tRechnung.kRechnung
JOIN [dbo].[tFirmaHistory] ON tFirmaHistory.kFirmaHistory = tRechnung.kFirmaHistory
JOIN [dbo].[tPlattform] ON tPlattform.nPlattform = tRechnung.kPlattform
LEFT OUTER JOIN [dbo].[tkunde] ON tkunde.kKunde = trechnung.kKunde
LEFT OUTER JOIN [Verkauf].[tAuftragRechnung] ON tAuftragRechnung.kRechnung = tRechnung.kRechnung
LEFT OUTER JOIN [Verkauf].[tAuftrag] ON tAuftrag.kAuftrag = tAuftragRechnung.kAuftrag

WHERE 
	CONVERT(DATE, CASE WHEN @nZahldatum = 1 THEN tRechnungEckdaten.dBezahlt ELSE trechnung.dErstellt END, 105)  >= CONVERT(DATE, @dDatumStart, 105) AND
	CONVERT(DATE, CASE WHEN @nZahldatum = 1 THEN tRechnungEckdaten.dBezahlt ELSE trechnung.dErstellt END, 105) <= CONVERT(DATE, @dDatumEnde, 105) AND
	tRechnung.nIstEntwurf = 0 AND
	--tRechnung.nStorno = 0 AND
	tPlattform.nTyp IN (*cPlattformen*);

/* Dann alle Stornos */
INSERT INTO @Bestellungen
SELECT	 
	 ISNULL(tAuftrag.kAuftrag, 0)
	,ISNULL(tAuftrag.kShopAuftrag, 0)
	,trechnung.kRechnung
	,ISNULL(trechnung.kKunde, 0)
	,tFirmaHistory.kFirma
	,trechnung.kZahlungsArt 
	,trechnung.kVersandArt 
	,0 --kRechnungsAdresse
	,0 --kLieferAdresse
	,tPlattform.nTyp
	,'Stornierte Rechnung'
	,tPlattform.cName
	,ISNULL(tAuftrag.cAuftragsNr, '') 
	,ISNULL(trechnung.cExterneAuftragsnummer, '')
	,ISNULL(trechnung.cRechnungsNr, '')
	,ISNULL(trechnung.cKundenNr, '')
	,trechnung.cWaehrung
	,ISNULL(trechnung.cUstId, '')	
	,trechnung.cVersandlandISO
	,'' --cAnmerkung
	,trechnung.fWaehrungsfaktor
	,trechnung.dErstellt
	,NULL
	,tRechnungEckdaten.dBezahlt
	,trechnung.dLeistungsdatum
	,'CANCELLEDINVOICE'

FROM [Rechnung].[tRechnung]
JOIN [Rechnung].[tRechnungEckdaten] ON tRechnungEckdaten.kRechnung = tRechnung.kRechnung
JOIN [Rechnung].[tRechnungStorno] ON tRechnungStorno.kRechnung = tRechnung.kRechnung
JOIN [dbo].[tFirmaHistory] ON tFirmaHistory.kFirmaHistory = tRechnung.kFirmaHistory
JOIN [dbo].[tPlattform] ON tPlattform.nPlattform = tRechnung.kPlattform
LEFT OUTER JOIN [dbo].[tkunde] ON tkunde.kKunde = trechnung.kKunde
LEFT OUTER JOIN [Verkauf].[tAuftragRechnung] ON tAuftragRechnung.kRechnung = tRechnung.kRechnung
LEFT OUTER JOIN [Verkauf].[tAuftrag] ON tAuftrag.kAuftrag = tAuftragRechnung.kAuftrag

WHERE 
	CONVERT(DATE, tRechnungStorno.dStorniert, 105) >= CONVERT(DATE, @dDatumStart, 105) AND
	CONVERT(DATE, tRechnungStorno.dStorniert, 105) <= CONVERT(DATE, @dDatumEnde, 105) AND
	tRechnung.nIstEntwurf = 0 AND
	tRechnung.nStorno = 1 AND
	tPlattform.nTyp IN (*cPlattformen*);

/* Nun alle Externen Rechnungen lesen */
INSERT INTO @Bestellungen
SELECT 
	 ISNULL(tAuftrag.kAuftrag, 0)
	,ISNULL(tAuftrag.kShopAuftrag, 0)
	,0 AS kRechnung
	,tAuftrag.kKunde
	,tFirmaHistory.kFirma
	,ISNULL(tAuftrag.kZahlungsArt, 0)
	,ISNULL(tAuftrag.kVersandArt, 0)
	,0 --kRechnungsAdresse
	,0 --kLieferAdresse
	,tPlattform.nTyp
	,CASE WHEN tAuftrag.nIstExterneRechnung = 1 THEN 'Externe Rechnung' ELSE 'Auftrag' END + ' ('+tPlattform.cName+')'
	,tPlattform.cName
	,ISNULL(tAuftrag.cAuftragsNr, '') 
	,ISNULL(tAuftrag.cExterneAuftragsnummer, '')
	,'' AS cRechnungsNr
	,ISNULL(tAuftrag.cKundenNr, '')
	,tAuftrag.cWaehrung
	,ISNULL(tAuftrag.cUstId, '')	
	,tAuftrag.cVersandlandISO
	,'' --cAnmerkung
	,tAuftrag.fFaktor
	,tAuftrag.dErstellt
	,NULL
	,tAuftragEckdaten.dBezahlt
	,tAuftragEckdaten.dLetzterVersand
	,'POS'

FROM [Verkauf].[tAuftrag]
JOIN [Verkauf].[tAuftragEckdaten] ON tAuftragEckdaten.kAuftrag = tAuftrag.kAuftrag
JOIN [dbo].[tFirmaHistory] ON tFirmaHistory.kFirmaHistory = tAuftrag.kFirmaHistory
JOIN [dbo].[tPlattform] ON tPlattform.nPlattform = tAuftrag.kPlattform
LEFT OUTER JOIN [Rechnung].[tRechnung] ON tRechnung.cExterneAuftragsnummer = tAuftrag.cExterneAuftragsnummer
OUTER APPLY (
	SELECT COUNT(*) AS InvoiceCount FROM [Verkauf].[tAuftragRechnung] WHERE tAuftragRechnung.kAuftrag = tAuftrag.kAuftrag
) Invoices
WHERE 
	(
		tAuftrag.nIstExterneRechnung = 1 OR
		Invoices.InvoiceCount = 0 
	) AND 
	tRechnung.kRechnung IS NULL AND
	tPlattform.nTyp = 9 AND --JTL-POS / LS-POS
	tAuftrag.nType = 1 AND
	tAuftrag.nStorno = 0 AND
	--Invoices.InvoiceCount = 0 AND
	CONVERT(DATE, CASE WHEN @nZahldatum = 1 THEN tAuftragEckdaten.dBezahlt ELSE tAuftrag.dErstellt END, 105)  >= CONVERT(DATE, @dDatumStart, 105) AND
	CONVERT(DATE, CASE WHEN @nZahldatum = 1 THEN tAuftragEckdaten.dBezahlt ELSE tAuftrag.dErstellt END, 105) <= CONVERT(DATE, @dDatumEnde, 105) AND
	tPlattform.nTyp IN (*cPlattformen*);

INSERT INTO @SerialNumbers
SELECT 
	 tAuftragPosition.kAuftrag
	,tAuftragPosition.kAuftragPosition
	,tLagerArtikel.cSeriennr
	,tLagerArtikel.cBeschreibung1
	,tLagerArtikel.cBeschreibung2

FROM @Bestellungen
JOIN [Verkauf].[tAuftragPosition] ON tAuftragPosition.kAuftrag = [@Bestellungen].kBestellung
JOIN [dbo].[tLieferscheinPos] ON tLieferscheinPos.kBestellPos = tAuftragPosition.kAuftragPosition
JOIN [dbo].[tLagerArtikel] ON tLagerArtikel.kLieferscheinPos = tLieferscheinPos.kLieferscheinPos
	
INSERT INTO @Temp
SELECT 
	 [@Bestellungen].cTyp
	,[@Bestellungen].kBestellung
	,ISNULL([@Bestellungen].kInetBestellung, 0)
	,ISNULL([@Bestellungen].kRechnung, 0)
	,[@Bestellungen].kKunde
	,[@Bestellungen].kFirma
	,ISNULL(tRechnungPosition.kArtikel, 0)
	,tRechnungPosition.kRechnungPosition
	,tRechnungPosition.kStuecklisteRechnungPos
	,ISNULL([@Bestellungen].cBestellNr, '')
	,ISNULL([@Bestellungen].cInetBestellNr, '')
	,[@Bestellungen].cRechnungsNr
	,ISNULL([@Bestellungen].cKundenNr, '')
	,ISNULL(CONVERT(VARCHAR(255), tKunde.nDebitorennr), '')
	,ISNULL([@Bestellungen].cUstId, '')
	,ISNULL([@Bestellungen].cPlattform, '')
	,ISNULL(tZahlungsart.cName, '')
	,ISNULL(tversandart.cName, '')
	,'' --tBestellung.cStatus,
	,'' --Hinweis kommt später
	,[@Bestellungen].cAnmerkung

	/* Buchungskonto nach Positiontyp lesen */
	,tSteuerschluessel.cSteuerkonto

	,ISNULL(tZahlungsart.cKonto, '') AS cBuchungskontoZahlungsart
	,ISNULL([@Bestellungen].cWaehrung, '')
	,ISNULL(tVersandland.cName, '') AS cVersandland
	,ISNULL(tRechnungPosition.fMwSt, 0)
	,ISNULL([@Bestellungen].fFaktor, 1)
	,ISNULL(tRechnungEckdaten.fZahlung, 0)
	,CASE WHEN tRechnungPosition.kSteuerklasse = Steuerdaten.kSteuerklasse THEN 1 ELSE 0 END
	,ISNULL(tLieferland.nEU, 0)
	,CASE WHEN tVersandland.nEU = 1 AND tlieferadresse.cISO != tVersandland.cISO THEN 1 ELSE 0 END
	,ISNULL(tRechnungPosition.nType, 0)
	,ISNULL(tRechnungPosition.nSort, 0)
	,ISNULL(tRechnungPosition.cArtNr, '')
	,ISNULL(tRechnungPosition.cName, '')
	,ISNULL(tRechnungPosition.fAnzahl, 0)

	
	,ISNULL(CASE WHEN tWarenEingang.fEKEinzel > 0 THEN tWarenEingang.fEKEinzel ELSE CASE WHEN tRechnungPosition.fEKNetto > 0 THEN tRechnungPosition.fEKNetto ELSE ISNULL(tArtikel.fEKNetto, 0) END END, 0)
	,ISNULL((CASE WHEN tWarenEingang.fEKEinzel > 0 THEN tWarenEingang.fEKEinzel ELSE CASE WHEN tRechnungPosition.fEKNetto > 0 THEN tRechnungPosition.fEKNetto ELSE ISNULL(tArtikel.fEKNetto, 0) END END *tRechnungPosition.fAnzahl), 0)
	,ISNULL((tRechnungPosition.fWertNettoGesamtFixiert /CASE WHEN tRechnungPosition.fAnzahl = 0 THEN 1 ELSE tRechnungPosition.fAnzahl END), 0)
	,ISNULL(tRechnungPosition.fWertNettoGesamtFixiert, 0)
	,ISNULL((tRechnungPosition.fWertBruttoGesamtFixiert /CASE WHEN tRechnungPosition.fAnzahl = 0 THEN 1 ELSE tRechnungPosition.fAnzahl END), 0)
	,ISNULL(tRechnungPosition.fWertBruttoGesamtFixiert, 0)
	,ISNULL(((tRechnungPosition.fWertNettoGesamtFixiert /CASE WHEN tRechnungPosition.fAnzahl = 0 THEN 1 ELSE tRechnungPosition.fAnzahl END) /[@Bestellungen].fFaktor), 0)
	,ISNULL((tRechnungPosition.fWertNettoGesamtFixiert /[@Bestellungen].fFaktor), 0)
	,ISNULL(((tRechnungPosition.fWertBruttoGesamtFixiert /CASE WHEN tRechnungPosition.fAnzahl = 0 THEN 1 ELSE tRechnungPosition.fAnzahl END) /[@Bestellungen].fFaktor), 0)
	,ISNULL((tRechnungPosition.fWertBruttoGesamtFixiert /[@Bestellungen].fFaktor), 0)
	

	/*
	,ISNULL(CASE WHEN tWarenEingang.fEKEinzel > 0 THEN tWarenEingang.fEKEinzel ELSE CASE WHEN tRechnungPosition.fEKNetto > 0 THEN tRechnungPosition.fEKNetto ELSE ISNULL(tArtikel.fEKNetto, 0) END END, 0)
	,ISNULL((CASE WHEN tWarenEingang.fEKEinzel > 0 THEN tWarenEingang.fEKEinzel ELSE CASE WHEN tRechnungPosition.fEKNetto > 0 THEN tRechnungPosition.fEKNetto ELSE ISNULL(tArtikel.fEKNetto, 0) END END *tRechnungPosition.fAnzahl), 0)
	,ISNULL((tRechnungPosition.fVkNettoGesamt /CASE WHEN tRechnungPosition.fAnzahl = 0 THEN 1 ELSE tRechnungPosition.fAnzahl END), 0)
	,ISNULL(tRechnungPosition.fVkNettoGesamt, 0)
	,ISNULL((tRechnungPosition.fVkBruttoGesamt /CASE WHEN tRechnungPosition.fAnzahl = 0 THEN 1 ELSE tRechnungPosition.fAnzahl END), 0)
	,ISNULL(tRechnungPosition.fVkBruttoGesamt, 0)
	,ISNULL(((tRechnungPosition.fVkNettoGesamt /CASE WHEN tRechnungPosition.fAnzahl = 0 THEN 1 ELSE tRechnungPosition.fAnzahl END) /[@Bestellungen].fFaktor), 0)
	,ISNULL((tRechnungPosition.fVkNettoGesamt /[@Bestellungen].fFaktor), 0)
	,ISNULL(((tRechnungPosition.fVkBruttoGesamt /CASE WHEN tRechnungPosition.fAnzahl = 0 THEN 1 ELSE tRechnungPosition.fAnzahl END) /[@Bestellungen].fFaktor), 0)
	,ISNULL((tRechnungPosition.fVkBruttoGesamt /[@Bestellungen].fFaktor), 0)
	*/

	,ISNULL(tfirma.cName, '')
	,ISNULL(tfirma.cUnternehmer, '')
	,ISNULL(tfirma.cStrasse, '')
	,ISNULL(tfirma.cPLZ, '')
	,ISNULL(tfirma.cOrt, '')
	,ISNULL(tfirma.cLand, '')
	,ISNULL(tfirma.cWWW, '')
	,ISNULL(tfirma.cEMail, '')
	,ISNULL(tfirma.cBank, '')
	,ISNULL(tfirma.cKontoNr, '')
	,ISNULL(tfirma.cBLZ, '')
	,ISNULL(tfirma.cIBAN, '')
	,ISNULL(tfirma.cBIC, '')
	,ISNULL(tfirma.cSteuerNr, '')
	,ISNULL(tfirma.cGlaeubigerID, '')
	,ISNULL(trechnungsadresse.cAnrede, '')
	,ISNULL(trechnungsadresse.cFirma, '')
	,ISNULL(trechnungsadresse.cVorname, '')
	,ISNULL(trechnungsadresse.cName, '')
	,ISNULL(trechnungsadresse.cStrasse, '')
	,ISNULL(trechnungsadresse.cPLZ, '')
	,ISNULL(trechnungsadresse.cOrt, '')
	,ISNULL(trechnungsadresse.cBundesland, '')
	,ISNULL(trechnungsadresse.cLand, '')
	,ISNULL(trechnungsadresse.cTel, '')
	,ISNULL(trechnungsadresse.cFax, '')
	,ISNULL(trechnungsadresse.cMobil, '')
	,ISNULL(trechnungsadresse.cMail, '')
	,ISNULL(tlieferadresse.cAnrede, '')
	,ISNULL(tlieferadresse.cFirma, '')
	,ISNULL(tlieferadresse.cVorname, '')
	,ISNULL(tlieferadresse.cName, '')
	,ISNULL(tlieferadresse.cStrasse, '')
	,ISNULL(tlieferadresse.cPLZ, '')
	,ISNULL(tlieferadresse.cOrt, '')
	,ISNULL(tlieferadresse.cBundesland, '')
	,ISNULL(tlieferadresse.cLand, '')
	,ISNULL(tlieferadresse.cISO, '')
	,ISNULL(tlieferadresse.cTel, '')
	,ISNULL(tlieferadresse.cFax, '')
	,ISNULL(tlieferadresse.cMobil, '')
	,ISNULL(tlieferadresse.cMail, '')
	,REPLACE(REPLACE(REPLACE(
		ISNULL((
			SELECT CONCAT([@SerialNumbers].SerialNumber, CASE WHEN [@SerialNumbers].Comment1 != '' THEN ' ('+[@SerialNumbers].Comment1+') ' ELSE '' END) AS cSeriennr
			FROM @SerialNumbers WHERE [@SerialNumbers].SalesOrderPositionId = tRechnungPosition.kAuftragPosition
		
			FOR XML PATH('')), '')
		,'</cSeriennr><cSeriennr>', ' | ')
		,'<cSeriennr>', '')
		,'</cSeriennr>', ''
	)
	,REPLACE(
		 REPLACE(REPLACE(ISNULL((
			SELECT X.cChargenNr 
			FROM [dbo].[tWarenLagerEingang] X 
			JOIN [dbo].[tWarenLagerAusgang] Y ON Y.kWarenLagerEingang = X.kWarenLagerEingang
			JOIN [dbo].[tLieferscheinPos] Z ON Z.kLieferscheinPos = Y.kLieferscheinPos
			WHERE Z.kBestellPos = tRechnungPosition.kAuftragPosition
		
			FOR XML PATH('')), '')
		,'</cChargenNr><cChargenNr>', ' | ')
		,'<cChargenNr>', '''')
		,'</cChargenNr>', ''
	)
	,[@Bestellungen].dErstellt
	,ISNULL([@Bestellungen].dErstelltAuftrag, [@Bestellungen].dErstellt)
	,ISNULL(tWarenEingang.dGeliefertAm, tWarenEingang.dErstellt) AS dGeliefertAm
	,[@Bestellungen].dBezahlt
	,[@Bestellungen].dVersandt
	,CASE WHEN tRechnung.nSteuereinstellung = 15 THEN 1 ELSE 0 END
	,DocumentType
	,ISNULL(Steuerdaten.TaxRate, 0) AS DiffTaxRate

FROM @Bestellungen 
JOIN [Rechnung].[tRechnung] ON tRechnung.kRechnung = [@Bestellungen].kRechnung
JOIN [Rechnung].[tRechnungEckdaten] ON tRechnungEckdaten.kRechnung = [@Bestellungen].kRechnung
JOIN [Rechnung].[tRechnungAdresse] AS trechnungsadresse ON trechnungsadresse.kRechnung = [@Bestellungen].kRechnung AND trechnungsadresse.nTyp = 1
JOIN [Rechnung].[tRechnungAdresse] AS tlieferadresse ON tlieferadresse.kRechnung = [@Bestellungen].kRechnung AND tlieferadresse.nTyp = 0
LEFT OUTER JOIN [dbo].[tFirmaHistory] ON tFirmaHistory.kFirmaHistory = tRechnung.kFirmaHistory
LEFT OUTER JOIN [dbo].[tfirma] ON tfirma.kFirma = tFirmaHistory.kFirma
LEFT OUTER JOIN [dbo].[tkunde] ON tkunde.kKunde = [@Bestellungen].kKunde
LEFT OUTER JOIN [dbo].[tAdresse] ON tAdresse.kKunde = tkunde.kKunde AND tAdresse.nStandard = 1 AND tAdresse.nTyp = 1
LEFT OUTER JOIN [dbo].[tZahlungsart] ON tZahlungsart.kZahlungsart = [@Bestellungen].kZahlungsArt
LEFT OUTER JOIN [dbo].[tversandart] ON tversandart.kVersandArt = [@Bestellungen].kVersandArt
JOIN @tLand AS tVersandland ON tVersandland.cISO = [@Bestellungen].cVersandlandISO
JOIN @tLand AS tRechnungsland ON tRechnungsland.cISO = trechnungsadresse.cISO
JOIN @tLand AS tLieferland ON tLieferland.cISO = tlieferadresse.cISO


JOIN [Rechnung].[tRechnungPosition] ON tRechnungPosition.kRechnung = [@Bestellungen].kRechnung
LEFT OUTER JOIN [eazybusiness].[dbo].[em_tSteuerEinstellung] AS Steuerdaten 
	ON Steuerdaten.cDB = 'eazybusiness'
	AND Steuerdaten.kFirma = tfirma.kFirma
	AND Steuerdaten.kSteuerklasse = tRechnungPosition.kSteuerklasse

LEFT OUTER JOIN [dbo].[tSteuerschluessel] ON tSteuerschluessel.kSteuerschluessel = tRechnungPosition.kSteuerschluessel
LEFT OUTER JOIN [dbo].[tArtikel] ON tArtikel.kArtikel = tRechnungPosition.kArtikel
OUTER APPLY(
	SELECT TOP(1)
		 tWarenLagerAusgang.kWarenLagerEingang
		,tWarenLagerEingang.fEKEinzel 
		,tWarenLagerEingang.dGeliefertAM
		,tWarenLagerEingang.dErstellt
		
	FROM [dbo].[tWarenLagerAusgang] 	
	JOIN [dbo].[tWarenLagerEingang] ON tWarenLagerEingang.kWarenLagerEingang = tWarenLagerAusgang.kWarenLagerEingang
	JOIN [dbo].[tLieferscheinPos] ON tLieferscheinPos.kLieferscheinPos = tWarenLagerAusgang.kLieferscheinPos
	WHERE
		tLieferscheinPos.kBestellPos = tRechnungPosition.kAuftragPosition

	ORDER BY 
		tWarenLagerEingang.dErstellt ASC
) AS tWarenEingang
WHERE DocumentType IN ('INVOICE', 'CANCELLEDINVOICE')

ORDER BY 
	[@Bestellungen].dErstellt ASC;

INSERT INTO @Temp
SELECT 
	 [@Bestellungen].cTyp
	,[@Bestellungen].kBestellung
	,ISNULL([@Bestellungen].kInetBestellung, 0)
	,ISNULL([@Bestellungen].kRechnung, 0)
	,ISNULL([@Bestellungen].kKunde, 0)
	,[@Bestellungen].kFirma
	,ISNULL(tAuftragPosition.kArtikel, 0)
	,tAuftragPosition.kAuftragPosition
	,ISNULL(tAuftragPosition.kAuftragStueckliste, 0)
	,ISNULL([@Bestellungen].cBestellNr, '')
	,ISNULL([@Bestellungen].cInetBestellNr, '')
	,[@Bestellungen].cRechnungsNr
	,ISNULL([@Bestellungen].cKundenNr, '')
	,ISNULL(CONVERT(VARCHAR(255), tKunde.nDebitorennr), '')
	,ISNULL([@Bestellungen].cUstId, '')
	,ISNULL([@Bestellungen].cPlattform, '')
	,ISNULL(tZahlungsart.cName, '')
	,ISNULL(tversandart.cName, '')
	,'' --tBestellung.cStatus,
	,'' --Hinweis kommt später
	,[@Bestellungen].cAnmerkung

	/* Buchungskonto nach Positiontyp lesen */
	,tSteuerschluessel.cSteuerkonto

	,ISNULL(tZahlungsart.cKonto, '') AS cBuchungskontoZahlungsart
	,ISNULL([@Bestellungen].cWaehrung, '')
	,ISNULL(tVersandland.cName, '') AS cVersandland
	,ISNULL(tAuftragPosition.fMwSt, 0)
	,ISNULL([@Bestellungen].fFaktor, 1)
	,ISNULL(tAuftragEckdaten.fZahlung, 0)
	,CASE WHEN tAuftragPosition.kSteuerklasse = Steuerdaten.kSteuerklasse THEN 1 ELSE 0 END
	,ISNULL(tLieferland.nEU, 0)
	,CASE WHEN tVersandland.nEU = 1 AND tlieferadresse.cISO != tVersandland.cISO THEN 1 ELSE 0 END
	,ISNULL(tAuftragPosition.nType, 0)
	,ISNULL(tAuftragPosition.nSort, 0)
	,ISNULL(tAuftragPosition.cArtNr, '')
	,ISNULL(tAuftragPosition.cName, '')
	,ISNULL(tAuftragPosition.fAnzahl, 0)

	,ISNULL(CASE WHEN tWarenEingang.fEKEinzel > 0 THEN tWarenEingang.fEKEinzel ELSE CASE WHEN tAuftragPosition.fEKNetto > 0 THEN tAuftragPosition.fEKNetto ELSE ISNULL(tArtikel.fEKNetto, 0) END END, 0)
	,ISNULL((CASE WHEN tWarenEingang.fEKEinzel > 0 THEN tWarenEingang.fEKEinzel ELSE CASE WHEN tAuftragPosition.fEKNetto > 0 THEN tAuftragPosition.fEKNetto ELSE ISNULL(tArtikel.fEKNetto, 0) END END *tAuftragPosition.fAnzahl), 0)


	,tAuftragPosition.fVKNetto * ((100 -tAuftragPosition.fRabatt) /100)
	,(tAuftragPosition.fVKNetto * ((100 -tAuftragPosition.fRabatt) /100)) * tAuftragPosition.fAnzahl 
	,(tAuftragPosition.fVKNetto * ((100 -tAuftragPosition.fRabatt) /100)) * ((tAuftragPosition.fMwSt +100) /100)
	,(tAuftragPosition.fVKNetto * ((100 -tAuftragPosition.fRabatt) /100) * ((tAuftragPosition.fMwSt +100) /100)) * tAuftragPosition.fAnzahl 
	,(tAuftragPosition.fVKNetto * ((100 -tAuftragPosition.fRabatt) /100)) /[@Bestellungen].fFaktor
	,((tAuftragPosition.fVKNetto * ((100 -tAuftragPosition.fRabatt) /100)) * tAuftragPosition.fAnzahl) /[@Bestellungen].fFaktor
	,(tAuftragPosition.fVKNetto * ((100 -tAuftragPosition.fRabatt) /100) * ((tAuftragPosition.fMwSt +100) /100)) /[@Bestellungen].fFaktor
	,((tAuftragPosition.fVKNetto * ((100 -tAuftragPosition.fRabatt) /100) * ((tAuftragPosition.fMwSt +100) /100)) * tAuftragPosition.fAnzahl ) /[@Bestellungen].fFaktor
	/*
	,ISNULL((tAuftragPosition.fWertNettoGesamtFixiert /CASE WHEN tAuftragPosition.fAnzahl = 0 THEN 1 ELSE tAuftragPosition.fAnzahl END), 0)
	,ISNULL(tAuftragPosition.fWertNettoGesamtFixiert, 0)
	,ISNULL((tAuftragPosition.fWertBruttoGesamtFixiert /CASE WHEN tAuftragPosition.fAnzahl = 0 THEN 1 ELSE tAuftragPosition.fAnzahl END), 0)
	,ISNULL(tAuftragPosition.fWertBruttoGesamtFixiert, 0)
	,ISNULL(((tAuftragPosition.fWertNettoGesamtFixiert /CASE WHEN tAuftragPosition.fAnzahl = 0 THEN 1 ELSE tAuftragPosition.fAnzahl END) /[@Bestellungen].fFaktor), 0)
	,ISNULL((tAuftragPosition.fWertNettoGesamtFixiert /[@Bestellungen].fFaktor), 0)
	,ISNULL(((tAuftragPosition.fWertBruttoGesamtFixiert /CASE WHEN tAuftragPosition.fAnzahl = 0 THEN 1 ELSE tAuftragPosition.fAnzahl END) /[@Bestellungen].fFaktor), 0)	
	,ISNULL((tAuftragPosition.fWertBruttoGesamtFixiert /[@Bestellungen].fFaktor), 0)
	*/

	,ISNULL(tFirmaHistory.cName, '')
	,ISNULL(tFirmaHistory.cUnternehmer, '')
	,ISNULL(tFirmaHistory.cStrasse, '')
	,ISNULL(tFirmaHistory.cPLZ, '')
	,ISNULL(tFirmaHistory.cOrt, '')
	,ISNULL(tFirmaHistory.cLand, '')
	,ISNULL(tFirmaHistory.cWWW, '')
	,ISNULL(tFirmaHistory.cEMail, '')
	,ISNULL(tFirmaHistory.cBank, '')
	,''
	,''
	,ISNULL(tFirmaHistory.cIBAN, '')
	,ISNULL(tFirmaHistory.cBIC, '')
	,ISNULL(tFirmaHistory.cSteuerNr, '')
	,ISNULL(tFirmaHistory.cGlaeubigerID, '')
	,ISNULL(trechnungsadresse.cAnrede, '')
	,ISNULL(trechnungsadresse.cFirma, '')
	,ISNULL(trechnungsadresse.cVorname, '')
	,ISNULL(trechnungsadresse.cName, '')
	,ISNULL(trechnungsadresse.cStrasse, '')
	,ISNULL(trechnungsadresse.cPLZ, '')
	,ISNULL(trechnungsadresse.cOrt, '')
	,ISNULL(trechnungsadresse.cBundesland, '')
	,ISNULL(trechnungsadresse.cLand, '')
	,ISNULL(trechnungsadresse.cTel, '')
	,ISNULL(trechnungsadresse.cFax, '')
	,ISNULL(trechnungsadresse.cMobil, '')
	,ISNULL(trechnungsadresse.cMail, '')
	,ISNULL(tlieferadresse.cAnrede, '')
	,ISNULL(tlieferadresse.cFirma, '')
	,ISNULL(tlieferadresse.cVorname, '')
	,ISNULL(tlieferadresse.cName, '')
	,ISNULL(tlieferadresse.cStrasse, '')
	,ISNULL(tlieferadresse.cPLZ, '')
	,ISNULL(tlieferadresse.cOrt, '')
	,ISNULL(tlieferadresse.cBundesland, '')
	,ISNULL(tlieferadresse.cLand, '')
	,ISNULL(tlieferadresse.cISO, '')
	,ISNULL(tlieferadresse.cTel, '')
	,ISNULL(tlieferadresse.cFax, '')
	,ISNULL(tlieferadresse.cMobil, '')
	,ISNULL(tlieferadresse.cMail, '')
	,REPLACE(
		 REPLACE(REPLACE(ISNULL((
			SELECT CONCAT([@SerialNumbers].SerialNumber, CASE WHEN [@SerialNumbers].Comment1 != '' THEN ' ('+[@SerialNumbers].Comment1+') ' ELSE '' END) AS cSeriennr
			FROM @SerialNumbers WHERE [@SerialNumbers].SalesOrderPositionId = tAuftragPosition.kAuftragPosition
		
			FOR XML PATH('')), '')
		,'</cSeriennr><cSeriennr>', ' | ')
		,'<cSeriennr>', '')
		,'</cSeriennr>', ''
	)
	,REPLACE(
		 REPLACE(REPLACE(ISNULL((
			SELECT X.cChargenNr 
			FROM [dbo].[tWarenLagerEingang] X 
			JOIN [dbo].[tWarenLagerAusgang] Y ON Y.kWarenLagerEingang = X.kWarenLagerEingang
			JOIN [dbo].[tLieferscheinPos] Z ON Z.kLieferscheinPos = Y.kLieferscheinPos
			WHERE Z.kBestellPos = tAuftragPosition.kAuftragPosition
		
			FOR XML PATH('')), '')
		,'</cChargenNr><cChargenNr>', ' | ')
		,'<cChargenNr>', '''')
		,'</cChargenNr>', ''
	)
	,[@Bestellungen].dErstellt
	,ISNULL([@Bestellungen].dErstelltAuftrag, [@Bestellungen].dErstellt)
	,ISNULL(tWarenEingang.dGeliefertAm, tWarenEingang.dErstellt) AS dGeliefertAm
	,[@Bestellungen].dBezahlt
	,[@Bestellungen].dVersandt
	,CASE WHEN tAuftrag.nSteuereinstellung = 15 THEN 1 ELSE 0 END
	,DocumentType
	,ISNULL(Steuerdaten.TaxRate, 0) AS DiffTaxRate

FROM @Bestellungen 
JOIN [Verkauf].[tAuftrag] ON tAuftrag.kAuftrag = [@Bestellungen].kBestellung
JOIN [Verkauf].[tAuftragEckdaten] ON tAuftragEckdaten.kAuftrag = tAuftrag.kAuftrag
CROSS APPLY (
	SELECT TOP(1)
		 cAnrede
		,cFirma
		,cVorname
		,cName
		,cStrasse
		,cPLZ
		,cOrt
		,cBundesland
		,cLand
		,cTel
		,cFax
		,cMobil
		,cMail
	FROM [Verkauf].[tAuftragAdresse] WHERE tAuftragAdresse.kAuftrag = tAuftrag.kAuftrag AND tAuftragAdresse.nTyp = 1
) AS tRechnungsAdresse
CROSS APPLY (
	SELECT TOP(1)
		 cAnrede
		,cFirma
		,cVorname
		,cName
		,cStrasse
		,cPLZ
		,cOrt
		,cBundesland
		,cLand
		,cTel
		,cFax
		,cMobil
		,cMail
		,cISO
	FROM [Verkauf].[tAuftragAdresse] WHERE tAuftragAdresse.kAuftrag = tAuftrag.kAuftrag AND tAuftragAdresse.nTyp = 0
) AS tLieferAdresse
JOIN [dbo].[tFirmaHistory] ON tFirmaHistory.kFirmaHistory = tAuftrag.kFirmaHistory
LEFT OUTER JOIN [dbo].[tkunde] ON tkunde.kKunde = [@Bestellungen].kKunde
LEFT OUTER JOIN [dbo].[tAdresse] ON tAdresse.kKunde = tkunde.kKunde AND tAdresse.nStandard = 1 AND tAdresse.nTyp = 1
LEFT OUTER JOIN [dbo].[tZahlungsart] ON tZahlungsart.kZahlungsart = [@Bestellungen].kZahlungsArt
LEFT OUTER JOIN [dbo].[tversandart] ON tversandart.kVersandArt = [@Bestellungen].kVersandArt
JOIN @tLand AS tVersandland ON tVersandland.cISO = [@Bestellungen].cVersandlandISO
JOIN @tLand AS tRechnungsland ON tRechnungsland.cISO = tLieferAdresse.cISO
JOIN @tLand AS tLieferland ON tLieferland.cISO = tlieferadresse.cISO


JOIN [Verkauf].[tAuftragPosition] ON tAuftragPosition.kAuftrag = tAuftrag.kAuftrag
LEFT OUTER JOIN [eazybusiness].[dbo].[em_tSteuerEinstellung] AS Steuerdaten 
	ON Steuerdaten.cDB = 'eazybusiness'
	AND Steuerdaten.kFirma = tFirmaHistory.kFirma
	AND Steuerdaten.kSteuerklasse = tAuftragPosition.kSteuerklasse
LEFT OUTER JOIN [dbo].[tSteuerschluessel] ON tSteuerschluessel.kSteuerschluessel = tAuftragPosition.kSteuerschluessel
LEFT OUTER JOIN [dbo].[tArtikel] ON tArtikel.kArtikel = tAuftragPosition.kArtikel
OUTER APPLY(
	SELECT TOP(1)
		 tWarenLagerAusgang.kWarenLagerEingang
		,tWarenLagerEingang.fEKEinzel 
		,tWarenLagerEingang.dGeliefertAM
		,tWarenLagerEingang.dErstellt
		
	FROM [dbo].[tWarenLagerAusgang] 	
	JOIN [dbo].[tWarenLagerEingang] ON tWarenLagerEingang.kWarenLagerEingang = tWarenLagerAusgang.kWarenLagerEingang
	JOIN [dbo].[tLieferscheinPos] ON tLieferscheinPos.kLieferscheinPos = tWarenLagerAusgang.kLieferscheinPos
	WHERE
		tLieferscheinPos.kBestellPos = tAuftragPosition.kAuftragPosition

	ORDER BY 
		tWarenLagerEingang.dErstellt ASC
) AS tWarenEingang
WHERE DocumentType = 'POS'

ORDER BY 
	[@Bestellungen].dErstellt ASC;

UPDATE @Temp SET 
	 fEKNettoEinzel = fEKNettoEinzel *-1
	,fEKNettoGesamt = fEKNettoGesamt *-1
	,fVKNettoEinzel = fVKNettoEinzel *-1
	,fVKNettoGesamt = fVKNettoGesamt *-1
	,fVKBruttoEinzel = fVKBruttoEinzel *-1
	,fVKBruttoGesamt = fVKBruttoGesamt *-1
	,fVKNettoEinzelWahrungsFaktor = fVKNettoEinzelWahrungsFaktor *-1
	,fVKNettoGesamtWahrungsFaktor = fVKNettoGesamtWahrungsFaktor *-1
	,fVKBruttoEinzelWahrungsFaktor = fVKBruttoEinzelWahrungsFaktor *-1
	,fVKBruttoGesamtWahrungsFaktor = fVKBruttoGesamtWahrungsFaktor *-1

WHERE DocumentType = 'CANCELLEDINVOICE';

/* Häuftigstes Buchungskonto auf Versandart anwerden */
IF @nBuchungskontoVersandkostenPositionAusMasse = 1	
BEGIN
	UPDATE @Temp 
	SET 
		cBuchungskonto = (
			Select TOP(1) A.cBuchungskonto FROM @Temp A WHERE A.kBestellung = [@Temp].kBestellung AND A.nType <> 2 GROUP BY A.cBuchungskonto ORDER BY count((A.cBuchungskonto)) DESC, SUM(A.fVKNettoGesamt) DESC
		),
		nDifferenzbesteuerung = (
			Select TOP(1) A.nDifferenzbesteuerung FROM @Temp A WHERE A.kBestellung = [@Temp].kBestellung AND A.nType <> 2 GROUP BY A.nDifferenzbesteuerung ORDER BY count((A.nDifferenzbesteuerung)) DESC, SUM(A.fVKNettoGesamt) DESC
		)

	WHERE 
		nType = 2;
END

/* Einkaufspreis der Stücklistenkomponenten auf den Vater übertragen (Differenzberechnung) */
IF @nEKSteucklistenKomponentenAnwenden = 1
BEGIN
	UPDATE @Temp 
	SET 
		 fEKNettoEinzel = ISNULL((SELECT SUM(fEKNettoEinzel) FROM @Temp A WHERE A.kBestellStuckliste = [@Temp].kBestellPos AND A.kBestellStuckliste != A.kBestellPos), 0)
		,fEKNettoGesamt = ISNULL(((SELECT SUM(fEKNettoEinzel) FROM @Temp A WHERE A.kBestellStuckliste = [@Temp].kBestellPos AND A.kBestellStuckliste != A.kBestellPos) *[@Temp].nAnzahl), 0)

	WHERE
		kBestellStuckliste = kBestellPos;

	UPDATE @Temp 
	SET
		fEKNettoEinzel = 0,
		fEKNettoGesamt = 0

	WHERE
		kBestellStuckliste > 0 AND
		kBestellStuckliste != kBestellPos;
END

/* 0-Summen entfernen */
IF @nNullEuroPositionen = 1
BEGIN
DELETE FROM @Temp WHERE fVKNettoEinzel = 0 AND kBestellStuckliste = 0;
END

/* Stücklisten-Kinder entfernen */
IF @nStuecklistenfilter = 1
BEGIN
	DELETE FROM @Temp WHERE kBestellStuckliste > 0 AND kBestellStuckliste != kBestellPos;
END

/* Stücklisten-Väter entfernen */
IF @nStuecklistenfilter = 2
BEGIN
	DELETE FROM @Temp WHERE kBestellStuckliste = kBestellPos;
END

/* Zahlungen nur in der ersten Position ausgeben */
;WITH cte (kBestellung, fZahlung, row_num) AS (
	SELECT 
		 kBestellung
		,fZahlung
		,ROW_NUMBER() OVER (
			PARTITION BY 
				 kBestellung
				,fZahlung
			ORDER BY 
				 kBestellung
				,fZahlung
		) row_num
	FROM @Temp
)
UPDATE cte SET fZahlung = 0 WHERE row_num > 1

SELECT 
	 cTyp AS Type
	,kBestellung AS SalesOrderId
	,kInetBestellung AS ExternalSalesOrderId
	,kRechnung AS SalesInvoiceId
	,0 AS SalesInvoiceCorrectionId
	,kKunde AS CustomerId
	,kFirma AS CompanyId
	,kArtikel AS ProductId
	,kBestellPos AS SakesOrderPositionId
	,cBestellNr AS SalesOrderNumber
	,cInetBestellNr AS ExternalSalesOrderNumber
	,cRechnungsNr AS SalesInvoiceNumber
	,'' AS SalesInvoiceCorrectionNumber
	,cKundenNr AS CustomerNumber
	,cDebitorennummer AS DebitorNumber
	,cUmsatzsteuerID AS VatIdNumber
	,cPlattform AS PlatformName
	,cZahlungsart AS PaymentMethod
	,cVersandart AS ShippingMethod
	,cStatus AS Status
	,cHinweis AS Comment1
	,cAnmerkung AS Comment2
	,cBuchungskonto AS BookingAccount
	,cBuchungskontoZahlungsart AS BookingAccountPaymentMethod
	,cWaehrung AS Currency
	,cVersandland AS DepartmentCountry
	,fMwSt AS VatRate
	,fFaktor AS CurrencyFactor
	,fZahlung AS TotalPayd
	,nDifferenzBesteuerung AS IsDifferencialTaxation
	,nIstEU AS IsEU
	,nIGL AS IsIGL
	,nType AS PositionTypeId
	,nSortiernummer AS SortNumber
	,cArtNr AS Sku
	,cName AS Name
	,SUM(nAnzahl) AS Quantity
	,SUM(fEKNettoEinzel) AS NetPurchasingPrice
	,SUM(fEKNettoGesamt) AS TotalNetPurchasingPrice
	,SUM(fVKNettoEinzel) AS NetPrice
	,SUM(fVKNettoGesamt) AS TotalNetPrice
	,SUM(fVKBruttoEinzel) AS GrossPrice
	,SUM(fVKBruttoGesamt) AS TotalGrossPrice
	,SUM(fVKNettoEinzelWahrungsFaktor) AS NetPriceInBaseCurrency
	,SUM((fVKNettoEinzelWahrungsFaktor *nAnzahl)) AS TotalNetPriceInBaseCurrency
	,SUM(fVKBruttoEinzelWahrungsFaktor) AS GrossPriceInBaseCurrency
	,SUM(fVKBruttoEinzelWahrungsFaktor *nAnzahl) AS TotalGrossPriceInBaseCurrency
	,tFirma_cName AS CompanyName
	,tFirma_cUnternehmer AS CompanyCeo
	,tfirma_cStrasse AS CompanyStreet
	,tfirma_cPLZ AS CompanyPostalCode
	,tfirma_cOrt AS CompanyCity
	,tfirma_cLand AS CompanyCountry
	,tfirma_cWWW AS CompanyHomepage
	,tfirma_cEMail AS CompanyEmail
	,tfirma_cBank AS CompanyBankName
	,tfirma_cKontoNr AS CompanyAccountNumber
	,tfirma_cBLZ AS CompanyBankCode
	,tfirma_cIBAN AS CompanyIban
	,tfirma_cBIC AS CompanyBic
	,tfirma_cSteuerNr AS CompanyTaxNumber
	,tfirma_cGlaeubigerID AS CompanyCreditorId
	,cRE_Anrede AS InvoiceAddressSalutation
	,cRE_Firma AS InvoiceAddressCompanyName
	,cRE_Vorname AS InvoiceAddressFirstName
	,cRE_Nachname AS InvoiceAddressLastName
	,cRE_Strasse AS InvoiceAddressStreet
	,cRE_PLZ AS InvoiceAddressPostalCode
	,cRE_Ort AS InvoiceAddressCity
	,cRE_Bundesland AS InvoiceAddressFederalState
	,cRE_Land AS InvoiceAddressCountry
	,cRE_Telefon AS InvoiceAddressPhone
	,cRE_Telefax AS InvoiceAddressFax
	,cRE_Mobil AS InvoiceAddressMobile
	,cRE_Mail AS InvoiceAddressEmail
	,cLA_Anrede AS ShippingAddressSalutation
	,cLA_Firma AS ShippingAddressCompanyName
	,cLA_Vorname AS ShippingAddressFirstName
	,cLA_Nachname AS ShippingAddressLastName
	,cLA_Strasse AS ShippingAddressStreet
	,cLA_PLZ AS ShippingAddressPostalCode
	,cLA_Ort AS ShippingAddressCity
	,cLA_Bundesland AS ShippingAddressFederalState
	,cLA_Land AS ShippingAddressCountry
	,cLA_ISO AS ShippingAddressCountryIso
	,cLA_Telefon AS ShippingAddressPhone
	,cLA_Telefax AS ShippingAddressFax
	,cLA_Mobil AS ShippingAddressMobile
	,cLA_Mail AS ShippingAddressEmail
	,cSeriennummer AS SerialNumbers
	,cCharge AS BatchNumbers
	,'' AS PositionComment
	,dErstellt AS CreatedAt
	,dErstelltAuftrag AS SalesOrderDate
	,NULL AS SalesInvoiceDate
	,dGeliefertAm AS ShippedAt
	,dBezahlt AS PaydAt
	,dVersand AS ShppingDate
	,IsReverseCharge AS IsReverseCharge
	,DiffTaxRate AS DiffTaxRate

FROM @Temp
WHERE (
		ISNULL(cRechnungsNr, '') LIKE '%' + @cSuchbegriff + '%' OR 
		cArtNr LIKE '%' + @cSuchbegriff + '%' OR 
		cName LIKE '%' + @cSuchbegriff + '%'
	) AND
	nIstEU = (
		CASE @nRegion
		WHEN 0 THEN nIstEU
		WHEN 1 THEN 1
		WHEN 2 THEN 0
		END
	) AND
	nDifferenzBesteuerung = (
		CASE @nPosition
		WHEN 0 THEN nDifferenzBesteuerung
		WHEN 1 THEN 1
		WHEN 2 THEN 0
		END
	) AND
	kFirma = (
		CASE WHEN @kFirma > 0 THEN @kFirma ELSE kFirma END
	) AND
	fMwSt = (
		CASE WHEN @fMwSt > -1 THEN @fMwSt ELSE fMwSt END
	)
	#nTypeIN#
	#nDifferenz#
	

GROUP BY
	cTyp,
	kBestellung,
	kInetBestellung,
	kRechnung,
	kKunde,
	kFirma,
	kArtikel,
	kBestellPos,
	cBestellNr,
	cInetBestellNr,
	cRechnungsNr,
	cKundenNr,
	cDebitorennummer,
	cUmsatzsteuerID,
	cPlattform,
	cZahlungsart,
	cVersandart,
	cStatus,
	cHinweis,
	cAnmerkung,
	cBuchungskonto,
	cBuchungskontoZahlungsart,
	cWaehrung,
	cVersandland,
	fMwSt,
	fFaktor,
	fZahlung,
	nDifferenzBesteuerung,
	nIstEU,
	nIGL,
	nType,
	nSortiernummer,
	cArtNr,
	cName,	
	tFirma_cName,
	tFirma_cUnternehmer,
	tfirma_cStrasse,
	tfirma_cPLZ,
	tfirma_cOrt,
	tfirma_cLand,
	tfirma_cWWW,
	tfirma_cEMail,
	tfirma_cBank,
	tfirma_cKontoNr,
	tfirma_cBLZ,
	tfirma_cIBAN,
	tfirma_cBIC,
	tfirma_cSteuerNr,
	tfirma_cGlaeubigerID,
	cRE_Anrede,
	cRE_Firma,
	cRE_Vorname,
	cRE_Nachname,
	cRE_Strasse,
	cRE_PLZ,
	cRE_Ort,
	cRE_Bundesland,
	cRE_Land,
	cRE_Telefon,
	cRE_Telefax,
	cRE_Mobil,
	cRE_Mail,
	cLA_Anrede,
	cLA_Firma,
	cLA_Vorname,
	cLA_Nachname,
	cLA_Strasse,
	cLA_PLZ,
	cLA_Ort,
	cLA_Bundesland,
	cLA_Land,
	cLA_ISO,
	cLA_Telefon,
	cLA_Telefax,
	cLA_Mobil,
	cLA_Mail,
	cSeriennummer,
	cCharge,
	dErstellt,
	dErstelltAuftrag,
	dGeliefertAm,
	dBezahlt,
	dVersand
	,IsReverseCharge
	,DiffTaxRate

ORDER BY 
	dErstellt DESC,
	kBestellPos ASC;
