#!/usr/bin/env python3
"""Procedural audio generator for Chase the Score.

Synthesizes the four 120 BPM music stems (bass/drums/pads/lead — identical
length, loop-safe) and all one-shot fills as WAV, ready for OGG conversion.
All output is original, generated from pure math, and dedicated to the
public domain under CC0 1.0 (see CREDITS.md).

Usage:  python3 generate_audio.py <output_dir>
"""
import math
import os
import sys
import wave

import numpy as np

SR = 44100
BPM = 120.0
BEAT = 60.0 / BPM               # 0.5 s
BAR = 4 * BEAT                  # 2.0 s
LOOP_BARS = 8
LOOP_LEN = int(SR * BAR * LOOP_BARS)  # exactly 705600 samples = 16 s

rng = np.random.default_rng(20260719)


# ----------------------------------------------------------------- helpers

def t(n):
    return np.arange(n) / SR


def sine(freq, n):
    return np.sin(2 * np.pi * freq * t(n))


def saw(freq, n):
    return 2.0 * ((freq * t(n)) % 1.0) - 1.0


def square(freq, n, duty=0.5):
    return np.where((freq * t(n)) % 1.0 < duty, 1.0, -1.0)


def noise(n):
    return rng.uniform(-1.0, 1.0, n)


def env_decay(n, k=6.0):
    return np.exp(-k * np.linspace(0, 1, n))


def env_ar(n, attack=0.01, release=0.2):
    a = max(1, int(attack * SR))
    r = max(1, int(release * SR))
    e = np.ones(n)
    e[:a] = np.linspace(0, 1, a)
    if r < n:
        e[-r:] = np.minimum(e[-r:], np.linspace(1, 0, r))
    return e


def fft_filter(x, lo=None, hi=None, soft=0.5):
    """Brick-ish band filter via FFT (soft = octaves of rolloff)."""
    spec = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(len(x), 1 / SR)
    gain = np.ones_like(freqs)
    if hi is not None:
        gain *= 1.0 / (1.0 + (freqs / max(hi, 1.0)) ** (2 / max(soft, 0.05)))
    if lo is not None:
        gain *= 1.0 / (1.0 + (max(lo, 1.0) / np.maximum(freqs, 1.0)) ** (2 / max(soft, 0.05)))
    return np.fft.irfft(spec * gain, len(x))


def echo(x, delay_s, fb=0.35, taps=3):
    y = x.copy()
    d = int(delay_s * SR)
    g = fb
    for i in range(1, taps + 1):
        if i * d >= len(x):
            break
        y[i * d:] += g * x[:-i * d]
        g *= fb
    return y


def put(buf, start_s, clip, gain=1.0):
    i = int(start_s * SR)
    j = min(len(buf), i + len(clip))
    if i < len(buf):
        buf[i:j] += clip[:j - i] * gain


def normalize(x, peak=0.85):
    m = np.max(np.abs(x))
    return x * (peak / m) if m > 0 else x


