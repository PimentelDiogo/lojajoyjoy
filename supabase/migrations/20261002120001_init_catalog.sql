-- =============================================================================
-- Catálogo: categorias, produtos, imagens e variantes (tamanho × cor)
-- SDD §8 · ADR-0006 (estoque na variante)
-- =============================================================================

create type public.gender_type as enum ('feminino', 'masculino', 'unissex');

-- Atualiza `updated_at` automaticamente em qualquer UPDATE.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- categories
-- -----------------------------------------------------------------------------
create table public.categories (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (length(trim(name)) between 1 and 60),
  slug        text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  gender      public.gender_type not null default 'unissex',
  position    int  not null default 0,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

comment on table public.categories is 'Categorias da vitrine (Vestidos, Camisas…).';

create trigger categories_updated_at
  before update on public.categories
  for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- products
-- -----------------------------------------------------------------------------
create table public.products (
  id                uuid primary key default gen_random_uuid(),
  category_id       uuid references public.categories (id) on delete set null,
  name              text not null check (length(trim(name)) between 1 and 120),
  slug              text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  description       text check (length(description) <= 4000),
  gender            public.gender_type not null,
  base_price        numeric(10, 2) not null check (base_price > 0),
  -- Preço "de" riscado (referências A4). Só faz sentido se for maior que o preço.
  compare_at_price  numeric(10, 2) check (compare_at_price is null or compare_at_price > base_price),
  is_active         boolean not null default true,
  is_featured       boolean not null default false,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

comment on table public.products is 'Peças. Preço e estoque reais ficam nas variantes.';
comment on column public.products.compare_at_price is 'Preço riscado ("de"). Null = sem promoção.';

create index products_gender_active_idx on public.products (gender, is_active);
create index products_category_idx on public.products (category_id);
create index products_featured_idx on public.products (is_featured) where is_featured;

create trigger products_updated_at
  before update on public.products
  for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- product_images
-- -----------------------------------------------------------------------------
create table public.product_images (
  id            uuid primary key default gen_random_uuid(),
  product_id    uuid not null references public.products (id) on delete cascade,
  -- Caminho dentro do bucket `product-images` (ex.: "<product_id>/<uuid>.jpg").
  storage_path  text not null check (storage_path !~ '\.\.' and storage_path !~ '^/'),
  position      int  not null default 0, -- 0 = capa
  created_at    timestamptz not null default now(),
  unique (product_id, position)
);

create index product_images_product_idx on public.product_images (product_id, position);

-- -----------------------------------------------------------------------------
-- product_variants  (o que existe fisicamente: "Vestido M Rosa")
-- -----------------------------------------------------------------------------
create table public.product_variants (
  id              uuid primary key default gen_random_uuid(),
  product_id      uuid not null references public.products (id) on delete cascade,
  size            text not null check (length(trim(size)) between 1 and 10),
  color_name      text not null check (length(trim(color_name)) between 1 and 40),
  color_hex       text check (color_hex ~ '^#[0-9A-Fa-f]{6}$'),
  sku             text unique,
  stock_qty       int  not null default 0 check (stock_qty >= 0),
  price_override  numeric(10, 2) check (price_override is null or price_override > 0),
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  unique (product_id, size, color_name)
);

comment on column public.product_variants.stock_qty is 'Saldo atual. Nunca negativo (ADR-0006).';
comment on column public.product_variants.price_override is 'Null = usa products.base_price.';

create index product_variants_product_idx on public.product_variants (product_id);

create trigger product_variants_updated_at
  before update on public.product_variants
  for each row execute function public.set_updated_at();
