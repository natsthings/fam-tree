-- ============================================================================
--  FAMILY TREE — COMPLETE DATABASE SETUP
--  Paste this WHOLE file into Supabase → SQL Editor → New query → Run.
--  Safe to run on a brand-new project. (Safe to re-run too — it won't
--  delete your data.)
--
--  ✏️  ONE THING TO EDIT BEFORE YOU RUN IT:  the admin email (search for
--      "EDIT ME" below — it's the only one). It MUST be the same email you
--      put in lib/config.ts as ADMIN_EMAIL.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 0. SETTINGS TABLE  (holds the admin email; nobody can read it from the site)
-- ----------------------------------------------------------------------------
create table if not exists public.app_settings (
  key   text primary key,
  value text not null
);
alter table public.app_settings enable row level security;
-- (No policies on purpose: the website can't read this table directly.
--  Only the database functions below can.)

-- ✏️ EDIT ME ↓↓↓  put YOUR email between the quotes (same as lib/config.ts)
insert into public.app_settings (key, value)
values ('admin_email', 'you@example.com')
on conflict (key) do update set value = excluded.value;
-- ✏️ EDIT ME ↑↑↑


-- ----------------------------------------------------------------------------
-- 1. HELPER: "is the person using the site the admin?"
-- ----------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    lower(auth.jwt() ->> 'email') = (
      select lower(value) from public.app_settings where key = 'admin_email'
    ),
    false
  );
$$;


-- ----------------------------------------------------------------------------
-- 2. TABLES
-- ----------------------------------------------------------------------------

-- 2a. MEMBERS — every person on the shared family tree
create table if not exists public.members (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references auth.users(id) on delete cascade, -- who added this person
  name             text not null,
  birth_year       int,
  birth_date       text,                       -- "YYYY-MM-DD"
  death_year       int,
  death_date       text,
  is_deceased      boolean default false,
  birthplace       text,
  deathplace       text,
  grave_location   text,
  biography        text,
  notes            text,
  familysearch_id  text,
  origins          text[],                     -- countries, e.g. {Panama,Spain}
  social_links     jsonb default '[]'::jsonb,
  source_links     jsonb default '[]'::jsonb,
  personal_events  jsonb default '[]'::jsonb,
  photo_url        text,
  is_root          boolean not null default false,
  is_imported      boolean not null default false,  -- true = hidden bulk GEDCOM data
  is_admin         boolean not null default false,  -- set automatically, see trigger below
  claimed_by       uuid references auth.users(id) on delete set null,  -- the login that "is" this person
  position_x       double precision default 0,
  position_y       double precision default 0,
  created_at       timestamptz default now(),
  updated_at       timestamptz default now()
);
create index if not exists members_claimed_by_idx on public.members (claimed_by);
create index if not exists members_familysearch_idx on public.members (familysearch_id);

-- 2b. RELATIONSHIPS — lines between people on the shared tree
create table if not exists public.relationships (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users(id) on delete cascade,
  source_id      uuid not null references public.members(id) on delete cascade,
  target_id      uuid not null references public.members(id) on delete cascade,
  relation_type  text not null check (relation_type in
                   ('parent','child','spouse','sibling','step_sibling','half_sibling','other')),
  label          text,
  is_imported    boolean not null default false,
  created_at     timestamptz default now(),
  unique (source_id, target_id, relation_type)   -- needed by the GEDCOM importer
);
create index if not exists relationships_source_idx on public.relationships (source_id);
create index if not exists relationships_target_idx on public.relationships (target_id);

-- 2c. MEMBER POSITIONS — where EACH user dragged each card (everyone has their own layout)
create table if not exists public.member_positions (
  user_id     uuid not null references auth.users(id) on delete cascade,
  member_id   uuid not null references public.members(id) on delete cascade,
  position_x  double precision not null default 0,
  position_y  double precision not null default 0,
  primary key (user_id, member_id)
);

-- 2d. MEMBER COMPLETE — the "mark as complete" checkmark (per user)
create table if not exists public.member_complete (
  user_id    uuid not null references auth.users(id) on delete cascade,
  member_id  uuid not null,
  primary key (user_id, member_id)
);

-- 2e. PRIVATE (admin-only) people, lines, notes, positions
create table if not exists public.private_members (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references auth.users(id) on delete cascade,
  name             text not null,
  birth_year       int,
  birth_date       text,
  death_year       int,
  death_date       text,
  is_deceased      boolean default false,
  birthplace       text,
  deathplace       text,
  grave_location   text,
  biography        text,
  notes            text,
  familysearch_id  text,
  origins          text[],
  social_links     jsonb default '[]'::jsonb,
  source_links     jsonb default '[]'::jsonb,
  personal_events  jsonb default '[]'::jsonb,
  photo_url        text,
  position_x       double precision default 0,
  position_y       double precision default 0,
  created_at       timestamptz default now()
);

