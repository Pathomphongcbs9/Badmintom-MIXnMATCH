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
