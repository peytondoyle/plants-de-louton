-- Fix RLS policies to require authentication
-- This migration updates all RLS policies to require a valid user session

-- Drop existing policies (these will fail if they don't exist, but that's okay)
drop policy if exists pd_select on plant_details;
drop policy if exists pd_insert on plant_details;
drop policy if exists pd_update on plant_details;
drop policy if exists pd_delete on plant_details;

drop policy if exists pi_select on plant_instances;
drop policy if exists pi_insert on plant_instances;
drop policy if exists pi_update on plant_instances;
drop policy if exists pi_delete on plant_instances;

drop policy if exists ce_select on care_events;
drop policy if exists ce_insert on care_events;
drop policy if exists ce_update on care_events;
drop policy if exists ce_delete on care_events;

drop policy if exists psc_select on plant_search_cache;
drop policy if exists psc_insert on plant_search_cache;
drop policy if exists psc_update on plant_search_cache;
drop policy if exists psc_delete on plant_search_cache;

-- Create new authenticated policies for plant_details
create policy pd_select on plant_details for select using (auth.uid() is not null);
create policy pd_insert on plant_details for insert with check (auth.uid() is not null);
create policy pd_update on plant_details for update using (auth.uid() is not null) with check (auth.uid() is not null);
create policy pd_delete on plant_details for delete using (auth.uid() is not null);

-- Create new authenticated policies for plant_instances
create policy pi_select on plant_instances for select using (auth.uid() is not null);
create policy pi_insert on plant_instances for insert with check (auth.uid() is not null);
create policy pi_update on plant_instances for update using (auth.uid() is not null) with check (auth.uid() is not null);
create policy pi_delete on plant_instances for delete using (auth.uid() is not null);

-- Create new authenticated policies for care_events
create policy ce_select on care_events for select using (auth.uid() is not null);
create policy ce_insert on care_events for insert with check (auth.uid() is not null);
create policy ce_update on care_events for update using (auth.uid() is not null) with check (auth.uid() is not null);
create policy ce_delete on care_events for delete using (auth.uid() is not null);

-- Create new authenticated policies for plant_search_cache
create policy psc_select on plant_search_cache for select using (auth.uid() is not null);
create policy psc_insert on plant_search_cache for insert with check (auth.uid() is not null);
create policy psc_update on plant_search_cache for update using (auth.uid() is not null) with check (auth.uid() is not null);
create policy psc_delete on plant_search_cache for delete using (auth.uid() is not null);

-- Enable RLS on pins and beds tables if not already enabled
alter table pins enable row level security;
alter table beds enable row level security;

-- Drop existing policies for pins and beds if they exist
drop policy if exists pins_select on pins;
drop policy if exists pins_insert on pins;
drop policy if exists pins_update on pins;
drop policy if exists pins_delete on pins;

drop policy if exists beds_select on beds;
drop policy if exists beds_insert on beds;
drop policy if exists beds_update on beds;
drop policy if exists beds_delete on beds;

-- Create authenticated policies for pins table
create policy pins_select on pins for select using (auth.uid() is not null);
create policy pins_insert on pins for insert with check (auth.uid() is not null);
create policy pins_update on pins for update using (auth.uid() is not null) with check (auth.uid() is not null);
create policy pins_delete on pins for delete using (auth.uid() is not null);

-- Create authenticated policies for beds table
create policy beds_select on beds for select using (auth.uid() is not null);
create policy beds_insert on beds for insert with check (auth.uid() is not null);
create policy beds_update on beds for update using (auth.uid() is not null) with check (auth.uid() is not null);
create policy beds_delete on beds for delete using (auth.uid() is not null);
