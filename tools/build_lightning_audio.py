import math
from pathlib import Path
import random
import struct
import wave

RATE = 44100
OUT = Path(__file__).resolve().parents[1] / 'audio' / 'sfx'

def write(name, duration, charge=False):
    rng = random.Random(73 if charge else 92)
    slow = 0.0
    low = 0.0
    samples = []
    for index in range(int(duration * RATE)):
        t = index / RATE
        noise = rng.uniform(-1.0, 1.0)
        low += 0.055 * (noise - low)
        slow += 0.012 * (noise - slow)
        if charge:
            envelope = min(1.0, t / 0.025) * min(1.0, (duration - t) / 0.04)
            value = envelope * (0.14 * math.sin(2 * math.pi * (180 * t + 650 * t * t)) + 0.12 * noise)
        else:
            snap = noise * math.exp(-t * 65) * 0.65
            crackle = noise * math.exp(-t * 12) * (0.2 + 0.2 * math.sin(t * 280) ** 8)
            rumble = (low * 1.8 + slow * 2.5) * math.exp(-t * 3.4)
            value = (snap + crackle + rumble) * min(1.0, (duration - t) / 0.15)
        samples.append(value)
    peak = max(abs(value) for value in samples)
    gain = min(1.0, 0.85 / peak)
    with wave.open(str(OUT / name), 'wb') as audio:
        audio.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        audio.writeframes(b''.join(struct.pack('<h', round(value * gain * 32767)) for value in samples))
    print(name, 'seconds=', duration, 'peak=', peak * gain)

if __name__ == '__main__':
    write('lightning_gather.wav', 0.23, True)
    write('lightning_thunder.wav', 1.25)
