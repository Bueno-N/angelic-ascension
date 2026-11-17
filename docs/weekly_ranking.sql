-- Ranking mundial do BOSS SEMANAL (Lucifer) — Supabase (plano gratuito). Rode TUDO no "SQL Editor" do projeto, uma vez.
-- Segurança: a tabela fica TRAVADA (RLS ligado, sem políticas): o app só consegue chamar as 3 funções abaixo com a chave "anon".
-- A semana é calculada AQUI (segunda 00:00 UTC), então mudar o relógio do celular não dá entradas extras.
-- LIMITE CONHECIDO: a pontuação é enviada pelo aparelho (não há servidor de jogo); o teto abaixo só barra valores absurdos.
-- Para trapaça séria seria preciso validar a luta no servidor (fora do escopo da primeira versão).

create table if not exists weekly_scores (
  week       int              not null,
  player     uuid             not null,
  name       text             not null default 'ANJO',
  score      double precision not null default 0,
  attempts   int              not null default 0,
  updated_at timestamptz      not null default now(),
  primary key (week, player)
);
create index if not exists weekly_scores_rank on weekly_scores (week, score desc);
alter table weekly_scores enable row level security;   -- sem políticas: ninguém lê/escreve direto

-- Semana atual: contada a partir de segunda-feira 00:00 UTC (a época Unix caiu numa quinta: +4 dias).
create or replace function current_week() returns int language sql stable as $$
  select floor((extract(epoch from now()) - 4 * 86400) / 604800)::int
$$;

-- Gasta 1 entrada (máx. p_max por semana). Devolve {ok, attempts, week}.
create or replace function start_attempt(p_player uuid, p_name text, p_max int default 4)
returns json language plpgsql security definer set search_path = public as $$
declare w int := current_week(); a int;
begin
  p_max := least(greatest(coalesce(p_max, 4), 1), 4);                 -- o servidor é quem manda: nunca mais que 4
  insert into weekly_scores (week, player, name) values (w, p_player, left(coalesce(nullif(trim(p_name), ''), 'ANJO'), 12))
    on conflict (week, player) do update set name = excluded.name;
  update weekly_scores set attempts = attempts + 1, updated_at = now()
    where week = w and player = p_player and attempts < p_max
    returning attempts into a;
  if a is null then
    select attempts into a from weekly_scores where week = w and player = p_player;
    return json_build_object('ok', false, 'attempts', a, 'week', w);
  end if;
  return json_build_object('ok', true, 'attempts', a, 'week', w);
end $$;

-- Envia a pontuação da luta; só vale se o jogador gastou uma entrada nesta semana e só se for MAIOR que a atual.
create or replace function submit_score(p_player uuid, p_score double precision)
returns json language plpgsql security definer set search_path = public as $$
declare w int := current_week(); s double precision;
begin
  if p_score is null or p_score <> p_score or p_score < 0 or p_score > 1e24 then   -- NaN, negativo ou absurdo
    return json_build_object('ok', false);
  end if;
  update weekly_scores set score = p_score, updated_at = now()
    where week = w and player = p_player and attempts > 0 and p_score > score
    returning score into s;
  return json_build_object('ok', s is not null, 'week', w);
end $$;

-- Tudo que a tela precisa: top p_limit, minha posição e a da semana ANTERIOR (para o prêmio).
create or replace function weekly_overview(p_player uuid, p_limit int default 10)
returns json language plpgsql security definer set search_path = public as $$
declare
  w int := current_week();
  my_score double precision; my_rank int; tot int; att int;
  pr int; pr_rank int; pr_tot int; pr_score double precision;
  top json;
begin
  p_limit := least(greatest(coalesce(p_limit, 10), 1), 10);
  select coalesce(json_agg(t order by t.rank), '[]'::json) into top from (
    select (row_number() over (order by score desc, updated_at asc))::int as rank, name, score
    from weekly_scores where week = w and score > 0
    order by score desc, updated_at asc limit p_limit) t;
  select score, attempts into my_score, att from weekly_scores where week = w and player = p_player;
  select count(*) into tot from weekly_scores where week = w and score > 0;
  if coalesce(my_score, 0) > 0 then
    select 1 + count(*) into my_rank from weekly_scores where week = w and score > my_score;
  end if;
  pr := w - 1;
  select score into pr_score from weekly_scores where week = pr and player = p_player;
  if coalesce(pr_score, 0) > 0 then
    select 1 + count(*) into pr_rank from weekly_scores where week = pr and score > pr_score;
    select count(*) into pr_tot from weekly_scores where week = pr and score > 0;
  end if;
  return json_build_object('week', w, 'attempts', coalesce(att, 0), 'total', tot, 'top', top,
    'me', json_build_object('rank', coalesce(my_rank, 0), 'score', coalesce(my_score, 0)),
    'prev', json_build_object('week', pr, 'rank', coalesce(pr_rank, 0), 'total', coalesce(pr_tot, 0)));
end $$;

revoke all on function start_attempt(uuid, text, int), submit_score(uuid, double precision), weekly_overview(uuid, int) from public;
grant execute on function start_attempt(uuid, text, int), submit_score(uuid, double precision), weekly_overview(uuid, int) to anon;
