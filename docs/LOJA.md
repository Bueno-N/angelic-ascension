# Loja paga (Google Play Billing)

**Status:** código pronto e testado no PC (lógica, aba Loja e compra SIMULADA em build de debug).
A cobrança real **nunca foi executada num aparelho**: falta o plugin e a configuração no Play Console (abaixo).

## O que existe no jogo
- Aba **Loja** (primeira do MENU, ícone de baú). Preço mostrado = o que o Google Play devolver
  (na moeda do jogador). Sem resposta do Google, mostra o preço de referência abaixo.
- `scripts/logic/shop_logic.gd`: catálogo, regras e entrega (testes em `tests/test_shop.gd`).
- `autoload/shop_manager.gd`: conversa com o plugin. Sem o plugin fica inerte. Em **debug** sem a loja do Google,
  as compras são **simuladas** (sem cobrança) para testar.
- Proteção contra entrega dupla: cada compra tem um token. Os já entregues ficam em `user://iap_ledger.json`
  (vale para os 2 espaços de jogo). Compra paga com o app fechado no meio é entregue na próxima abertura.
- As gemas/ouro vão para o jogo **aberto** no momento (se estiver no menu inicial, espera entrar num jogo).

## Produtos (criar EXATAMENTE com estes IDs)
Play Console > seu app > **Monetizar > Produtos > Produtos no app** > Criar produto:

| ID do produto | Conteúdo | Preço (BRL) | Tipo no jogo |
|---|---|---|---|
| `gems_5000` | 5.000 gemas | R$ 2,99 | consumível |
| `gems_10000` | 10.000 gemas | R$ 5,00 | consumível |
| `gems_25000` | 25.000 gemas | R$ 13,99 | consumível |
| `pack_legend_50000` | 50.000 gemas (Pacote Lendário) | R$ 10,00 | **compra única** (só libera depois da fase 50) |
| `gold_50000` | 50.000 de ouro | R$ 0,99 | consumível |
| `gold_100000` | 100.000 de ouro | R$ 1,79 | consumível |
| `gold_250000` | 250.000 de ouro | R$ 3,99 | consumível |

O Play Console não tem um campo "consumível": quem decide é o jogo (consome os pacotes comuns e só
*confirma* o Lendário, que fica para sempre na conta, e por isso o Google não deixa comprar de novo).
Para mudar preço, mude no Play Console. Se mudar quantidade/ID, mude também `ShopLogic.CATALOG`.

## Passo a passo
1. **Plugin**: baixe a última versão em github.com/godot-sdk-integrations/godot-google-play-billing (Releases),
   copie para `addons/GodotGooglePlayBilling/` e ative em Projeto > Configurações > Plugins.
   O export já usa Gradle (`gradle_build/use_gradle_build=true`).
2. **Conta de comerciante**: Play Console > Configuração > Perfil de pagamentos.
3. **Build**: exporte o **AAB** de release assinado (preset "Android Release" com `gradle_build/export_format=1`)
   e envie para **Teste interno**. Os produtos só podem ser criados depois que um build com billing for enviado.
4. **Produtos**: crie os 7 da tabela e **ative** cada um.
5. **Testadores de licença**: Play Console > Configuração > Teste de licença > adicione seu e-mail.
   Esses e-mails compram com cartões de teste, sem cobrança.
6. **Instale pela Play Store** (link do teste interno). APK instalado à mão não consegue comprar.
7. Teste: comprar cada pacote, cancelar uma compra, fechar o app no meio de uma compra e reabrir.

## Limites conhecidos
- A validação da compra é feita no aparelho. Com crack é possível burlar; o certo, depois, é validar o token
  num servidor (o projeto já tem o Supabase do ranking) antes de entregar.
- O formato exato dos "detalhes do produto" do plugin não está documentado: o preço é procurado pelas chaves
  `formatted_price`/`formattedPrice`. Se aparecer o preço de referência mesmo pela Play Store, essa leitura precisa de ajuste.
- O ouro é um valor fixo: muito forte no começo, pouco no fim do jogo (o ouro por fase cresce 10% a cada fase).