def write_wav(path, x):
    data = (np.clip(x, -1, 1) * 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print(f'  {os.path.basename(path)}  {len(x)/SR:.3f}s')


# ------------------------------------------------------------- note tables

# A minor progression, 2 bars each, with 7th/9th voicings:
# Am9 - Fmaj9 - Cmaj7 - G6/9 (no b7 — a G9's F natural tritones against the key)
ROOTS = [55.00, 43.65, 65.41, 49.00]            # A1 F1 C2 G1
CHORDS = [
    [220.00, 261.63, 329.63, 392.00, 493.88],   # Am9:   A3 C4 E4 G4 B4
    [174.61, 220.00, 261.63, 329.63, 392.00],   # Fmaj9: F3 A3 C4 E4 G4
    [261.63, 329.63, 392.00, 493.88],           # Cmaj7: C4 E4 G4 B4
    [196.00, 246.94, 293.66, 329.63, 440.00],   # G6/9:  G3 B3 D4 E4 A4
]


def chord_at_bar(bar):
    return (bar // 2) % 4


# ------------------------------------------------------------------- stems

def stem_bass():
    buf = np.zeros(LOOP_LEN)
    note_n = int(BEAT / 2 * SR)                 # eighth notes
    for bar in range(LOOP_BARS):
        root = ROOTS[chord_at_bar(bar)]
        for e in range(8):                      # 8 eighths per bar
            freq = root * (2.0 if e in (3, 7) else 1.0)
            clip = (0.6 * square(freq, note_n) + 0.4 * saw(freq, note_n))
            clip = fft_filter(clip, hi=220) * env_decay(note_n, 5.0)
            put(buf, bar * BAR + e * BEAT / 2, clip)
    return normalize(buf)


def stem_drums():
    buf = np.zeros(LOOP_LEN)
    kick_n = int(0.16 * SR)
    kick = sine(np.linspace(150, 40, kick_n), kick_n)  # freq array trick
    kick = np.sin(2 * np.pi * np.cumsum(np.linspace(150, 40, kick_n)) / SR)
    kick *= env_decay(kick_n, 9.0)
    snare_n = int(0.14 * SR)
    snare = (0.7 * fft_filter(noise(snare_n), lo=900, hi=6000)
             + 0.3 * sine(185, snare_n)) * env_decay(snare_n, 11.0)
    hat_n = int(0.05 * SR)
    for bar in range(LOOP_BARS):
        for beat in range(4):
            put(buf, bar * BAR + beat * BEAT, kick, 1.0)
            if beat in (1, 3):
                put(buf, bar * BAR + beat * BEAT, snare, 0.8)
        for e in range(8):
            hat = fft_filter(noise(hat_n), lo=6000) * env_decay(hat_n, 14.0)
            put(buf, bar * BAR + e * BEAT / 2, hat, 0.35 if e % 2 else 0.5)
    return normalize(buf)


def stem_pads():
    buf = np.zeros(LOOP_LEN)
    seg_n = int(2 * BAR * SR)
    for seg in range(LOOP_BARS // 2):
        chord = CHORDS[seg % 4]
        clip = np.zeros(seg_n)
        for f in chord:
            clip += saw(f * 0.999, seg_n) + saw(f * 1.001, seg_n)
        clip = fft_filter(clip, hi=1500) * env_ar(seg_n, attack=0.4, release=0.6)
        put(buf, seg * 2 * BAR, clip)
    return normalize(buf, 0.7)


def stem_lead():
    buf = np.zeros(LOOP_LEN)
    step_n = int(BEAT / 4 * SR)                 # sixteenth notes
    # Indices reach into the 7th/9th extensions (wrapped per chord size).
    pattern = [0, 2, 4, 5, 4, 2, 1, 3, 5, 3, 2, 4, 0, 3, 4, 2]
    for bar in range(LOOP_BARS):
        chord = CHORDS[chord_at_bar(bar)]
        tones = chord + [chord[0] * 2.0]        # voicing + octave root
        for s in range(16):
            freq = tones[pattern[s] % len(tones)]
            clip = square(freq, step_n, duty=0.3) * env_decay(step_n, 7.0)
            put(buf, bar * BAR + s * BEAT / 4, clip, 0.9 if s % 4 == 0 else 0.65)
    buf = echo(buf, BEAT * 0.75, fb=0.3)
    return normalize(fft_filter(buf, hi=6500), 0.75)


# ------------------------------------------------------------------- fills

def blip(freqs, each=0.09, wave_fn=square, k=7.0):
    parts = []
    for f in freqs:
        n = int(each * SR)
        parts.append(wave_fn(f, n) * env_decay(n, k))
    return normalize(np.concatenate(parts))


def make_fills():
    f = {}
    # weapon fire
    f['fire_pitch'] = blip([880, 660], 0.055, k=9)
    n = int(0.09 * SR)
    f['fire_tempo'] = normalize(
        (0.6 * square(520, n) + 0.4 * fft_filter(noise(n), lo=2000)) * env_decay(n, 12))
    n = int(0.28 * SR)
    f['fire_forte'] = normalize(
        (0.7 * fft_filter(noise(n), hi=1400) + 0.5 * sine(75, n)) * env_decay(n, 8))
    n = int(0.4 * SR)
    sweep = np.sin(2 * np.pi * np.cumsum(np.linspace(320, 60, n)) / SR)
    f['fire_chord'] = normalize(
        (0.6 * sweep + 0.4 * fft_filter(noise(n), hi=900)) * env_decay(n, 5))
    n = int(0.22 * SR)
    vib = np.sin(2 * np.pi * np.cumsum(440 * (1 + 0.02 * sine(9, n))) / SR)
    f['fire_rest'] = normalize(vib * env_ar(n, 0.02, 0.15), 0.7)
    # movement / events
    f['slash'] = normalize(
        fft_filter(noise(int(0.16 * SR)), lo=700, hi=5200) * env_decay(int(0.16 * SR), 9))
    f['double_jump'] = blip([660, 990], 0.08, k=6)
    n = int(0.6 * SR)
    drop = np.sin(2 * np.pi * np.cumsum(np.linspace(110, 34, n)) / SR)
    f['bass_drop'] = normalize(np.tanh(2.2 * drop) * env_decay(n, 3.5))
    n = int(0.5 * SR)
    riser = np.sin(2 * np.pi * np.cumsum(np.linspace(180, 980, n)) / SR)
    f['meteor'] = normalize(
        (0.6 * riser + 0.5 * fft_filter(noise(n), lo=np.clip(1200, None, None))) *
        env_ar(n, 0.05, 0.1))
    steps = [2093, 1568, 2637, 1175, 3136, 1319, 2489, 988]
    f['grapple'] = blip(steps, 0.028, k=10)
    n = int(0.45 * SR)
    chord = sum(sine(fr, n) for fr in (220.0, 261.63, 329.63, 493.88))
    f['shield'] = normalize(fft_filter(chord, hi=2500) * env_ar(n, 0.05, 0.3), 0.7)
    n = int(0.2 * SR)
    down = np.sin(2 * np.pi * np.cumsum(np.linspace(660, 210, n)) / SR)
    f['kill'] = normalize(
        (0.7 * np.sign(down) + 0.3 * fft_filter(noise(n), lo=1500)) * env_decay(n, 8))
    n = int(0.16 * SR)
    f['hit'] = normalize(
        (0.6 * square(110, n) + 0.5 * noise(n)) * env_decay(n, 10))
    f['pickup'] = blip([1047, 1319], 0.07, k=6)
    n = int(0.9 * SR)
    gliss = np.sin(2 * np.pi * np.cumsum(np.geomspace(440, 110, n)) / SR)
    f['death'] = normalize(
        (0.7 * gliss + 0.25 * fft_filter(noise(n), hi=800)) * env_decay(n, 3))
    return f


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else '.'
    os.makedirs(out, exist_ok=True)
    print('stems (must all be identical length):')
    write_wav(os.path.join(out, 'bass_loop.wav'), stem_bass())
    write_wav(os.path.join(out, 'drums_loop.wav'), stem_drums())
    write_wav(os.path.join(out, 'pads_loop.wav'), stem_pads())
    write_wav(os.path.join(out, 'lead_loop.wav'), stem_lead())
    print('fills:')
    for name, clip in make_fills().items():
        write_wav(os.path.join(out, f'fill_{name}.wav'), clip)


if __name__ == '__main__':
    main()
