
---
USE #cDB#

DECLARE @tLand Table(
	cISO VARCHAR(20) NOT NULL,
	cName VARCHAR(100) NOT NULL,
	nEU INT NOT NULL
);

INSERT INTO @tLand SELECT cISO, cName, nEU FROM [dbo].[tLand];

DECLARE @Gutschriften TABLE(	 
	 kBestellung INT
	,kInetBestellung INT
	,kRechnung INT
	,kRechnungskorrektur INT
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
	,cRechnungskorrekturNr VARCHAR(255)
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
);

DECLARE @Temp TABLE(
	cTyp VARCHAR(255),
	kBestellung INT NOT NULL,
	kInetBestellung INT NOT NULL,
	kRechnung INT NOT NULL,
	kRechnungskorrektur INT NOT NULL,
	kKunde INT NOT NULL,
	kFirma INT NOT NULL,	
	kArtikel INT NOT NULL,
	kBestellPos INT NULL,	
	kBestellStuckliste INT NULL,
	cBestellNr VARCHAR(255) NOT NULL,
	cInetBestellNr VARCHAR(255) NOT NULL,
	cRechnungsNr VARCHAR(255) NOT NULL,
	cRechnungskorrekturNr VARCHAR(255) NOT NULL,
	cKundenNr VARCHAR(255) NOT NULL,
	cDebitorennummer VARCHAR(255) NOT NULL,
	cUmsatzsteuerID VARCHAR(40) NULL,
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
	nType INT NOT NULL,
	nSortiernummer INT NULL,
	cArtNr VARCHAR(255) NOT NULL,
	cName VARCHAR(255) NOT NULL,
	nAnzahl FLOAT NOT NULL,	
	fGutschriftanteilProzent FLOAT NOT NULL,
	fVKNettoEinzelBestellung FLOAT NOT NULL,
	fVKNettoGesamtBestellung FLOAT NOT NULL,
	fVKBruttoEinzelBestellung FLOAT NOT NULL,
	fVKBruttoGesamtBestellung FLOAT NOT NULL,
	fVKNettoEinzelWahrungsFaktorBestellung FLOAT NOT NULL,
	fVKNettoGesamtWahrungsFaktorBestellung FLOAT NOT NULL,
	fVKBruttoEinzelWahrungsFaktorBestellung FLOAT NOT NULL,
	fVKBruttoGesamtWahrungsFaktorBestellung FLOAT NOT NULL,
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
	fVKNettoEinzelRechnung FLOAT NOT NULL,
	fVKNettoGesamtRechnung FLOAT NOT NULL,
	fVKBruttoEinzelRechnung FLOAT NOT NULL,
	fVKBruttoGesamtRechnung FLOAT NOT NULL,
	fVKNettoEinzelWahrungsFaktorRechnung FLOAT NOT NULL,
	fVKNettoGesamtWahrungsFaktorRechnung FLOAT NOT NULL,
	fVKBruttoEinzelWahrungsFaktorRechnung FLOAT NOT NULL,
	fVKBruttoGesamtWahrungsFaktorRechnung FLOAT NOT NULL,
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
	cLA_ISO VARCHAR(255) NOT NULL,
	cLA_Telefon VARCHAR(255) NOT NULL,
	cLA_Telefax VARCHAR(255) NOT NULL,
	cLA_Mobil VARCHAR(255) NOT NULL,
	cLA_Mail VARCHAR(255) NOT NULL,
	cSeriennummer NVARCHAR(MAX) NOT NULL,
	cCharge NVARCHAR(MAX) NOT NULL,
	dErstellt DATETIME NOT NULL,
	dErstelltRechnung DATETIME NULL,
	dGeliefertAm DATETIME NULL,
	dBezahlt DATETIME NULL,
	dVersand DATETIME NULL
	,DiffTaxRate FLOAT NULL
);

DECLARE @SerialNumbers TABLE(
	 SalesOrderId INT
	,SalesOrderPositionId INT
	,SerialNumber VARCHAR(255)
	,Comment1 VARCHAR(255)
	,Comment2 VARCHAR(255)
);


