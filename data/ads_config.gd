class_name AdsConfig
extends RefCounted
## Configuração dos anúncios (AdMob). Em DESENVOLVIMENTO só se usam IDs de TESTE do Google (públicos, não rendem nem arriscam a conta).
## Para publicar: crie as unidades no AdMob, cole os IDs REAIS abaixo e ponha USE_REAL_ADS := true.
## Mesmo assim, builds de DEBUG (OS.is_debug_build()) SEMPRE usam os IDs de teste.

# IDs de teste oficiais do Google (https://developers.google.com/admob/android/test-ads)
const TEST_APP_ID_ANDROID := "ca-app-pub-3940256099942544~3347511713"
const TEST_REWARDED_ANDROID := "ca-app-pub-3940256099942544/5224354917"
const TEST_PREFIX := "ca-app-pub-3940256099942544/"

# IDs REAIS (vazios até você criar a conta/unidade no AdMob). O App ID (com "~") é configurado em Project Settings > Admob (ver docs/ADMOB.md);
# o ID da UNIDADE (com "/") é este:
const REAL_REWARDED_ANDROID := ""
const USE_REAL_ADS := false

const PLUGIN_TAG := "v5.1.0"     # versão do plugin que o CI instala (tools/ci/setup_admob.sh)
