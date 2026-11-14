# Gerando a versão final (APK de release)

**Status: preparado, NUNCA executado.** Precisa da SUA chave de assinatura; ninguém além de você deve tê-la.

## 1) Criar a chave (uma única vez, no seu computador)
```bash
keytool -genkeypair -v -keystore angelic-release.keystore -alias angelic \
  -keyalg RSA -keysize 2048 -validity 10000
```
Anote as senhas. **Guarde o arquivo `.keystore` e as senhas em lugar seguro (backup em 2 locais).**
Se perder a chave, não será possível publicar atualizações do mesmo app. Nunca envie o arquivo ao repositório (o `.gitignore` já bloqueia `*.keystore`).

## 2) Cadastrar os secrets no GitHub
Repositório > Settings > Secrets and variables > Actions > New repository secret:

| Secret | Valor |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | saída de `base64 -w0 angelic-release.keystore` (no macOS: `base64 -i angelic-release.keystore`) |
| `ANDROID_KEY_ALIAS` | `angelic` (o alias usado acima) |
| `ANDROID_KEY_PASSWORD` | a senha da chave/keystore |

O workflow usa a mesma senha para keystore e chave (o padrão do `keytool` quando você digita a mesma nas duas perguntas).

## 3) Rodar
Actions > "Gerar APK de release (manual)" > Run workflow > informe `version_name` (ex.: 1.0.0) e `version_code` (inteiro; aumente a cada versão).

O script `tools/ci/build_release.sh`:
1. força `DEBUG_TOOLS := false` (a aba Teste some; em release o `OS.is_debug_build()` já é falso);
2. grava a versão no `export_presets.cfg`;
3. roda importação, **testes** e **smoke** com essa configuração;
4. exporta com `--export-release "Android Release"`;
5. confere com `apksigner` que o APK NÃO foi assinado com a chave de debug.

O artefato final é `AngelicAscension-release-apk`.

## Limitações
- Distribuição por APK direto (sideload). Loja Google Play exige AAB (build com Gradle) e uma taxa única de cadastro de desenvolvedor, que é um custo e portanto fora do escopo "100% gratuito" definido para o projeto.
- O APK de debug do CI usa uma chave de debug recriada a cada execução: para atualizar, desinstale a versão anterior (isso não acontece com o release, que usa sempre a mesma chave).
- Antes de divulgar: teste o APK de release num aparelho real (instalação, abrir, salvar, fechar e reabrir).
