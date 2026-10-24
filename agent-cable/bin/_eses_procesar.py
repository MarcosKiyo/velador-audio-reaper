"""Genera '<voz> - Velador DS.wav': idéntico al original salvo en S (volumen) y estridencia (banda 2-5 kHz)."""
import sys, json, subprocess, numpy as np
from scipy.signal import butter, sosfiltfilt
sys.path.insert(0, __import__("os").path.dirname(__import__("os").path.abspath(__file__))); from _eses_analisis import SR, analizar, curvas
def leer(p):
    raw = subprocess.run(["ffmpeg","-v","error","-i",p,"-f","s32le","-c:a","pcm_s32le","-"],capture_output=True).stdout
    return (np.frombuffer(raw, np.int32).reshape(-1,2).astype(np.float64)/2**31)
res = {}
for src in sys.argv[1:]:
    X = leer(src); m = X.mean(1)
    A = analizar(m); C = curvas(A); t = A["t"]
    ts = np.arange(len(m))/SR
    gs = np.interp(ts, t, C["g_s"]); gh = np.interp(ts, t, C["g_h"])
    gs[np.abs(gs)<0.01] = 0; gh[np.abs(gh)<0.01] = 0
    sos = butter(2, [2000,5000], "bandpass", fs=SR, output="sos")
    Y = X.copy(); act = (gs<0) | (gh<0)
    for c in range(2):
        xb = sosfiltfilt(sos, X[:,c])
        y = (X[:,c] + (10**(gh/20)-1)*xb) * 10**(gs/20)
        Y[act,c] = y[act]
    q = np.clip(np.round(Y*2**23), -2**23, 2**23-1).astype(np.int32)
    out = src[:-4] + " - Velador DS.wav"
    b = np.zeros((q.size,3), np.uint8); v = q.reshape(-1).astype(np.int64) & 0xFFFFFF
    b[:,0]=v&255; b[:,1]=(v>>8)&255; b[:,2]=(v>>16)&255
    subprocess.run(["ffmpeg","-y","-v","error","-f","s24le","-ar",str(SR),"-ac","2","-i","-","-c:a","pcm_s24le",out], input=b.tobytes(), check=True)
    orig = np.round(X*2**23).astype(np.int64)
    res[src.split("/")[-1]] = dict(salida=out.split("/")[-1], S=len(C["ev_s"]), S_bajadas=C["n_s_bajadas"], estridentes=len(C["ev_h"]),
        max_S=float(gs.min()), max_H=float(gh.min()), pct_muestras_tocadas=float(act.mean()*100),
        identico_fuera=bool((q.reshape(-1,2)[~act]==orig[~act]).all()))
print(json.dumps(res, indent=1, ensure_ascii=False))
