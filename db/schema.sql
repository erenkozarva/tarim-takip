-- =============================================
-- Tarım Takip Sistemi - Veritabanı Şeması
-- PostgreSQL
-- =============================================

-- ---------------------------------------------
-- TABLOLAR
-- ---------------------------------------------

CREATE TABLE iller (
    plaka_kodu  INT PRIMARY KEY,
    il_adi      VARCHAR(30) NOT NULL
);

CREATE TABLE ciftciler (
    ciftci_id   SERIAL PRIMARY KEY,
    tc_no       VARCHAR(11) UNIQUE NOT NULL,
    ad          VARCHAR(50) NOT NULL,
    soyad       VARCHAR(50) NOT NULL,
    tel_no      VARCHAR(15),
    dogum_tar   DATE,
    kayit_tar   TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tarlalar (
    tarla_id    SERIAL PRIMARY KEY,
    ciftci_id   INT NOT NULL REFERENCES ciftciler(ciftci_id),
    plaka_kodu  INT NOT NULL REFERENCES iller(plaka_kodu),
    ilce        VARCHAR(50),
    ada_no      VARCHAR(20),
    parsel_no   VARCHAR(20),
    dekar       INT NOT NULL
);

CREATE TABLE urunler (
    urun_id     SERIAL PRIMARY KEY,
    urun_adi    VARCHAR(50) NOT NULL,
    tur         VARCHAR(30),
    birim       VARCHAR(10)
);

CREATE TABLE ekim_hasat (
    islem_id        SERIAL PRIMARY KEY,
    tarla_id        INT NOT NULL REFERENCES tarlalar(tarla_id),
    urun_id         INT NOT NULL REFERENCES urunler(urun_id),
    ekim_tar        DATE NOT NULL,
    tahmini_hasat   DATE,
    gercek_hasat    DATE,
    hasat_miktari   DECIMAL(10,2),
    durum           VARCHAR(30) DEFAULT 'ekildi',
    notlar          VARCHAR(300)
);

CREATE TABLE tarim_stok (
    stok_id         SERIAL PRIMARY KEY,
    malzeme_adi     VARCHAR(50) NOT NULL,
    tur             VARCHAR(30),
    stok_adet       INT DEFAULT 0,
    birim_fiyat     DECIMAL(10,2)
);

CREATE TABLE bakim_islemleri (
    bakim_id        SERIAL PRIMARY KEY,
    ekim_islem_id   INT NOT NULL REFERENCES ekim_hasat(islem_id),
    stok_id         INT NOT NULL REFERENCES tarim_stok(stok_id),
    miktar          INT NOT NULL,
    islem_tar       TIMESTAMP DEFAULT NOW(),
    aciklama        VARCHAR(200)
);

CREATE TABLE satislar (
    satis_id        SERIAL PRIMARY KEY,
    ekim_islem_id   INT NOT NULL REFERENCES ekim_hasat(islem_id),
    satis_tar       DATE NOT NULL,
    alici           VARCHAR(100),
    miktar          DECIMAL(10,2) NOT NULL,
    birim_fiyat     DECIMAL(10,2) NOT NULL,
    toplam_tutar    DECIMAL(10,2) GENERATED ALWAYS AS (miktar * birim_fiyat) STORED,
    odeme_durumu    VARCHAR(20) DEFAULT 'beklemede',
    notlar          VARCHAR(300)
);

CREATE TABLE loglar (
    log_id      SERIAL PRIMARY KEY,
    islem       VARCHAR(50),
    tarih       TIMESTAMP DEFAULT NOW(),
    aciklama    VARCHAR(255)
);


-- ---------------------------------------------
-- FONKSİYONLAR (Stored Procedures)
-- ---------------------------------------------

-- Sistem özeti
CREATE OR REPLACE FUNCTION sistem_ozeti()
RETURNS TABLE(toplam_ciftci BIGINT, toplam_tarla BIGINT, toplam_dekar NUMERIC, toplam_ekim BIGINT, toplam_satis BIGINT)
LANGUAGE sql AS $$
    SELECT
        (SELECT COUNT(*) FROM ciftciler),
        (SELECT COUNT(*) FROM tarlalar),
        (SELECT COALESCE(SUM(dekar), 0) FROM tarlalar),
        (SELECT COUNT(*) FROM ekim_hasat),
        (SELECT COUNT(*) FROM satislar);
$$;

-- Tüm çiftçileri listele
CREATE OR REPLACE FUNCTION tum_ciftciler()
RETURNS SETOF ciftciler
LANGUAGE sql AS $$
    SELECT * FROM ciftciler ORDER BY soyad, ad;
$$;

-- Çiftçi ara (ad veya soyad)
CREATE OR REPLACE FUNCTION ciftci_ara(arama_metni VARCHAR)
RETURNS SETOF ciftciler
LANGUAGE sql AS $$
    SELECT * FROM ciftciler
    WHERE ad   ILIKE '%' || arama_metni || '%'
       OR soyad ILIKE '%' || arama_metni || '%';
$$;

-- Çiftçinin toplam arazi miktarı
CREATE OR REPLACE FUNCTION ciftci_arazi_toplami(p_ciftci_id INT)
RETURNS TABLE(ad VARCHAR, soyad VARCHAR, toplam_dekar NUMERIC, tarla_sayisi BIGINT)
LANGUAGE sql AS $$
    SELECT
        c.ad,
        c.soyad,
        COALESCE(SUM(t.dekar), 0),
        COUNT(t.tarla_id)
    FROM ciftciler c
    LEFT JOIN tarlalar t ON c.ciftci_id = t.ciftci_id
    WHERE c.ciftci_id = p_ciftci_id
    GROUP BY c.ad, c.soyad;
$$;

-- Belirli dekarın üzerindeki tarlalar
CREATE OR REPLACE FUNCTION buyuk_tarlalar(minimum_dekar INT)
RETURNS TABLE(
    tarla_id INT, ciftci_id INT, plaka_kodu INT,
    ilce VARCHAR, ada_no VARCHAR, parsel_no VARCHAR,
    dekar INT, ciftci_adi TEXT, il_adi VARCHAR
)
LANGUAGE sql AS $$
    SELECT
        t.tarla_id, t.ciftci_id, t.plaka_kodu,
        t.ilce, t.ada_no, t.parsel_no, t.dekar,
        c.ad || ' ' || c.soyad AS ciftci_adi,
        i.il_adi
    FROM tarlalar t
    JOIN ciftciler c ON t.ciftci_id = c.ciftci_id
    JOIN iller i     ON t.plaka_kodu = i.plaka_kodu
    WHERE t.dekar >= minimum_dekar
    ORDER BY t.dekar DESC;
$$;

-- Aktif ekimler (hasat edilmemiş)
CREATE OR REPLACE FUNCTION aktif_ekimler()
RETURNS TABLE(
    islem_id INT, ciftci_adi TEXT, il_adi VARCHAR,
    ilce VARCHAR, urun_adi VARCHAR, ekim_tar DATE,
    tahmini_hasat DATE, durum VARCHAR
)
LANGUAGE sql AS $$
    SELECT
        e.islem_id,
        c.ad || ' ' || c.soyad AS ciftci_adi,
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
$$;

-- Stok durumu
CREATE OR REPLACE FUNCTION stok_durumu()
RETURNS SETOF tarim_stok
LANGUAGE sql AS $$
    SELECT * FROM tarim_stok ORDER BY tur, malzeme_adi;
$$;

-- Satış raporu
CREATE OR REPLACE FUNCTION satis_raporu()
RETURNS TABLE(
    satis_id INT, ciftci_adi TEXT, urun_adi VARCHAR,
    satis_tar DATE, alici VARCHAR, miktar DECIMAL,
    birim VARCHAR, birim_fiyat DECIMAL, toplam_tutar DECIMAL,
    odeme_durumu VARCHAR
)
LANGUAGE sql AS $$
    SELECT
        s.satis_id,
        c.ad || ' ' || c.soyad AS ciftci_adi,
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
$$;

-- İle göre tarlalar
CREATE OR REPLACE FUNCTION ile_gore_tarlalar(p_plaka INT)
RETURNS TABLE(
    tarla_id INT, ciftci_id INT, plaka_kodu INT,
    ilce VARCHAR, ada_no VARCHAR, parsel_no VARCHAR,
    dekar INT, ciftci_adi TEXT
)
LANGUAGE sql AS $$
    SELECT
        t.tarla_id, t.ciftci_id, t.plaka_kodu,
        t.ilce, t.ada_no, t.parsel_no, t.dekar,
        c.ad || ' ' || c.soyad AS ciftci_adi
    FROM tarlalar t
    JOIN ciftciler c ON t.ciftci_id = c.ciftci_id
    WHERE t.plaka_kodu = p_plaka;
$$;

-- Genç çiftçiler
CREATE OR REPLACE FUNCTION genc_ciftciler(p_tarih DATE)
RETURNS SETOF ciftciler
LANGUAGE sql AS $$
    SELECT * FROM ciftciler WHERE dogum_tar > p_tarih ORDER BY dogum_tar DESC;
$$;

-- Çiftçi sil (bağlı kayıtlarla birlikte)
CREATE OR REPLACE FUNCTION ciftci_sil(p_ciftci_id INT)
RETURNS void
LANGUAGE sql AS $$
    DELETE FROM tarlalar WHERE ciftci_id = p_ciftci_id;
    DELETE FROM ciftciler WHERE ciftci_id = p_ciftci_id;
$$;

-- Kaç çiftçi var
CREATE OR REPLACE FUNCTION kac_ciftci_var()
RETURNS BIGINT
LANGUAGE sql AS $$
    SELECT COUNT(*) FROM ciftciler;
$$;


-- ---------------------------------------------
-- TRIGGER FONKSİYONLARI
-- ---------------------------------------------

-- Çiftçi eklenince log yaz
CREATE OR REPLACE FUNCTION fn_ciftci_ekle_log()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO loglar (islem, aciklama)
    VALUES ('CIFTCI_EKLENDI', 'Sisteme yeni bir çiftçi kaydı eklendi.');
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_ciftci_ekle_log
AFTER INSERT ON ciftciler
FOR EACH ROW EXECUTE FUNCTION fn_ciftci_ekle_log();

-- Çiftçi silinince log yaz
CREATE OR REPLACE FUNCTION fn_ciftci_sil_log()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO loglar (islem, aciklama)
    VALUES ('CIFTCI_SILINDI', 'Bir çiftçi kaydı sistemden silindi.');
    RETURN OLD;
END;
$$;
CREATE TRIGGER trg_ciftci_sil_log
AFTER DELETE ON ciftciler
FOR EACH ROW EXECUTE FUNCTION fn_ciftci_sil_log();

-- Ad ve soyadı otomatik büyüt
CREATE OR REPLACE FUNCTION fn_isim_buyut()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.ad    := UPPER(NEW.ad);
    NEW.soyad := UPPER(NEW.soyad);
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_isim_buyut
BEFORE INSERT OR UPDATE ON ciftciler
FOR EACH ROW EXECUTE FUNCTION fn_isim_buyut();

-- Kayıt tarihi değiştirilemez
CREATE OR REPLACE FUNCTION fn_kayit_tar_degismez()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.kayit_tar IS DISTINCT FROM OLD.kayit_tar THEN
        RAISE EXCEPTION 'Kayıt tarihi sonradan değiştirilemez.';
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_kayit_tar_degismez
BEFORE UPDATE ON ciftciler
FOR EACH ROW EXECUTE FUNCTION fn_kayit_tar_degismez();

-- İlçeyi otomatik büyüt, boşsa MERKEZ yap
CREATE OR REPLACE FUNCTION fn_ilce_duzenle()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.ilce IS NULL OR TRIM(NEW.ilce) = '' THEN
        NEW.ilce := 'MERKEZ';
    ELSE
        NEW.ilce := UPPER(NEW.ilce);
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_ilce_duzenle
BEFORE INSERT OR UPDATE ON tarlalar
FOR EACH ROW EXECUTE FUNCTION fn_ilce_duzenle();

-- İller tablosu değiştirilemez
CREATE OR REPLACE FUNCTION fn_iller_sabittir()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'İl bilgileri sabittir, değişiklik yapılamaz.';
    RETURN NULL;
END;
$$;
CREATE TRIGGER trg_iller_sabittir
BEFORE UPDATE OR DELETE ON iller
FOR EACH ROW EXECUTE FUNCTION fn_iller_sabittir();

-- Bakım işlemi eklenince stoktan düş
CREATE OR REPLACE FUNCTION fn_stok_guncelle()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE tarim_stok
    SET stok_adet = stok_adet - NEW.miktar
    WHERE stok_id = NEW.stok_id;
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_stok_guncelle
AFTER INSERT ON bakim_islemleri
FOR EACH ROW EXECUTE FUNCTION fn_stok_guncelle();

-- Ekim eklenince log yaz
CREATE OR REPLACE FUNCTION fn_ekim_log()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO loglar (islem, aciklama)
    VALUES ('EKIM_EKLENDI', 'Yeni bir ekim/hasat kaydı oluşturuldu.');
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_ekim_log
AFTER INSERT ON ekim_hasat
FOR EACH ROW EXECUTE FUNCTION fn_ekim_log();
