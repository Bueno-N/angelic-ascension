extends TestCase
## Arte de cenário (assets/env): fundo da arena, tochas/braseiros animados e fogueiras.

func test_background_exists_and_fills_16_9() -> void:
    var bg: Texture2D = EnvArt.background()
    check(bg != null, "fundo da arena carrega")
    if bg != null:
        var ratio: float = float(bg.get_width()) / float(bg.get_height())
        check(absf(ratio - 16.0 / 9.0) < 0.03, "fundo em 16:9 (não distorce na tela 1280x720)")

func test_strips_split_into_equal_frames() -> void:
    for name in EnvArt.STRIPS:
        var sf: SpriteFrames = EnvArt.frames(name)
        check(sf != null, "tira %s carrega" % name)
        if sf == null:
            continue
        var n: int = int(EnvArt.STRIPS[name]["frames"])
        check(sf.get_frame_count("default") == n, "%s tem %d quadros" % [name, n])
        var tex: Texture2D = EnvArt.texture(name + ".png")
        check(tex.get_width() % n == 0, "%s: largura divide exatamente em %d quadros" % [name, n])

func test_ground_fires_and_sprite_anchor() -> void:
    for i in range(EnvArt.GROUND_FIRES):
        check(EnvArt.texture("ground_fire_%d.png" % i) != null, "fogueira %d" % i)
    var s := EnvArt.make("brazier", 100.0)
    var h: float = float(s.sprite_frames.get_frame_texture("default", 0).get_height()) * s.scale.y
    check(absf(h - 100.0) < 0.5, "braseiro com a altura pedida na tela")
    check(not s.centered and s.offset.y < 0.0, "base do braseiro no ponto de posição")
    s.free()
