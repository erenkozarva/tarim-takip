-- =============================================
-- Tarım Takip Sistemi - Veritabanı Şeması
-- MS SQL Server
-- =============================================

CREATE DATABASE Tarim_Takip_Sistemi;
GO

USE Tarim_Takip_Sistemi;
GO

-- ---------------------------------------------
-- TABLOLAR
-- ---------------------------------------------

CREATE TABLE iller (
    plaka_kodu  INT PRIMARY KEY,
    il_adi      VARCHAR(30) NOT NULL
);
GO

CREATE TABLE ciftciler (
    ciftci_id   INT PRIMARY KEY IDENTITY(1,1),
    tc_no       VARCHAR(11) UNIQUE NOT NULL,
    ad          VARCHAR(50) NOT NULL,
    soyad       VARCHAR(50) NOT NULL,
    tel_no      VARCHAR(15),
    dogum_tar   DATE,
    kayit_tar   DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE tarlalar (
    tarla_id    INT PRIMARY KEY IDENTITY(1,1),
    ciftci_id   INT NOT NULL,
    plaka_kodu  INT NOT NULL,
    ilce        VARCHAR(50),
    ada_no      VARCHAR(20),
    parsel_no   VARCHAR(20),
    dekar       INT NOT NULL,
    FOREIGN KEY (ciftci_id)  REFERENCES ciftciler(ciftci_id),
    FOREIGN KEY (plaka_kodu) REFERENCES iller(plaka_kodu)
);
GO

CREATE TABLE urunler (
    urun_id     INT PRIMARY KEY IDENTITY(1,1),
    urun_adi    VARCHAR(50) NOT NULL,
    tur         VARCHAR(30),
    birim       VARCHAR(10)
);
GO

CREATE TABLE ekim_hasat (
    islem_id        INT PRIMARY KEY IDENTITY(1,1),
    tarla_id        INT NOT NULL,
    urun_id         INT NOT NULL,
    ekim_tar        DATE NOT NULL,
    tahmini_hasat   DATE,
    gercek_hasat    DATE,
    hasat_miktari   DECIMAL(10,2),
    durum           VARCHAR(30) DEFAULT 'ekildi',
    notlar          VARCHAR(300),
    FOREIGN KEY (tarla_id) REFERENCES tarlalar(tarla_id),
    FOREIGN KEY (urun_id)  REFERENCES urunler(urun_id)
);
GO

CREATE TABLE tarim_stok (
    stok_id         INT PRIMARY KEY IDENTITY(1,1),
    malzeme_adi     VARCHAR(50) NOT NULL,
    tur             VARCHAR(30),   -- gubre, ilac, tohum, yakit, ekipman, yem
    stok_adet       INT DEFAULT 0,
    birim_fiyat     DECIMAL(10,2)
);
GO

CREATE TABLE bakim_islemleri (
    bakim_id        INT PRIMARY KEY IDENTITY(1,1),
    ekim_islem_id   INT NOT NULL,
    stok_id         INT NOT NULL,
    miktar          INT NOT NULL,
    islem_tar       DATETIME DEFAULT GETDATE(),
    aciklama        VARCHAR(200),
    FOREIGN KEY (ekim_islem_id) REFERENCES ekim_hasat(islem_id),
    FOREIGN KEY (stok_id)       REFERENCES tarim_stok(stok_id)
);
GO

CREATE TABLE satislar (
    satis_id        INT PRIMARY KEY IDENTITY(1,1),
    ekim_islem_id   INT NOT NULL,
    satis_tar       DATE NOT NULL,
    alici           VARCHAR(100),
    miktar          DECIMAL(10,2) NOT NULL,
    birim_fiyat     DECIMAL(10,2) NOT NULL,
    toplam_tutar    AS (miktar * birim_fiyat) PERSISTED,
    odeme_durumu    VARCHAR(20) DEFAULT 'beklemede',
    notlar          VARCHAR(300),
    FOREIGN KEY (ekim_islem_id) REFERENCES ekim_hasat(islem_id)
);
GO

CREATE TABLE loglar (
    log_id      INT PRIMARY KEY IDENTITY(1,1),
    islem       VARCHAR(50),
    tarih       DATETIME DEFAULT GETDATE(),
    aciklama    VARCHAR(255)
);
GO


-- ---------------------------------------------
-- STORED PROCEDURES
-- ---------------------------------------------

-- Sistem özeti
CREATE PROCEDURE sistem_ozeti
AS
BEGIN
    SELECT
        (SELECT COUNT(*) FROM ciftciler)    AS toplam_ciftci,
        (SELECT COUNT(*) FROM tarlalar)     AS toplam_tarla,
        (SELECT SUM(dekar) FROM tarlalar)   AS toplam_dekar,
        (SELECT COUNT(*) FROM ekim_hasat)   AS toplam_ekim,
        (SELECT COUNT(*) FROM satislar)     AS toplam_satis;
END;
GO

-- Tüm çiftçileri listele
CREATE PROCEDURE tum_ciftciler
AS
BEGIN
    SELECT * FROM ciftciler ORDER BY soyad, ad;
END;
GO

-- Çiftçi ara (ad veya soyad)
CREATE PROCEDURE ciftci_ara
    @arama_metni VARCHAR(50)
AS
BEGIN
    SELECT * FROM ciftciler
    WHERE ad   LIKE '%' + @arama_metni + '%'
       OR soyad LIKE '%' + @arama_metni + '%';
END;
GO

-- Çiftçinin toplam arazi miktarı
CREATE PROCEDURE ciftci_arazi_toplami
    @ciftci_id INT
AS
BEGIN
    SELECT
        c.ad,
        c.soyad,
        ISNULL(SUM(t.dekar), 0) AS toplam_dekar,
        COUNT(t.tarla_id)       AS tarla_sayisi
    FROM ciftciler c
    LEFT JOIN tarlalar t ON c.ciftci_id = t.ciftci_id
    WHERE c.ciftci_id = @ciftci_id
    GROUP BY c.ad, c.soyad;
END;
GO

-- Belirli dekarin üzerindeki tarlalar
CREATE PROCEDURE buyuk_tarlalar
    @minimum_dekar INT
AS
BEGIN
    SELECT
        t.*,
        c.ad + ' ' + c.soyad AS ciftci_adi,
        i.il_adi
    FROM tarlalar t
    JOIN ciftciler c ON t.ciftci_id = c.ciftci_id
    JOIN iller i     ON t.plaka_kodu = i.plaka_kodu
    WHERE t.dekar >= @minimum_dekar
    ORDER BY t.dekar DESC;
END;
GO

-- Aktif ekimler (hasat edilmemiş)
CREATE PROCEDURE aktif_ekimler
AS
BEGIN
    SELECT
        e.islem_id,
        c.ad + ' ' + c.soyad   AS ciftci_adi,
        i.il_adi,
        t.ilce,
        u.urun_adi,
        e.ekim_tar,
        e.tahmini_hasat,
        e.durum
    FROM ekim_hasat e
    JOIN tarlalar t  ON e.tarla_id = t.tarla_id
    JOIN ciftciler c ON t.ciftci_id = c.ciftci_id
    JOIN iller i     ON t.plaka_kodu = i.plaka_kodu
    JOIN urunler u   ON e.urun_id = u.urun_id
    WHERE e.durum != 'hasat edildi'
    ORDER BY e.tahmini_hasat;
END;
GO

-- Stok durumu
CREATE PROCEDURE stok_durumu
AS
BEGIN
    SELECT * FROM tarim_stok
    ORDER BY tur, malzeme_adi;
END;
GO

-- Satış raporu
CREATE PROCEDURE satis_raporu
AS
BEGIN
    SELECT
        s.satis_id,
        c.ad + ' ' + c.soyad   AS ciftci_adi,
        u.urun_adi,
        s.satis_tar,
        s.alici,
        s.miktar,
        u.birim,
        s.birim_fiyat,
        s.toplam_tutar,
        s.odeme_durumu
    FROM satislar s
    JOIN ekim_hasat e ON s.ekim_islem_id = e.islem_id
    JOIN tarlalar t   ON e.tarla_id = t.tarla_id
    JOIN ciftciler c  ON t.ciftci_id = c.ciftci_id
    JOIN urunler u    ON e.urun_id = u.urun_id
    ORDER BY s.satis_tar DESC;
END;
GO

-- İle göre tarlalar
CREATE PROCEDURE ile_gore_tarlalar
    @plaka INT
AS
BEGIN
    SELECT
        t.*,
        c.ad + ' ' + c.soyad AS ciftci_adi
    FROM tarlalar t
    JOIN ciftciler c ON t.ciftci_id = c.ciftci_id
    WHERE t.plaka_kodu = @plaka;
END;
GO

-- Genç çiftçiler
CREATE PROCEDURE genc_ciftciler
    @tarih DATE
AS
BEGIN
    SELECT * FROM ciftciler
    WHERE dogum_tar > @tarih
    ORDER BY dogum_tar DESC;
END;
GO

-- Çiftçi sil (bağlı kayıtlarla birlikte)
CREATE PROCEDURE ciftci_sil
    @ciftci_id INT
AS
BEGIN
    DELETE FROM tarlalar WHERE ciftci_id = @ciftci_id;
    DELETE FROM ciftciler WHERE ciftci_id = @ciftci_id;
END;
GO

-- Kaç çiftçi var
CREATE PROCEDURE kac_ciftci_var
AS
BEGIN
    SELECT COUNT(*) AS toplam_sayi FROM ciftciler;
END;
GO


-- ---------------------------------------------
-- TRIGGER'LAR
-- ---------------------------------------------

-- Çiftçi eklenince log yaz
CREATE TRIGGER trg_ciftci_ekle_log
ON ciftciler
AFTER INSERT
AS
BEGIN
    INSERT INTO loglar (islem, aciklama)
    VALUES ('CIFTCI_EKLENDI', 'Sisteme yeni bir çiftçi kaydı eklendi.');
END;
GO

-- Çiftçi silinince log yaz
CREATE TRIGGER trg_ciftci_sil_log
ON ciftciler
AFTER DELETE
AS
BEGIN
    INSERT INTO loglar (islem, aciklama)
    VALUES ('CIFTCI_SILINDI', 'Bir çiftçi kaydı sistemden silindi.');
END;
GO

-- Ad ve soyadı otomatik büyüt
CREATE TRIGGER trg_isim_buyut
ON ciftciler
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE ciftciler
    SET ad    = UPPER(ad),
        soyad = UPPER(soyad)
    WHERE ciftci_id IN (SELECT ciftci_id FROM inserted);
END;
GO

-- Kayıt tarihi değiştirilemez
CREATE TRIGGER trg_kayit_tar_degismez
ON ciftciler
AFTER UPDATE
AS
BEGIN
    IF UPDATE(kayit_tar)
    BEGIN
        ROLLBACK TRANSACTION;
        PRINT 'Kayıt tarihi sonradan değiştirilemez.';
    END
END;
GO

-- İlçeyi otomatik büyüt, boşsa MERKEZ yap
CREATE TRIGGER trg_ilce_duzenle
ON tarlalar
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE tarlalar
    SET ilce = 'MERKEZ'
    WHERE ilce IS NULL
      AND tarla_id IN (SELECT tarla_id FROM inserted);

    UPDATE tarlalar
    SET ilce = UPPER(ilce)
    WHERE tarla_id IN (SELECT tarla_id FROM inserted);
END;
GO

-- İller tablosu değiştirilemez
CREATE TRIGGER trg_iller_sabittir
ON iller
AFTER UPDATE, DELETE
AS
BEGIN
    ROLLBACK TRANSACTION;
    PRINT 'İl bilgileri sabittir, değişiklik yapılamaz.';
END;
GO

-- Bakım işlemi eklenince stoktan düş
CREATE TRIGGER trg_stok_guncelle
ON bakim_islemleri
AFTER INSERT
AS
BEGIN
    UPDATE tarim_stok
    SET stok_adet = stok_adet - i.miktar
    FROM tarim_stok ts
    JOIN inserted i ON ts.stok_id = i.stok_id;
END;
GO

-- Ekim eklenince log yaz
CREATE TRIGGER trg_ekim_log
ON ekim_hasat
AFTER INSERT
AS
BEGIN
    INSERT INTO loglar (islem, aciklama)
    VALUES ('EKIM_EKLENDI', 'Yeni bir ekim/hasat kaydı oluşturuldu.');
END;
GO
