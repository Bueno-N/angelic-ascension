# Boss Semanal e ranking mundial — como ligar o online

**Estado:** o cliente (`scripts/runtime/online_client.gd`, painel `weekly_panel.gd`) e o SQL (`docs/weekly_ranking.sql`) estão
ESCRITOS, mas **nunca foram executados contra um servidor real** (o ambiente de desenvolvimento não tem rede nem Godot).
Sem configuração o jogo roda em **modo OFFLINE**: a luta, as 4 entradas e a melhor pontuação funcionam localmente; o ranking mundial
aparece como "MODO OFFLINE" e a recompensa semanal é só a de participação.

## Regras do boss semanal
- Libera ao **concluir a fase 50** (recorde > 50). O botão "BOSS SEMANAL" fica no HUD, abaixo de FASES, travado até lá.
- Semana = **segunda 00:00 UTC** até domingo 23:59 UTC. **4 entradas por semana** (gastas ao ENTRAR, mesmo se perder).
- Luta de **2 minutos** contra o **Lucifer**: 4 habilidades (Nova infernal, Raio do abismo, Tempestade infernal, Colheita de almas)
  + **invoca 1 chefe a cada 20 s** (até 4 vivos). Vida = 8x a do chefe da fase 300; dano = 1,2x.
- Acabou o tempo: aparece **"O SEU TEMPO ACABOU"** e volta a partida normal. Se o anjo cai, a luta também acaba (sem a tela de morte comum).
- **Pontuação** = dano causado ao Lucifer (se matar: vida dele + até 25% de bônus pelo tempo que sobrou). Vale o melhor da semana.
- **Prêmios** (resgatados na semana seguinte, pela posição final): ver `WeeklyBoss.REWARD_RANKS` (1º = 600 gemas + 25 fragmentos ... top 500 = 40 gemas + 2;
  depois top 10% = 30 gemas, top 50% = 20, participação = 10). Valores são PALPITE — ajuste em `scripts/logic/weekly_boss.gd`.

## Ligando o ranking (Supabase, grátis)
1. Crie uma conta e um projeto em supabase.com (plano Free).
2. Abra **SQL Editor**, cole todo o `docs/weekly_ranking.sql` e execute.
3. Em **Project Settings → API** copie a **Project URL** e a chave **anon public**.
4. Preencha `URL` e `ANON_KEY` em `data/online_config.gd`. (A chave anon é pública por desenho; a proteção está nas funções SQL.
   NUNCA coloque a chave `service_role` no app.)
5. O export Android precisa da permissão INTERNET (já marcada em `export_presets.cfg`).
6. Teste no celular: abra o painel (deve mostrar o ranking e "ATUALIZAR"), entre na luta, volte ao painel e confira sua posição.

## Limites conhecidos (seja honesto com os jogadores antes de lançar)
- **Pontuação enviada pelo aparelho:** quem alterar o app pode mandar qualquer valor até o teto (1e24). Validar de verdade exigiria simular a luta no servidor.
- Entradas e semana são contadas no servidor (o relógio do celular não ajuda), mas o jogador pode ter várias contas/instalações (o id é anônimo, por instalação/slot).
- Sem login: trocar de aparelho começa um id novo (a pontuação da semana não acompanha).
- Plano gratuito do Supabase pausa projetos inativos por semanas sem uso; para a Play Store, considere um plano pago.
- Política de privacidade: o nome do perfil (até 12 caracteres) é enviado ao servidor; a Play Store exige declarar isso.
