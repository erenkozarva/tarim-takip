-- =============================================
-- Tarım Takip Sistemi - Örnek Veriler
-- PostgreSQL
-- =============================================

-- ---------------------------------------------
-- İller
-- ---------------------------------------------
INSERT INTO iller (plaka_kodu, il_adi) VALUES
(1,  'Adana'),
(6,  'Ankara'),
(7,  'Antalya'),
(16, 'Bursa'),
(34, 'İstanbul'),
(35, 'İzmir'),
(38, 'Kayseri'),
(42, 'Konya'),
(47, 'Mardin'),
(55, 'Samsun');

-- ---------------------------------------------
-- Çiftçiler (13 kişi)
-- ---------------------------------------------
INSERT INTO ciftciler (tc_no, ad, soyad, tel_no, dogum_tar) VALUES
('12345678901', 'Ahmet',    'Yılmaz',   '05321112233', '1975-03-10'),
('22345678902', 'Mehmet',   'Kaya',     '05332223344', '1980-07-22'),
('32345678903', 'Fatma',    'Demir',    '05423334455', '1985-08-20'),
('42345678904', 'Hüseyin',  'Çelik',    '05444445566', '1968-11-05'),
('52345678905', 'Ayşe',     'Arslan',   '05555556677', '1990-01-30'),
('62345678906', 'Mustafa',  'Şahin',    '05336667788', '1972-07-14'),
('72345678907', 'Zeynep',   'Koç',      '05357778899', '1995-09-25'),
('82345678908', 'İbrahim',  'Doğan',    '05418889900', '1965-12-12'),
('92345678909', 'Hatice',   'Aydın',    '05519990011', '1988-04-18'),
('10345678910', 'Ramazan',  'Güneş',    '05360001122', '1978-06-22'),
('11345678911', 'Serdar',   'Keskin',   '05421113344', '1992-02-14'),
('12345678912', 'Emine',    'Polat',    '05332224455', '1983-09-09'),
('13345678913', 'Kemal',    'Arslan',   '05553335566', '1970-12-01');

-- ---------------------------------------------
-- Ürünler
-- ---------------------------------------------
INSERT INTO urunler (urun_adi, tur, birim) VALUES
('Buğday',          'tahıl',     'ton'),
('Arpa',            'tahıl',     'ton'),
('Mısır',           'tahıl',     'ton'),
('Çavdar',          'tahıl',     'ton'),
('Ayçiçeği',        'bitki',     'ton'),
('Kolza',           'bitki',     'ton'),
('Pamuk',           'bitki',     'balya'),
('Domates',         'sebze',     'kasa'),
('Biber',           'sebze',     'kasa'),
('Patlıcan',        'sebze',     'kasa'),
('Soğan',           'sebze',     'çuval'),
('Sarımsak',        'sebze',     'çuval'),
('Elma',            'meyve',     'kasa'),
('Kiraz',           'meyve',     'kasa'),
('Üzüm',            'meyve',     'ton'),
('Nohut',           'baklagil',  'ton'),
('Mercimek',        'baklagil',  'ton'),
('Şeker Pancarı',   'bitki',     'ton');

-- ---------------------------------------------
-- Tarlalar (15 tarla)
-- ---------------------------------------------
INSERT INTO tarlalar (ciftci_id, plaka_kodu, ilce, ada_no, parsel_no, dekar) VALUES
(1,  42, 'Karatay',           '101', '5',  50),
(1,  42, 'Selçuklu',          '102', '8',  30),
(1,  42, 'Çumra',             '103', '3',  70),
(2,  6,  'Polatlı',           '205', '12', 120),
(2,  6,  'Sincan',            '206', '4',  45),
(3,  7,  'Aksu',              '301', '7',  35),
(3,  7,  'Kepez',             '302', '2',  90),
(4,  16, 'İnegöl',            '405', '9',  85),
(4,  16, 'Mustafakemalpaşa',  '406', '6',  60),
(5,  1,  'Seyhan',            '500', '1',  75),
(6,  6,  'Haymana',           '601', '22', 100),
(7,  35, 'Ödemiş',            '702', '4',  20),
(8,  55, 'Bafra',             '808', '7',  45),
(9,  47, 'Kızıltepe',         '901', '10', 55),
(10, 42, 'Ereğli',            '1001','6',  110);

