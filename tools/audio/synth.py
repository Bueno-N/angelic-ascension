"""Primitivas de síntese (numpy/scipy) para os efeitos sonoros e as músicas. Tudo ORIGINAL (CC0): nenhum áudio de terceiros."""
import numpy as np
from scipy import signal

def tarr(n, sr): return np.arange(n) / sr

def lp(x, fc, sr, order=2):
    fc = min(fc, sr * 0.45)
    return signal.sosfilt(signal.butter(order, fc, 'low', fs=sr, output='sos'), x)

def hp(x, fc, sr, order=2):
    return signal.sosfilt(signal.butter(order, fc, 'high', fs=sr, output='sos'), x)

def bp(x, f1, f2, sr, order=2):
    f2 = min(f2, sr * 0.45)
    return signal.sosfilt(signal.butter(order, [f1, f2], 'band', fs=sr, output='sos'), x)

def noise(n, rng):
    return rng.uniform(-1, 1, n)

def phase(f, sr):
    """fase acumulada para uma frequência (escalar ou vetor)"""
    return np.cumsum(f) / sr if np.ndim(f) else None

def osc(kind, f, n, sr, vib=0.0, vib_hz=5.5):
    t = tarr(n, sr)
    ff = (np.full(n, float(f)) if np.ndim(f) == 0 else np.asarray(f, float))
    if vib:
        ff = ff * (1.0 + vib * np.sin(2 * np.pi * vib_hz * t))
    ph = np.cumsum(ff) / sr
    if kind == 'sine': return np.sin(2 * np.pi * ph)
    if kind == 'saw': return 2.0 * (ph % 1.0) - 1.0
    if kind == 'square': return np.where((ph % 1.0) < 0.5, 1.0, -1.0)
    if kind == 'tri': return 2.0 * np.abs(2.0 * (ph % 1.0) - 1.0) - 1.0
    raise ValueError(kind)

def sweep(f0, f1, n, curve=2.0):
    u = np.linspace(0, 1, n)
    return f1 + (f0 - f1) * (1 - u) ** curve

def exp_env(n, sr, decay, attack=0.002):
    t = tarr(n, sr)
    e = np.exp(-t * decay)
    a = max(1, int(attack * sr))
    e[:a] *= np.linspace(0, 1, a)
    return e

def adsr(n, sr, a, d, s, r):
    e = np.full(n, float(s))
    na, nd, nr = int(a * sr), int(d * sr), int(r * sr)
    na = min(na, n)
    if na: e[:na] = np.linspace(0, 1, na)
    nd = min(nd, n - na)
    if nd > 0: e[na:na + nd] = np.linspace(1, s, nd)
    if nr > 0 and nr < n:
        e[n - nr:] *= np.linspace(1, 0, nr)
    return e

def reverb(x, sr, secs=1.2, wet=0.25, rng=None, circular=False, damp=3500):
    rng = rng or np.random.default_rng(7)
    m = int(secs * sr)
    ir = rng.uniform(-1, 1, m) * np.exp(-tarr(m, sr) * (6.9 / secs))
    ir = lp(ir, damp, sr, 1)
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    if circular:
        n = len(x)
        irp = np.zeros(n); irp[:min(m, n)] = ir[:n]
        y = np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(irp), n)
    else:
        y = signal.fftconvolve(x, ir)[:len(x) + m // 2]
        x = np.concatenate([x, np.zeros(len(y) - len(x))])
    return x * (1 - wet * 0.5) + y * wet * 1.6

def mixsum(*sigs):
    n = max(len(s) for s in sigs)
    out = np.zeros(n)
    for s in sigs:
        out[:len(s)] += s
    return out

def place(buf, sig, start_s, sr):
    i = int(start_s * sr)
    if i >= len(buf): return
    m = min(len(sig), len(buf) - i)
    buf[i:i + m] += sig[:m]

def norm(x, peak=0.85):
    m = np.max(np.abs(x)) + 1e-9
    return x / m * peak

def fade(x, sr, fin=0.003, fout=0.02):
    x = x.copy()
    a, b = int(fin * sr), int(fout * sr)
    if a > 0: x[:a] *= np.linspace(0, 1, a)
    if b > 0 and b < len(x): x[-b:] *= np.linspace(1, 0, b)
    return x

def soft(x, drive=1.0):
    return np.tanh(x * drive)

def formant_voice(f0, n, sr, formants, rng, vib=0.01, breath=0.05):
    """voz simples: serra filtrada por formantes (vogal)"""
    src = osc('saw', f0, n, sr, vib=vib)
    out = np.zeros(n)
    for (fc, bw, g) in formants:
        out += g * bp(src, max(60, fc - bw / 2), fc + bw / 2, sr, 2)
    out += breath * bp(noise(n, rng), 1500, 6000, sr)
    return out

VOW_A = [(700, 200, 1.0), (1200, 250, 0.6), (2600, 300, 0.25)]
VOW_O = [(450, 150, 1.0), (800, 150, 0.5), (2500, 300, 0.12)]
VOW_U = [(320, 100, 1.0), (700, 150, 0.35), (2400, 300, 0.08)]
