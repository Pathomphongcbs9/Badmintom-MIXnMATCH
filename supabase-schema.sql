-- Badminton Mix&Match: online groups
-- วิธีใช้: Supabase Dashboard → SQL Editor → New query → วางทั้งไฟล์นี้ → กด Run (รันครั้งเดียว)

-- 1) ตารางก๊วน: หนึ่งแถวต่อหนึ่งก๊วน ข้อมูลทั้งหมดของก๊วนเก็บใน state
create table if not exists public.groups (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique check (code ~ '^[A-Z0-9]{6,12}$'),
  name        text not null check (char_length(name) between 1 and 60),
  owner       uuid not null default auth.uid() references auth.users(id) on delete cascade,
  state       jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists groups_owner_idx on public.groups(owner);

-- 2) อัปเดตเวลาแก้ไขล่าสุดอัตโนมัติ
create or replace function public.groups_touch() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;
drop trigger if exists groups_touch on public.groups;
create trigger groups_touch before update on public.groups
  for each row execute function public.groups_touch();

-- 3) สิทธิ์: ผู้จัดเห็นและแก้ได้เฉพาะก๊วนของตัวเอง
alter table public.groups enable row level security;

drop policy if exists "owner can read"   on public.groups;
drop policy if exists "owner can create" on public.groups;
drop policy if exists "owner can update" on public.groups;
drop policy if exists "owner can delete" on public.groups;

create policy "owner can read"   on public.groups for select to authenticated using (owner = auth.uid());
create policy "owner can create" on public.groups for insert to authenticated with check (owner = auth.uid());
create policy "owner can update" on public.groups for update to authenticated using (owner = auth.uid()) with check (owner = auth.uid());
create policy "owner can delete" on public.groups for delete to authenticated using (owner = auth.uid());

-- 4) สมาชิกดูก๊วนได้ด้วยรหัสเท่านั้น (ไม่สามารถดูรายชื่อก๊วนทั้งหมดได้)
create or replace function public.get_group(p_code text)
returns table (name text, state jsonb, updated_at timestamptz)
language sql stable security definer set search_path = public as $$
  select g.name, g.state, g.updated_at
  from public.groups g
  where g.code = upper(p_code)
  limit 1
$$;
revoke all on function public.get_group(text) from public;
grant execute on function public.get_group(text) to anon, authenticated;

-- 5) กรรมการกรอกคะแนนสด (เพิ่มเมื่อ ต.ค. 2569 · รันไฟล์นี้ซ้ำได้ ข้อมูลเดิมไม่หาย)
--    ผู้จัดสร้าง "ลิงก์กรรมการ" ได้ กรรมการที่มีลิงก์ส่งคะแนนสดได้อย่างเดียว แก้ข้อมูลอื่นของก๊วนไม่ได้
alter table public.groups add column if not exists ref_token text;

create table if not exists public.live_scores (
  group_id    uuid not null references public.groups(id) on delete cascade,
  mkey        text not null check (char_length(mkey) <= 80),
  data        jsonb not null,
  updated_at  timestamptz not null default now(),
  primary key (group_id, mkey)
);
alter table public.live_scores enable row level security;
drop policy if exists "owner manages live" on public.live_scores;
create policy "owner manages live" on public.live_scores for all to authenticated
  using (exists (select 1 from public.groups g where g.id = group_id and g.owner = auth.uid()))
  with check (exists (select 1 from public.groups g where g.id = group_id and g.owner = auth.uid()));

create or replace function public.ref_check(p_code text, p_token text)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.groups g
    where g.code = upper(p_code) and g.ref_token is not null
      and char_length(p_token) >= 16 and g.ref_token = p_token)
$$;

create or replace function public.ref_put(p_code text, p_token text, p_key text, p_data jsonb)
returns boolean
language plpgsql security definer set search_path = public as $$
declare gid uuid;
begin
  select g.id into gid from public.groups g
  where g.code = upper(p_code) and g.ref_token is not null
    and char_length(p_token) >= 16 and g.ref_token = p_token;
  if gid is null then return false; end if;
  if char_length(p_key) > 80 or pg_column_size(p_data) > 4000 then return false; end if;
  insert into public.live_scores (group_id, mkey, data, updated_at)
  values (gid, p_key, p_data, now())
  on conflict (group_id, mkey) do update set data = excluded.data, updated_at = now();
  return true;
end $$;

create or replace function public.get_live(p_code text)
returns table (mkey text, data jsonb, updated_at timestamptz)
language sql stable security definer set search_path = public as $$
  select l.mkey, l.data, l.updated_at
  from public.live_scores l join public.groups g on g.id = l.group_id
  where g.code = upper(p_code)
$$;

revoke all on function public.ref_check(text, text) from public;
revoke all on function public.ref_put(text, text, text, jsonb) from public;
revoke all on function public.get_live(text) from public;
grant execute on function public.ref_check(text, text) to anon, authenticated;
grant execute on function public.ref_put(text, text, text, jsonb) to anon, authenticated;
grant execute on function public.get_live(text) to anon, authenticated;
