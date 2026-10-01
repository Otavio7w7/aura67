-- Aura 67: ranking + login por nick (Supabase). Rode tudo no SQL Editor, de uma vez.

create table if not exists public.players (
  id uuid primary key references auth.users(id) on delete cascade,
  nick text not null,
  aura double precision not null default 0,
  ego double precision not null default 0,
  level int not null default 0,
  earned double precision not null default 0,
  save jsonb,
  updated_at timestamptz not null default now()
);
create unique index if not exists players_nick_lower on public.players (lower(nick));

alter table public.players enable row level security;
revoke all on public.players from anon, authenticated;
grant select on public.players to authenticated;
drop policy if exists "ler o proprio" on public.players;
create policy "ler o proprio" on public.players for select to authenticated using (auth.uid() = id);

-- cria a linha do jogador quando a conta é criada (nick vem do cadastro)
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.players (id, nick)
  values (new.id, coalesce(new.raw_user_meta_data->>'nick', split_part(new.email, '@', 1)));
  return new;
end $$;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- único jeito de gravar pontuação: só a própria linha, com validação básica
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

-- ranking público (sem o save): só nick, aura, ego, nível
create or replace view public.ranking as
  select nick, aura, ego, level, earned from public.players where earned > 0;
grant select on public.ranking to anon, authenticated;
