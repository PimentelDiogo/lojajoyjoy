-- =============================================================================
-- PR-09 · Cadastro de produtos pela Ana
--
-- `save_product` grava produto + variantes + fotos numa transação só: ou salva
-- tudo, ou nada. É `security invoker`: o RLS ("admin gerencia …") continua
-- valendo; o `is_admin()` explícito só dá um erro claro para quem não é admin.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- slugify: "Vestido Midi Linho Rosê" → "vestido-midi-linho-rose"
-- -----------------------------------------------------------------------------
create or replace function public.slugify(p_text text)
returns text
language sql
immutable
set search_path = ''
as $$
  select left(
    trim(both '-' from regexp_replace(
      lower(translate(
        coalesce(p_text, ''),
        'ÁÀÂÃÄáàâãäÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÕÖóòôõöÚÙÛÜúùûüÇçÑñ',
        'AAAAAaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuCcNn'
      )),
      '[^a-z0-9]+', '-', 'g'
    )),
    60
  );
$$;

comment on function public.slugify(text) is 'Texto → slug de URL (sem acento, minúsculo, hífens).';

-- -----------------------------------------------------------------------------
-- create_category: categoria nova direto do formulário de produto
-- -----------------------------------------------------------------------------
create or replace function public.create_category(p_name text, p_gender public.gender_type)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_name text := regexp_replace(trim(coalesce(p_name, '')), '\s+', ' ', 'g');
  v_base text;
  v_slug text;
  v_n    int := 1;
  v_row  public.categories;
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if length(v_name) not between 1 and 60 then
    raise exception 'invalid_category' using errcode = '22023';
  end if;

  select * into v_row
    from public.categories c
   where lower(c.name) = lower(v_name) and c.gender = p_gender;
  if found then
    -- Já existe (talvez desativada): reaproveita em vez de duplicar.
    update public.categories set is_active = true where id = v_row.id;
    return jsonb_build_object('id', v_row.id, 'name', v_row.name, 'slug', v_row.slug, 'gender', v_row.gender);
  end if;

  v_base := coalesce(nullif(public.slugify(v_name), ''), 'categoria');
  v_slug := v_base;
  while exists (select 1 from public.categories c where c.slug = v_slug) loop
    v_n := v_n + 1;
    v_slug := v_base || '-' || v_n;
  end loop;

  insert into public.categories (name, slug, gender, position)
  values (
    v_name, v_slug, p_gender,
    coalesce((select max(c.position) + 1 from public.categories c), 1)
  )
  returning * into v_row;

  return jsonb_build_object('id', v_row.id, 'name', v_row.name, 'slug', v_row.slug, 'gender', v_row.gender);
end;
$$;

