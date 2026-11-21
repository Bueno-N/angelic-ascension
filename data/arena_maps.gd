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
    # Cemitério: toda a ilha até a borda de rochas; cada túmulo/mausoléu/arco/coluna é bloqueado (lápides são sólidas).
    "graveyard": {"image": "res://assets/env/maps/graveyard.png", "start": Vector2(1000, 760),
        "walk": [[Vector2(160, 240), Vector2(175, 120), Vector2(300, 92), Vector2(420, 62), Vector2(500, 40), Vector2(625, 40), Vector2(700, 70), Vector2(790, 92), Vector2(815, 130), Vector2(830, 190), Vector2(870, 120), Vector2(950, 96), Vector2(1060, 92), Vector2(1180, 88), Vector2(1300, 110), Vector2(1340, 168), Vector2(1420, 195), Vector2(1500, 142), Vector2(1580, 150), Vector2(1640, 190), Vector2(1690, 250), Vector2(1760, 262), Vector2(1840, 322), Vector2(1880, 420), Vector2(1870, 520), Vector2(1840, 560), Vector2(1830, 700), Vector2(1840, 820), Vector2(1830, 950), Vector2(1800, 1020), Vector2(1650, 1040), Vector2(1400, 1050), Vector2(1240, 1050), Vector2(1100, 1060), Vector2(940, 1045), Vector2(800, 1042), Vector2(600, 1042), Vector2(450, 1050), Vector2(300, 1030), Vector2(220, 1000), Vector2(160, 930), Vector2(150, 800), Vector2(150, 600), Vector2(142, 400)]],
        "block": [
            [Vector2(815, 545), Vector2(968, 445), Vector2(1125, 560), Vector2(962, 665)],   # cripta do centro
            [Vector2(170, 80), Vector2(310, 80), Vector2(310, 245), Vector2(170, 245)],   # mausoléu em cima à esquerda
            [Vector2(350, 90), Vector2(425, 90), Vector2(425, 175), Vector2(350, 175)],   # lápide
            [Vector2(425, 60), Vector2(475, 60), Vector2(475, 125), Vector2(425, 125)],   # lápide
            [Vector2(495, 25), Vector2(630, 25), Vector2(630, 175), Vector2(495, 175)],   # mausoléu em cima
            [Vector2(680, 75), Vector2(745, 75), Vector2(745, 140), Vector2(680, 140)],   # lápide
            [Vector2(440, 295), Vector2(605, 295), Vector2(605, 440), Vector2(440, 440)],   # túmulo no bolsão de cima
            [Vector2(575, 285), Vector2(645, 285), Vector2(645, 375), Vector2(575, 375)],   # lápide no bolsão de cima
            [Vector2(700, 200), Vector2(750, 200), Vector2(750, 285), Vector2(700, 285)],   # lápide
            [Vector2(750, 250), Vector2(785, 250), Vector2(785, 300), Vector2(750, 300)],   # fogo
            [Vector2(785, 235), Vector2(905, 235), Vector2(905, 335), Vector2(785, 335)],   # lápides
            [Vector2(160, 245), Vector2(205, 245), Vector2(205, 305), Vector2(160, 305)],   # lápide
            [Vector2(195, 370), Vector2(255, 370), Vector2(255, 445), Vector2(195, 445)],   # lápide
            [Vector2(195, 515), Vector2(265, 515), Vector2(265, 605), Vector2(195, 605)],   # lápide
            [Vector2(155, 580), Vector2(205, 580), Vector2(205, 655), Vector2(155, 655)],   # lápide
            [Vector2(290, 495), Vector2(355, 495), Vector2(355, 590), Vector2(290, 590)],   # lápides perto da escada
            [Vector2(205, 700), Vector2(255, 700), Vector2(255, 770), Vector2(205, 770)],   # lápide
            [Vector2(150, 795), Vector2(275, 795), Vector2(275, 905), Vector2(150, 905)],   # mausoléu à esquerda
            [Vector2(210, 900), Vector2(270, 900), Vector2(270, 975), Vector2(210, 975)],   # lápide
            [Vector2(275, 915), Vector2(380, 915), Vector2(380, 1010), Vector2(275, 1010)],   # túmulo embaixo à esquerda
            [Vector2(400, 685), Vector2(455, 685), Vector2(455, 765), Vector2(400, 765)],   # lápide no bolsão de baixo
            [Vector2(445, 705), Vector2(615, 705), Vector2(615, 845), Vector2(445, 845)],   # túmulo no bolsão de baixo
            [Vector2(645, 615), Vector2(795, 615), Vector2(795, 785), Vector2(645, 785)],   # arco no bolsão de baixo
            [Vector2(435, 960), Vector2(505, 960), Vector2(505, 1045), Vector2(435, 1045)],   # lápide
            [Vector2(515, 945), Vector2(585, 945), Vector2(585, 1045), Vector2(515, 1045)],   # lápide
            [Vector2(605, 915), Vector2(675, 915), Vector2(675, 1000), Vector2(605, 1000)],   # lápide
            [Vector2(695, 875), Vector2(775, 875), Vector2(775, 955), Vector2(695, 955)],   # lápide
            [Vector2(755, 965), Vector2(805, 965), Vector2(805, 1005), Vector2(755, 1005)],   # túmulo raso
            [Vector2(800, 895), Vector2(955, 895), Vector2(955, 1045), Vector2(800, 1045)],   # correntes e arco embaixo
            [Vector2(735, 415), Vector2(778, 415), Vector2(778, 452), Vector2(735, 452)],   # bloco
            [Vector2(1075, 20), Vector2(1145, 20), Vector2(1145, 120), Vector2(1075, 120)],   # lápide em cima
            [Vector2(1060, 255), Vector2(1105, 255), Vector2(1105, 310), Vector2(1060, 310)],   # lápide
            [Vector2(1105, 290), Vector2(1160, 290), Vector2(1160, 345), Vector2(1105, 345)],   # lápide
            [Vector2(1160, 110), Vector2(1285, 110), Vector2(1285, 250), Vector2(1160, 250)],   # mausoléu em cima
            [Vector2(1235, 190), Vector2(1325, 190), Vector2(1325, 275), Vector2(1235, 275)],   # lápides
            [Vector2(1230, 345), Vector2(1370, 345), Vector2(1370, 505), Vector2(1230, 505)],   # arco
            [Vector2(1450, 360), Vector2(1510, 360), Vector2(1510, 455), Vector2(1450, 455)],   # coluna
            [Vector2(1540, 230), Vector2(1665, 230), Vector2(1665, 425), Vector2(1540, 425)],   # obelisco e correntes
            [Vector2(1420, 135), Vector2(1570, 135), Vector2(1570, 285), Vector2(1420, 285)],   # mausoléu
            [Vector2(1640, 270), Vector2(1870, 270), Vector2(1870, 540), Vector2(1640, 540)],   # mausoléu grande
            [Vector2(1700, 500), Vector2(1760, 500), Vector2(1760, 570), Vector2(1700, 570)],   # lápide
            [Vector2(1775, 525), Vector2(1825, 525), Vector2(1825, 595), Vector2(1775, 595)],   # lápide
            [Vector2(1595, 555), Vector2(1665, 555), Vector2(1665, 650), Vector2(1595, 650)],   # coluna
            [Vector2(1580, 680), Vector2(1665, 680), Vector2(1665, 770), Vector2(1580, 770)],   # lápides
            [Vector2(1690, 725), Vector2(1810, 725), Vector2(1810, 870), Vector2(1690, 870)],   # mausoléu à direita
            [Vector2(1045, 755), Vector2(1150, 755), Vector2(1150, 875), Vector2(1045, 875)],   # correntes
            [Vector2(1205, 755), Vector2(1265, 755), Vector2(1265, 810), Vector2(1205, 810)],   # lápide
            [Vector2(1290, 775), Vector2(1510, 775), Vector2(1510, 905), Vector2(1290, 905)],   # túmulos embaixo à direita
            [Vector2(1440, 740), Vector2(1495, 740), Vector2(1495, 800), Vector2(1440, 800)],   # lápide
            [Vector2(1085, 895), Vector2(1245, 895), Vector2(1245, 1045), Vector2(1085, 1045)],   # arco embaixo
            [Vector2(1375, 955), Vector2(1450, 955), Vector2(1450, 1035), Vector2(1375, 1035)],   # lápides embaixo
            [Vector2(1480, 960), Vector2(1600, 960), Vector2(1600, 1050), Vector2(1480, 1050)],   # lápides embaixo
            [Vector2(1660, 915), Vector2(1800, 915), Vector2(1800, 1040), Vector2(1660, 1040)],   # mausoléu embaixo à direita
        ]},
}

static func ids() -> Array:
    return MAPS.keys()

## Mapa de cada fase: fases de chefe (e o Lucifer) na forja; as outras alternam portão/cemitério a cada 10 fases.
static func for_stage(stage: int, weekly: bool = false) -> String:
    if weekly or StageLogic.is_boss_stage(stage):
        return "forge"
    return "gate" if (floori(float(maxi(stage, 1) - 1) / 10.0) % 2) == 0 else "graveyard"
