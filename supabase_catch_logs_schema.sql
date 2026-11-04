-- Run this migration in Supabase SQL Editor before testing fisherman catch sync.
-- The mobile catch form writes these fields to public.catch_logs.

ALTER TYPE public.market_stage
  ADD VALUE IF NOT EXISTS 'direct_selling';

ALTER TABLE public.catch_logs
  ADD COLUMN IF NOT EXISTS client_catch_id uuid DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS banyera_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS logged_by_id uuid,
  ADD COLUMN IF NOT EXISTS landing_date_time timestamptz,
  ADD COLUMN IF NOT EXISTS supply_source text,
  ADD COLUMN IF NOT EXISTS marketplace_stage text,
  ADD COLUMN IF NOT EXISTS auction_state text,
  ADD COLUMN IF NOT EXISTS current_highest_bid numeric,
  ADD COLUMN IF NOT EXISTS final_price numeric,
  ADD COLUMN IF NOT EXISTS legality_status boolean DEFAULT true;

UPDATE public.catch_logs
SET client_catch_id = gen_random_uuid()
WHERE client_catch_id IS NULL;

CREATE INDEX IF NOT EXISTS catch_logs_fisherman_id_idx
  ON public.catch_logs (fisherman_id);

CREATE UNIQUE INDEX IF NOT EXISTS catch_logs_client_catch_id_uidx
  ON public.catch_logs (client_catch_id)
  WHERE client_catch_id IS NOT NULL;

-- The sync upsert uses ON CONFLICT (client_catch_id), which requires a
-- non-partial unique index. Keep the legacy partial index above for
-- compatibility and add the conflict target used by SyncManager.
CREATE UNIQUE INDEX IF NOT EXISTS catch_logs_client_catch_id_unique_idx
  ON public.catch_logs (client_catch_id);

CREATE INDEX IF NOT EXISTS catch_logs_marketplace_stage_idx
  ON public.catch_logs (marketplace_stage);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'catch_logs'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.catch_logs;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'transactions'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.transactions;
  END IF;
END
$$;
