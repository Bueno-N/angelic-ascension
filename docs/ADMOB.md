# AdMob (anúncios premiados) — integração técnica

**Escopo atual:** só a infraestrutura. NÃO existem ainda as mecânicas (reviver ao morrer, 100 gemas a cada 30 min, 500 gemas por dia):
o `AdsManager` carrega/mostra um anúncio premiado e emite sinais; quem pedir o anúncio decide a recompensa depois.

## Estado real (sem enfeite)
| Item | Estado |
|---|---|
| `autoload/ads_manager.gd`, `scripts/logic/ads_logic.gd`, `data/ads_config.gd`, `tests/test_ads.gd` | escritos; **nunca executados** (nem CI nem aparelho) |
| Plugin AdMob (Poing Studios) **dentro do repositório** | ❌ **não instalado**: o ambiente de desenvolvimento não tem rede para baixar o plugin. O CI instala (workflow manual) ou você instala pelo editor |
| Exportação Android com o plugin | ❌ **não validada** (depende do CI/editor) |
| Anúncio aparecendo no celular | ❌ nada foi visto |
| IDs | só **de teste** do Google; `USE_REAL_ADS = false` |

## Compatibilidade (consultada na documentação oficial)
- Plugin **v5.1.0** (release "Latest"): Godot **4.4+** (um PR cita 4.5); a doc de Android pede **Godot 4.5+**, minSdk 24+, compileSdk 35+, **Android Build Template** e **exportar com Gradle**.
- O projeto está no **Godot 4.5** (ok), mas hoje o APK é exportado **sem** Gradle: o AdMob exige trocar isso (só neste fluxo).

## Como o jogo usa (modular)
- `AdsManager` (autoload) é o único ponto de contato. Ele **não referencia o plugin em compilação**: procura as classes por nome em execução. Sem o plugin (PC, CI normal, APK sem AdMob) fica inerte e o jogo roda igual.
- Nada no jogador, combate, movimento ou interface foi alterado.
- API: `AdsManager.start()` (consentimento UMP + inicialização do SDK; roda sozinho no Android), `load_rewarded()`, `is_rewarded_ready()`, `show_rewarded()`; sinais `sdk_ready`, `rewarded_loaded`, `rewarded_load_failed(msg)`, `rewarded_earned(amount, type)`, `rewarded_dismissed`, `rewarded_show_failed(msg)`.
- IDs: debug **sempre** usa o ID de teste `ca-app-pub-3940256099942544/5224354917`. Release só usa o real se `USE_REAL_ADS = true` e o ID for válido (`data/ads_config.gd`).

## O que depende de você
1. **Rodar o workflow** `AdMob (APK de teste com anúncios)` (Actions > Run workflow). Ele baixa o plugin v5.1.0, habilita, instala o Android Build Template, liga o Gradle e exporta o APK. **Mande o log** se falhar: foi escrito sem poder executar.
2. **App ID** (com `~`): o plugin lê em *Project Settings > General > Admob > General* (Android). Abra o projeto no Godot 4.5, ative o plugin, preencha com o App ID de **teste** `ca-app-pub-3940256099942544~3347511713` e faça commit do `project.godot`. (Sem App ID o app com o plugin costuma fechar ao abrir.)
3. **Conta AdMob real**: criar o app, a unidade **premiada**, colar o ID em `AdsConfig.REAL_REWARDED_ANDROID`, trocar o App ID de teste pelo real e pôr `USE_REAL_ADS := true` só no lançamento.
4. **Consentimento (UMP)**: criar a mensagem em AdMob > Privacidade e mensagens (sem ela o SDK devolve erro de consentimento).
5. **Instalar no celular** o APK do workflow e ver um anúncio de teste (logcat: `adb logcat -s poing-godot-admob godot`).
6. Política de privacidade, Data safety e declaração de anúncios no Play Console (ver conversa anterior).

## Alternativa manual (se preferir o editor)
AssetLib > "AdMob" (Poing Studios) > Download > ativar em Project Settings > Plugins; *Project > Install Android Build Template*; App ID em Project Settings; no export, marcar **Use Gradle Build**. Depois commite `addons/admob`, `android/` e as mudanças de `project.godot`/`export_presets.cfg`. **Atenção:** isso troca o export do fluxo normal (`build.yml`) para Gradle; o CI de build precisará do SDK completo (build-tools 35.0.1 e NDK).
