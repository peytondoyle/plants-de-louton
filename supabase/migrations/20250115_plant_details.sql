-- Plant Details table (species-level information)
create table if not exists plant_details (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  scientific_name text,
  common_names text[], -- array of common names
  family text,
  genus text,
  species text,
  cultivar text,
  
  -- Growth Characteristics
  growth_habit text check (growth_habit in ('annual', 'perennial', 'biennial', 'shrub', 'tree', 'vine', 'groundcover')),
  hardiness_zones integer[], -- array of zone numbers
  sun_exposure text check (sun_exposure in ('full_sun', 'partial_sun', 'partial_shade', 'full_shade')),
  water_needs text check (water_needs in ('low', 'moderate', 'high')),
  mature_height integer, -- in inches
  mature_width integer, -- in inches
  
  -- Blooming & Seasons
  bloom_time text check (bloom_time in ('spring', 'summer', 'fall', 'winter', 'year_round')),
  bloom_duration integer, -- weeks
  flower_color text[], -- array of colors
  foliage_color text[], -- array of colors
  
  -- Care Requirements
  soil_type text check (soil_type in ('clay', 'loam', 'sandy', 'well_draining')),
  soil_ph text check (soil_ph in ('acidic', 'neutral', 'alkaline')),
  fertilizer_needs text check (fertilizer_needs in ('low', 'moderate', 'high')),
  pruning_needs text check (pruning_needs in ('minimal', 'moderate', 'heavy')),
  
  -- Planting Info
  planting_season text check (planting_season in ('spring', 'summer', 'fall', 'winter')),
  planting_depth integer, -- inches
  spacing integer, -- inches between plants
  
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Plant Instances table (individual plant tracking)
create table if not exists plant_instances (
  id uuid primary key default gen_random_uuid(),
  plant_details_id uuid not null references plant_details(id) on delete cascade,
  bed_id uuid not null references beds(id) on delete cascade,
  pin_id uuid not null references pins(id) on delete cascade,
  
  -- Instance-specific data
  planted_date date,
  source text check (source in ('nursery', 'seed', 'cutting', 'division', 'gift', 'other')),
  source_notes text,
  cost decimal(10,2),
  
  -- Health & Status
  health_status text check (health_status in ('excellent', 'good', 'fair', 'poor', 'dead')) default 'good',
  notes text,
  
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Care Events table (care history)
create table if not exists care_events (
  id uuid primary key default gen_random_uuid(),
  plant_instance_id uuid not null references plant_instances(id) on delete cascade,
  event_type text check (event_type in ('watering', 'fertilizing', 'pruning', 'pest_treatment', 'disease_treatment', 'transplanting', 'harvesting', 'other')),
  event_date date not null,
  description text not null,
  notes text,
  cost decimal(10,2),
  images text[], -- array of image URLs
  
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Add missing columns to pins table
alter table pins
  add column if not exists plant_instance_id uuid references plant_instances(id) on delete set null,
  add column if not exists plant_details_id uuid references plant_details(id) on delete set null,
  add column if not exists status text check (status in ('active', 'dormant', 'removed', 'dead')) default 'active',
  add column if not exists last_care_date date,
  add column if not exists next_care_date date;

-- Create indexes for performance
create index if not exists plant_details_name_idx on plant_details(name);
create index if not exists plant_details_scientific_name_idx on plant_details(scientific_name);
create index if not exists plant_instances_bed_idx on plant_instances(bed_id);
create index if not exists plant_instances_pin_idx on plant_instances(pin_id);
create index if not exists plant_instances_details_idx on plant_instances(plant_details_id);
create index if not exists care_events_instance_idx on care_events(plant_instance_id);
create index if not exists care_events_date_idx on care_events(event_date);
create index if not exists pins_instance_idx on pins(plant_instance_id);
create index if not exists pins_details_idx on pins(plant_details_id);

-- Enable RLS
alter table plant_details enable row level security;
alter table plant_instances enable row level security;
alter table care_events enable row level security;

-- RLS Policies
create policy pd_select on plant_details for select using (true);
create policy pd_insert on plant_details for insert with check (true);
create policy pd_update on plant_details for update using (true) with check (true);
create policy pd_delete on plant_details for delete using (true);

create policy pi_select on plant_instances for select using (true);
create policy pi_insert on plant_instances for insert with check (true);
create policy pi_update on plant_instances for update using (true) with check (true);
create policy pi_delete on plant_instances for delete using (true);

create policy ce_select on care_events for select using (true);
create policy ce_insert on care_events for insert with check (true);
create policy ce_update on care_events for update using (true) with check (true);
create policy ce_delete on care_events for delete using (true);

-- Update triggers for updated_at
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger update_plant_details_updated_at before update on plant_details
  for each row execute function update_updated_at_column();

create trigger update_plant_instances_updated_at before update on plant_instances
  for each row execute function update_updated_at_column();

create trigger update_care_events_updated_at before update on care_events
  for each row execute function update_updated_at_column();
