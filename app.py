from flask import Flask, render_template, request, redirect, url_for, flash, session
from flask_mail import Mail, Message
from functools import wraps
from models import get_db
import os, re
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv('SECRET_KEY')

app.config['MAIL_SERVER']         = 'smtp.gmail.com'
app.config['MAIL_PORT']           = 587
app.config['MAIL_USE_TLS']        = True
app.config['MAIL_USERNAME']       = os.getenv('MAIL_USERNAME')
app.config['MAIL_PASSWORD']       = os.getenv('MAIL_PASSWORD')
app.config['MAIL_DEFAULT_SENDER'] = os.getenv('MAIL_USERNAME')

mail = Mail(app)

# ---------------------------------------------
# GİRİŞ / ÇIKIŞ
# ---------------------------------------------
def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if not session.get('giris_yapildi'):
            flash('Bu işlem için giriş yapmanız gerekiyor.', 'warning')
            return redirect(url_for('giris'))
        return f(*args, **kwargs)
    return decorated

@app.route('/giris', methods=['GET', 'POST'])
def giris():
    if session.get('giris_yapildi'):
        return redirect(url_for('index'))
    if request.method == 'POST':
        kullanici = request.form['kullanici']
        sifre     = request.form['sifre']
        if kullanici == os.getenv('ADMIN_USER') and sifre == os.getenv('ADMIN_PASSWORD'):
            session['giris_yapildi'] = True
            flash('Giriş başarılı.', 'success')
            return redirect(url_for('index'))
        flash('Kullanıcı adı veya şifre hatalı.', 'danger')
    return render_template('giris.html')

@app.route('/cikis')
def cikis():
    session.clear()
    flash('Çıkış yapıldı.', 'info')
    return redirect(url_for('index'))

# ---------------------------------------------
# ANA SAYFA - Dashboard
# ---------------------------------------------
@app.route('/')
def index():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM sistem_ozeti()")
    row = cursor.fetchone()
    ozet = {
        'toplam_ciftci': row[0],
        'toplam_tarla':  row[1],
        'toplam_dekar':  row[2],
        'toplam_ekim':   row[3],
        'toplam_satis':  row[4],
    }
    conn.close()
    return render_template('index.html', ozet=ozet)

# ---------------------------------------------
# CİFTÇİLER
# ---------------------------------------------
@app.route('/ciftciler')
def ciftciler():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM tum_ciftciler()")
    rows = cursor.fetchall()
    conn.close()
    return render_template('ciftciler.html', ciftciler=rows)

@app.route('/ciftciler/ekle', methods=['GET', 'POST'])
@login_required
def ciftci_ekle():
    if request.method == 'POST':
        tc_no     = request.form['tc_no'].strip()
        ad        = request.form['ad'].strip()
        soyad     = request.form['soyad'].strip()
        tel_no    = request.form['tel_no'].strip()
        dogum_tar = request.form['dogum_tar']

        if not re.fullmatch(r'\d{11}', tc_no):
            flash('TC No 11 haneli rakamlardan oluşmalıdır.', 'danger')
            return render_template('ciftci_ekle.html')
        if not re.fullmatch(r'[a-zA-ZçÇğĞıİöÖşŞüÜ ]+', ad):
            flash('Ad yalnızca harf içerebilir.', 'danger')
            return render_template('ciftci_ekle.html')
        if not re.fullmatch(r'[a-zA-ZçÇğĞıİöÖşŞüÜ ]+', soyad):
            flash('Soyad yalnızca harf içerebilir.', 'danger')
            return render_template('ciftci_ekle.html')
        if tel_no and not re.fullmatch(r'[\d\s\-\+\(\)]{7,15}', tel_no):
            flash('Geçersiz telefon numarası formatı.', 'danger')
            return render_template('ciftci_ekle.html')

        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM ciftciler WHERE tc_no = %s", (tc_no,))
        if cursor.fetchone()[0] > 0:
            conn.close()
            flash('Bu TC No ile kayıtlı bir çiftçi zaten mevcut.', 'danger')
            return render_template('ciftci_ekle.html')

        cursor.execute(
            "INSERT INTO ciftciler (tc_no, ad, soyad, tel_no, dogum_tar) VALUES (%s,%s,%s,%s,%s)",
            (tc_no, ad, soyad, tel_no or None, dogum_tar or None)
        )
        conn.commit()
        conn.close()
        flash('Çiftçi başarıyla eklendi.', 'success')
        return redirect(url_for('ciftciler'))
    return render_template('ciftci_ekle.html')

@app.route('/ciftciler/sil/<int:ciftci_id>')
@login_required
def ciftci_sil(ciftci_id):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT ciftci_sil(%s)", (ciftci_id,))
    conn.commit()
    conn.close()
    flash('Çiftçi silindi.', 'warning')
    return redirect(url_for('ciftciler'))

