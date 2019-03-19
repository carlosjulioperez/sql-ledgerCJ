-- Swiss chart of accounts
-- adapted to numeric representation of chart no.
--
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('10000','AKTIVEN','H','1','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('11000','UMLAUFSVERMÖGEN','H','10000','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('11100','Flüssige Mittel','H','11000','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('11102','Bank CS Kt. 177929-11','A','11100','A','AR_paid:AP_paid');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('11110','Forderungen','H','11000','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('11120','Vorräte und angefangene Arbeiten','H','11000','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('11128','Angefangene Arbeiten','A','11120','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('11130','Aktive Rechnungsabgrenzung','A','11000','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('14000','ANLAGEVERMÖGEN','H','10000','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('18000','AKTIVIERTER AUFWAND UND AKTIVE BERICHTIGUNGSPOSTEN','H','10000','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('18182','Entwicklungsaufwand','A','18000','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('20000','PASSIVEN','H','2','L','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('21000','FREMDKAPITAL KURZFRISTIG','H','20000','L','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('21200','Kurzfristige Verbindlichkeiten aus Lieferungen und Leistungen','H','21000','L','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('21201','Lieferanten','A','21200','L','AP');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('21202','Personalaufwand','A','21200','L','AP');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('21203','Sozialversicherungen','A','21200','L','AP');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('21205','Leasing','A','21200','L','AP');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('21210','Kurzfristige Finanzverbindlichkeiten','H','21000','L','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('21220','Andere kurzfristige Verbindlichkeiten','H','21000','L','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('21222','MWST (3,6)','A','21220','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('21229','Gewinnausschüttung','A','21220','L','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('21230','Passive Rechnungsabgrenzung, kurzfristige Rückstellungen','H','21000','L','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('21235','Rückstellungen','A','21230','L','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('24000','FREMDKAPITAL LANGFRISTIG','H','20000','L','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('24256','Gesellschafter','A','24000','L','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('28000','EIGENKAPITAL','H','20000','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('28280','Stammkapital','A','28000','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('28290','Reserven, Bilanzgewinn','H','28000','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('28291','Reserven','A','28290','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('28295','Gewinnvortrag','A','28290','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('28296','Jahresgewinn','A','28290','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('30000','BETRIEBSERTRAG AUS LIEFERUNGEN UND LEISTUNGEN','H','30000','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('31000','PRODUKTIONSERTRAG','H','30000','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('31001','Computer','A','31000','I','AR_amount:IC_sale');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('31005','Übrige Produkte','A','31000','I','AR_amount:IC_sale');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('32000','HANDELSERTRAG','H','30000','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('32001','Hardware','A','32000','I','AR_amount:IC_sale');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('32002','Software OSS','A','32000','I','AR_amount:IC_sale');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('32003','Software kommerz.','A','32000','I','AR_amount:IC_sale');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('32005','Übrige','A','32000','I','AR_amount:IC_sale');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('34000','DIENSTLEISTUNGSERTRAG','H','30000','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('34001','Beratung','A','34000','I','AR_amount:IC_income');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('34002','Installation','A','34000','I','AR_amount:IC_income');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('36000','ÜBRIGER ERTRAG','H','30000','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('37000','EIGENLEISTUNGEN UND EIGENVERBRAUCH','H','30000','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('37001','Eigenleistungen','A','37000','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('37002','Eigenverbrauch','A','37000','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('38000','BESTANDESÄNDERUNGEN ANGEFANGENE UND FERTIGGESTELLTE ARBEITUNG AUS PRODUKTION UND DIENSTLEISTUNG','H','30000','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('38001','Bestandesänderungen','A','38000','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('39000','ERTRAGSMINDERUNGEN AUS PRODUKTIONS-, HANDELS- UND DIENSTLEISTUNGSERTRÄGEN','H','30000','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('40000','AUFWAND FÜR MATERIAL, WAREN UND DIENSTLEISTUNGEN','H','40000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('41000','MATERIALAUFWAND','H','40000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('41001','Computer','A','41000','E','AP_amount:IC_cogs');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('41005','Übrige Produkte','A','41000','E','AP_amount:IC_cogs');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('42000','HANDELSWARENAUFWAND','H','40000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('42001','Hardware','A','42000','E','AP_amount:IC_cogs');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('42002','Software OSS','A','32000','I','AP_amount:IC_cogs');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('42003','Software kommerz.','A','42000','I','AP_amount:IC_cogs');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('42005','Übrige','A','42000','E','AP_amount:IC_cogs');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('44000','AUFWAND FÜR DRITTLEISTUNGEN','H','40000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('46000','ÜBRIGER AUFWAND','H','40000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('47000','DIREKTE EINKAUFSSPESEN','H','40000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('47001','Einkaufsspesen','A','47000','E','AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('48000','BESTANDESVERÄNDERUNGEN, MATERIAL- UND WARENVERLUSTE','H','40000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('48001','Bestandesänderungen','A','48000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('49000','AUFWANDMINDERUNGEN','H','40000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('49005','Aufwandminderungen','A','49000','E','AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('50000','PERSONALAUFWAND','H','50000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('57000','SOZIALVERSICHERUNGSAUFWAND','H','50000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('58000','ÜBRIGER PERSONALAUFWAND','H','58000','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('58005','Sonstiger Personalaufwand','A','58000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('59000','ARBEITSLEISTUNGEN DRITTER','H','50000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('60000','SONSTIGER BETRIEBSAUFWAND','H','60000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('61000','RAUMAUFWAND','H','60000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('61900','UNTERHALT, REPARATUREN, ERSATZ, LEASINGAUFWAND MOBILE SACHANLAGEN','H','60000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('61901','Unterhalt','A','61900','E','AP_amount');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('62000','FAHRZEUG- UND TRANSPORTAUFWAND','H','60000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('62002','Transportaufwand','A','62000','E','AP_amount');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('63000','SACHVERSICHERUNGEN, ABGABEN, GEBÜHREN, BEWILLIGUNGEN','H','60000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('65000','VERWALTUNGS- UND INFORMATIKAUFWAND','H','60000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('66000','WERBEAUFWAND','H','60000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('67000','ÜBRIGER BETRIEBSAUFWAND','H','60000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('67001','Übriger Betriebsaufwand','A','67000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('68000','FINANZERFOLG','H','60000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('68001','Finanzaufwand','A','68000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('68002','Bankspesen','A','68000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('68005','Finanzertrag','A','68000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('69000','ABSCHREIBUNGEN','H','60000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('69001','Abschreibungen','A','69000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('80000','AUSSERORDENTLICHER UND BETRIEBSFREMDER ERFOLG, STEUERN','H','80000','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('80001','Ausserordentlicher Ertrag','A','80000','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('80002','Ausserordentlicher Aufwand','A','80000','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('89000','STEUERAUFWAND','H','80000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('89001','Steuern','A','80000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('90000','ABSCHLUSS','H','90000','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('91000','ERFOLGSRECHNUNG','H','91000','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('92000','BILANZ','H','92000','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('93000','GEWINNVERWENDUNG','H','93000','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('99000','SAMMEL- UND FEHLBUCHUNGEN','H','99000','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('11121','Warenvorräte','A','11120','A','IC');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('44001','Aufwand für Drittleistungen','A','44000','E','AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('63001','Betriebsversicherungen','A','63000','E','AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('57004','Unfallversicherung','A','57000','E','AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('57005','Krankentaggeldversicherung','A','57000','E','AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('57003','Berufliche Vorsorge','A','57000','E','AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('57002','FAK','A','57000','E','AP_amount:IC_income:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('65009','Übriger Verwaltungsaufwand','A','65000','E','AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('65003','Porti','A','65000','E','AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('65002','Telekomm','A','65000','E','AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('65001','Büromaterial','A','65000','E','AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('18181','Gründungsaufwand','A','18000','A','IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('50001','Löhne und Gehälter','A','50000','E','IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('50002','Erfolgsbeteiligungen','A','50000','E','IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('21216','Gesellschafter','A','21210','L','AP');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('62001','Fahrzeugaufwand','A','62000','E','AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('58003','Spesen','A','58000','E','IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('65004','Fachliteratur','A','65000','E','AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('39001','Skonti','A','39000','I','IC_sale:IC_cogs:IC_income:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('39002','Rabatte, Preisnachlässe','A','39000','I','IC_sale:IC_cogs:IC_income:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('36005','Kursgewinn','A','39000','I','IC_sale:IC_cogs:IC_income');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('39006','Kursverlust','A','39000','E','IC_sale:IC_cogs:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('39005','Verluste aus Forderungen','A','39000','E','IC_sale:IC_cogs:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('14151','Mobiliar und Einrichtungen','A','14150','A','IC');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('14152','Büromaschinen, EDV','A','14150','A','IC');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('11119','Verrechnungssteuer','A','11110','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('11118','MWST Vorsteuer auf Investitionen','A','11110','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('36004','Versand','A','36000','I','IC_income');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('36001','Reisezeit','A','36000','I','IC_income');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('36002','Reise (Fahrt)','A','36000','I','IC_income');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('11117','MWST Vorsteuer auf Aufwand','A','11110','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('21228','Geschuldete Steuern','A','21220','L','AP');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('21223','MWST (7,6)','A','21220','L','AR_tax:AP_tax:IC_taxpart:IC_expense:IC_taxservice');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('57001','AHV, IV, EO, ALV','A','57000','E','AP_amount:IC_income:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('21221','MWST (2,4)','A','21220','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('21224','MWST (7.6) 1/2','A','21220','L','AR_tax:AP_tax:IC_taxpart:IC_expense:IC_taxservice');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('66001','Werbeaufwand','A','66000','E','AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('21217','Privat','A','21210','L','AP');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('11101','Kasse','A','11100','A','AR_paid:AP_paid');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('50005','Leistungen von Sozialversicherung','A','50000','E','AP_amount:IC_income:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('65005','Informatikaufwand','A','65000','E','AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('39004','Rundungsdifferenzen','A','39000','I','AR_paid:AP_paid');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('11111','Debitoren','A','11110','A','AR');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('61001','Miete','A','61000','E','IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('61002','Reinigung','A','61000','E','IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('61005','Übriger Raumaufwand','A','61000','E','IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('36003','Essen','A','36000','I','IC_income');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('21231','Passive Rechnungsabgrenzung','A','21230','L','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('67002','Produkteentwicklung','A','67000','E','');
--
insert into tax (chart_id,rate) values ((select id from chart where accno = '21222'),0.036);
insert into tax (chart_id,rate) values ((select id from chart where accno = '21223'),0.076);
insert into tax (chart_id,rate) values ((select id from chart where accno = '21221'),0.024);
insert into tax (chart_id,rate) values ((select id from chart where accno = '21224'),0.076);
--
INSERT INTO defaults (fldname, fldvalue) VALUES ('inventory_accno_id', (SELECT id FROM chart WHERE accno = '11121'));
INSERT INTO defaults (fldname, fldvalue) VALUES ('income_accno_id', (SELECT id FROM chart WHERE accno = '34002'));
INSERT INTO defaults (fldname, fldvalue) VALUES ('expense_accno_id', (SELECT id FROM chart WHERE accno = '42005'));
INSERT INTO defaults (fldname, fldvalue) VALUES ('fxgain_accno_id', (SELECT id FROM chart WHERE accno = '36005'));
INSERT INTO defaults (fldname, fldvalue) VALUES ('fxloss_accno_id', (SELECT id FROM chart WHERE accno = '39006'));
INSERT INTO defaults (fldname, fldvalue) VALUES ('weightunit', 'kg');
INSERT INTO defaults (fldname, fldvalue) VALUES ('precision', '2');
--
INSERT INTO curr (rn, curr, precision) VALUES (1,'CHF',2);
INSERT INTO curr (rn, curr, precision) VALUES (2,'EUR',2);
INSERT INTO curr (rn, curr, precision) VALUES (3,'USD',2);

