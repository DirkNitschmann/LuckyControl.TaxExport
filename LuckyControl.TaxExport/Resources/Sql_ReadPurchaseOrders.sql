/*
EM TaxExport
Copyright (c) Evolution Media, www.evolution-media.de
Alle Rechte vorbehalten
*/
DECLARE @nBuchungskontoVersandkostenPositionAusMasse INT = #nBuchungskontoVersandkostenPositionAusMasse#;
DECLARE @nPosition INT = #nPosition#;
DECLARE @kFirma INT = #kFirma#;
DECLARE @kLieferant INT = #kLieferant#;
DECLARE @kSuchvorlage INT = #kSuchvorlage#;
DECLARE @cSuchvorlage NVARCHAR(MAX) = N'';

DECLARE @SQL_CreateTemp NVARCHAR(MAX) = N'
DECLARE @Temp TABLE(
	kLieferantenBestellung INT NOT NULL,
	kLieferant INT NOT NULL,	
	kFirma INT NOT NULL,	
	kArtikel INT NOT NULL,	
	cLieferantennummer VARCHAR(100) NOT NULL,
	cEigeneBestellnummer VARCHAR(100) NOT NULL,
	cBezugsauftragsnummer VARCHAR(100) NOT NULL,
	cFremdbelegsnummer VARCHAR(100) NOT NULL,
	cBuchungskonto VARCHAR(20) NULL,
	cWaehrung VARCHAR(10) NOT NULL,			
	fMwSt FLOAT NOT NULL,
	nDifferenzBesteuerung INT NOT NULL,		
	nType INT NOT NULL,
	cArtNr VARCHAR(50) NOT NULL,
	cName VARCHAR(255) NOT NULL,
	nAnzahl FLOAT NOT NULL,
	fEKNettoEinzel FLOAT NOT NULL,
	fEKNettoGesamt FLOAT NOT NULL,
	fVKNettoEinzel FLOAT NOT NULL,
	fVKNettoGesamt FLOAT NOT NULL,
	tFirma_cName VARCHAR(100) NOT NULL,
	tFirma_cUnternehmer VARCHAR(255) NOT NULL,
	tfirma_cStrasse VARCHAR(255) NOT NULL,
	tfirma_cPLZ VARCHAR(100) NOT NULL,
	tfirma_cOrt VARCHAR(100) NOT NULL,
	tfirma_cLand VARCHAR(100) NOT NULL,
	tfirma_cWWW VARCHAR(100) NOT NULL,
	tfirma_cEMail VARCHAR(100) NOT NULL,
	tfirma_cBank VARCHAR(100) NOT NULL,
	tfirma_cKontoNr VARCHAR(100) NOT NULL,
	tfirma_cBLZ VARCHAR(100) NOT NULL,
	tfirma_cIBAN VARCHAR(100) NOT NULL,
	tfirma_cBIC VARCHAR(100) NOT NULL,
	tfirma_cSteuerNr VARCHAR(100) NOT NULL,
	tfirma_cGlaeubigerID VARCHAR(100) NOT NULL,
	cRE_Anrede VARCHAR(100) NOT NULL,
	cRE_Firma VARCHAR(100) NOT NULL,
	cRE_Vorname VARCHAR(100) NOT NULL,
	cRE_Nachname VARCHAR(100) NOT NULL,
	cRE_Strasse VARCHAR(100) NOT NULL,
	cRE_PLZ VARCHAR(100) NOT NULL,
	cRE_Ort VARCHAR(100) NOT NULL,
	cRE_Bundesland VARCHAR(100) NOT NULL,
	cRE_Land VARCHAR(100) NOT NULL,
	cRE_Telefon VARCHAR(100) NOT NULL,
	cRE_Telefax VARCHAR(100) NOT NULL,
	cRE_Mobil VARCHAR(100) NOT NULL,
	cRE_Mail VARCHAR(100) NOT NULL,
	cLA_Anrede VARCHAR(100) NOT NULL,
	cLA_Firma VARCHAR(100) NOT NULL,
	cLA_Vorname VARCHAR(100) NOT NULL,
	cLA_Nachname VARCHAR(100) NOT NULL,
	cLA_Strasse VARCHAR(100) NOT NULL,
	cLA_PLZ VARCHAR(100) NOT NULL,
	cLA_Ort VARCHAR(100) NOT NULL,
	cLA_Bundesland VARCHAR(100) NOT NULL,
	cLA_Land VARCHAR(100) NOT NULL,
	cLA_Telefon VARCHAR(100) NOT NULL,
	cLA_Telefax VARCHAR(100) NOT NULL,
	cLA_Mobil VARCHAR(100) NOT NULL,
	cLA_Mail VARCHAR(100) NOT NULL,
	tLieferant_cFirma VARCHAR(255) NOT NULL,
	tLieferant_cFirmenZusatz VARCHAR(255) NOT NULL,
	tLieferant_cAnrede VARCHAR(255) NOT NULL,
	tLieferant_cVorname VARCHAR(255) NOT NULL,
	tLieferant_cNachname VARCHAR(255) NOT NULL,
	tLieferant_cStrasse VARCHAR(255) NOT NULL,
	tLieferant_cPLZ VARCHAR(20) NOT NULL,
	tLieferant_cOrt VARCHAR(255) NOT NULL,
	tLieferant_cLand VARCHAR(255) NOT NULL,
	tLieferant_cBundesland VARCHAR(100) NOT NULL,
	tLieferant_cTelefon VARCHAR(100) NOT NULL,
	tLieferant_cTelefax VARCHAR(100) NOT NULL,
	tLieferant_cEMail VARCHAR(100) NOT NULL,
	tLieferant_cHomepage VARCHAR(100) NOT NULL,
	tLieferant_cUmsatzsteuerID VARCHAR(40) NOT NULL,	
	dErstellt DATETIME NOT NULL
);';
DECLARE @SQL_InsertTemp NVARCHAR(MAX) = N'
INSERT INTO @Temp
SELECT
	tLieferantenBestellung.kLieferantenBestellung,
	tLieferantenBestellung.kLieferant,
	tLieferantenBestellung.kFirma,	
	tLieferantenBestellungPos.kArtikel,
	ISNULL(tlieferant.cLiefNr, ''''),
	ISNULL(tLieferantenBestellung.cEigeneBestellnummer, ''''),
	ISNULL(tLieferantenBestellung.cBezugsauftragsnummer, ''''),
	ISNULL(tLieferantenBestellung.cFremdbelegnummer, ''''),

	ISNULL(( 
		SELECT 
			TOP(1) tSteuerschluessel.cSteuerkonto 

		FROM #cDB#.[dbo].[tSteuersatz] 
		JOIN #cDB#.[dbo].[tSteuerzoneLand] ON tSteuerzoneLand.kSteuerzone = tSteuersatz.kSteuerzone 
		JOIN #cDB#.[dbo].[tSteuerschluessel] ON tSteuerschluessel.kSteuerschluessel = 
			CASE 
			/* Wenn Differenzbesteuerung und Eingestellter Steuerschl�ssel */
			WHEN tSteuerklasse.kSteuerklasse = Steuerdaten.kSteuerklasse AND Steuerdaten.kSteuerschlussel > 0 
			THEN Steuerdaten.kSteuerschlussel 
			/* Steuerschl�ssel anhand von Steuereinstellungen lesen */
			ELSE 
				CASE 
				/* IGL ohne Umsatzsteuer-ID */
				WHEN tland.nEU = 1 AND ISNULL(tlieferant.cUstId, '''') = '''' AND tlieferant.cISO != tlandFirma.cISO THEN tSteuersatz.kStSchlUStIGL 
				/* IGL mit Umsatzsteuer-ID */
				WHEN tland.nEU = 1 AND ISNULL(tlieferant.cUstId, '''') != '''' AND tlieferant.cISO != tlandFirma.cISO THEN tSteuersatz.kStSchlIGL 
				/* Inlands-Lieferung */
				ELSE tSteuersatz.kStSchl END 
			END 
		WHERE tSteuersatz.kSteuerklasse = tSteuerklasse.kSteuerklasse 
		AND tSteuerzoneLand.cISO = tlieferant.cISO 
	), 
		/* Unbekanntes Buchungskonto */
		''-'' 
	) 
	AS cBuchungskonto, 

	ISNULL(tLieferantenBestellung.cWaehrungISO, ''''),
	ISNULL(tLieferantenBestellungPos.fUST, 0),
	CASE WHEN tSteuerklasse.kSteuerklasse = Steuerdaten.kSteuerklasse THEN 1 ELSE 0 END,
	ISNULL(tLieferantenBestellungPos.nPosTyp, 0),
	ISNULL(tLieferantenBestellungPos.cArtNr, ''''),
	ISNULL(tLieferantenBestellungPos.cName, ''''),
	ISNULL(tLieferantenBestellungPos.fMenge, 0),
	ISNULL(tLieferantenBestellungPos.fEKNetto, 0),
	(tLieferantenBestellungPos.fEKNetto *tLieferantenBestellungPos.fMenge),
	ISNULL(tArtikel.fVKNetto, 0),
	(ISNULL(tArtikel.fVKNetto, 0) *tLieferantenBestellungPos.fMenge),
	ISNULL(tfirma.cName, ''''),
	ISNULL(tfirma.cUnternehmer, ''''),
	ISNULL(tfirma.cStrasse, ''''),
	ISNULL(tfirma.cPLZ, ''''),
	ISNULL(tfirma.cOrt, ''''),
	ISNULL(tfirma.cLand, ''''),
	ISNULL(tfirma.cWWW, ''''),
	ISNULL(tfirma.cEMail, ''''),
	ISNULL(tfirma.cBank, ''''),
	ISNULL(tfirma.cKontoNr, ''''),
	ISNULL(tfirma.cBLZ, ''''),
	ISNULL(tfirma.cIBAN, ''''),
	ISNULL(tfirma.cBIC, ''''),
	ISNULL(tfirma.cSteuerNr, ''''),
	ISNULL(tfirma.cGlaeubigerID, ''''),
	ISNULL(tLieferantenBestellungRA.cAnrede, ''''),
	ISNULL(tLieferantenBestellungRA.cFirma, ''''),
	ISNULL(tLieferantenBestellungRA.cVorname, ''''),
	ISNULL(tLieferantenBestellungRA.cNachname, ''''),
	ISNULL(tLieferantenBestellungRA.cStrasse, ''''),
	ISNULL(tLieferantenBestellungRA.cPLZ, ''''),
	ISNULL(tLieferantenBestellungRA.cOrt, ''''),
	ISNULL(tLieferantenBestellungRA.cBundesland, ''''),
	ISNULL(tLandRA.cName, ''''),
	ISNULL(tLieferantenBestellungRA.cTel, ''''),
	ISNULL(tLieferantenBestellungRA.cFax, ''''),
	ISNULL(tLieferantenBestellungRA.cMobil, ''''),
	ISNULL(tLieferantenBestellungRA.cMail, ''''),
	ISNULL(tLieferantenBestellungLA.cAnrede, ''''),
	ISNULL(tLieferantenBestellungLA.cFirma, ''''),
	ISNULL(tLieferantenBestellungLA.cVorname, ''''),
	ISNULL(tLieferantenBestellungLA.cNachname, ''''),
	ISNULL(tLieferantenBestellungLA.cStrasse, ''''),
	ISNULL(tLieferantenBestellungLA.cPLZ, ''''),
	ISNULL(tLieferantenBestellungLA.cOrt, ''''),
	ISNULL(tLieferantenBestellungLA.cBundesland, ''''),
	ISNULL(tLandLA.cName, ''''),
	ISNULL(tLieferantenBestellungLA.cTel, ''''),
	ISNULL(tLieferantenBestellungLA.cFax, ''''),
	ISNULL(tLieferantenBestellungLA.cMobil, ''''),
	ISNULL(tLieferantenBestellungLA.cMail, ''''),
	ISNULL(tlieferant.cFirma, ''''),
	ISNULL(tLieferant.cFirmenZusatz, ''''),
	ISNULL(tLieferant.cAnrede, ''''),
	ISNULL(tLieferant.cVorname, ''''),
	ISNULL(tLieferant.cNachname, ''''),
	ISNULL(tLieferant.cStrasse, ''''),
	ISNULL(tLieferant.cPLZ, ''''),
	ISNULL(tLieferant.cOrt, ''''),
	ISNULL(tLieferant.cLand, ''''),
	ISNULL(tLieferant.cBundesland, ''''),
	ISNULL(tLieferant.cTelDurchwahl, ''''),
	ISNULL(tLieferant.cFax, ''''),
	ISNULL(tLieferant.cEMail, ''''),
	ISNULL(tLieferant.cWWW, ''''),
	ISNULL(tLieferant.cUstid, ''''),
	tLieferantenBestellung.dErstellt

FROM #cDB#.[dbo].[tLieferantenBestellung]
JOIN #cDB#.[dbo].[tLieferantenBestellungRA] ON tLieferantenBestellungRA.kLieferantenBestellungRA = tLieferantenBestellung.kLieferantenBestellungRA
JOIN #cDB#.[dbo].[tLieferantenBestellungLA] ON tLieferantenBestellungLA.kLieferantenBestellungLA = tLieferantenBestellung.kLieferantenBestellungLA
JOIN #cDB#.[dbo].[tland] AS tLandRA ON tLandRA.cISO = tLieferantenBestellungRA.cLandISO
JOIN #cDB#.[dbo].[tland] AS tLandLA ON tLandLA.cISO = tLieferantenBestellungLA.cLandISO
JOIN #cDB#.[dbo].[tLieferantenBestellungPos] ON tLieferantenBestellungPos.kLieferantenBestellung = tLieferantenBestellung.kLieferantenBestellung
LEFT OUTER JOIN #cDB#.[dbo].[tlieferant] ON tlieferant.kLieferant = tLieferantenBestellung.kLieferant
LEFT OUTER JOIN #cDB#.[dbo].[tArtikel] ON tArtikel.kArtikel = tLieferantenBestellungPos.kArtikel
LEFT OUTER JOIN #cDB#.[dbo].[tSteuerklasse] ON tSteuerklasse.kSteuerklasse = tArtikel.kSteuerklasse
LEFT OUTER JOIN #cDB#.[dbo].[tfirma] ON tfirma.kFirma = tLieferantenBestellung.kFirma
LEFT OUTER JOIN #cDB#.[dbo].[tland] on tland.cName = tfirma.cLand
LEFT OUTER JOIN #cDB#.[dbo].[tland] AS tlandFirma ON tlandFirma.cName = tfirma.cLand

LEFT OUTER JOIN [eazybusiness].[dbo].[em_tSteuerEinstellung] AS Steuerdaten
	ON Steuerdaten.cDB = ''#cDBraw#''
	AND Steuerdaten.kFirma = tfirma.kFirma

WHERE CONVERT(DATE, tLieferantenBestellung.dErstellt) >= CONVERT(DATE, @dDatumStart)
AND CONVERT(DATE, tLieferantenBestellung.dErstellt) <= CONVERT(DATE, @dDatumEnde)';
DECLARE @SQL_UpdateTemp NVARCHAR(MAX) = N'';
DECLARE @SQL_SelectTemp NVARCHAR(MAX) = N'
SELECT
	 ''PurchaseOrder'' AS Type
	,kLieferantenBestellung AS PurchaseOrderId
	,kLieferant AS SupplierId
	,kFirma AS CompanyId
	,kArtikel AS ProductId
	,cLieferantennummer AS SupplierNumber
	,cEigeneBestellnummer AS PurchaseOrderNumber
	,cBezugsauftragsnummer AS PurchaseReferenceOrderNumber
	,cFremdbelegsnummer AS PurchaseExternalDocumentNumber
	,cBuchungskonto AS BookingAccount
	,cWaehrung AS Currency
	,fMwSt AS VatRate
	,nDifferenzBesteuerung AS DifferentialTaxationMode
	,CASE WHEN nDifferenzBesteuerung > 0 THEN 1 ELSE 0 END AS IsDifferencialTaxation
	,nType AS PositionTypeId
	,cArtNr AS Sku
	,cName AS Name
	,nAnzahl AS Quantity
	,fEKNettoEinzel AS NetPurchasingPrice
	,fEKNettoGesamt AS TotalNetPurchasingPrice
	,fVKNettoEinzel AS NetPrice
	,fVKNettoGesamt AS TotalNetPrice
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
	,cLA_Telefon AS ShippingAddressPhone
	,cLA_Telefax AS ShippingAddressFax
	,cLA_Mobil AS ShippingAddressMobile
	,cLA_Mail AS ShippingAddressEmail
	,tLieferant_cFirma AS SupplierCompanyName
	,tLieferant_cFirmenZusatz AS SupplierCompanyNameAddition
	,tLieferant_cAnrede AS SupplierSalutation
	,tLieferant_cVorname AS SupplierFirstName
	,tLieferant_cNachname AS SupplierLastName
	,tLieferant_cStrasse AS SupplierStreet
	,tLieferant_cPLZ AS SupplierPostalCode
	,tLieferant_cOrt AS SupplierCity
	,tLieferant_cBundesland AS SupplierFederalState
	,tLieferant_cLand AS SupplierCountry
	,tLieferant_cTelefon AS SupplierPhone
	,tLieferant_cTelefax AS SupplierFax
	,tLieferant_cEMail AS SupplierEmail
	,tLieferant_cHomepage AS SupplierHomepage
	,tLieferant_cUmsatzsteuerID AS SupplierVatIdNumber
	,dErstellt AS CreatedAt
FROM @Temp
WHERE
	(
		cEigeneBestellnummer LIKE ''%'' + @cSuchbegriff + ''%'' OR
		cArtNr LIKE ''%'' + @cSuchbegriff + ''%'' OR
		cName LIKE ''%'' + @cSuchbegriff + ''%''
	)

	*cSuchvorlage*
	*nPosition*
	*kFirma*
	*kLieferant*

ORDER BY
	dErstellt DESC,
	cBuchungskonto ASC,
	cArtNr ASC';

BEGIN
	SET @SQL_UpdateTemp = 
	CASE WHEN @nBuchungskontoVersandkostenPositionAusMasse > 0
	THEN 
	'UPDATE @Temp SET cBuchungskonto = (
		Select TOP(1) A.cBuchungskonto from @Temp A WHERE A.kLieferantenBestellung = [@Temp].kLieferantenBestellung AND A.nType <> 2 GROUP BY A.cBuchungskonto ORDER BY count((A.cBuchungskonto)) DESC, SUM(A.fVKNettoGesamt) DESC
    )'
	ELSE '' END
	
	SET @SQL_SelectTemp = REPLACE(
		@SQL_SelectTemp,
		'*nPosition*',
		CASE @nPosition
		WHEN 0 THEN ''
		WHEN 1 THEN 'AND nDifferenzBesteuerung = 1'
		WHEN 2 THEN 'AND nDifferenzBesteuerung = 0'
		ELSE '' END
	)

	SET @SQL_SelectTemp = REPLACE(
		@SQL_SelectTemp, 
		'*kFirma*', 
		CASE WHEN @kFirma > 0
		THEN CONCAT('AND kFirma = ', @kFirma)
		ELSE '' END
	)

	SET @SQL_SelectTemp = REPLACE(
		@SQL_SelectTemp, 
		'*kLieferant*', 
		CASE WHEN @kLieferant > 0
		THEN CONCAT('AND kLieferant = ', @kLieferant)
		ELSE '' END
	)

	IF @kSuchvorlage > 0	 
	(
		SELECT @cSuchvorlage = @cSuchvorlage + cSQL + ' ' FROM #cDB#.[dbo].[em_tSuchvorlageWert] WHERE kSuchvorlage = @kSuchvorlage
	)
	
	SET @SQL_SelectTemp = REPLACE(
		@SQL_SelectTemp, 
		'*cSuchvorlage*', 
		@cSuchvorlage
	)
END

DECLARE @SQL NVARCHAR(MAX) = 
	@SQL_CreateTemp + 
	@SQL_InsertTemp +
	@SQL_UpdateTemp +
	@SQL_SelectTemp;

EXEC sp_executesql 
@statement = @SQL,
@parameters = N'
@dDatumStart VARCHAR(40),
@dDatumEnde VARCHAR(40),
@cSuchbegriff VARCHAR(100)',

@dDatumStart = N'#dDatumStart#',
@dDatumEnde = N'#dDatumEnde#',
@cSuchbegriff = '#cSuchbegriff#';