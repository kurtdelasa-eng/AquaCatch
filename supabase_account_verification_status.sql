BEGIN;

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS verification_status text,
  ADD COLUMN IF NOT EXISTS verified_at timestamptz,
  ADD COLUMN IF NOT EXISTS rejected_at timestamptz;

UPDATE public.users
SET
  verification_status = CASE
    WHEN is_verified = true THEN 'APPROVED'
    ELSE 'PENDING'
  END,
  verified_at = CASE
    WHEN is_verified = true AND verified_at IS NULL THEN now()
    ELSE verified_at
  END
WHERE verification_status IS NULL;

ALTER TABLE public.users
  ALTER COLUMN verification_status SET DEFAULT 'PENDING',
  ALTER COLUMN verification_status SET NOT NULL;

ALTER TABLE public.users
  DROP CONSTRAINT IF EXISTS users_verification_status_check;

ALTER TABLE public.users
  ADD CONSTRAINT users_verification_status_check
  CHECK (verification_status IN ('PENDING', 'APPROVED', 'REJECTED'));

COMMIT;