# ---------------------------------------------
# TARLALAR
# ---------------------------------------------
@app.route('/tarlalar')
def tarlalar():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT t.tarla_id, c.ad || ' ' || c.soyad AS ciftci_adi,
               i.il_adi, t.ilce, t.ada_no, t.parsel_no, t.dekar
        FROM tarlalar t
        JOIN ciftciler c ON t.ciftci_id = c.ciftci_id
        JOIN iller i     ON t.plaka_kodu = i.plaka_kodu
        ORDER BY t.tarla_id
    """)
    rows = cursor.fetchall()
    conn.close()
    return render_template('tarlalar.html', tarlalar=rows)

@app.route('/tarlalar/ekle', methods=['GET', 'POST'])
@login_required
def tarla_ekle():
    conn = get_db()
    cursor = conn.cursor()
    if request.method == 'POST':
        ciftci_id  = request.form['ciftci_id']
        plaka_kodu = request.form['plaka_kodu']
        ilce       = request.form['ilce']
        ada_no     = request.form['ada_no']
        parsel_no  = request.form['parsel_no']
        dekar      = request.form['dekar']
        cursor.execute(
            "INSERT INTO tarlalar (ciftci_id, plaka_kodu, ilce, ada_no, parsel_no, dekar) VALUES (%s,%s,%s,%s,%s,%s)",
            (ciftci_id, plaka_kodu, ilce, ada_no, parsel_no, dekar)
        )
        conn.commit()
        conn.close()
        flash('Tarla başarıyla eklendi.', 'success')
        return redirect(url_for('tarlalar'))
    cursor.execute("SELECT ciftci_id, ad || ' ' || soyad FROM ciftciler ORDER BY soyad")
    ciftciler = cursor.fetchall()
    cursor.execute("SELECT plaka_kodu, il_adi FROM iller ORDER BY il_adi")
    iller = cursor.fetchall()
    conn.close()
    return render_template('tarla_ekle.html', ciftciler=ciftciler, iller=iller)

# ---------------------------------------------
# EKİM / HASAT
# ---------------------------------------------
@app.route('/ekim')
def ekim():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT e.islem_id, c.ad || ' ' || c.soyad AS ciftci_adi,
               i.il_adi, t.ilce, u.urun_adi,
               e.ekim_tar, e.tahmini_hasat, e.gercek_hasat,
               e.hasat_miktari, u.birim, e.durum
        FROM ekim_hasat e
        JOIN tarlalar t  ON e.tarla_id = t.tarla_id
        JOIN ciftciler c ON t.ciftci_id = c.ciftci_id
        JOIN iller i     ON t.plaka_kodu = i.plaka_kodu
        JOIN urunler u   ON e.urun_id = u.urun_id
        ORDER BY e.ekim_tar DESC
    """)
    rows = cursor.fetchall()
    conn.close()
    return render_template('ekim.html', ekimler=rows)

@app.route('/ekim/ekle', methods=['GET', 'POST'])
@login_required
def ekim_ekle():
    conn = get_db()
    cursor = conn.cursor()
    if request.method == 'POST':
        tarla_id      = request.form['tarla_id']
        urun_id       = request.form['urun_id']
        ekim_tar      = request.form['ekim_tar']
        tahmini_hasat = request.form['tahmini_hasat']
        notlar        = request.form['notlar']
        cursor.execute(
            "INSERT INTO ekim_hasat (tarla_id, urun_id, ekim_tar, tahmini_hasat, notlar) VALUES (%s,%s,%s,%s,%s)",
            (tarla_id, urun_id, ekim_tar, tahmini_hasat or None, notlar)
        )
        conn.commit()
        conn.close()
        flash('Ekim kaydı eklendi.', 'success')
        return redirect(url_for('ekim'))
    cursor.execute("""
        SELECT t.tarla_id, c.ad || ' ' || c.soyad || ' — ' || i.il_adi || ' / ' || t.ilce
        FROM tarlalar t
        JOIN ciftciler c ON t.ciftci_id = c.ciftci_id
        JOIN iller i     ON t.plaka_kodu = i.plaka_kodu
        ORDER BY c.soyad
    """)
    tarlalar = cursor.fetchall()
    cursor.execute("SELECT urun_id, urun_adi FROM urunler ORDER BY urun_adi")
    urunler = cursor.fetchall()
    conn.close()
    return render_template('ekim_ekle.html', tarlalar=tarlalar, urunler=urunler)

