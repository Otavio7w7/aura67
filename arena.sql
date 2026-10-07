-- Aura 67: ARENA (batalha entre jogadores).
-- Rode UMA vez no Supabase: SQL Editor > New query > cole tudo > Run (depois do supabase.sql).
-- Pode rodar de novo sem problema: não apaga moedas, itens nem batalhas.

-- 1) Colunas novas do jogador
alter table public.players add column if not exists last_seen timestamptz;
alter table public.players add column if not exists coins int not null default 0;
alter table public.players add column if not exists arena_items jsonb not null default '{}'::jsonb;
alter table public.players add column if not exists arena_wins int not null default 0;

-- 2) Batalhas (só as funções abaixo leem e gravam aqui)
create table if not exists public.battles (
  id bigint generated always as identity primary key,
  a uuid not null references public.players(id) on delete cascade,   -- quem desafiou
  b uuid not null references public.players(id) on delete cascade,   -- quem foi desafiado
  status text not null default 'pending' check (status in ('pending', 'active', 'done', 'declined', 'expired')),
  created_at timestamptz not null default now(),
  started_at timestamptz,
  finished_at timestamptz,
  a_score double precision not null default 0,
  b_score double precision not null default 0,
  a_seen timestamptz,
  b_seen timestamptz,
  winner uuid,
  reason text,
  coin boolean not null default false
);
create index if not exists battles_a on public.battles (a, status);
create index if not exists battles_b on public.battles (b, status);
create index if not exists battles_winner on public.battles (winner, finished_at);
alter table public.battles enable row level security;
revoke all on public.battles from anon, authenticated;

-- 3) Regras fixas
-- Duração 300 s, contagem 4 s, W.O. após 20 s sem sinal, convite vale 35 s.
-- Teto de aura possível na arena após t segundos (calibrado por simulação com folga grande;
-- um jogador real fica umas 100x abaixo disso).
create or replace function public.arena_cap(t double precision) returns double precision
language sql immutable as $$ select 1e5 * power(10, least(greatest(t, 0), 300) / 100.0) $$;

-- Como o jogador vê a batalha (sempre do ponto de vista de "me")
create or replace function public.arena_view(bt public.battles, me uuid) returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'id', bt.id,
    'status', bt.status,
    'mine', bt.a = me,                                   -- true = eu desafiei
    'opp', (select nick from public.players where id = case when bt.a = me then bt.b else bt.a end),
    'me_score', case when bt.a = me then bt.a_score else bt.b_score end,
    'opp_score', case when bt.a = me then bt.b_score else bt.a_score end,
    'expires_in', greatest(0, 35 - extract(epoch from now() - bt.created_at)),
    'starts_in', case when bt.started_at is null then null else extract(epoch from bt.started_at - now()) end,
    'left', case when bt.started_at is null then null else greatest(0, 300 - extract(epoch from now() - bt.started_at)) end,
    'result', case when bt.status <> 'done' then null when bt.winner is null then 'draw' when bt.winner = me then 'win' else 'loss' end,
    'reason', bt.reason,
    'coin', bt.coin and bt.winner = me
  )
$$;

-- Encerra a batalha e dá a moeda (máx 3 por dia; 1 por dia contra o mesmo oponente)
create or replace function public.arena_close(p_id bigint, p_winner uuid, p_reason text) returns void
language plpgsql security definer set search_path = public as $$
declare
  bt public.battles; opp uuid; give boolean := false; n_today int; n_opp int;
  today date := (now() at time zone 'America/Sao_Paulo')::date;
begin
  select * into bt from public.battles where id = p_id for update;
  if not found or bt.status <> 'active' then return; end if;
  if p_winner is not null then
    opp := case when p_winner = bt.a then bt.b else bt.a end;
    select count(*) into n_today from public.battles
     where winner = p_winner and coin and (finished_at at time zone 'America/Sao_Paulo')::date = today;
    select count(*) into n_opp from public.battles
     where winner = p_winner and coin and (a = opp or b = opp) and (finished_at at time zone 'America/Sao_Paulo')::date = today;
    give := n_today < 3 and n_opp = 0;
    update public.players set arena_wins = arena_wins + 1, coins = coins + (case when give then 1 else 0 end) where id = p_winner;
  end if;
  update public.battles set status = 'done', finished_at = now(), winner = p_winner, reason = p_reason, coin = give where id = p_id;
end $$;

