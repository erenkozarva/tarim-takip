from flask import Flask, render_template, request, redirect, url_for, flash
from models import get_db
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv('SECRET_KEY')

# ---------------------------------------------
# ANA SAYFA - Dashboard
# ---------------------------------------------
@app.route('/')
def index():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("EXEC sistem_ozeti")
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
    cursor.execute("EXEC tum_ciftciler")
    rows = cursor.fetchall()
    conn.close()
    return render_template('ciftciler.html', ciftciler=rows)

@app.route('/ciftciler/ekle', methods=['GET', 'POST'])
def ciftci_ekle():
    if request.method == 'POST':
        tc_no    = request.form['tc_no']
        ad       = request.form['ad']
        soyad    = request.form['soyad']
        tel_no   = request.form['tel_no']
        dogum_tar= request.form['dogum_tar']
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO ciftciler (tc_no, ad, soyad, tel_no, dogum_tar) VALUES (?,?,?,?,?)",
            tc_no, ad, soyad, tel_no, dogum_tar
        )
        conn.commit()
        conn.close()
        flash('Çiftçi başarıyla eklendi.', 'success')
        return redirect(url_for('ciftciler'))
    return render_template('ciftci_ekle.html')

@app.route('/ciftciler/sil/<int:ciftci_id>')
def ciftci_sil(ciftci_id):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("EXEC ciftci_sil ?", ciftci_id)
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
        SELECT t.tarla_id, c.ad + ' ' + c.soyad AS ciftci_adi,
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
            "INSERT INTO tarlalar (ciftci_id, plaka_kodu, ilce, ada_no, parsel_no, dekar) VALUES (?,?,?,?,?,?)",
            ciftci_id, plaka_kodu, ilce, ada_no, parsel_no, dekar
        )
        conn.commit()
        conn.close()
        flash('Tarla başarıyla eklendi.', 'success')
        return redirect(url_for('tarlalar'))
    cursor.execute("SELECT ciftci_id, ad + ' ' + soyad FROM ciftciler ORDER BY soyad")
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
        SELECT e.islem_id, c.ad + ' ' + c.soyad AS ciftci_adi,
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
def ekim_ekle():
    conn = get_db()
    cursor = conn.cursor()
    if request.method == 'POST':
        tarla_id       = request.form['tarla_id']
        urun_id        = request.form['urun_id']
        ekim_tar       = request.form['ekim_tar']
        tahmini_hasat  = request.form['tahmini_hasat']
        notlar         = request.form['notlar']
        cursor.execute(
            "INSERT INTO ekim_hasat (tarla_id, urun_id, ekim_tar, tahmini_hasat, notlar) VALUES (?,?,?,?,?)",
            tarla_id, urun_id, ekim_tar, tahmini_hasat, notlar
        )
        conn.commit()
        conn.close()
        flash('Ekim kaydı eklendi.', 'success')
        return redirect(url_for('ekim'))
    cursor.execute("""
        SELECT t.tarla_id, c.ad + ' ' + c.soyad + ' - ' + i.il_adi + ' / ' + t.ilce
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
# SATIŞLAR
# ---------------------------------------------
@app.route('/satislar')
def satislar():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("EXEC satis_raporu")
    rows = cursor.fetchall()
    conn.close()
    return render_template('satislar.html', satislar=rows)

# ---------------------------------------------
# STOK
# ---------------------------------------------
@app.route('/stok')
def stok():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("EXEC stok_durumu")
    rows = cursor.fetchall()
    conn.close()
    return render_template('stok.html', stoklar=rows)

if __name__ == '__main__':
    app.run(debug=True)
