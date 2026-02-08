-- =========================================
-- PetCare 신규 테이블 마이그레이션
-- pet_allergies + emergency_contacts
-- =========================================

-- =========================================
-- 1) pet_allergies 테이블
-- =========================================
create table if not exists public.pet_allergies (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  allergen text not null,
  reaction text,
  severity text not null default 'moderate',  -- mild|moderate|severe
  notes text,
  diagnosed_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- RLS 활성화
alter table public.pet_allergies enable row level security;

-- RLS 정책: pet owner만 접근
drop policy if exists "owner can read allergies" on public.pet_allergies;
create policy "owner can read allergies"
on public.pet_allergies for select using (
  exists (select 1 from public.pets p where p.id = pet_allergies.pet_id and p.owner_id = auth.uid())
);

drop policy if exists "owner can write allergies" on public.pet_allergies;
create policy "owner can write allergies"
on public.pet_allergies for all using (
  exists (select 1 from public.pets p where p.id = pet_allergies.pet_id and p.owner_id = auth.uid())
) with check (
  exists (select 1 from public.pets p where p.id = pet_allergies.pet_id and p.owner_id = auth.uid())
);

-- updated_at 트리거
drop trigger if exists pet_allergies_set_updated_at on public.pet_allergies;
create trigger pet_allergies_set_updated_at
before update on public.pet_allergies
for each row execute function public.set_updated_at();

-- 인덱스
create index if not exists idx_pet_allergies_pet_id on public.pet_allergies(pet_id);

-- =========================================
-- 2) emergency_contacts 테이블
-- =========================================
create table if not exists public.emergency_contacts (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  contact_type text not null default 'other',  -- vet_clinic|emergency_hospital|pet_sitter|other
  name text not null,
  phone text not null,
  address text,
  operating_hours text,
  notes text,
  is_primary boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- RLS 활성화
alter table public.emergency_contacts enable row level security;

-- RLS 정책: pet owner만 접근
drop policy if exists "owner can read contacts" on public.emergency_contacts;
create policy "owner can read contacts"
on public.emergency_contacts for select using (
  exists (select 1 from public.pets p where p.id = emergency_contacts.pet_id and p.owner_id = auth.uid())
);

drop policy if exists "owner can write contacts" on public.emergency_contacts;
create policy "owner can write contacts"
on public.emergency_contacts for all using (
  exists (select 1 from public.pets p where p.id = emergency_contacts.pet_id and p.owner_id = auth.uid())
) with check (
  exists (select 1 from public.pets p where p.id = emergency_contacts.pet_id and p.owner_id = auth.uid())
);

-- updated_at 트리거
drop trigger if exists emergency_contacts_set_updated_at on public.emergency_contacts;
create trigger emergency_contacts_set_updated_at
before update on public.emergency_contacts
for each row execute function public.set_updated_at();

-- 인덱스
create index if not exists idx_emergency_contacts_pet_id on public.emergency_contacts(pet_id);
create index if not exists idx_emergency_contacts_type on public.emergency_contacts(contact_type);

-- =========================================
-- 3) 확인 쿼리
-- =========================================
-- pet_allergies 구조 확인
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'pet_allergies' AND table_schema = 'public'
ORDER BY ordinal_position;

-- emergency_contacts 구조 확인
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'emergency_contacts' AND table_schema = 'public'
ORDER BY ordinal_position;
