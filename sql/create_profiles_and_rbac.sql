-- Simple RBAC for Supabase Auth users.
-- First existing/new user becomes admin; all following users become empleado.

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  full_name text,
  role text not null default 'empleado' check (role in ('admin', 'empleado')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

create or replace function public.prevent_last_admin_removal()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if tg_op = 'UPDATE' then
    if old.role = 'admin'
      and new.role <> 'admin'
      and not exists (
        select 1
        from public.profiles p
        where p.id <> old.id
          and p.role = 'admin'
      ) then
      raise exception 'Debe existir al menos un administrador activo';
    end if;

    return new;
  end if;

  if tg_op = 'DELETE' then
    if old.role = 'admin'
      and not exists (
        select 1
        from public.profiles p
        where p.id <> old.id
          and p.role = 'admin'
      ) then
      raise exception 'No puedes eliminar al ultimo administrador';
    end if;

    return old;
  end if;

  return coalesce(new, old);
end;
$$;

drop trigger if exists prevent_last_admin_role_update on public.profiles;
create trigger prevent_last_admin_role_update
before update of role on public.profiles
for each row
execute function public.prevent_last_admin_removal();

drop trigger if exists prevent_last_admin_delete on public.profiles;
create trigger prevent_last_admin_delete
before delete on public.profiles
for each row
execute function public.prevent_last_admin_removal();

create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  bootstrap_role text := 'empleado';
begin
  if not exists (select 1 from public.profiles) then
    bootstrap_role := 'admin';
  end if;

  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    bootstrap_role
  )
  on conflict (id) do update
  set email = excluded.email,
      full_name = coalesce(excluded.full_name, public.profiles.full_name);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_create_profile on auth.users;
create trigger on_auth_user_created_create_profile
after insert on auth.users
for each row
execute function public.handle_new_user_profile();

with ranked_users as (
  select
    u.id,
    u.email,
    coalesce(u.raw_user_meta_data ->> 'full_name', u.raw_user_meta_data ->> 'name') as full_name,
    row_number() over (order by u.created_at, u.id) as rn
  from auth.users u
)
insert into public.profiles (id, email, full_name, role)
select
  ru.id,
  ru.email,
  ru.full_name,
  case
    when not exists (select 1 from public.profiles) and ru.rn = 1 then 'admin'
    else 'empleado'
  end as role
from ranked_users ru
where not exists (
  select 1
  from public.profiles p
  where p.id = ru.id
);

create or replace function public.current_app_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select p.role
  from public.profiles p
  where p.id = auth.uid();
$$;

create or replace function public.has_app_role(allowed_roles text[])
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.role() = 'authenticated'
    and coalesce(public.current_app_role() = any (allowed_roles), false);
$$;

create or replace function public.require_app_role(allowed_roles text[])
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.has_app_role(allowed_roles) then
    raise exception 'Permisos insuficientes para esta operación';
  end if;
end;
$$;

grant select, update on public.profiles to authenticated;

alter table if exists public.profiles enable row level security;
alter table if exists public.clientes enable row level security;
alter table if exists public.productos enable row level security;
alter table if exists public.pedidos enable row level security;
alter table if exists public.pedido_items enable row level security;
alter table if exists public.pagos enable row level security;
alter table if exists public.gastos enable row level security;

drop policy if exists "profiles_select_self_or_admin" on public.profiles;
create policy "profiles_select_self_or_admin"
on public.profiles
for select
to authenticated
using (id = auth.uid() or public.has_app_role(array['admin']));

drop policy if exists "profiles_update_admin_only" on public.profiles;
create policy "profiles_update_admin_only"
on public.profiles
for update
to authenticated
using (public.has_app_role(array['admin']))
with check (public.has_app_role(array['admin']));

drop policy if exists "clientes_select_authenticated" on public.clientes;
create policy "clientes_select_authenticated"
on public.clientes
for select
to authenticated
using (public.has_app_role(array['admin', 'empleado']));

drop policy if exists "clientes_write_admin_only" on public.clientes;
create policy "clientes_write_admin_only"
on public.clientes
for all
to authenticated
using (public.has_app_role(array['admin']))
with check (public.has_app_role(array['admin']));

drop policy if exists "productos_select_authenticated" on public.productos;
create policy "productos_select_authenticated"
on public.productos
for select
to authenticated
using (public.has_app_role(array['admin', 'empleado']));

drop policy if exists "productos_write_admin_only" on public.productos;
create policy "productos_write_admin_only"
on public.productos
for all
to authenticated
using (public.has_app_role(array['admin']))
with check (public.has_app_role(array['admin']));

drop policy if exists "pedidos_select_authenticated" on public.pedidos;
create policy "pedidos_select_authenticated"
on public.pedidos
for select
to authenticated
using (public.has_app_role(array['admin', 'empleado']));

drop policy if exists "pedidos_insert_authenticated" on public.pedidos;
create policy "pedidos_insert_authenticated"
on public.pedidos
for insert
to authenticated
with check (public.has_app_role(array['admin', 'empleado']));

drop policy if exists "pedidos_update_authenticated" on public.pedidos;
create policy "pedidos_update_authenticated"
on public.pedidos
for update
to authenticated
using (public.has_app_role(array['admin', 'empleado']))
with check (public.has_app_role(array['admin', 'empleado']));

drop policy if exists "pedidos_delete_admin_only" on public.pedidos;
create policy "pedidos_delete_admin_only"
on public.pedidos
for delete
to authenticated
using (public.has_app_role(array['admin']));

drop policy if exists "pedido_items_select_authenticated" on public.pedido_items;
create policy "pedido_items_select_authenticated"
on public.pedido_items
for select
to authenticated
using (public.has_app_role(array['admin', 'empleado']));

drop policy if exists "pedido_items_insert_authenticated" on public.pedido_items;
create policy "pedido_items_insert_authenticated"
on public.pedido_items
for insert
to authenticated
with check (public.has_app_role(array['admin', 'empleado']));

drop policy if exists "pedido_items_update_authenticated" on public.pedido_items;
create policy "pedido_items_update_authenticated"
on public.pedido_items
for update
to authenticated
using (public.has_app_role(array['admin', 'empleado']))
with check (public.has_app_role(array['admin', 'empleado']));

drop policy if exists "pedido_items_delete_authenticated" on public.pedido_items;
create policy "pedido_items_delete_authenticated"
on public.pedido_items
for delete
to authenticated
using (public.has_app_role(array['admin', 'empleado']));

drop policy if exists "pagos_select_authenticated" on public.pagos;
create policy "pagos_select_authenticated"
on public.pagos
for select
to authenticated
using (public.has_app_role(array['admin', 'empleado']));

drop policy if exists "pagos_insert_authenticated" on public.pagos;
create policy "pagos_insert_authenticated"
on public.pagos
for insert
to authenticated
with check (public.has_app_role(array['admin', 'empleado']));

drop policy if exists "pagos_update_admin_only" on public.pagos;
create policy "pagos_update_admin_only"
on public.pagos
for update
to authenticated
using (public.has_app_role(array['admin']))
with check (public.has_app_role(array['admin']));

drop policy if exists "pagos_delete_admin_only" on public.pagos;
create policy "pagos_delete_admin_only"
on public.pagos
for delete
to authenticated
using (public.has_app_role(array['admin']));

drop policy if exists "gastos_admin_only" on public.gastos;
create policy "gastos_admin_only"
on public.gastos
for all
to authenticated
using (public.has_app_role(array['admin']))
with check (public.has_app_role(array['admin']));

-- Manual promotion example:
-- update public.profiles set role = 'admin' where email = 'dueno@tuimprenta.com';