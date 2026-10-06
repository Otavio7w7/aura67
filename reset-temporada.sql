-- Aura 67: RESET GERAL DA TEMPORADA.
-- ATENÇÃO: apaga TODAS as contas (nicks e senhas) e TODO o ranking. Não tem como desfazer.
-- Rode no Supabase: SQL Editor > New query > cole tudo > Run.

begin;

-- 1) Ranking e saves na nuvem
delete from public.players;

-- 2) Contas (logins). Apaga também sessões e tokens ligados a elas.
delete from auth.users;

commit;

-- 3) Garante a versão atual da função que grava a pontuação
--    (a antiga tinha limite de ego 1e9 e recusava o envio com "valores inválidos").
create or replace function public.submit_score(
  p_aura double precision, p_ego double precision, p_level int,
  p_earned double precision, p_save jsonb
) returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'não autenticado'; end if;
  if p_aura < 0 or p_ego < 0 or p_earned < 0 or p_level < 0 or p_level > 40
     or p_aura > 1e300 or p_earned > 1e300 or p_ego > 1e300 then
    raise exception 'valores inválidos';
  end if;
  if p_save is not null and pg_column_size(p_save) > 20000 then
    raise exception 'save grande demais';
  end if;
  update public.players
     set aura = p_aura, ego = p_ego, level = p_level, earned = p_earned,
         save = p_save, updated_at = now()
   where id = auth.uid();
end $$;
revoke execute on function public.submit_score(double precision, double precision, int, double precision, jsonb) from public, anon;
grant execute on function public.submit_score(double precision, double precision, int, double precision, jsonb) to authenticated;

-- Conferência: as duas contagens devem dar 0
select (select count(*) from auth.users) as contas, (select count(*) from public.players) as jogadores;
