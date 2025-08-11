-- Plants table (if not exists)
create table if not exists plants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  scientific_name text,
  notes text,
  created_at timestamptz not null default now()
);

-- Pins: ensure plant_id column exists
alter table pins
  add column if not exists plant_id uuid references plants(id) on delete set null;
create index if not exists pins_plant_id_idx on pins(plant_id);

-- Plant media table
create table if not exists plant_media (
  id uuid primary key default gen_random_uuid(),
  plant_id uuid not null references plants(id) on delete cascade,
  image_id uuid references bed_images(id) on delete set null,
  pin_id uuid references pins(id) on delete set null,
  storage_path text not null,
  caption text,
  captured_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists plant_media_plant_idx on plant_media(plant_id);
create index if not exists plant_media_image_idx on plant_media(image_id);
create index if not exists plant_media_pin_idx on plant_media(pin_id);

-- RLS
alter table plant_media enable row level security;
create policy if not exists pm_select on plant_media for select using (true);
create policy if not exists pm_insert on plant_media for insert with check (true);
create policy if not exists pm_update on plant_media for update using (true) with check (true);
create policy if not exists pm_delete on plant_media for delete using (true);