-- ---------------------------------------------
-- Tarım Stok
-- ---------------------------------------------
INSERT INTO tarim_stok (malzeme_adi, tur, stok_adet, birim_fiyat) VALUES
('Hayvan Gübresi',      'gubre',    5000, 15),
('Bitki Gübresi',       'gubre',    3000, 18),
('DAP Gübresi',         'gubre',    2000, 45),
('NPK 15-15-15',        'gubre',    1500, 52),
('Bitki İlacı',         'ilac',      200, 450),
('Böcek İlacı',         'ilac',      150, 600),
('Mantar İlacı',        'ilac',      180, 520),
('Herbisit',            'ilac',      120, 480),
('Buğday Tohumu',       'tohum',    2000, 35),
('Mısır Tohumu',        'tohum',    1000, 55),
('Ayçiçeği Tohumu',     'tohum',     800, 48),
('Mazot',               'yakit',    5000, 42),
('Sulama Hortumu',      'ekipman',   500, 3),
('Hayvan Yemi',         'yem',     10000, 5);

-- ---------------------------------------------
-- Ekim / Hasat
-- ---------------------------------------------
INSERT INTO ekim_hasat (tarla_id, urun_id, ekim_tar, tahmini_hasat, gercek_hasat, hasat_miktari, durum, notlar) VALUES
(1,  1,  '2024-10-15', '2025-06-15', '2025-06-18', 18500, 'hasat edildi',    'Kış buğdayı, sertifikalı tohum'),
(2,  15, '2024-03-20', '2024-09-15', '2024-09-10',  5200, 'hasat edildi',    'Bağ budaması yapıldı'),
(3,  2,  '2024-10-20', '2025-06-10', NULL,           NULL, 'hasat bekleniyor','Kışlık arpa ekimi'),
(4,  3,  '2024-04-10', '2024-09-15', '2024-09-12', 22000, 'hasat edildi',    'Hibrit mısır tohumu'),
(5,  5,  '2024-04-25', '2024-09-20', '2024-09-18',  9800, 'hasat edildi',    'Ayçiçeği geniş alana ekildi'),
(6,  8,  '2024-02-05', '2024-06-10', '2024-06-05',  3800, 'hasat edildi',    'Sera içi domates'),
(7,  9,  '2024-03-01', '2024-07-15', '2024-07-10',  5600, 'hasat edildi',    'Sivri biber ihracat kalitesi'),
(8,  13, '2024-03-15', '2024-08-20', '2024-08-22',  4100, 'hasat edildi',    'Elma bahçesi 5 yaşında fidanlar'),
(9,  14, '2024-03-10', '2024-06-25', '2024-06-28',  9800, 'hasat edildi',    'Kiraz erkenci çeşit'),
(10, 6,  '2024-04-05', '2024-09-01', '2024-08-30', 11500, 'hasat edildi',    'Kolza ekimi ilk yıl'),
(11, 1,  '2024-10-18', '2025-06-15', NULL,           NULL, 'hasat bekleniyor','Buğday kuraklığa dayanıklı çeşit'),
(12, 15, '2024-04-01', '2024-10-01', '2024-10-05',  6300, 'hasat edildi',    'Üzüm sofralık çeşit'),
(13, 11, '2024-03-25', '2024-07-20', '2024-07-18',  8700, 'hasat edildi',    'Yazlık soğan'),
(14, 12, '2024-10-01', '2025-06-01', NULL,           NULL, 'ekildi',          'Sarımsak kışlık'),
(15, 17, '2024-11-01', '2025-06-01', NULL,           NULL, 'ekildi',          'Kışlık kırmızı mercimek');

