# Tarım Takip Sistemi

Çiftçilerin tarım faaliyetlerini dijital ortamda takip etmelerini sağlayan web tabanlı bir yönetim sistemidir.

---

## Kullanılan Teknolojiler

| Katman | Teknoloji |
|--------|-----------|
| Backend | Python 3.12, Flask |
| Veritabanı | MS SQL Server (Docker container) |
| DB Bağlantısı | pyodbc, ODBC Driver 17 |
| Frontend | HTML, Bootstrap 5, Bootstrap Icons |
| Ortam Değişkenleri | python-dotenv |

---

## Proje Yapısı

```
tarim-takip/
├── app.py               # Flask uygulaması, route'lar
├── models.py            # Veritabanı bağlantısı
├── requirements.txt     # Python bağımlılıkları
├── .env                 # Gizli bilgiler (DB bağlantısı)
├── db/
│   ├── schema.sql       # Veritabanı, tablolar, procedure'ler, trigger'lar
│   └── seed.sql         # Örnek veriler
└── templates/
    ├── base.html        # Ortak şablon (navbar, layout)
    ├── index.html       # Ana sayfa (dashboard)
    ├── ciftciler.html   # Çiftçi listesi
    ├── ciftci_ekle.html # Çiftçi ekleme formu
    ├── tarlalar.html    # Tarla listesi
    ├── tarla_ekle.html  # Tarla ekleme formu
    ├── ekim.html        # Ekim/Hasat listesi
    ├── ekim_ekle.html   # Ekim kaydı formu
    ├── satislar.html    # Satış listesi
    └── stok.html        # Stok durumu
```

---

## Veritabanı Tasarımı

Veritabanı MS SQL Server üzerinde `Tarim_Takip_Sistemi` adıyla oluşturulmuştur.

### Tablolar

| Tablo | Açıklama |
|-------|----------|
| `iller` | İl bilgileri (plaka kodu ile) |
| `ciftciler` | Çiftçi kayıtları (TC no, ad, soyad, telefon, doğum tarihi) |
| `tarlalar` | Araziler (çiftçiye ve ile bağlı, ada/parsel numarası ile) |
| `urunler` | Ürün kataloğu (buğday, domates, elma vb.) |
| `ekim_hasat` | Ekim ve hasat kayıtları (tarla + ürün bazlı) |
| `tarim_stok` | Gübre, ilaç, tohum, yakıt gibi malzeme envanteri |
| `bakim_islemleri` | Tarlaya yapılan gübre/ilaç/sulama işlemleri |
| `satislar` | Hasat sonrası satış kayıtları (otomatik toplam tutar hesabı) |
| `loglar` | Sistem log kayıtları (trigger tarafından otomatik doldurulur) |

### Tablo İlişkileri

```
iller ──────────┐
                ↓
ciftciler ──→ tarlalar ──→ ekim_hasat ──→ satislar
                               ↓
tarim_stok ──→ bakim_islemleri
```

### Stored Procedure'ler

| Procedure | Açıklama |
|-----------|----------|
| `sistem_ozeti` | Toplam çiftçi, tarla, ekim ve satış sayısını döndürür |
| `tum_ciftciler` | Tüm çiftçileri listeler |
| `ciftci_ara @arama` | Ad veya soyadına göre çiftçi arar |
| `ciftci_arazi_toplami @id` | Çiftçinin toplam arazi miktarını hesaplar |
| `buyuk_tarlalar @dekar` | Belirtilen dekarın üzerindeki tarlaları listeler |
| `aktif_ekimler` | Henüz hasat edilmemiş ekimleri listeler |
| `stok_durumu` | Tüm stok malzemelerini listeler |
| `satis_raporu` | Satışları çiftçi ve ürün bilgisiyle listeler |
| `ile_gore_tarlalar @plaka` | İle göre tarlaları filtreler |
| `genc_ciftciler @tarih` | Belirtilen tarihten sonra doğan çiftçileri listeler |
| `ciftci_sil @id` | Çiftçiyi bağlı tarlalarıyla siler |
| `kac_ciftci_var` | Toplam çiftçi sayısını döndürür |

### Trigger'lar

| Trigger | Tablo | Açıklama |
|---------|-------|----------|
| `trg_ciftci_ekle_log` | ciftciler | Yeni çiftçi eklenince loglar tablosuna kayıt yazar |
| `trg_ciftci_sil_log` | ciftciler | Çiftçi silinince log yazar |
| `trg_isim_buyut` | ciftciler | Ad ve soyadı otomatik büyük harfe çevirir |
| `trg_kayit_tar_degismez` | ciftciler | Kayıt tarihinin değiştirilmesini engeller |
| `trg_ilce_duzenle` | tarlalar | İlçeyi büyük harfe çevirir, boşsa MERKEZ yazar |
| `trg_iller_sabittir` | iller | İl bilgilerinin güncellenmesini/silinmesini engeller |
| `trg_stok_guncelle` | bakim_islemleri | Bakım işlemi eklenince stok miktarını düşürür |
| `trg_ekim_log` | ekim_hasat | Yeni ekim kaydı eklenince log yazar |