INSERT INTO @Gutschriften
SELECT	 
	 0
	,0
	,tgutschrift.kRechnung
	,tgutschrift.kGutschrift
	,tgutschrift.kKunde
	,tgutschrift.kFirma
	,ISNULL(tRechnung.kZahlungsart, 0)
	,ISNULL(tRechnung.kVersandArt, 0)
	,tgutschrift.kRechnungsAdresse
	,0
	,tPlattform.nTyp
	,'Rechnungskorrektur'
	,tPlattform.cName
	,''
	,ISNULL(tRechnung.cExterneAuftragsnummer, '')
	,ISNULL(trechnung.cRechnungsNr, '')
	,tgutschrift.cGutschriftNr
	,ISNULL(tKunde.cKundenNr, '')
	,tgutschrift.cWaehrung
	,ISNULL(tRechnung.cUstId, '')	
	,tRechnung.cVersandlandISO
	,'' --tBestellung.cAnmerkung
	,tgutschrift.fFaktor
	,tgutschrift.dErstellt
	,NULL --tBestellung.dErstellt
	,tRechnungEckdaten.dBezahlt
	,tRechnung.dLeistungsdatum

FROM [dbo].[tgutschrift]
JOIN [dbo].[tPlattform] ON tPlattform.nPlattform = tgutschrift.kPlattform
LEFT OUTER JOIN [dbo].[tkunde] ON tkunde.kKunde = tgutschrift.kKunde
LEFT OUTER JOIN [Rechnung].[tRechnung] ON tRechnung.kRechnung = tgutschrift.kRechnung
LEFT OUTER JOIN [Rechnung].[tRechnungEckdaten] ON tRechnungEckdaten.kRechnung = tRechnung.kRechnung
WHERE 
	CONVERT(DATE,tgutschrift.dErstellt, 105)  >= CONVERT(DATE, @dDatumStart, 105) AND
	CONVERT(DATE,tgutschrift.dErstellt, 105)  <= CONVERT(DATE, @dDatumEnde, 105) AND
	tgutschrift.cGutschriftNr != '' AND
	tgutschrift.nStornotyp = 0
	--tPlattform.nTyp IN (1,3)
	;

INSERT INTO @SerialNumbers
SELECT 
	 0
	,tLieferscheinPos.kBestellPos
	,tLagerArtikel.cSeriennr
	,tLagerArtikel.cBeschreibung1
	,tLagerArtikel.cBeschreibung2

FROM @Gutschriften
JOIN [dbo].[tGutschriftPos] ON tGutschriftPos.tGutschrift_kGutschrift = [@Gutschriften].kRechnungskorrektur
JOIN [dbo].[tbestellpos] ON tbestellpos.kBestellPos = tgutschriftpos.kBestellPos
JOIN [dbo].[tLieferscheinPos] ON tLieferscheinPos.kBestellPos = tbestellpos.kBestellPos
JOIN [dbo].[tLagerArtikel] ON tLagerArtikel.kLieferscheinPos = tLieferscheinPos.kLieferscheinPos

