"""cable ordenar <carpeta> [salida]: sirve para cualquier DAW. Copia los audios a <carpeta>_ORDENADA con prefijo de familia + numero,
'?' en los dudosos, todos desde 0 y del mismo largo, y deja una hoja (HTML + CSV) con LUFS, pico, balance y fase de cada uno y de la suma.
Los originales no se tocan."""
import sys, re, time, subprocess, html, csv, tempfile, os
from pathlib import Path
import numpy as np
SR = 22050
FAM = [("BAT", "BATERIA"), ("BAJ", "BAJO"), ("SYN", "SYNTH"), ("GTR", "GUITARRAS"), ("AMB", "AMBIENTES"), ("VOZ", "VOCES"), ("REF", "REFERENCIA")]
PAT = [  # (familia, regex sobre el nombre): el primero que coincide gana
    ("REF", r"\b(ref|referencia|reference|rough|master)\b"),
    ("VOZ", r"\b(vox|voz|vocal|vocals|backing|coro|coros|choir|bv|dbl)\b"),
    ("BAT", r"\b(kick|bombo|snare|redoblante|caja|hat|hh|hihat|tom|toms|oh|overhead|cymbal|crash|ride|drum|drums|bateria|perc|percusion|clap)\b"),
    ("BAJ", r"\b(bass|bajo|sub|808)\b"),
    ("GTR", r"\b(gtr|guitar|guitarra|acoustic|acustica|elec|punteo|rhythm|ukulele|banjo)\b"),
    ("SYN", r"\b(synth|sinte|pad|keys|piano|organ|organo|rhodes|wurli|strings|cuerdas|lead|arp|pluck|teclado)\b"),
    ("AMB", r"\b(amb|room|ambiente|ambience|atmos|fx|sfx|riser|noise|texture)\b"),
]


def leer(f):
    r = subprocess.run(["ffmpeg", "-v", "error", "-i", str(f), "-ac", "2", "-ar", str(SR), "-f", "f32le", "-"], capture_output=True)
    return np.frombuffer(r.stdout, np.float32).reshape(-1, 2)


