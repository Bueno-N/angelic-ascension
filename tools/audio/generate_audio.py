"""Gera TODO o áudio do jogo em assets/audio/ (efeitos .wav e músicas .ogg) e data/audio_manifest.gd.
Uso: python3 tools/audio/generate_audio.py   (precisa de numpy, scipy e ffmpeg; áudio ORIGINAL, CC0)"""
import os, subprocess, sys, wave, json, tempfile
import numpy as np
sys.path.insert(0, os.path.dirname(__file__))
import sfx, music
from synth import norm, fade

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OUT = os.path.join(ROOT, 'assets', 'audio')
os.makedirs(OUT, exist_ok=True)

def write_wav(path, x, sr):
    pcm = (np.clip(x, -1, 1) * 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr)
        w.writeframes(pcm.tobytes())

sfx_info = {}
for name, fn in sfx.SFX.items():
    x = fade(norm(fn(), 0.85), sfx.SR, 0.002, 0.03)
    write_wav(os.path.join(OUT, 'sfx_%s.wav' % name), x, sfx.SR)
    sfx_info[name] = round(len(x) / sfx.SR, 3)

music_info = {}
for name, spec in music.TRACKS.items():
    x = music.build(spec)
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, name + '.wav')
        write_wav(wav, x, music.SR)
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav, '-c:a', 'libvorbis', '-q:a', '3', '-ac', '1',
                        os.path.join(OUT, name + '.ogg')], check=True)
    music_info[name] = round(len(x) / music.SR, 2)

gd = ("class_name AudioManifest\nextends RefCounted\n## GERADO por tools/audio/generate_audio.py. Não edite à mão.\n\n"
      "const SFX := " + json.dumps(sfx_info, indent=1) + "\n\nconst MUSIC := " + json.dumps(music_info, indent=1) + "\n")
open(os.path.join(ROOT, 'data', 'audio_manifest.gd'), 'w').write(gd)
print("efeitos:", len(sfx_info), "| músicas:", len(music_info))