INSERT INTO @Temp
SELECT 
	 [@Gutschriften].cTyp
	,[@Gutschriften].[kBestellung]
	,[@Gutschriften].[kInetBestellung]
	,[@Gutschriften].[kRechnung]
	,[@Gutschriften].[kRechnungskorrektur]
	,[@Gutschriften].[kKunde]
	,[@Gutschriften].[kFirma]	
	,tGutschriftPos.tArtikel_kArtikel
	,tGutschriftPos.kGutschriftPos
	,tGutschriftPos.kGutschriftStueckliste

	,[@Gutschriften].[cBestellNr]
	,[@Gutschriften].[cInetBestellNr]
	,[@Gutschriften].[cRechnungsNr]
	,[@Gutschriften].[cRechnungskorrekturNr]
	,[@Gutschriften].[cKundenNr]
	,ISNULL(CONVERT(VARCHAR(255), tKunde.nDebitorennr), '')
	,[@Gutschriften].[cUstId]
	,[@Gutschriften].[cPlattform] 
	,tZahlungsart.cName
	,tversandart.cName
	,'' --cStatus kommt sp�ter
	,'' --cHinweis kommt sp�ter
	,[@Gutschriften].[cAnmerkung]	
	
	/* Buchungskonto nach Positiontyp lesen */
	,ISNULL(
	 (
		SELECT TOP(1) tSteuerschluessel.cSteuerkonto 
		FROM tSteuerzone 
		JOIN tSteuerzoneLand ON tSteuerzoneLand.kSteuerzone = tSteuerzone.kSteuerzone
		JOIN tSteuersatz ON tSteuersatz.kSteuerzone = tSteuerzone.kSteuerzone 
		OUTER APPLY(
			SELECT
				tSteuerschluessel.cSteuerkonto

			FROM [dbo].[tSteuerschluessel] 
			WHERE
				tSteuerschluessel.kSteuerschluessel = 
				CASE WHEN tLieferland.nEU = 1 THEN
					CASE WHEN (CASE WHEN tVersandland.nEU = 1 AND tLieferland.nEU = 1 AND tVersandland.cISO != tLieferland.cISO THEN 1 ELSE 0 END) = 1 THEN
						CASE WHEN tAdresse.cUSTID != '' THEN 
							tSteuersatz.kStSchlIGL 
						ELSE tSteuersatz.kStSchlUStIGL END
					ELSE tSteuersatz.kStSchl END
				ELSE tSteuersatz.kStSchlIGL END
		)
		AS tSteuerschluessel

		WHERE 
			tSteuerzone.cLandISO = [@Gutschriften].cVersandlandISO AND 
			tSteuerzone.kFirma = 0 AND
			tSteuerzoneLand.cISO = tLieferland.cISO AND
			tSteuersatz.fSteuersatz = tGutschriftPos.fMwSt
	 ), '-')
	 AS cBuchungskonto

	,tZahlungsart.cKonto 
	,[@Gutschriften].[cWaehrung]
	,ISNULL(tVersandland.cName, '')

	,ISNULL(tGutschriftPos.fMwSt, 0)
	,ISNULL([@Gutschriften].fFaktor, 1)
	,0 --fZahlung
	,CASE WHEN tSteuerklasse.kSteuerklasse = Steuerdaten.kSteuerklasse THEN 1 ELSE 0 END
	,ISNULL(tLieferland.nEU, 0)	
	,ISNULL(tbestellpos.nType, 0)
	,ISNULL(tbestellpos.nSort, 0)
	,ISNULL(tGutschriftPos.cArtNr, '')
	,ISNULL(tGutschriftPos.cString, '')
	,ISNULL(tGutschriftPos.nAnzahl, 0)

	,CASE WHEN ISNULL(tbestellpos.fVKPreis, 0) > 0 THEN ((tgutschriftpos.fVKPreis *100) /tbestellpos.fVKPreis) ELSE 100 END
	,ISNULL(tbestellpos.fVKNetto -CASE WHEN ISNULL(tbestellpos.fRabatt, 0) > 0 THEN ((tbestellpos.fVKNetto /100) *tbestellpos.fRabatt) ELSE 0 END, 0)
	,ISNULL(((tbestellpos.fVKNetto -CASE WHEN ISNULL(tbestellpos.fRabatt, 0) > 0 THEN ((tbestellpos.fVKNetto /100) *tbestellpos.fRabatt) ELSE 0 END) *tbestellpos.nAnzahl), 0)
	,ISNULL(tbestellpos.fVKPreis -CASE WHEN ISNULL(tbestellpos.fRabatt, 0) > 0 THEN ((tbestellpos.fVKPreis /100) *tbestellpos.fRabatt) ELSE 0 END, 0)
	,ISNULL(((tbestellpos.fVKPreis -CASE WHEN ISNULL(tbestellpos.fRabatt, 0) > 0 THEN ((tbestellpos.fVKPreis /100) *tbestellpos.fRabatt) ELSE 0 END) *tbestellpos.nAnzahl), 0)
	,ISNULL((tbestellpos.fVKNetto -CASE WHEN ISNULL(tbestellpos.fRabatt, 0) > 0 THEN ((tbestellpos.fVKNetto /100) *tbestellpos.fRabatt) ELSE 0 END) /[@Gutschriften].fFaktor, 0)
	,ISNULL((((tbestellpos.fVKNetto -CASE WHEN ISNULL(tbestellpos.fRabatt, 0) > 0 THEN ((tbestellpos.fVKNetto /100) *tbestellpos.fRabatt) ELSE 0 END) *tbestellpos.nAnzahl)) /[@Gutschriften].fFaktor, 0)
	,ISNULL((tbestellpos.fVKPreis -CASE WHEN ISNULL(tbestellpos.fRabatt, 0) > 0 THEN ((tbestellpos.fVKPreis /100) *tbestellpos.fRabatt) ELSE 0 END) /[@Gutschriften].fFaktor, 0)
	,ISNULL((((tbestellpos.fVKPreis -CASE WHEN ISNULL(tbestellpos.fRabatt, 0) > 0 THEN ((tbestellpos.fVKPreis /100) *tbestellpos.fRabatt) ELSE 0 END) *tbestellpos.nAnzahl)) /[@Gutschriften].fFaktor, 0)
	,ISNULL(CASE WHEN tWarenEingang.fEKEinzel > 0 THEN tWarenEingang.fEKEinzel ELSE CASE WHEN tbestellpos.fEKNetto > 0 THEN tbestellpos.fEKNetto ELSE ISNULL(tArtikel.fEKNetto, 0) END END, 0)
	,ISNULL((CASE WHEN tWarenEingang.fEKEinzel > 0 THEN tWarenEingang.fEKEinzel ELSE CASE WHEN tbestellpos.fEKNetto > 0 THEN tbestellpos.fEKNetto ELSE ISNULL(tArtikel.fEKNetto, 0) END END *tgutschriftpos.nAnzahl), 0)
	,tgutschriftpos.fVKNetto -CASE WHEN tgutschriftpos.fRabatt > 0 THEN ((tgutschriftpos.fVKNetto /100) *tgutschriftpos.fRabatt) ELSE 0 END
	,((tgutschriftpos.fVKNetto -CASE WHEN tgutschriftpos.fRabatt > 0 THEN ((tgutschriftpos.fVKNetto /100) *tgutschriftpos.fRabatt) ELSE 0 END) *tgutschriftpos.nAnzahl)
	,tgutschriftpos.fVKPreis -CASE WHEN tgutschriftpos.fRabatt > 0 THEN ((tgutschriftpos.fVKPreis /100) *tgutschriftpos.fRabatt) ELSE 0 END
	,((tgutschriftpos.fVKPreis -CASE WHEN tgutschriftpos.fRabatt > 0 THEN ((tgutschriftpos.fVKPreis /100) *tgutschriftpos.fRabatt) ELSE 0 END) *tgutschriftpos.nAnzahl)
	,((tgutschriftpos.fVKNetto -CASE WHEN tgutschriftpos.fRabatt > 0 THEN ((tgutschriftpos.fVKNetto /100) *tgutschriftpos.fRabatt) ELSE 0 END) /[@Gutschriften].fFaktor)
	,((((tgutschriftpos.fVKNetto -CASE WHEN tgutschriftpos.fRabatt > 0 THEN ((tgutschriftpos.fVKNetto /100) *tgutschriftpos.fRabatt) ELSE 0 END) *tgutschriftpos.nAnzahl)) /[@Gutschriften].fFaktor)
	,((tgutschriftpos.fVKPreis -CASE WHEN tgutschriftpos.fRabatt > 0 THEN ((tgutschriftpos.fVKPreis /100) *tgutschriftpos.fRabatt) ELSE 0 END) /[@Gutschriften].fFaktor)
	,((((tgutschriftpos.fVKPreis -CASE WHEN tgutschriftpos.fRabatt > 0 THEN ((tgutschriftpos.fVKPreis /100) *tgutschriftpos.fRabatt) ELSE 0 END) *tgutschriftpos.nAnzahl)) /[@Gutschriften].fFaktor)
	,ISNULL(tbestellpos.fVKNetto -CASE WHEN tbestellpos.fRabatt > 0 THEN ((tbestellpos.fVKNetto /100) *tbestellpos.fRabatt) ELSE 0 END, 0)
	,ISNULL(((tbestellpos.fVKNetto -CASE WHEN tbestellpos.fRabatt > 0 THEN ((tbestellpos.fVKNetto /100) *tbestellpos.fRabatt) ELSE 0 END) *tbestellpos.nAnzahl), 0)
	,ISNULL(tbestellpos.fVKPreis -CASE WHEN tbestellpos.fRabatt > 0 THEN ((tbestellpos.fVKPreis /100) *tbestellpos.fRabatt) ELSE 0 END, 0)
	,ISNULL(((tbestellpos.fVKPreis -CASE WHEN tbestellpos.fRabatt > 0 THEN ((tbestellpos.fVKPreis /100) *tbestellpos.fRabatt) ELSE 0 END) *tbestellpos.nAnzahl), 0)
	,ISNULL(((tbestellpos.fVKNetto -CASE WHEN tbestellpos.fRabatt > 0 THEN ((tbestellpos.fVKNetto /100) *tbestellpos.fRabatt) ELSE 0 END) /[@Gutschriften].fFaktor), 0)
	,ISNULL(((((tbestellpos.fVKNetto -CASE WHEN tbestellpos.fRabatt > 0 THEN ((tbestellpos.fVKNetto /100) *tbestellpos.fRabatt) ELSE 0 END) *tbestellpos.nAnzahl)) /[@Gutschriften].fFaktor), 0)
	,ISNULL(((tbestellpos.fVKPreis -CASE WHEN tbestellpos.fRabatt > 0 THEN ((tbestellpos.fVKPreis /100) *tbestellpos.fRabatt) ELSE 0 END) /[@Gutschriften].fFaktor), 0)
	,ISNULL(((((tbestellpos.fVKPreis -CASE WHEN tbestellpos.fRabatt > 0 THEN ((tbestellpos.fVKPreis /100) *tbestellpos.fRabatt) ELSE 0 END) *tbestellpos.nAnzahl)) /[@Gutschriften].fFaktor), 0)

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

	,''
	,''
	,''
	,''
	,''
	,''
	,''
	,''
	,''
	,''
	,''
	,''
	,''
	,''

	,REPLACE(
		 REPLACE(REPLACE(ISNULL((
			SELECT CONCAT([@SerialNumbers].SerialNumber, CASE WHEN [@SerialNumbers].Comment1 != '' THEN ' ('+[@SerialNumbers].Comment1+') ' ELSE '' END) AS cSeriennr
			FROM @SerialNumbers WHERE [@SerialNumbers].SalesOrderPositionId = tGutschriftPos.kBestellPos
		
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
			WHERE Z.kBestellPos = tGutschriftPos.kBestellPos
		
			FOR XML PATH('')), '')
		,'</cChargenNr><cChargenNr>', ' | ')
		,'<cChargenNr>', '''')
		,'</cChargenNr>', ''
	)
	,[@Gutschriften].dErstellt
	,[@Gutschriften].dErstelltAuftrag
	,ISNULL(tWarenEingang.dGeliefertAm, tWarenEingang.dErstellt) AS dGeliefertAm
	,[@Gutschriften].dBezahlt
	,[@Gutschriften].dVersandt
	,ISNULL(Steuerdaten.TaxRate, 0) AS DiffTaxRate

FROM @Gutschriften
LEFT OUTER JOIN [dbo].[tKunde] ON tKunde.kKunde = [@Gutschriften].kKunde
LEFT OUTER JOIN [dbo].[tfirma] ON tfirma.kFirma = [@Gutschriften].kFirma
JOIN [dbo].[tGutschriftPos] ON tGutschriftPos.tGutschrift_kGutschrift = [@Gutschriften].kRechnungskorrektur
LEFT OUTER JOIN [dbo].[tbestellpos] ON tbestellpos.kBestellPos = tgutschriftpos.kBestellPos

JOIN [dbo].[trechnungsadresse] ON trechnungsadresse.kRechnungsAdresse = [@Gutschriften].kRechnungsAdresse
--LEFT OUTER JOIN [dbo].[tlieferadresse] ON tlieferadresse.kLieferAdresse = [@Gutschriften].kLieferAdresse 

--JOIN [Rechnung].[tRechnungAdresse] AS trechnungsadresse ON trechnungsadresse.kRechnungAdresse = [@Gutschriften].kRechnungsAdresse AND trechnungsadresse.nTyp = 1
--LEFT OUTER JOIN [Rechnung].[tRechnungAdresse] AS tlieferadresse ON tlieferadresse.kRechnungAdresse = [@Gutschriften].kLieferAdresse AND tlieferadresse.nTyp = 0
LEFT OUTER JOIN [dbo].[tAdresse] ON tAdresse.kKunde = tkunde.kKunde AND tAdresse.nStandard = 1 AND tAdresse.nTyp = 1
LEFT OUTER JOIN [dbo].[tZahlungsart] ON tZahlungsart.kZahlungsart = [@Gutschriften].kZahlungsart
LEFT OUTER JOIN [dbo].[tversandart] ON tversandart.kVersandArt = [@Gutschriften].kVersandArt
LEFT OUTER JOIN [dbo].[tArtikel] ON tArtikel.kArtikel = tGutschriftPos.tArtikel_kArtikel
LEFT OUTER JOIN [dbo].[tSteuerklasse] ON tSteuerklasse.kSteuerklasse = tArtikel.kSteuerklasse
LEFT OUTER JOIN @tLand AS tVersandland ON tVersandland.cISO = [@Gutschriften].cVersandlandISO
LEFT OUTER JOIN @tLand AS tRechnungsland ON tRechnungsland.cISO = trechnungsadresse.cISO
LEFT OUTER JOIN @tLand AS tLieferland ON tLieferland.cISO = trechnungsadresse.cISO
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
		tLieferscheinPos.kBestellPos = tbestellpos.kBestellPos

	ORDER BY 
		tWarenLagerEingang.dErstellt ASC
) AS tWarenEingang
LEFT OUTER JOIN [eazybusiness].[dbo].[em_tSteuerEinstellung] AS Steuerdaten 
	ON Steuerdaten.cDB = 'eazybusiness'
	AND Steuerdaten.kFirma = tfirma.kFirma
	AND Steuerdaten.kSteuerklasse = tSteuerklasse.kSteuerklasse

ORDER BY 
	[@Gutschriften].dErstellt ASC;

-- Stornierte Rechnungen als Gutschriften holen


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

/* Einkaufspreis der St�cklistenkomponenten auf den Vater �bertragen (Differenzberechnung) */
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

/* St�cklisten-Kinder entfernen */
IF @nStuecklistenfilter = 1
BEGIN
	DELETE FROM @Temp WHERE kBestellStuckliste > 0 AND kBestellStuckliste != kBestellPos;
END

/* St�cklisten-V�ter entfernen */
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
	,kRechnungskorrektur AS SalesInvoiceCorrectionId
	,kKunde AS CustomerId
	,kFirma AS CompanyId
	,kArtikel AS ProductId
	,kBestellPos AS SakesOrderPositionId
	,cBestellNr AS SalesOrderNumber
	,cInetBestellNr AS ExternalSalesOrderNumber
	,cRechnungsNr AS SalesInvoiceNumber
	,cRechnungskorrekturNr AS SalesInvoiceCorrectionNumber
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
	,0 AS IsIGL
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
	,NULL AS SalesOrderDate
	,dErstelltRechnung AS SalesInvoiceDate
	,dGeliefertAm AS ShippedAt
	,dBezahlt AS PaydAt
	,NULL AS ShppingDate
	,0 AS IsReverseCharge
	,DiffTaxRate AS DiffTaxRate

FROM @Temp
WHERE (
		ISNULL(cRechnungsNr, '') LIKE '%' + @cSuchbegriff + '%' OR 
		cRechnungskorrekturNr LIKE '%' + @cSuchbegriff + '%' OR 
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
	kRechnungskorrektur,
	kKunde,
	kFirma,
	kArtikel,
	cBestellNr,
	cInetBestellNr,
	cRechnungsNr,
	cRechnungskorrekturNr,
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
	nType,
	kBestellPos,
	nSortiernummer,
	cArtNr,
	cName,	
	fGutschriftanteilProzent,
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
	dErstelltRechnung,
	dGeliefertAm,
	dBezahlt
	,DiffTaxRate

ORDER BY 
	dErstellt DESC,
	kBestellPos ASC;
