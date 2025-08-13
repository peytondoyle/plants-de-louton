-- Plant Search Cache table for AI search results
create table if not exists plant_search_cache (
  id uuid primary key default gen_random_uuid(),
  query text not null unique,
  results jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Create index for fast query lookups
create index if not exists plant_search_cache_query_idx on plant_search_cache(query);
create index if not exists plant_search_cache_created_at_idx on plant_search_cache(created_at);

-- Enable RLS
alter table plant_search_cache enable row level security;

-- RLS Policies
create policy psc_select on plant_search_cache for select using (true);
create policy psc_insert on plant_search_cache for insert with check (true);
create policy psc_update on plant_search_cache for update using (true) with check (true);
create policy psc_delete on plant_search_cache for delete using (true);

-- Update trigger for updated_at
create trigger update_plant_search_cache_updated_at before update on plant_search_cache
  for each row execute function update_updated_at_column();

-- Clean up old cache entries (older than 30 days)
create or replace function cleanup_old_search_cache()
returns void as $$
begin
  delete from plant_search_cache 
  where created_at < now() - interval '30 days';
end;
$$ language plpgsql;

-- Optional: Set up a scheduled job to clean old cache entries
-- This would require pg_cron extension which may not be available in free tier
-- select cron.schedule('cleanup-search-cache', '0 2 * * *', 'select cleanup_old_search_cache();');
