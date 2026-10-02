-- =============================================================================
-- Storage: bucket público de imagens de produto (leitura pública, escrita admin)
-- ADR-0002 · RNF-08 (imagens comprimidas no cliente, ≤ 5 MB aqui por segurança)
-- =============================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-images',
  'product-images',
  true,
  5 * 1024 * 1024,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Bucket público = URL pública de download sem policy de SELECT.
-- Não criamos policy de SELECT para anon: impede LISTAR todos os arquivos.

create policy "admin envia imagens de produto"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'product-images' and (select public.is_admin()));

create policy "admin altera imagens de produto"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'product-images' and (select public.is_admin()))
  with check (bucket_id = 'product-images' and (select public.is_admin()));

create policy "admin remove imagens de produto"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'product-images' and (select public.is_admin()));

-- Admin precisa de SELECT para upsert/remoção pela API.
create policy "admin lista imagens de produto"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'product-images' and (select public.is_admin()));
