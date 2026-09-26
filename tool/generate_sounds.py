"""Uyku seslerini üretir: beyaz, pembe, kahverengi gürültü ve yağmur.

Çalıştırma (proje kökünden):  python tool/generate_sounds.py
Çıktı: assets/sounds/*.wav — 22,05 kHz, mono, 16 bit.

Sesler frekans uzayında sentezlenir; ters FFT dairesel olduğu için dosyanın
sonu başına dikişsiz bağlanır ve döngüde tık sesi duyulmaz. Aynı tohumla her
çalıştırmada aynı dosyalar üretilir.
"""

import os
import wave

import numpy as np

RATE = 22050
SECONDS = 24
N = RATE * SECONDS
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')

rng = np.random.default_rng(20260926)


def shaped_noise(exponent, low_cut=0.0, band=None):
    """Genliği f^(-exponent/2) olan dairesel gürültü (güç ~ 1/f^exponent)."""
    spectrum = rng.normal(size=N // 2 + 1) + 1j * rng.normal(size=N // 2 + 1)
    freqs = np.fft.rfftfreq(N, 1 / RATE)
    gain = np.ones_like(freqs)
    nz = freqs > 0
    gain[nz] = freqs[nz] ** (-exponent / 2)
    gain[~nz] = 0
    if low_cut:
        gain *= 1 / np.sqrt(1 + (low_cut / np.maximum(freqs, 1e-9)) ** 4)
    if band:
        lo, hi = band
        gain *= 1 / np.sqrt(1 + (lo / np.maximum(freqs, 1e-9)) ** 2)
        gain *= 1 / np.sqrt(1 + (freqs / hi) ** 4)
    return np.fft.irfft(spectrum * gain, n=N)


def normalize(x, peak_db=-6.0, rms_db=-20.0):
    """RMS'i hedefe getirir, tepeyi sınırlar."""
    x = x - x.mean()
    x = x * (10 ** (rms_db / 20) / np.sqrt(np.mean(x**2)))
    peak = 10 ** (peak_db / 20)
    return np.tanh(x / peak) * peak


def rain():
    # Zemin: yüksek frekans ağırlıklı yumuşak şırıltı.
    bed = shaped_noise(0.6, band=(400, 7000))
    # Yavaş yoğunluk dalgalanması (dairesel: tam sayıda periyot).
    t = np.arange(N) / N
    swell = 1 + 0.15 * np.sin(2 * np.pi * 3 * t) + 0.08 * np.sin(2 * np.pi * 7 * t + 1)
    bed *= swell
    # Damlalar: kısa, sönümlenen, filtreli gürültü patlamaları.
    drops = np.zeros(N)
    count = SECONDS * 55
    for _ in range(count):
        start = rng.integers(0, N)
        length = int(RATE * rng.uniform(0.004, 0.02))
        env = np.exp(-np.linspace(0, 6, length))
        burst = rng.normal(size=length) * env * rng.uniform(0.2, 1.0)
        idx = (start + np.arange(length)) % N
        drops[idx] += burst
    # Damlaları yumuşat: basit hareketli ortalama ile tizliği törpüle.
    kernel = np.ones(3) / 3
    drops = np.convolve(np.concatenate([drops[-2:], drops]), kernel, 'valid')[:N]
    bed = bed / np.sqrt(np.mean(bed**2))
    drops = drops / np.sqrt(np.mean(drops**2))
    return bed + 0.35 * drops


def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    data = (np.clip(samples, -1, 1) * 32767).astype('<i2')
    path = os.path.join(OUT, f'{name}.wav')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    print(path, f'{os.path.getsize(path) / 1024:.0f} KB')


if __name__ == '__main__':
    write('white', normalize(shaped_noise(0.0), rms_db=-24))
    write('pink', normalize(shaped_noise(1.0, low_cut=20), rms_db=-20))
    write('brown', normalize(shaped_noise(2.0, low_cut=25), rms_db=-18))
    write('rain', normalize(rain(), rms_db=-20))
