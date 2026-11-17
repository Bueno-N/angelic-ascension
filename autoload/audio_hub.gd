extends Node
## Gerenciador de áudio (autoload): trilha sonora com troca suave entre faixas e um conjunto de vozes para os efeitos.
## Os efeitos chegam por Events (habilidades, mortes, chefes) ou por AudioHub.play(id) direto dos nós de combate.
## Roda mesmo com o jogo em pausa (PROCESS_MODE_ALWAYS) para os cliques do menu e a troca de música.

const VOICES := 16
const FADE_SECONDS := 1.2
const SILENT_DB := -60.0

var played := 0                   # efeitos iniciados (smoke/diagnóstico)
var dropped := 0                  # efeitos descartados pelo limitador ou por falta de voz
var missing: Array = []           # arquivos que não carregaram
var music_track := ""             # faixa pedida (toca se a música estiver ligada)
var _streams: Dictionary = {}
var _voices: Array = []           # AudioStreamPlayer
var _voice_info: Array = []       # [{"priority": int, "start": float}]
var _last: Dictionary = {}
var _mp: Array = []               # 2 players de música (troca suave)
var _active := 0
var _fade := 1.0                  # 0 = começo da troca, 1 = fim
var _last_ms := 0
var _last_stage := -1
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _rng.randomize()
    AudioLogic.apply_buses(GameState.global_settings)
    for i in range(VOICES):
        var p := AudioStreamPlayer.new()
        p.bus = AudioLogic.BUS_SFX
        add_child(p)
        _voices.append(p)
        _voice_info.append({"priority": 0, "start": -100.0})
    for i in range(2):
        var m := AudioStreamPlayer.new()
        m.bus = AudioLogic.BUS_MUSIC
        m.volume_db = SILENT_DB
        add_child(m)
        _mp.append(m)
    _last_ms = Time.get_ticks_msec()
    for id in AudioManifest.SFX.keys():
        _get_sfx(str(id))
    Events.audio_changed.connect(_sync_music)
    Events.stage_changed.connect(_on_stage_changed)
    Events.enemy_died.connect(_on_enemy_died)
    Events.ability_cast.connect(_on_ability_cast)
    Events.boss_warning.connect(_on_boss_warning)

func _now() -> float:
    return float(Time.get_ticks_msec()) / 1000.0

func _get_sfx(id: String) -> AudioStream:
    if _streams.has(id):
        return _streams[id]
    var st = load(AudioLogic.sfx_path(id))
    if st == null:
        missing.append(id)
        push_warning("AudioHub: efeito ausente " + id)
    _streams[id] = st
    return st

## Toca um efeito. pitch = 1.0 normal; jitter = variação aleatória de tom (+-). Devolve true se começou a tocar.
func play(id: String, pitch: float = 1.0, jitter: float = 0.05, extra_db: float = 0.0) -> bool:
    if id == "":
        return false
    if not AudioLogic.allow(_last, id, _now()):
        dropped += 1
        return false
    var st: AudioStream = _get_sfx(id)
    if st == null:
        return false
    var v: int = AudioLogic.pick_voice(_free_or_all(), AudioLogic.priority(id))
    if v < 0:
        dropped += 1
        return false
    var p: AudioStreamPlayer = _voices[v]
    p.stream = st
    p.pitch_scale = maxf(0.3, pitch * (1.0 + _rng.randf_range(-jitter, jitter)))
    p.volume_db = AudioLogic.gain_db(id) + extra_db
    p.play()
    _voice_info[v] = {"priority": AudioLogic.priority(id), "start": _now()}
    played += 1
    return true

## Lista para pick_voice: voz livre vira prioridade -1 (a mais barata de sacrificar).
func _free_or_all() -> Array:
    var out: Array = []
    for i in range(VOICES):
        var p: AudioStreamPlayer = _voices[i]
        out.append({"priority": -1 if not p.playing else int(_voice_info[i]["priority"]), "start": float(_voice_info[i]["start"])})
    return out

# ---------------------------------------------------------------- música
func play_music(track: String) -> void:
    if track == music_track and _is_music_playing():
        return
    music_track = track
    _start_track()

func stop_music() -> void:
    music_track = ""
    for m in _mp:
        m.stop()

func _is_music_playing() -> bool:
    return _mp[_active].playing

func _start_track() -> void:
    if music_track == "" or not OptionsLogic.music_enabled(GameState.global_settings):
        return
    var st = load(AudioLogic.track_path(music_track))
    if st == null:
        missing.append(music_track)
        push_warning("AudioHub: música ausente " + music_track)
        return
    if st is AudioStreamOggVorbis:
        st.loop = true
    var outgoing: AudioStreamPlayer = _mp[_active]
    _active = 1 - _active
    var incoming: AudioStreamPlayer = _mp[_active]
    incoming.stream = st
    incoming.volume_db = SILENT_DB if outgoing.playing else 0.0
    incoming.play()
    _fade = 0.0 if outgoing.playing else 1.0

## Opções mudaram: liga/desliga a música sem perder a faixa atual.
func _sync_music() -> void:
    var on: bool = OptionsLogic.music_enabled(GameState.global_settings)
    if not on:
        for m in _mp:
            m.stop()
    elif music_track != "" and not _is_music_playing():
        _start_track()

func _process(_delta: float) -> void:
    var now_ms: int = Time.get_ticks_msec()
    var dt: float = float(now_ms - _last_ms) / 1000.0   # tempo REAL (a troca suave não depende do 2x nem da pausa)
    _last_ms = now_ms
    if _fade >= 1.0:
        return
    _fade = minf(1.0, _fade + dt / FADE_SECONDS)
    var inc: AudioStreamPlayer = _mp[_active]
    var out: AudioStreamPlayer = _mp[1 - _active]
    inc.volume_db = lerpf(SILENT_DB, 0.0, _fade)
    out.volume_db = lerpf(0.0, SILENT_DB, _fade)
    if _fade >= 1.0:
        out.stop()

# ---------------------------------------------------------------- eventos do jogo
func _on_stage_changed(stage: int) -> void:
    play_music(AudioLogic.music_for(stage))
    if stage != _last_stage and _last_stage != -1:
        play("stage_up", 1.0, 0.0)
    _last_stage = stage

func _on_enemy_died(_pos: Vector2, def: Dictionary, is_boss: bool, _gold: int) -> void:
    var id := AudioLogic.death_sfx(def, is_boss)
    if id != "":
        play(id, 1.0, 0.08)

func _on_ability_cast(ability_id: String) -> void:
    play(AudioLogic.ability_sfx(ability_id), 1.0, 0.03)

func _on_boss_warning(_boss_name: String, is_mini: bool) -> void:
    play("mini_roar" if is_mini else "boss_roar", 1.0, 0.0)

## Para o smoke do CI: toca TODOS os efeitos e as 4 músicas (falha de carregamento aparece em `missing`).
func debug_play_all() -> void:
    for id in AudioManifest.SFX.keys():
        _last.erase(id)
        play(str(id), 1.0, 0.0)
    for t in AudioLogic.all_tracks():
        play_music(str(t))