# ---------------------------------------------
# HASAT TAMAMLA
# ---------------------------------------------
@app.route('/ekim/hasat/<int:islem_id>', methods=['GET', 'POST'])
@login_required
def hasat_tamamla(islem_id):
    conn = get_db()
    cursor = conn.cursor()
    if request.method == 'POST':
        gercek_hasat  = request.form['gercek_hasat']
        hasat_miktari = request.form['hasat_miktari']
        cursor.execute("""
            UPDATE ekim_hasat
            SET gercek_hasat  = %s,
                hasat_miktari = %s,
                durum         = 'hasat edildi'
            WHERE islem_id = %s
        """, (gercek_hasat, hasat_miktari, islem_id))
        conn.commit()
        conn.close()
        flash('Hasat kaydı tamamlandı.', 'success')
        return redirect(url_for('ekim'))
    cursor.execute("""
        SELECT e.islem_id, c.ad || ' ' || c.soyad, i.il_adi, t.ilce,
               u.urun_adi, e.ekim_tar, e.tahmini_hasat, e.durum,
               e.hasat_miktari, u.birim
        FROM ekim_hasat e
        JOIN tarlalar t  ON e.tarla_id = t.tarla_id
        JOIN ciftciler c ON t.ciftci_id = c.ciftci_id
        JOIN iller i     ON t.plaka_kodu = i.plaka_kodu
        JOIN urunler u   ON e.urun_id = u.urun_id
        WHERE e.islem_id = %s
    """, (islem_id,))
    ekim = cursor.fetchone()
    conn.close()
    if not ekim:
        flash('Kayıt bulunamadı.', 'danger')
        return redirect(url_for('ekim'))
    return render_template('hasat_tamamla.html', ekim=ekim)

# ---------------------------------------------
# SATIŞLAR
# ---------------------------------------------
@app.route('/satislar')
def satislar():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM satis_raporu()")
    rows = cursor.fetchall()
    conn.close()
    return render_template('satislar.html', satislar=rows)

@app.route('/satislar/ekle', methods=['GET', 'POST'])
@login_required
def satis_ekle():
    conn = get_db()
    cursor = conn.cursor()
    if request.method == 'POST':
        ekim_islem_id = request.form['ekim_islem_id']
        satis_tar     = request.form['satis_tar']
        alici         = request.form['alici'].strip()
        miktar        = request.form['miktar']
        birim_fiyat   = request.form['birim_fiyat']
        odeme_durumu  = request.form['odeme_durumu']
        notlar        = request.form['notlar'].strip()
        cursor.execute(
            "INSERT INTO satislar (ekim_islem_id, satis_tar, alici, miktar, birim_fiyat, odeme_durumu, notlar) VALUES (%s,%s,%s,%s,%s,%s,%s)",
            (ekim_islem_id, satis_tar, alici or None, miktar, birim_fiyat, odeme_durumu, notlar or None)
        )
        conn.commit()
        conn.close()
        flash('Satış kaydı başarıyla eklendi.', 'success')
        return redirect(url_for('satislar'))
    cursor.execute("""
        SELECT e.islem_id,
               c.ad || ' ' || c.soyad || ' — ' || u.urun_adi || ' (' || TO_CHAR(e.gercek_hasat, 'DD.MM.YYYY') || ')'
        FROM ekim_hasat e
        JOIN tarlalar t  ON e.tarla_id = t.tarla_id
        JOIN ciftciler c ON t.ciftci_id = c.ciftci_id
        JOIN urunler u   ON e.urun_id = u.urun_id
        WHERE e.durum = 'hasat edildi'
        ORDER BY e.gercek_hasat DESC
    """)
    ekimler = cursor.fetchall()
    conn.close()
    return render_template('satis_ekle.html', ekimler=ekimler)

# ---------------------------------------------
# STOK
# ---------------------------------------------
@app.route('/stok')
def stok():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM stok_durumu()")
    rows = cursor.fetchall()
    conn.close()
    return render_template('stok.html', stoklar=rows)

@app.route('/stok/ekle', methods=['GET', 'POST'])
@login_required
def stok_ekle():
    if request.method == 'POST':
        malzeme_adi = request.form['malzeme_adi'].strip()
        tur         = request.form['tur']
        stok_adet   = request.form['stok_adet']
        birim_fiyat = request.form['birim_fiyat']
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO tarim_stok (malzeme_adi, tur, stok_adet, birim_fiyat) VALUES (%s,%s,%s,%s)",
            (malzeme_adi, tur, stok_adet, birim_fiyat or None)
        )
        conn.commit()
        conn.close()
        flash('Malzeme stoka eklendi.', 'success')
        return redirect(url_for('stok'))
    return render_template('stok_ekle.html')

# ---------------------------------------------
# İLETİŞİM
# ---------------------------------------------
@app.route('/iletisim', methods=['GET', 'POST'])
def iletisim():
    if request.method == 'POST':
        ad_soyad = request.form['ad_soyad']
        email    = request.form['email']
        konu     = request.form['konu']
        mesaj    = request.form['mesaj']
        try:
            msg = Message(
                subject=f"[Tarım Takip] {konu} - {ad_soyad}",
                recipients=[os.getenv('MAIL_USERNAME')],
                body=f"Gönderen: {ad_soyad}\nE-posta: {email}\nKonu: {konu}\n\n{mesaj}"
            )
            mail.send(msg)
            flash('Mesajınız başarıyla iletildi, teşekkür ederiz!', 'success')
        except Exception:
            flash('Mesaj gönderilemedi, lütfen daha sonra tekrar deneyin.', 'danger')
        return redirect(url_for('iletisim'))
    return render_template('iletisim.html')


if __name__ == '__main__':
    app.run(debug=True)
