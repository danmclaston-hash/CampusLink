-- CampusLink database schema (Supabase / Postgres)
-- Run this once in the Supabase SQL editor, or with `supabase db push`.

create extension if not exists "pgcrypto";

-- ---------- Profiles ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  student_number text unique,
  programme text,
  year_of_study int check (year_of_study between 1 and 6),
  faculty text,
  role text not null default 'student' check (role in ('student','staff','admin')),
  is_tutor boolean not null default false,
  tutor_subjects text[] not null default '{}',
  is_buddy_mentor boolean not null default false,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''))
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users for each row execute function public.handle_new_user();

-- ---------- Announcements ----------
create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  category text not null default 'general',
  audience text not null default 'all',           -- all | faculty:FST | year:1 | programme:BDSAI
  is_pinned boolean not null default false,
  author_id uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

-- ---------- Help directory (offices / services) ----------
create table if not exists public.help_offices (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null default '',
  category text not null default 'academic',     -- academic | finance | welfare | it | admin | library | health
  location text not null default '',
  building text,
  floor text,
  contact_email text,
  contact_phone text,
  open_hours text,
  keywords text[] not null default '{}',          -- used by "Where do I go?" search
  lat double precision,
  lng double precision
);

-- ---------- Help requests (tickets) ----------
create table if not exists public.help_requests (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  office_id uuid references public.help_offices(id),
  title text not null,
  description text not null,
  status text not null default 'open' check (status in ('open','in_progress','resolved','closed')),
  priority text not null default 'normal' check (priority in ('low','normal','urgent')),
  assigned_to uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.help_request_updates (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.help_requests(id) on delete cascade,
  author_id uuid references public.profiles(id),
  message text not null,
  new_status text,
  created_at timestamptz not null default now()
);

-- ---------- Tutors & study groups ----------
create table if not exists public.study_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  course_code text not null,
  description text not null default '',
  meeting_time text,
  location text,
  owner_id uuid references public.profiles(id),
  max_members int not null default 12,
  created_at timestamptz not null default now()
);

create table if not exists public.study_group_members (
  group_id uuid references public.study_groups(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

-- ---------- Campus Pulse (quick polls / mood) ----------
create table if not exists public.pulse_polls (
  id uuid primary key default gen_random_uuid(),
  question text not null,
  options text[] not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.pulse_votes (
  poll_id uuid references public.pulse_polls(id) on delete cascade,
  voter_hash text not null,                        -- sha256(user_id + poll_id): anonymous but one vote each
  option_index int not null,
  created_at timestamptz not null default now(),
  primary key (poll_id, voter_hash)
);

-- ---------- First-year Buddy ----------
create table if not exists public.buddy_pairs (
  id uuid primary key default gen_random_uuid(),
  mentee_id uuid not null references public.profiles(id) on delete cascade,
  mentor_id uuid references public.profiles(id) on delete set null,
  status text not null default 'waiting' check (status in ('waiting','matched','ended')),
  created_at timestamptz not null default now()
);

-- ---------- Engagement: feedback, events, clubs ----------
create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  topic text not null,
  message text not null,
  sentiment text check (sentiment in ('positive','neutral','negative')),
  created_at timestamptz not null default now()
  -- intentionally no user_id: anonymous
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  starts_at timestamptz not null,
  ends_at timestamptz,
  location text,
  organiser text,
  club_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists public.clubs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null default '',
  contact text,
  member_count int not null default 0
);

-- ---------- Timetable ----------
create table if not exists public.timetable_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  course_code text not null,
  course_name text,
  day_of_week int not null check (day_of_week between 1 and 7),
  start_time time not null,
  end_time time not null,
  room text,
  lecturer text,
  source text not null default 'manual',          -- manual | csv | xlsx | pdf
  created_at timestamptz not null default now()
);

-- ---------- Row Level Security ----------
alter table public.profiles enable row level security;
alter table public.announcements enable row level security;
alter table public.help_offices enable row level security;
alter table public.help_requests enable row level security;
alter table public.help_request_updates enable row level security;
alter table public.study_groups enable row level security;
alter table public.study_group_members enable row level security;
alter table public.pulse_polls enable row level security;
alter table public.pulse_votes enable row level security;
alter table public.buddy_pairs enable row level security;
alter table public.feedback enable row level security;
alter table public.events enable row level security;
alter table public.clubs enable row level security;
alter table public.timetable_entries enable row level security;

-- helper: is current user staff/admin?
create or replace function public.is_staff() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role in ('staff','admin'));
$$;

