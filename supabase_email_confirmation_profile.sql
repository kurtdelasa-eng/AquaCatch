BEGIN;

CREATE OR REPLACE FUNCTION public.create_pending_profile_for_confirmed_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  requested_role text;
BEGIN
  IF NEW.email_confirmed_at IS NULL THEN
    RETURN NEW;
  END IF;

  requested_role := CASE lower(COALESCE(NEW.raw_user_meta_data ->> 'requested_role', ''))
    WHEN 'buyer' THEN 'Buyer'
    WHEN 'fisherman' THEN 'Fisherman'
    ELSE NULL
  END;

  IF requested_role IS NULL THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.users (
    user_id,
    full_name,
    contact_number,
    role,
    requested_role,
    permit_id_number,
    permit_document_path,
    is_verified,
    verification_status
  )
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data ->> 'full_name',
    NEW.raw_user_meta_data ->> 'contact_number',
    requested_role,
    requested_role,
    NEW.raw_user_meta_data ->> 'permit_id_number',
    NEW.raw_user_meta_data ->> 'permit_document_path',
    false,
    'PENDING'
  )
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS create_pending_profile_after_email_confirmation
  ON auth.users;

CREATE TRIGGER create_pending_profile_after_email_confirmation
  AFTER INSERT OR UPDATE OF email_confirmed_at ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.create_pending_profile_for_confirmed_user();

COMMIT;