-- -----------------------------------------------------------------------------
-- save_product
--
-- p_product  {id, name, description, gender, category_id, base_price,
--             compare_at_price, is_active, is_featured}
--            `id` é gerado no app (as fotos sobem antes, em "<id>/…").
-- p_variants [{id?, size, color_name, color_hex?, stock, base_stock?}]
--            `base_stock` = estoque que a Ana viu ao abrir o formulário. O
--            banco aplica só a DIFERENÇA (stock - base_stock): se um pedido
--            baixar estoque enquanto ela edita, a baixa não se perde.
-- p_images   ["<id>/<arquivo>.webp", …] na ordem; o primeiro é a capa.
--
-- Variante que sumiu do formulário: apagada; se já tem pedido, desativada
-- (order_items guarda a referência).
-- -----------------------------------------------------------------------------
create or replace function public.save_product(p_product jsonb, p_variants jsonb, p_images jsonb)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_id       uuid;
  v_name     text;
  v_slug     text;
  v_base     text;
  v_n        int := 1;
  v_exists   boolean;
  v_variant  jsonb;
  v_vid      uuid;
  v_size     text;
  v_color    text;
  v_hex      text;
  v_stock    int;
  v_base_stk int;
  v_kept     uuid[] := '{}';
  v_path     text;
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if jsonb_typeof(p_product) is distinct from 'object'
     or jsonb_typeof(p_variants) is distinct from 'array'
     or jsonb_typeof(p_images) is distinct from 'array' then
    raise exception 'invalid_payload' using errcode = '22023';
  end if;

  v_id := (p_product ->> 'id')::uuid;
  v_name := regexp_replace(trim(coalesce(p_product ->> 'name', '')), '\s+', ' ', 'g');
  if v_id is null or length(v_name) not between 1 and 120 then
    raise exception 'invalid_product' using errcode = '22023';
  end if;

  if jsonb_array_length(p_variants) not between 1 and 100 then
    raise exception 'invalid_variants' using errcode = '22023';
  end if;
  if jsonb_array_length(p_images) > 8 then
    raise exception 'too_many_images' using errcode = '22023';
  end if;

  -- Produto ------------------------------------------------------------------
  select true into v_exists from public.products where id = v_id for update;

  if v_exists then
    update public.products set
      name             = v_name,
      description      = nullif(trim(p_product ->> 'description'), ''),
      gender           = (p_product ->> 'gender')::public.gender_type,
      category_id      = (p_product ->> 'category_id')::uuid,
      base_price       = (p_product ->> 'base_price')::numeric,
      compare_at_price = (p_product ->> 'compare_at_price')::numeric,
      is_active        = coalesce((p_product ->> 'is_active')::boolean, true),
      is_featured      = coalesce((p_product ->> 'is_featured')::boolean, false)
    where id = v_id
    returning slug into v_slug;
  else
    -- Slug só nasce na criação: renomear a peça não quebra links já enviados.
    v_base := coalesce(nullif(public.slugify(v_name), ''), 'peca');
    v_slug := v_base;
    while exists (select 1 from public.products p where p.slug = v_slug) loop
      v_n := v_n + 1;
      v_slug := v_base || '-' || v_n;
    end loop;

    insert into public.products
      (id, name, slug, description, gender, category_id, base_price,
       compare_at_price, is_active, is_featured)
    values (
      v_id, v_name, v_slug,
      nullif(trim(p_product ->> 'description'), ''),
      (p_product ->> 'gender')::public.gender_type,
      (p_product ->> 'category_id')::uuid,
      (p_product ->> 'base_price')::numeric,
      (p_product ->> 'compare_at_price')::numeric,
      coalesce((p_product ->> 'is_active')::boolean, true),
      coalesce((p_product ->> 'is_featured')::boolean, false)
    );
  end if;

  -- Fotos ---------------------------------------------------------------------
  for v_path in select value from jsonb_array_elements_text(p_images) loop
    if v_path !~ ('^' || v_id::text || '/[A-Za-z0-9_-]{1,64}\.(jpg|jpeg|png|webp)$') then
      raise exception 'invalid_image' using errcode = '22023';
    end if;
    if not exists (
      select 1 from storage.objects o
       where o.bucket_id = 'product-images' and o.name = v_path
    ) then
      raise exception 'image_not_found' using errcode = '22023';
    end if;
  end loop;
  if (select count(distinct value) from jsonb_array_elements_text(p_images))
     <> jsonb_array_length(p_images) then
    raise exception 'invalid_image' using errcode = '22023';
  end if;

  delete from public.product_images where product_id = v_id;
  insert into public.product_images (product_id, storage_path, position)
  select v_id, e.value, e.ord - 1
    from jsonb_array_elements_text(p_images) with ordinality as e(value, ord);

  -- Variantes -----------------------------------------------------------------
  if (
    select count(*) from (
      select distinct lower(trim(v ->> 'size')), lower(trim(v ->> 'color_name'))
        from jsonb_array_elements(p_variants) v
    ) d
  ) <> jsonb_array_length(p_variants) then
    raise exception 'duplicate_variant' using errcode = '22023';
  end if;

  for v_variant in select value from jsonb_array_elements(p_variants) loop
    v_vid := (v_variant ->> 'id')::uuid;
    if v_vid is not null then
      if not exists (
        select 1 from public.product_variants
         where id = v_vid and product_id = v_id
      ) then
        raise exception 'invalid_variant' using errcode = '22023';
      end if;
      v_kept := v_kept || v_vid;
    end if;
  end loop;

  -- 1) Saíram do formulário: com pedido → desativa; sem pedido → apaga.
  update public.product_variants pv
     set is_active = false
   where pv.product_id = v_id
     and pv.id <> all (v_kept)
     and exists (select 1 from public.order_items oi where oi.variant_id = pv.id);

  delete from public.product_variants pv
   where pv.product_id = v_id
     and pv.id <> all (v_kept)
     and not exists (select 1 from public.order_items oi where oi.variant_id = pv.id);

  -- 2) Atualiza as que ficaram e cria as novas.
  for v_variant in select value from jsonb_array_elements(p_variants) loop
    v_vid      := (v_variant ->> 'id')::uuid;
    v_size     := trim(v_variant ->> 'size');
    v_color    := regexp_replace(trim(coalesce(v_variant ->> 'color_name', '')), '\s+', ' ', 'g');
    v_hex      := nullif(trim(v_variant ->> 'color_hex'), '');
    v_stock    := (v_variant ->> 'stock')::int;
    v_base_stk := (v_variant ->> 'base_stock')::int;

    if v_stock is null or v_stock not between 0 and 99999 then
      raise exception 'invalid_stock' using errcode = '22023';
    end if;

    if v_vid is not null then
      update public.product_variants set
        size       = v_size,
        color_name = v_color,
        color_hex  = v_hex,
        is_active  = true,
        stock_qty  = case
          when v_base_stk is null then v_stock
          else greatest(0, stock_qty + (v_stock - v_base_stk))
        end
      where id = v_vid;
    else
      insert into public.product_variants
        (product_id, size, color_name, color_hex, stock_qty)
      values (v_id, v_size, v_color, v_hex, v_stock)
      on conflict (product_id, size, color_name) do update set
        color_hex = excluded.color_hex,
        stock_qty = excluded.stock_qty,
        is_active = true;
    end if;
  end loop;

  return jsonb_build_object('id', v_id, 'slug', v_slug);
end;
$$;

comment on function public.save_product(jsonb, jsonb, jsonb) is
  'Admin: cria/edita peça + variantes (estoque por diferença) + fotos, numa transação.';

-- -----------------------------------------------------------------------------
-- Permissões: só quem está logado chama (o RLS/is_admin decide o resto).
-- `slugify` é chamada de dentro das funções invoker, então o papel logado
-- precisa executá-la; é uma função pura, sem acesso a dados.
-- -----------------------------------------------------------------------------
revoke execute on function public.slugify(text) from public, anon;
revoke execute on function public.create_category(text, public.gender_type) from public, anon;
revoke execute on function public.save_product(jsonb, jsonb, jsonb) from public, anon;

grant execute on function public.slugify(text) to authenticated;
grant execute on function public.create_category(text, public.gender_type) to authenticated;
grant execute on function public.save_product(jsonb, jsonb, jsonb) to authenticated;
