-- JADSTORE : schéma initial et règles de sécurité
-- À exécuter UNE FOIS dans Supabase > SQL Editor.
-- Ensuite, crée l'utilisateur admin dans Authentication > Users,
-- copie son UUID, puis exécute la requête indiquée dans README.md.

create table if not exists public.store_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 160),
  category text not null,
  price numeric(10,2) not null check (price >= 0),
  description text not null default '',
  sizes text[] not null default '{}',
  colors text[] not null default '{}',
  stock integer not null default 0 check (stock >= 0),
  image_url text,
  image_path text,
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists products_published_idx
  on public.products (is_published, created_at desc);

alter table public.store_admins enable row level security;
alter table public.products enable row level security;

revoke all on table public.store_admins from anon, authenticated;
grant select on table public.store_admins to authenticated;

revoke all on table public.products from anon, authenticated;
grant select on table public.products to anon, authenticated;
grant insert, update, delete on table public.products to authenticated;

drop policy if exists "admin can read own admin record" on public.store_admins;
create policy "admin can read own admin record"
on public.store_admins for select to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "public can read published products" on public.products;
create policy "public can read published products"
on public.products for select to anon, authenticated
using (is_published = true);

drop policy if exists "admins can read all products" on public.products;
create policy "admins can read all products"
on public.products for select to authenticated
using (
  exists (
    select 1 from public.store_admins a
    where a.user_id = (select auth.uid())
  )
);

drop policy if exists "admins can insert products" on public.products;
create policy "admins can insert products"
on public.products for insert to authenticated
with check (
  exists (
    select 1 from public.store_admins a
    where a.user_id = (select auth.uid())
  )
);

drop policy if exists "admins can update products" on public.products;
create policy "admins can update products"
on public.products for update to authenticated
using (
  exists (
    select 1 from public.store_admins a
    where a.user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1 from public.store_admins a
    where a.user_id = (select auth.uid())
  )
);

drop policy if exists "admins can delete products" on public.products;
create policy "admins can delete products"
on public.products for delete to authenticated
using (
  exists (
    select 1 from public.store_admins a
    where a.user_id = (select auth.uid())
  )
);

-- Bucket public pour que les visiteurs voient les photos des produits.
-- L'écriture reste limitée aux administrateurs ci-dessous.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('jadstore-products', 'jadstore-products', true, 5242880,
        array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg','image/png','image/webp'];

drop policy if exists "public can view JADSTORE product photos" on storage.objects;
create policy "public can view JADSTORE product photos"
on storage.objects for select to anon, authenticated
using (bucket_id = 'jadstore-products');

drop policy if exists "admins can upload JADSTORE product photos" on storage.objects;
create policy "admins can upload JADSTORE product photos"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'jadstore-products'
  and exists (
    select 1 from public.store_admins a
    where a.user_id = (select auth.uid())
  )
);

drop policy if exists "admins can update JADSTORE product photos" on storage.objects;
create policy "admins can update JADSTORE product photos"
on storage.objects for update to authenticated
using (
  bucket_id = 'jadstore-products'
  and exists (
    select 1 from public.store_admins a
    where a.user_id = (select auth.uid())
  )
)
with check (
  bucket_id = 'jadstore-products'
  and exists (
    select 1 from public.store_admins a
    where a.user_id = (select auth.uid())
  )
);

drop policy if exists "admins can delete JADSTORE product photos" on storage.objects;
create policy "admins can delete JADSTORE product photos"
on storage.objects for delete to authenticated
using (
  bucket_id = 'jadstore-products'
  and exists (
    select 1 from public.store_admins a
    where a.user_id = (select auth.uid())
  )
);

-- Produit de démonstration demandé.
insert into public.products
  (name, category, price, description, sizes, colors, stock, is_published)
select
  'Costume classique', 'Costume', 899,
  'Costume élégant pour les occasions spéciales.',
  array['48','50','52','54'], array['Noir','Bleu marine'], 10, true
where not exists (
  select 1 from public.products where name = 'Costume classique'
);