-- ---------------------------------------------
-- Bakım İşlemleri
-- ---------------------------------------------
INSERT INTO bakim_islemleri (ekim_islem_id, stok_id, miktar, aciklama) VALUES
(1,  3,   150, 'Ekim sonrası DAP taban gübre uygulandı'),
(1,  12,  200, 'Mazot ile toprak sürüldü'),
(2,  2,    50, 'Bağa bitki gübresi verildi'),
(3,  3,   120, 'Arpa ekimi sonrası gübre uygulandı'),
(4,  10,  300, 'Mısır için özel tohum kullanıldı'),
(4,  6,     5, 'Böcek ilacı uygulandı'),
(5,  4,   180, 'Ayçiçeği NPK gübre uygulandı'),
(6,  1,   300, 'Sera toprağına hayvan gübresi karıştırıldı'),
(6,  7,    10, 'Mantar hastalığına karşı ilaç uygulandı'),
(7,  4,    80, 'Biber için potasyum takviyesi'),
(7,  6,     3, 'Yaprak biti mücadelesi'),
(8,  2,   250, 'Elma bahçesi bahar gübreleme'),
(8,  7,    12, 'Fungal hastalık önleme'),
(9,  4,   100, 'Kiraz için NPK gübre'),
(10, 3,   200, 'Kolza taban gübre'),
(11, 3,   200, 'Buğday taban gübre'),
(13, 1,   130, 'Soğan için hayvan gübresi'),
(14, 1,   200, 'Sarımsak toprak hazırlığı'),
(15, 3,   110, 'Mercimek taban gübre');

-- ---------------------------------------------
-- Satışlar
-- ---------------------------------------------
INSERT INTO satislar (ekim_islem_id, satis_tar, alici, miktar, birim_fiyat, odeme_durumu, notlar) VALUES
(1,  '2025-06-20', 'Konya Tarım Kooperatifi',      10000, 7.50,  'odendi',    'Buğday ilk parti'),
(1,  '2025-07-05', 'Konya Un Fabrikası',             8500, 7.80,  'odendi',    'Buğday ikinci parti'),
(2,  '2024-09-15', 'İzmir Şarap Fabrikası',          3000, 8.50,  'odendi',    'Şaraplık üzüm'),
(2,  '2024-09-25', 'İzmir Hal Pazarı',               2200, 10.00, 'odendi',    'Sofralık üzüm'),
(4,  '2024-09-20', 'Ankara Yem Fabrikası',          10000, 7.50,  'odendi',    'Mısır ilk parti'),
(4,  '2024-10-05', 'Ankara Yem Fabrikası',           8500, 7.80,  'beklemede', 'Mısır ikinci parti ödeme bekleniyor'),
(5,  '2024-09-25', 'Bursa Yağ Fabrikası',            9800, 5.20,  'odendi',    'Ayçiçeği tamamı'),
(6,  '2024-06-10', 'Antalya Hal Pazarı',             2000, 12.00, 'odendi',    'Erken domates hasadı'),
(6,  '2024-06-18', 'Antalya Hal Pazarı',             1800, 11.50, 'beklemede', 'Ödeme bekleniyor'),
(7,  '2024-07-15', 'İstanbul İthalatçı Firma',       5600, 18.00, 'odendi',    'İhracat euro fiyatından'),
(8,  '2024-08-28', 'Ankara Meyve Toptancısı',        4100, 9.00,  'odendi',    'Elma tamamı'),
(9,  '2024-07-03', 'İstanbul Yaş Meyve Hal',         4100, 22.00, 'odendi',    'Kiraz ihracat kalitesi'),
(10, '2024-09-05', 'Eskişehir Yağ Fabrikası',       11500, 6.80,  'odendi',    'Kolza tamamı'),
(12, '2024-10-10', 'İzmir Şarap Fabrikası',          6300, 9.50,  'odendi',    'Sofralık üzüm ihracat'),
(13, '2024-07-22', 'Gaziantep Gıda Toptancısı',      8700, 4.20,  'odendi',    'Soğan toptan satış');