create table if not exists public.private_relationships (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users(id) on delete cascade,
  source_id      uuid not null,   -- can point at a private OR a public member
  target_id      uuid not null,
  relation_type  text not null check (relation_type in
                   ('parent','child','spouse','sibling','step_sibling','half_sibling','other')),
  label          text,
  created_at     timestamptz default now()
);

create table if not exists public.private_member_positions (
  user_id     uuid not null references auth.users(id) on delete cascade,
  member_id   uuid not null references public.private_members(id) on delete cascade,
  position_x  double precision not null default 0,
  position_y  double precision not null default 0,
  primary key (user_id, member_id)
);

create table if not exists public.private_notes (
  user_id    uuid not null references auth.users(id) on delete cascade,
  member_id  uuid not null,
  note       text,
  primary key (user_id, member_id)
);

-- 2f. TREE NOTES — yellow sticky notes on the tree canvas
create table if not exists public.tree_notes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  content     text not null default '',
  color       text not null default '#f5e642',
  position_x  double precision not null default 0,
  position_y  double precision not null default 0,
  created_at  timestamptz default now()
);

-- 2g. SCRAPBOOK — photos & notes pinned on each person's scrapbook page
create table if not exists public.scrapbook_items (
  id          uuid primary key default gen_random_uuid(),
  member_id   uuid not null references public.members(id) on delete cascade,
  user_id     uuid not null references auth.users(id) on delete cascade,
  type        text not null check (type in ('photo','text')),
  content     text not null default '',    -- photo URL, or the note's text
  caption     text,
  date_taken  text,
  pos_x       double precision not null default 0,
  pos_y       double precision not null default 0,
  width       double precision not null default 220,
  rotation    double precision not null default 0,
  created_at  timestamptz default now()
);
create index if not exists scrapbook_member_idx on public.scrapbook_items (member_id);

-- 2h. TIMELINE EVENTS — custom events people add to the timeline page
create table if not exists public.timeline_events (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  title        text not null,
  year         int  not null,
  description  text,
  category     text not null default 'personal',
  member_id    uuid references public.members(id) on delete set null,
  created_at   timestamptz default now()
);

-- 2i. MESSAGES — private messages between two logged-in people
create table if not exists public.messages (
  id              uuid primary key default gen_random_uuid(),
  sender_id       uuid not null references auth.users(id) on delete cascade,
  sender_name     text,
  recipient_id    uuid not null references auth.users(id) on delete cascade,
  recipient_name  text,
  content         text not null,
  read            boolean not null default false,
  created_at      timestamptz default now()
);
create index if not exists messages_recipient_idx on public.messages (recipient_id, read);
create index if not exists messages_sender_idx on public.messages (sender_id);

-- 2j. DELETE REQUESTS — "please delete this" requests that the admin approves/denies
create table if not exists public.delete_requests (
  id                  uuid primary key default gen_random_uuid(),
  requester_id        uuid not null references auth.users(id) on delete cascade,
  requester_name      text,
  target_type         text not null check (target_type in ('member','relationship','scrapbook_item')),
  target_id           uuid not null,
  target_description  text,
  status              text not null default 'pending' check (status in ('pending','approved','denied')),
  created_at          timestamptz default now()
);

-- 2k. USER PREFS — one row per person
create table if not exists public.user_prefs (
  user_id           uuid primary key references auth.users(id) on delete cascade,
  has_seen_welcome  boolean not null default false,
  language          text not null default 'en'
);


-- ----------------------------------------------------------------------------
-- 3. AUTOMATIC BEHAVIOUR (triggers)
-- ----------------------------------------------------------------------------

-- Keep "updated_at" fresh on members
create or replace function public.update_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists members_updated_at on public.members;
create trigger members_updated_at
  before update on public.members
  for each row execute function public.update_updated_at();

-- Nobody can make themselves admin from the browser: is_admin is only ever
-- true when the profile belongs to the logged-in person AND they are the admin.
create or replace function public.members_before_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.is_admin := (new.claimed_by is not null and new.claimed_by = auth.uid() and public.is_admin());
  return new;
end;
$$;

drop trigger if exists members_guard_insert on public.members;
create trigger members_guard_insert
  before insert on public.members
  for each row execute function public.members_before_insert();


-- ----------------------------------------------------------------------------
-- 4. FUNCTIONS THE WEBSITE CALLS  (supabase.rpc('...') in the code)
-- ----------------------------------------------------------------------------