---

## Backend (Flask)

`app.py` dosyası Flask ile yazılmıştır. Her sayfa için bir route (URL yolu) tanımlanmıştır.

| Route | Method | Açıklama |
|-------|--------|----------|
| `/` | GET | Dashboard - sistem özeti |
| `/ciftciler` | GET | Çiftçi listesi |
| `/ciftciler/ekle` | GET, POST | Çiftçi ekleme formu |
| `/ciftciler/sil/<id>` | GET | Çiftçi silme |
| `/tarlalar` | GET | Tarla listesi |
| `/tarlalar/ekle` | GET, POST | Tarla ekleme formu |
| `/ekim` | GET | Ekim/Hasat listesi |
| `/ekim/ekle` | GET, POST | Ekim kaydı ekleme |
| `/satislar` | GET | Satış raporu |
| `/stok` | GET | Stok durumu |

---

## Veritabanı Bağlantısı

`models.py` dosyası pyodbc kütüphanesiyle MS SQL Server'a bağlanır.  
Bağlantı bilgileri `.env` dosyasından okunur.

```python
# models.py
import pyodbc, os
from dotenv import load_dotenv

load_dotenv()

def get_db():
    conn = pyodbc.connect(
        f"DRIVER={{ODBC Driver 17 for SQL Server}};"
        f"SERVER={os.getenv('DB_SERVER')};"
        f"DATABASE={os.getenv('DB_NAME')};"
        f"UID={os.getenv('DB_USER')};"
        f"PWD={os.getenv('DB_PASSWORD')};"
        f"TrustServerCertificate=yes;"
    )
    return conn
```

`.env` dosyası:
```
DB_SERVER=localhost,1433
DB_NAME=Tarim_Takip_Sistemi
DB_USER=sa
DB_PASSWORD=****
SECRET_KEY=tarimtakip2025
```

---

## Frontend

Tüm sayfalar `templates/base.html` şablonunu miras alır.  
Bootstrap 5 ile responsive (mobil uyumlu) tasarım yapılmıştır.

| Sayfa | Dosya | Açıklama |
|-------|-------|----------|
| Ana Sayfa | `index.html` | Özet kartlar (çiftçi, tarla, ekim, satış sayıları) |
| Çiftçiler | `ciftciler.html` | Tablo listesi + silme butonu |
| Çiftçi Ekle | `ciftci_ekle.html` | TC no, ad, soyad, telefon, doğum tarihi formu |
| Tarlalar | `tarlalar.html` | İl, ilçe, ada/parsel, dekar bilgileriyle liste |
| Tarla Ekle | `tarla_ekle.html` | Dropdown ile çiftçi ve il seçimi |
| Ekim/Hasat | `ekim.html` | Durum badge'leriyle ekim listesi |
| Ekim Ekle | `ekim_ekle.html` | Tarla ve ürün dropdown, tarih seçici |
| Satışlar | `satislar.html` | Ödeme durumuna göre renkli badge |
| Stok | `stok.html` | Malzeme türüne göre stok listesi |

---

## Kurulum

### Gereksinimler
- Python 3.12+
- Docker (MS SQL Server için)
- ODBC Driver 17 for SQL Server

### Adımlar

```bash
# 1. Repoyu klonla
git clone https://github.com/erenkozarva/tarim-takip.git
cd tarim-takip

# 2. Sanal ortam oluştur ve aktif et
python3 -m venv venv
source venv/bin/activate

# 3. Bağımlılıkları yükle
pip install -r requirements.txt

# 4. .env dosyasını düzenle
cp .env.example .env
# DB_PASSWORD alanına kendi şifreni gir

# 5. Docker'da MS SQL Server'ı başlat
docker start mssql

# 6. Veritabanını oluştur (Azure Data Studio veya sqlcmd ile)
# db/schema.sql → önce çalıştır
# db/seed.sql   → sonra çalıştır

# 7. Uygulamayı başlat
python3 app.py
```

Tarayıcıda aç: [http://127.0.0.1:5000](http://127.0.0.1:5000)

---

## Ekran Görüntüleri

> Dashboard, çiftçi listesi, ekim/hasat kayıtları ve satış raporu ekranlarını içermektedir.

---

## Geliştirici

**Eren Kozarva**  
GitHub: [github.com/erenkozarva](https://github.com/erenkozarva)
