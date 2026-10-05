-- Remove o catálogo de demonstração (IDs com o marcador "dede").
-- Pedidos de teste feitos com peças demo também são apagados.
delete from public.order_items
 where variant_id in (select id from public.product_variants where id::text like 'dede0000-%');
delete from public.orders o
 where not exists (select 1 from public.order_items i where i.order_id = o.id);
delete from public.product_variants where id::text like 'dede0000-%';
delete from public.product_images  where product_id::text like 'dede0000-%';
delete from public.products        where id::text like 'dede0000-%';
delete from public.categories      where id::text like 'dede0000-%';
