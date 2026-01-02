/* Create gastos table to record expenses */
create table if not exists public.gastos (
  id uuid default gen_random_uuid() primary key,
  descripcion text,
  monto numeric not null,
  producto_id uuid references public.productos(id) on delete set null,
  referencia text,
  meta jsonb,
  created_at timestamptz default now()
);