-- Register page: "I'm already on the tree — claim my profile"
create or replace function public.claim_member(member_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'Not logged in'; end if;

  update public.members
     set claimed_by = auth.uid(),
         is_admin   = public.is_admin()
   where id = member_id
     and claimed_by is null;

  if not found then
    raise exception 'That profile has already been claimed by someone else.';
  end if;
end;
$$;

-- Edit-person popup: any logged-in family member may update a person's details
create or replace function public.update_member_details(
  p_member_id        uuid,
  p_name             text,
  p_photo_url        text,
  p_birth_date       text,
  p_death_date       text,
  p_birth_year       int,
  p_death_year       int,
  p_social_links     jsonb,
  p_is_deceased      boolean,
  p_origins          text[],
  p_biography        text,
  p_birthplace       text,
  p_deathplace       text,
  p_familysearch_id  text,
  p_grave_location   text,
  p_source_links     jsonb,
  p_personal_events  jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'Not logged in'; end if;

  update public.members set
    name            = p_name,
    photo_url       = p_photo_url,
    birth_date      = p_birth_date,
    death_date      = p_death_date,
    birth_year      = p_birth_year,
    death_year      = p_death_year,
    social_links    = coalesce(p_social_links, '[]'::jsonb),
    is_deceased     = p_is_deceased,
    origins         = p_origins,
    biography       = p_biography,
    birthplace      = p_birthplace,
    deathplace      = p_deathplace,
    familysearch_id = p_familysearch_id,
    grave_location  = p_grave_location,
    source_links    = coalesce(p_source_links, '[]'::jsonb),
    personal_events = coalesce(p_personal_events, '[]'::jsonb)
  where id = p_member_id;
end;
$$;

-- Delete a person (ADMIN ONLY). Everyone else must use "Request deletion".
create or replace function public.delete_member(member_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then raise exception 'Only the admin can delete people.'; end if;

  delete from public.private_relationships where source_id = member_id or target_id = member_id;
  delete from public.private_notes     where private_notes.member_id     = delete_member.member_id;
  delete from public.member_complete   where member_complete.member_id   = delete_member.member_id;
  delete from public.members           where id = member_id;   -- also removes their lines, scrapbook, positions
end;
$$;

-- Scrapbook page: any family member can move / edit scrapbook items
create or replace function public.update_scrapbook_item(
  item_id        uuid,
  new_pos_x      double precision,
  new_pos_y      double precision,
  new_content    text,
  new_caption    text,
  new_date_taken text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'Not logged in'; end if;

  update public.scrapbook_items set
    pos_x      = new_pos_x,
    pos_y      = new_pos_y,
    content    = new_content,
    caption    = new_caption,
    date_taken = new_date_taken
  where id = item_id;
end;
$$;

-- Tree page ↺ button: put MY card layout back to default
create or replace function public.reset_user_positions(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or auth.uid() <> p_user_id then
    raise exception 'You can only reset your own layout.';
  end if;
  delete from public.member_positions where user_id = p_user_id;
end;
$$;

-- Only logged-in people may call these functions
revoke execute on function public.claim_member(uuid)                         from public, anon;
revoke execute on function public.delete_member(uuid)                        from public, anon;
revoke execute on function public.reset_user_positions(uuid)                 from public, anon;
revoke execute on function public.update_scrapbook_item(uuid, double precision, double precision, text, text, text) from public, anon;
revoke execute on function public.update_member_details(uuid, text, text, text, text, int, int, jsonb, boolean, text[], text, text, text, text, text, jsonb, jsonb) from public, anon;
grant  execute on function public.claim_member(uuid)                         to authenticated;
grant  execute on function public.delete_member(uuid)                        to authenticated;
grant  execute on function public.reset_user_positions(uuid)                 to authenticated;
grant  execute on function public.update_scrapbook_item(uuid, double precision, double precision, text, text, text) to authenticated;
grant  execute on function public.update_member_details(uuid, text, text, text, text, int, int, jsonb, boolean, text[], text, text, text, text, text, jsonb, jsonb) to authenticated;


-- ----------------------------------------------------------------------------
-- 5. SECURITY RULES  (Row Level Security — who can see / change what)
--    Plain English version:
--      • Must be logged in to see anything.
--      • Everyone logged in can SEE the family tree, and ADD people/lines/notes.
--      • Only the ADMIN can DELETE people, lines, and scrapbook items.
--      • "Private" tables, messages and layouts only show to their owner.
-- ----------------------------------------------------------------------------
alter table public.members                 enable row level security;
alter table public.relationships           enable row level security;
alter table public.member_positions        enable row level security;
alter table public.member_complete         enable row level security;
alter table public.private_members         enable row level security;
alter table public.private_relationships   enable row level security;
alter table public.private_member_positions enable row level security;
alter table public.private_notes           enable row level security;
alter table public.tree_notes              enable row level security;
alter table public.scrapbook_items         enable row level security;
alter table public.timeline_events         enable row level security;
alter table public.messages                enable row level security;
alter table public.delete_requests         enable row level security;
alter table public.user_prefs              enable row level security;

-- MEMBERS
drop policy if exists "members: anyone logged in can view"  on public.members;
drop policy if exists "members: logged in can add"          on public.members;
drop policy if exists "members: admin can do everything"    on public.members;
create policy "members: anyone logged in can view" on public.members
  for select to authenticated using (true);
create policy "members: logged in can add" on public.members
  for insert to authenticated
  with check (user_id = auth.uid() and (claimed_by is null or claimed_by = auth.uid()));
create policy "members: admin can do everything" on public.members
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- RELATIONSHIPS
drop policy if exists "relationships: anyone logged in can view" on public.relationships;
drop policy if exists "relationships: logged in can add"         on public.relationships;
drop policy if exists "relationships: admin can do everything"   on public.relationships;
create policy "relationships: anyone logged in can view" on public.relationships
  for select to authenticated using (true);
create policy "relationships: logged in can add" on public.relationships
  for insert to authenticated with check (user_id = auth.uid());
create policy "relationships: admin can do everything" on public.relationships
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- PER-USER TABLES (only the owner)
drop policy if exists "own rows" on public.member_positions;
create policy "own rows" on public.member_positions
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own rows" on public.member_complete;
create policy "own rows" on public.member_complete
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own rows" on public.private_members;
create policy "own rows" on public.private_members
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own rows" on public.private_relationships;
create policy "own rows" on public.private_relationships
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own rows" on public.private_member_positions;
create policy "own rows" on public.private_member_positions
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own rows" on public.private_notes;
create policy "own rows" on public.private_notes
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own rows" on public.user_prefs;
create policy "own rows" on public.user_prefs
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- TREE NOTES (everyone sees them; only the author or admin can change/delete)
drop policy if exists "tree_notes: view"            on public.tree_notes;
drop policy if exists "tree_notes: add"             on public.tree_notes;
drop policy if exists "tree_notes: owner or admin"  on public.tree_notes;
create policy "tree_notes: view" on public.tree_notes
  for select to authenticated using (true);
create policy "tree_notes: add" on public.tree_notes
  for insert to authenticated with check (user_id = auth.uid());
create policy "tree_notes: owner or admin" on public.tree_notes
  for all to authenticated
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());

-- SCRAPBOOK (everyone sees & adds; editing goes through update_scrapbook_item; only admin deletes)
drop policy if exists "scrapbook: view"  on public.scrapbook_items;
drop policy if exists "scrapbook: add"   on public.scrapbook_items;
drop policy if exists "scrapbook: admin" on public.scrapbook_items;
create policy "scrapbook: view" on public.scrapbook_items
  for select to authenticated using (true);
create policy "scrapbook: add" on public.scrapbook_items
  for insert to authenticated with check (user_id = auth.uid());
create policy "scrapbook: admin" on public.scrapbook_items
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- TIMELINE EVENTS
drop policy if exists "timeline: view"           on public.timeline_events;
drop policy if exists "timeline: add"            on public.timeline_events;
drop policy if exists "timeline: owner or admin" on public.timeline_events;
create policy "timeline: view" on public.timeline_events
  for select to authenticated using (true);
create policy "timeline: add" on public.timeline_events
  for insert to authenticated with check (user_id = auth.uid());
create policy "timeline: owner or admin" on public.timeline_events
  for delete to authenticated using (user_id = auth.uid() or public.is_admin());

-- MESSAGES (only the two people in the conversation)
drop policy if exists "messages: see mine"   on public.messages;
drop policy if exists "messages: send"       on public.messages;
drop policy if exists "messages: mark read"  on public.messages;
create policy "messages: see mine" on public.messages
  for select to authenticated using (sender_id = auth.uid() or recipient_id = auth.uid());
create policy "messages: send" on public.messages
  for insert to authenticated with check (sender_id = auth.uid());
create policy "messages: mark read" on public.messages
  for update to authenticated using (recipient_id = auth.uid()) with check (recipient_id = auth.uid());

-- DELETE REQUESTS
drop policy if exists "requests: create"        on public.delete_requests;
drop policy if exists "requests: see own"       on public.delete_requests;
drop policy if exists "requests: admin"         on public.delete_requests;
create policy "requests: create" on public.delete_requests
  for insert to authenticated with check (requester_id = auth.uid());
create policy "requests: see own" on public.delete_requests
  for select to authenticated using (requester_id = auth.uid());
create policy "requests: admin" on public.delete_requests
  for all to authenticated using (public.is_admin()) with check (public.is_admin());


-- ----------------------------------------------------------------------------
-- 6. LIVE MESSAGES  (so new chat messages appear without refreshing)
-- ----------------------------------------------------------------------------
do $$
begin
  alter publication supabase_realtime add table public.messages;
exception
  when duplicate_object then null;   -- already added, that's fine
end $$;

-- ✅ DONE. You should see "Success. No rows returned."