-- Confere se a batalha acabou (tempo ou W.O.)
create or replace function public.arena_resolve(p_id bigint) returns void
language plpgsql security definer set search_path = public as $$
declare bt public.battles; a_off boolean; b_off boolean;
begin
  select * into bt from public.battles where id = p_id;
  if not found or bt.status <> 'active' then return; end if;
  -- 3 s de folga depois dos 5 min para chegar o placar final dos dois
  if now() > bt.started_at + interval '303 seconds' then
    perform public.arena_close(p_id,
      case when bt.a_score > bt.b_score then bt.a when bt.b_score > bt.a_score then bt.b else null end,
      case when bt.a_score = bt.b_score then 'empate' else 'pontos' end);
    return;
  end if;
  a_off := bt.a_seen < now() - interval '20 seconds';
  b_off := bt.b_seen < now() - interval '20 seconds';
  if a_off and b_off then perform public.arena_close(p_id, null, 'abandono');
  elsif a_off then perform public.arena_close(p_id, bt.b, 'wo');
  elsif b_off then perform public.arena_close(p_id, bt.a, 'wo');
  end if;
end $$;

-- Sinal de "estou online" + estado da minha batalha (o jogo chama a cada 5 s)
create or replace function public.arena_ping() returns jsonb
language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); p public.players; bt public.battles; r record;
begin
  if me is null then raise exception 'não autenticado'; end if;
  update public.players set last_seen = now() where id = me returning * into p;
  if not found then raise exception 'jogador não encontrado'; end if;
  update public.battles set status = 'expired' where status = 'pending' and created_at < now() - interval '35 seconds';
  for r in select id from public.battles where status = 'active' and (a = me or b = me) loop
    perform public.arena_resolve(r.id);
  end loop;
  select * into bt from public.battles where status in ('pending', 'active') and (a = me or b = me) order by id desc limit 1;
  return jsonb_build_object('coins', p.coins, 'items', p.arena_items, 'wins', p.arena_wins,
    'battle', case when bt.id is not null then public.arena_view(bt, me) else null end);
end $$;

-- Quem está online agora (visto nos últimos 30 s)
create or replace function public.arena_online() returns table (nick text, level int, busy boolean)
language sql stable security definer set search_path = public as $$
  select p.nick, p.level,
         exists (select 1 from public.battles x where x.status in ('pending', 'active') and (x.a = p.id or x.b = p.id)) as busy
    from public.players p
   where p.last_seen > now() - interval '30 seconds' and p.id <> auth.uid()
   order by lower(p.nick)
   limit 50
$$;

-- Desafiar um jogador pelo nick
create or replace function public.arena_challenge(p_nick text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); t public.players; bt public.battles;
begin
  if me is null then raise exception 'não autenticado'; end if;
  select * into t from public.players where lower(nick) = lower(p_nick);
  if not found then raise exception 'jogador não encontrado'; end if;
  if t.id = me then raise exception 'não dá para desafiar você mesmo'; end if;
  if t.last_seen is null or t.last_seen < now() - interval '30 seconds' then raise exception 'jogador offline'; end if;
  update public.battles set status = 'expired' where status = 'pending' and created_at < now() - interval '35 seconds';
  if exists (select 1 from public.battles where status in ('pending', 'active') and (a = me or b = me)) then
    raise exception 'você já tem uma batalha em andamento';
  end if;
  if exists (select 1 from public.battles where status in ('pending', 'active') and (a = t.id or b = t.id)) then
    raise exception 'jogador ocupado';
  end if;
  insert into public.battles (a, b) values (me, t.id) returning * into bt;
  return public.arena_view(bt, me);
end $$;

-- Aceitar ou recusar um desafio recebido
create or replace function public.arena_respond(p_id bigint, p_accept boolean) returns jsonb
language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); bt public.battles;
begin
  if me is null then raise exception 'não autenticado'; end if;
  select * into bt from public.battles where id = p_id and b = me for update;
  if not found then raise exception 'desafio não encontrado'; end if;
  if bt.status <> 'pending' or bt.created_at < now() - interval '35 seconds' then raise exception 'desafio expirado'; end if;
  if p_accept then
    update public.battles set status = 'active', started_at = now() + interval '4 seconds', a_seen = now(), b_seen = now()
     where id = p_id returning * into bt;
  else
    update public.battles set status = 'declined', finished_at = now() where id = p_id returning * into bt;
  end if;
  return public.arena_view(bt, me);
end $$;