-- profiles
create policy "profiles readable by signed-in" on public.profiles for select to authenticated using (true);
create policy "own profile update" on public.profiles for update to authenticated using (id = auth.uid());

-- public read tables
create policy "read announcements" on public.announcements for select to authenticated using (true);
create policy "staff write announcements" on public.announcements for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "read offices" on public.help_offices for select to authenticated using (true);
create policy "staff write offices" on public.help_offices for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "read events" on public.events for select to authenticated using (true);
create policy "staff write events" on public.events for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "read clubs" on public.clubs for select to authenticated using (true);
create policy "read polls" on public.pulse_polls for select to authenticated using (true);
create policy "staff write polls" on public.pulse_polls for all to authenticated using (public.is_staff()) with check (public.is_staff());

-- help requests: student sees own, staff sees all
create policy "student own requests" on public.help_requests for select to authenticated using (student_id = auth.uid() or public.is_staff());
create policy "student create request" on public.help_requests for insert to authenticated with check (student_id = auth.uid());
create policy "staff update request" on public.help_requests for update to authenticated using (public.is_staff() or student_id = auth.uid());
create policy "request updates visible" on public.help_request_updates for select to authenticated
  using (exists (select 1 from public.help_requests r where r.id = request_id and (r.student_id = auth.uid() or public.is_staff())));
create policy "request updates insert" on public.help_request_updates for insert to authenticated
  with check (exists (select 1 from public.help_requests r where r.id = request_id and (r.student_id = auth.uid() or public.is_staff())));

-- study groups
create policy "read groups" on public.study_groups for select to authenticated using (true);
create policy "create group" on public.study_groups for insert to authenticated with check (owner_id = auth.uid());
create policy "owner edit group" on public.study_groups for update to authenticated using (owner_id = auth.uid());
create policy "read members" on public.study_group_members for select to authenticated using (true);
create policy "join group" on public.study_group_members for insert to authenticated with check (user_id = auth.uid());
create policy "leave group" on public.study_group_members for delete to authenticated using (user_id = auth.uid());

-- pulse votes: anyone may insert; reading aggregates only via view
create policy "vote" on public.pulse_votes for insert to authenticated with check (true);
create policy "read votes" on public.pulse_votes for select to authenticated using (true);

-- buddy
create policy "own buddy pair" on public.buddy_pairs for select to authenticated using (mentee_id = auth.uid() or mentor_id = auth.uid() or public.is_staff());
create policy "request buddy" on public.buddy_pairs for insert to authenticated with check (mentee_id = auth.uid());
create policy "mentor accepts" on public.buddy_pairs for update to authenticated using (mentor_id = auth.uid() or public.is_staff() or (mentor_id is null and (select is_buddy_mentor from public.profiles where id = auth.uid())));

-- feedback: write-only for students, read for staff
create policy "submit feedback" on public.feedback for insert to authenticated with check (true);
create policy "staff read feedback" on public.feedback for select to authenticated using (public.is_staff());

-- timetable: strictly private
create policy "own timetable" on public.timetable_entries for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------- Grants (needed on Supabase for the API roles) ----------
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant select on public.help_offices, public.announcements, public.events, public.clubs to anon;
alter default privileges in schema public grant select, insert, update, delete on tables to authenticated;

-- ---------- Views ----------
create or replace view public.pulse_results as
  select p.id as poll_id, p.question, p.options, v.option_index, count(*) as votes
  from public.pulse_polls p
  left join public.pulse_votes v on v.poll_id = p.id
  group by p.id, p.question, p.options, v.option_index;
grant select on public.pulse_results to authenticated;
