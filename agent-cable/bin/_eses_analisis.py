"""Velador de-esser por automatización: detecta S (sibilantes) y estridencia (2-5 kHz) en una voz
y calcula la curva de reducción. Sin procesar el original: devuelve eventos + curvas."""
import sys, json, subprocess, numpy as np
from scipy.signal import stft, butter, sosfiltfilt
SR = 48000
N, HOP = 1024, 128            # ventana 21 ms, paso 2,7 ms

def cargar(p):
    raw = subprocess.run(["ffmpeg","-v","error","-i",p,"-ac","1","-ar",str(SR),"-f","f32le","-"],capture_output=True).stdout
    return np.frombuffer(raw, np.float32).astype(np.float64)

def banda(P, f, lo, hi): return P[(f>=lo)&(f<hi)].sum(0) + 1e-20

def periodicidad(x, hop, n):
    """máximo de la autocorrelación normalizada en 70-800 Hz (1 = tono, 0 = ruido)"""
    sos = butter(4, [60, 1200], "bandpass", fs=SR, output="sos"); y = sosfiltfilt(sos, x)
    idx = np.arange(0, len(x)-n, hop); lags = slice(SR//800, SR//70); out = []
    for c in range(0, len(idx), 4000):
        W = np.stack([y[i:i+n] for i in idx[c:c+4000]]) * np.hanning(n)
        R = np.fft.irfft(np.abs(np.fft.rfft(W, 2*n))**2)[:, :n]
        out.append(np.where(R[:,0]>1e-12, R[:,lags].max(1)/np.maximum(R[:,0],1e-12), 0))
    return np.concatenate(out)

def analizar(x):
    f, t, Z = stft(x, SR, nperseg=N, noverlap=N-HOP, boundary=None, padded=False)
    P = np.abs(Z)**2
    tot = 10*np.log10(banda(P,f,80,16000))
    sib = 10*np.log10(banda(P,f,4500,12000))
    cuerpo = 10*np.log10(banda(P,f,200,2000))
    estr = 10*np.log10(banda(P,f,2000,5000))
    per = periodicidad(x, HOP, N)[:len(t)]
    t = t[:len(per)]; tot, sib, cuerpo, estr = tot[:len(per)], sib[:len(per)], cuerpo[:len(per)], estr[:len(per)]
    activo = tot > np.percentile(tot, 95) - 40          # gate: 40 dB bajo el pico de la toma
    sonora = activo & (per > 0.55)
    # nivel de referencia local = mediana de la voz sonora en ±0,5 s
    k = int(0.5*SR/HOP); ref = np.full_like(tot, np.nan)
    for i in range(len(tot)):
        a, b = max(0,i-k), min(len(tot),i+k); v = tot[a:b][sonora[a:b]]
        if len(v) > 10: ref[i] = np.median(v)
    ref = np.where(np.isnan(ref), np.nanmedian(ref), ref)
    # S: sorda, energía arriba de 4,5 kHz domina a 200-2k
    es_s = activo & (per < 0.45) & (sib - cuerpo > 3)
    exceso_s = sib - ref                                   # nivel de la S contra la voz que la rodea
    # estridencia: voz sonora con 2-5 kHz alto contra su propio cuerpo
    from scipy.ndimage import median_filter, binary_dilation
    H = median_filter(estr - cuerpo, size=int(0.025*SR/HOP))          # 25 ms, ignora transitorios
    cerca_s = binary_dilation(es_s, iterations=int(0.04*SR/HOP))      # ±40 ms de una S no es estridencia
    sonora = sonora & ~cerca_s & (sib - cuerpo < -3) & (tot > ref - 6)   # colas de frase no cuentan
    return dict(t=t, f=f, P=P, tot=tot, sib=sib, ref=ref, per=per, H=H, es_s=es_s, sonora=sonora, exceso_s=exceso_s)

def eventos(mask, t, min_ms=20, gap_ms=12):
    ev=[]; i=0; n=len(mask)
    while i<n:
        if mask[i]:
            j=i
            while j<n and mask[j]: j+=1
            ev.append([i,j]); i=j
        else: i+=1
    m=[]
    for a,b in ev:
        if m and (t[a]-t[m[-1][1]-1])*1000 < gap_ms: m[-1][1]=b
        else: m.append([a,b])
    return [e for e in m if (t[e[1]-1]-t[e[0]])*1000 >= min_ms]

def curvas(A, tope_s=8.0, tope_h=5.0):
    t = A["t"]; g_s = np.zeros_like(t); g_h = np.zeros_like(t)
    ev_s = eventos(A["es_s"], t, min_ms=25, gap_ms=70)
    pico = np.array([A["exceso_s"][a:b].max() for a,b in ev_s]) if ev_s else np.array([])
    meta_s = float(np.percentile(pico, 40)) - 1.0 if len(pico) else 0   # S típica (p40) menos 1 dB
    for (a,b),p in zip(ev_s,pico):
        red = min(tope_s, max(0, p-meta_s))
        if red >= 1.0: g_s[a:b] = -red
    son = A["sonora"]; meta_h = float(np.percentile(A["H"][son], 85))
    exc = np.where(son, A["H"]-meta_h, 0)
    ev_h = eventos(exc > 1.0, t, min_ms=40, gap_ms=25)
    for a,b in ev_h: g_h[a:b] = -np.clip(exc[a:b], 0, tope_h)
    # rampas 3 ms entrada / 8 ms salida, sin clicks
    def suavizar(g, at=3, rl=8):
        ka = np.exp(-1/max(1,at/1000*SR/HOP)); kr = np.exp(-1/max(1,rl/1000*SR/HOP))
        o = g.copy()
        for i in range(1,len(o)): o[i] = min(o[i], o[i-1]*kr)          # release
        for i in range(len(o)-2,-1,-1): o[i] = min(o[i], o[i+1]*ka)    # lookahead / ataque
        return o
    from scipy.ndimage import minimum_filter1d
    g_h = minimum_filter1d(g_h, int(0.02*SR/HOP))   # sostiene 20 ms: sin serrucho
    return dict(g_s=suavizar(g_s), g_h=suavizar(g_h, 5, 25), meta_s=meta_s, meta_h=meta_h, ev_s=ev_s, ev_h=ev_h,
                n_s_bajadas=int(sum(1 for (a,b),p in zip(ev_s,pico) if p-meta_s>=1)))