-- Placar durante a batalha (o jogo chama a cada 2 s); devolve o estado
create or replace function public.arena_tick(p_id bigint, p_score double precision) returns jsonb
language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); bt public.battles; el double precision; ok boolean;
begin
  if me is null then raise exception 'não autenticado'; end if;
  select * into bt from public.battles where id = p_id and (a = me or b = me) for update;
  if not found then raise exception 'batalha não encontrada'; end if;
  if bt.status = 'active' then
    el := extract(epoch from now() - bt.started_at);
    -- placar impossível é ignorado (fica o último válido)
    ok := p_score is not null and p_score >= 0 and p_score <= public.arena_cap(el + 3);
    if bt.a = me then
      update public.battles set a_seen = now(), a_score = case when ok then greatest(a_score, p_score) else a_score end where id = p_id;
    else
      update public.battles set b_seen = now(), b_score = case when ok then greatest(b_score, p_score) else b_score end where id = p_id;
    end if;
    perform public.arena_resolve(p_id);
    select * into bt from public.battles where id = p_id;
  end if;
  return public.arena_view(bt, me);
end $$;

-- Desistir (batalha ativa = derrota) ou cancelar/recusar um convite
create or replace function public.arena_quit(p_id bigint) returns jsonb
language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); bt public.battles;
begin
  if me is null then raise exception 'não autenticado'; end if;
  select * into bt from public.battles where id = p_id and (a = me or b = me);
  if not found then raise exception 'batalha não encontrada'; end if;
  if bt.status = 'active' then
    perform public.arena_close(p_id, case when bt.a = me then bt.b else bt.a end, 'desistencia');
  elsif bt.status = 'pending' then
    update public.battles set status = case when bt.a = me then 'expired' else 'declined' end, finished_at = now() where id = p_id;
  end if;
  select * into bt from public.battles where id = p_id;
  return public.arena_view(bt, me);
end $$;

-- Loja da Arena: preço de cada nível (o jogo mostra os mesmos valores)
create or replace function public.arena_buy(p_item text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); p public.players; lv int; price int;
begin
  if me is null then raise exception 'não autenticado'; end if;
  select * into p from public.players where id = me for update;
  if not found then raise exception 'jogador não encontrado'; end if;
  lv := coalesce((p.arena_items ->> p_item)::int, 0);
  price := case p_item
    when 'campeao' then (array[1])[lv + 1]
    when 'maos'    then (array[1, 3, 6, 10, 15])[lv + 1]
    when 'grito'   then (array[2, 5, 10, 15, 20])[lv + 1]
    when 'titulo'  then (array[1])[lv + 1]
  end;
  if price is null then raise exception 'item indisponível'; end if;
  if p.coins < price then raise exception 'moedas insuficientes'; end if;
  update public.players set coins = coins - price, arena_items = jsonb_set(arena_items, array[p_item], to_jsonb(lv + 1))
   where id = me returning * into p;
  return jsonb_build_object('coins', p.coins, 'items', p.arena_items, 'wins', p.arena_wins);
end $$;

-- 4) Permissões: internas fechadas, as do jogo só para quem está logado
revoke execute on function public.arena_cap(double precision) from public, anon, authenticated;
revoke execute on function public.arena_view(public.battles, uuid) from public, anon, authenticated;
revoke execute on function public.arena_close(bigint, uuid, text) from public, anon, authenticated;
revoke execute on function public.arena_resolve(bigint) from public, anon, authenticated;
revoke execute on function public.arena_ping() from public, anon;
revoke execute on function public.arena_online() from public, anon;
revoke execute on function public.arena_challenge(text) from public, anon;
revoke execute on function public.arena_respond(bigint, boolean) from public, anon;
revoke execute on function public.arena_tick(bigint, double precision) from public, anon;
revoke execute on function public.arena_quit(bigint) from public, anon;
revoke execute on function public.arena_buy(text) from public, anon;
grant execute on function public.arena_ping() to authenticated;
grant execute on function public.arena_online() to authenticated;
grant execute on function public.arena_challenge(text) to authenticated;
grant execute on function public.arena_respond(bigint, boolean) to authenticated;
grant execute on function public.arena_tick(bigint, double precision) to authenticated;
grant execute on function public.arena_quit(bigint) to authenticated;
grant execute on function public.arena_buy(text) to authenticated;

-- 5) Ranking mostra o título ⚔️ de quem comprou (coluna nova no fim da view)
create or replace view public.ranking as
  select nick, aura, ego, level, earned, coalesce((arena_items ->> 'titulo')::int, 0) > 0 as gladiador
    from public.players where earned > 0;
grant select on public.ranking to anon, authenticated;

-- Conferência: deve mostrar as 4 colunas novas
select column_name from information_schema.columns
 where table_schema = 'public' and table_name = 'players' and column_name in ('last_seen', 'coins', 'arena_items', 'arena_wins');
