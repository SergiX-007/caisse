-- Schema de l'application Caisse : transferts Maurice > Madagascar et finances
-- personnelles. Applique sur le projet Supabase `caisse`.
-- Les identifiants sont generes par le client (chaine courte base36), d'ou le type text.

create table if not exists public.clients (
  id         text primary key,
  nom        text not null,
  telephone  text not null default '',
  cree       bigint not null default 0
);

create table if not exists public.contacts (
  id         text primary key,
  client_id  text not null references public.clients(id) on delete cascade,
  nom        text not null,
  numero     text not null default '',
  ville      text not null default '',
  cree       bigint not null default 0
);

create table if not exists public.operations (
  id          text primary key,
  client_id   text not null references public.clients(id) on delete cascade,
  type        text not null check (type in ('depot', 'envoi', 'remise')),
  date        date not null,
  montant_rs  numeric(14,2) not null default 0,
  montant_ar  numeric(16,2) not null default 0,
  contact_id  text references public.contacts(id) on delete set null,
  note        text not null default '',
  cree        bigint not null default 0
);

create table if not exists public.finances (
  id         text primary key,
  type       text not null check (type in ('depense', 'revenu')),
  date       date not null,
  montant    numeric(14,2) not null default 0,
  categorie  text not null default '',
  libelle    text not null default '',
  cree       bigint not null default 0
);

-- Ligne unique : etat de la caisse et solde d'ouverture.
create table if not exists public.reglages (
  id         smallint primary key default 1 check (id = 1),
  banque     numeric(14,2) not null default 0,
  liquide    numeric(14,2) not null default 0,
  ouverture  numeric(14,2) not null default 0,
  maj        timestamptz not null default now()
);

insert into public.reglages (id) values (1) on conflict (id) do nothing;

create index if not exists contacts_client_id_idx   on public.contacts (client_id);
create index if not exists operations_client_id_idx on public.operations (client_id);
create index if not exists operations_date_idx      on public.operations (date);
create index if not exists finances_date_idx        on public.finances (date);

-- Application mono-utilisateur sans authentification : la cle publique donne
-- un acces complet en lecture et en ecriture. RLS reste activee pour que
-- l'acces passe explicitement par des policies plutot que par defaut.

alter table public.clients    enable row level security;
alter table public.contacts   enable row level security;
alter table public.operations enable row level security;
alter table public.finances   enable row level security;
alter table public.reglages   enable row level security;

create policy "acces public clients"    on public.clients    for all to anon, authenticated using (true) with check (true);
create policy "acces public contacts"   on public.contacts   for all to anon, authenticated using (true) with check (true);
create policy "acces public operations" on public.operations for all to anon, authenticated using (true) with check (true);
create policy "acces public finances"   on public.finances   for all to anon, authenticated using (true) with check (true);

-- La ligne de reglages est unique : lecture, creation et mise a jour, jamais de suppression.
create policy "lecture reglages"      on public.reglages for select to anon, authenticated using (true);
create policy "creation reglages"     on public.reglages for insert to anon, authenticated with check (true);
create policy "mise a jour reglages"  on public.reglages for update to anon, authenticated using (true) with check (true);