def medir(x):
    m = x.mean(1)
    HOP = int(SR * .1)
    n = max(len(m) // HOP, 1)
    fr = m[:n * HOP].reshape(n, HOP)
    db = 20 * np.log10(np.sqrt((fr ** 2).mean(1)) + 1e-9)
    act = (db > db.max() - 40) & (db > -80)
    W = 2048
    idx = np.where(act)[0][::3]
    seg = [m[i * HOP:i * HOP + W] for i in idx if i * HOP + W <= len(m)]
    S = np.abs(np.fft.rfft(np.array(seg) * np.hanning(W), axis=1)) if seg else np.ones((1, W // 2 + 1))
    fq = np.fft.rfftfreq(W, 1 / SR)
    tot = S.sum() + 1e-12
    h = int(SR * .01)
    k = max(len(m) // h, 2)
    e = np.sqrt((m[:k * h].reshape(k, h) ** 2).mean(1))
    d = np.diff(np.log(e + 1e-6))
    L, R = x[:, 0], x[:, 1]
    return dict(graves=S[:, fq < 150].sum() / tot, agudos=S[:, fq >= 2500].sum() / tot,
                plan=float(np.mean(np.exp(np.log(S[:, 5:] + 1e-9).mean(1)) / (S[:, 5:].mean(1) + 1e-9))),
                atq=((d > 1.2) & (np.r_[d[1:], 0] < d)).sum() / max(act.sum() * .1, 1),
                ancho=float(np.sqrt(((L - R) ** 2).mean() / (((L + R) ** 2).mean() + 1e-12))))


def por_medicion(me):
    """familia deducida solo del audio: siempre dudosa. Devuelve (familia, motivo)."""
    if me["graves"] > .45 and me["atq"] < 3: return "BAJ", "graves sostenidos"
    if me["graves"] > .45: return "BAT", "graves con golpes"
    if me["atq"] >= 4 and me["agudos"] > .3: return "BAT", "agudos con golpes"
    if me["agudos"] > .5: return "AMB", "agudos sin ritmo"
    if me["ancho"] > .7 and me["plan"] < .15: return "SYN", "ancho y sostenido"
    return "SYN", "sin pistas claras"


def stats(path):
    r = subprocess.run(["ffmpeg", "-nostats", "-i", str(path), "-af", "ebur128=peak=true", "-f", "null", "-"], capture_output=True, text=True).stderr
    lufs = re.findall(r"I:\s+(-?[\d.]+) LUFS", r)
    pk = re.findall(r"Peak:\s+(-?[\d.]+) dBFS", r)
    return (float(lufs[-1]) if lufs else None), (float(pk[-1]) if pk else None)


def balance_fase(x):
    L, R = x[:, 0].astype(np.float64), x[:, 1].astype(np.float64)
    rl, rr = np.sqrt((L ** 2).mean()) + 1e-12, np.sqrt((R ** 2).mean()) + 1e-12
    return float(20 * np.log10(rl / rr)), float((L * R).mean() / (rl * rr))


def main(carpeta, salida=None):
    t0 = time.time()
    src = Path(carpeta).expanduser()
    dst = Path(salida) if salida else src.parent / (src.name + "_ORDENADA")
    ext = {".wav", ".mp3", ".flac", ".aif", ".aiff", ".m4a", ".ogg"}
    fs = sorted(f for f in src.iterdir() if f.suffix.lower() in ext and not f.name.startswith("."))
    if not fs:
        sys.exit("no hay audios en " + str(src))
    dst.mkdir(exist_ok=True)
    filas, largo = [], 0.0
    for f in fs:
        nombre = re.sub(r"[_\-\.\(\)]+", " ", f.stem.lower())
        fam = next((k for k, p in PAT if re.search(p, nombre)), None)
        dudoso, motivo = False, "por el nombre"
        x = leer(f)
        largo = max(largo, len(x) / SR)
        if fam is None:
            fam, motivo = por_medicion(medir(x))
            dudoso = True
        filas.append(dict(f=f, fam=fam, dudoso=dudoso, motivo=motivo, x=x))
    orden = {k: i for i, (k, _) in enumerate(FAM)}
    cont = {}
    for fi in sorted(filas, key=lambda r: (orden[r["fam"]], r["f"].name.lower())):
        cont[fi["fam"]] = cont.get(fi["fam"], 0) + 1
        base = re.sub(r"\s+", " ", fi["f"].stem.replace("_", " ")).strip()
        fi["nuevo"] = f'{fi["fam"]}{"?" if fi["dudoso"] else ""} {cont[fi["fam"]]:02d} - {base}.wav'
    for fi in filas:  # 48 kHz estereo 24 bit, desde 0, todas del mismo largo
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(fi["f"]), "-ar", "48000", "-ac", "2",
                        "-af", f"apad=whole_dur={largo:.3f}", "-c:a", "pcm_s24le", str(dst / fi["nuevo"])], check=True)
    tabla, suma = [], None
    for fi in sorted(filas, key=lambda r: r["nuevo"]):
        lufs, pico = stats(dst / fi["nuevo"])
        bal, cor = balance_fase(fi["x"])
        tabla.append(dict(archivo=fi["nuevo"], original=fi["f"].name, familia=dict(FAM)[fi["fam"]], dudoso="?" if fi["dudoso"] else "",
                          motivo=fi["motivo"], lufs=lufs, pico=pico, balance=round(bal, 1), fase=round(cor, 2)))
        if fi["fam"] != "REF":
            y = fi["x"].astype(np.float64)
            if suma is None:
                suma = y
            else:
                n = max(len(suma), len(y))
                suma = np.pad(suma, ((0, n - len(suma)), (0, 0))) + np.pad(y, ((0, n - len(y)), (0, 0)))
    tmp = Path(tempfile.gettempdir()) / f"cable_suma_{os.getpid()}.wav"
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "f32le", "-ar", str(SR), "-ac", "2", "-i", "-", str(tmp)],
                   input=np.clip(suma, -1, 1).astype(np.float32).tobytes(), check=True)
    lm, pm = stats(tmp)
    bm, cm = balance_fase(suma)
    tmp.unlink()
    with open(dst / "HOJA.csv", "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(tabla[0].keys()))
        w.writeheader()
        w.writerows(tabla)
    segs = round(time.time() - t0, 1)
    rows = "".join(f"<tr><td>{html.escape(r['archivo'])}</td><td>{html.escape(r['original'])}</td><td>{r['familia']}{r['dudoso']} <small>{html.escape(r['motivo'])}</small></td><td>{r['lufs']}</td><td>{r['pico']}</td><td>{r['balance']}</td><td>{r['fase']}</td></tr>" for r in tabla)
    avisos = [f"{r['archivo']}: fase {r['fase']} (posible polaridad invertida)" for r in tabla if r["fase"] < 0] + \
             [f"{r['archivo']}: balance {r['balance']} dB" for r in tabla if abs(r["balance"]) > 3]
    aviso_html = ("<p><b>Avisos:</b><br>" + "<br>".join(map(html.escape, avisos)) + "</p>") if avisos else ""
    page = f"""<!doctype html><meta charset=utf-8><title>Hoja de sesion</title>
<style>body{{font:15px system-ui;margin:32px;color:#222}}table{{border-collapse:collapse}}td,th{{padding:6px 12px;border-bottom:1px solid #ddd;text-align:left}}small{{color:#888}}</style>
<h1>{html.escape(src.name)}</h1>
<p>{len(tabla)} audios, desde 0, {largo:.1f} s cada uno, 48 kHz 24 bit, armado en {segs} s</p>
<p><b>Suma de todo menos la referencia:</b> {lm} LUFS, pico {pm} dBFS, balance {round(bm, 1)} dB, fase {round(cm, 2)}</p>
{aviso_html}
<table><tr><th>Archivo</th><th>Original</th><th>Familia</th><th>LUFS</th><th>Pico dBFS</th><th>Balance L/R dB</th><th>Fase</th></tr>{rows}</table>
<p><small>? = familia deducida por medicion, no por el nombre: revisar. Los originales no se tocaron.</small></p>"""
    (dst / "HOJA.html").write_text(page)
    print(f"{len(tabla)} audios -> {dst}")
    print(f"{sum(1 for r in tabla if r['dudoso'])} dudosos (?), suma {lm} LUFS, fase {round(cm, 2)}, {segs} s")
    print(f"Hoja: {dst / 'HOJA.html'}")


main(*sys.argv[1:3])
