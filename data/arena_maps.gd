class_name ArenaMaps
extends RefCounted
## Mapas desenhados em uma única imagem (assets/env/maps/<id>.png, 2000x1125, de art_source/maps/).
## Coordenadas em PIXELS DA IMAGEM. O mundo é a imagem ampliada por Arena.SCALE.
##   walk  = polígonos onde dá para andar (o chão de cima das plataformas);
##   block = polígonos DENTRO do chão que o anjo não atravessa (torres, muros, poço, cripta, mausoléus...).
## Além disso, a Arena tira automaticamente qualquer ponto de LAVA da área andável (pela cor da imagem).
## Para ajustar: edite os pontos e rode os testes (test_arena confere que nenhum ponto andável é lava).

const MAPS := {
    # Portão do castelo: centro amplo; torres e ruínas na borda; plataformas laterais.
    "gate": {"image": "res://assets/env/maps/gate.png", "start": Vector2(1000, 620),
        "walk": [[Vector2(955, 215), Vector2(1050, 215), Vector2(1085, 245), Vector2(1095, 300), Vector2(1120, 400),
            Vector2(1200, 440), Vector2(1280, 450), Vector2(1320, 420), Vector2(1360, 385), Vector2(1460, 355),
            Vector2(1500, 375), Vector2(1600, 415), Vector2(1645, 465), Vector2(1655, 520), Vector2(1695, 600),
            Vector2(1705, 650), Vector2(1690, 685), Vector2(1640, 740), Vector2(1560, 785), Vector2(1480, 795),
            Vector2(1400, 780), Vector2(1280, 815), Vector2(1220, 850), Vector2(1150, 880), Vector2(1100, 905),
            Vector2(1060, 915), Vector2(940, 915), Vector2(890, 895), Vector2(830, 860), Vector2(760, 835),
            Vector2(700, 825), Vector2(640, 820), Vector2(520, 830), Vector2(450, 815), Vector2(335, 795),
            Vector2(305, 755), Vector2(305, 610), Vector2(335, 565), Vector2(340, 465), Vector2(400, 405),
            Vector2(500, 385), Vector2(565, 395), Vector2(620, 425), Vector2(650, 432), Vector2(800, 412),
            Vector2(845, 372), Vector2(868, 300), Vector2(900, 242)]],
        "block": [
            [Vector2(515, 725), Vector2(695, 725), Vector2(695, 818), Vector2(515, 818)],      # ruínas embaixo à esquerda
            [Vector2(1315, 745), Vector2(1385, 745), Vector2(1385, 840), Vector2(1315, 840)],  # coluna quebrada embaixo à direita
            [Vector2(930, 905), Vector2(1070, 905), Vector2(1070, 1010), Vector2(930, 1010)],  # santuário embaixo
        ]},
    # Forja em cruz: muro em volta, poço de fogo no centro, altar embaixo (fases de chefe).
    "forge": {"image": "res://assets/env/maps/forge.png", "start": Vector2(1000, 640),
        "walk": [[Vector2(865, 140), Vector2(1045, 135), Vector2(1085, 190), Vector2(1150, 218), Vector2(1250, 245),
            Vector2(1525, 250), Vector2(1545, 305), Vector2(1575, 335), Vector2(1735, 432), Vector2(1760, 475),
            Vector2(1765, 695), Vector2(1610, 755), Vector2(1592, 845), Vector2(1340, 865), Vector2(1150, 890),
            Vector2(1135, 955), Vector2(1070, 968), Vector2(855, 960), Vector2(838, 888), Vector2(690, 812),
            Vector2(412, 795), Vector2(402, 692), Vector2(380, 668), Vector2(220, 598), Vector2(222, 442),
            Vector2(372, 392), Vector2(395, 362), Vector2(412, 252), Vector2(700, 238), Vector2(855, 152)]],
        "block": [
            [Vector2(895, 360), Vector2(1095, 360), Vector2(1095, 495), Vector2(895, 495)],    # poço de fogo
            [Vector2(930, 878), Vector2(1070, 878), Vector2(1070, 960), Vector2(930, 960)],    # altar embaixo
            [Vector2(1470, 590), Vector2(1530, 590), Vector2(1530, 690), Vector2(1470, 690)],  # coluna direita
            [Vector2(262, 445), Vector2(318, 445), Vector2(318, 495), Vector2(262, 495)],      # fogueira esquerda
            [Vector2(1672, 645), Vector2(1740, 645), Vector2(1740, 695), Vector2(1672, 695)],  # fogueira direita
            [Vector2(1420, 825), Vector2(1478, 825), Vector2(1478, 865), Vector2(1420, 865)],  # fogueira embaixo
        ]},
    # Cemitério: caminho em volta, cripta no centro, bolsões com túmulos.
    "graveyard": {"image": "res://assets/env/maps/graveyard.png", "start": Vector2(1000, 760),
        "walk": [[Vector2(295, 250), Vector2(660, 252), Vector2(720, 322), Vector2(790, 360), Vector2(910, 350),
            Vector2(895, 150), Vector2(1040, 142), Vector2(1058, 252), Vector2(1048, 355), Vector2(1160, 355),
            Vector2(1210, 290), Vector2(1305, 265), Vector2(1400, 300), Vector2(1580, 330), Vector2(1640, 470),
            Vector2(1600, 525), Vector2(1690, 545), Vector2(1700, 900), Vector2(1600, 912), Vector2(1450, 900),
            Vector2(1240, 900), Vector2(1100, 958), Vector2(1080, 1020), Vector2(950, 1020), Vector2(930, 960),
            Vector2(850, 900), Vector2(600, 890), Vector2(300, 880)]],
        "block": [
            [Vector2(395, 300), Vector2(600, 288), Vector2(655, 360), Vector2(635, 472), Vector2(520, 522), Vector2(405, 472)],   # bolsão de cima (mausoléu)
            [Vector2(355, 640), Vector2(620, 598), Vector2(705, 635), Vector2(745, 780), Vector2(640, 862), Vector2(420, 862), Vector2(348, 780)],  # bolsão de baixo (mausoléu + arco)
            [Vector2(815, 545), Vector2(968, 445), Vector2(1125, 560), Vector2(962, 665)],   # cripta do centro
            [Vector2(1228, 348), Vector2(1345, 348), Vector2(1352, 502), Vector2(1228, 472)],  # arco
            [Vector2(1455, 365), Vector2(1505, 365), Vector2(1505, 455), Vector2(1455, 455)],  # coluna
            [Vector2(1535, 305), Vector2(1625, 305), Vector2(1625, 405), Vector2(1535, 405)],  # pilares com corrente
            [Vector2(1595, 555), Vector2(1655, 555), Vector2(1655, 645), Vector2(1595, 645)],  # coluna
            [Vector2(1295, 755), Vector2(1512, 745), Vector2(1505, 895), Vector2(1295, 885)],  # túmulos embaixo à direita
            [Vector2(1205, 755), Vector2(1265, 755), Vector2(1265, 805), Vector2(1205, 805)],  # lápide
            [Vector2(1585, 685), Vector2(1665, 685), Vector2(1665, 765), Vector2(1585, 765)],  # lápide
            [Vector2(1045, 755), Vector2(1145, 755), Vector2(1145, 875), Vector2(1045, 875)],  # correntes
            [Vector2(735, 415), Vector2(778, 415), Vector2(778, 452), Vector2(735, 452)],    # bloco
        ]},
}

static func ids() -> Array:
    return MAPS.keys()

## Mapa de cada fase: fases de chefe (e o Lucifer) na forja; as outras alternam portão/cemitério a cada 10 fases.
static func for_stage(stage: int, weekly: bool = false) -> String:
    if weekly or StageLogic.is_boss_stage(stage):
        return "forge"
    return "gate" if (floori(float(maxi(stage, 1) - 1) / 10.0) % 2) == 0 else "graveyard"
