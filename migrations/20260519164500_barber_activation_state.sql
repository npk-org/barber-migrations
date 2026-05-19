-- Add activation lifecycle columns to barber_profiles.
-- Managed by barber-svc reaper (see barber-barber-svc/internal/reaper).
--
-- States: pending_profile | pending_admin_verify | active | abandoned | suspended

ALTER TABLE "public"."barber_profiles"
  ADD COLUMN "activation_state" VARCHAR(32) NOT NULL DEFAULT 'pending_profile',
  ADD COLUMN "state_changed_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  ADD COLUMN "last_active_at"   TIMESTAMPTZ NOT NULL DEFAULT now(),
  ADD COLUMN "last_reminder_at" TIMESTAMPTZ;

ALTER TABLE "public"."barber_profiles"
  ADD CONSTRAINT "barber_profiles_activation_state_check"
    CHECK (activation_state IN ('pending_profile','pending_admin_verify','active','abandoned','suspended'));

CREATE INDEX IF NOT EXISTS "barber_profiles_state_idx"
  ON "public"."barber_profiles" (activation_state, last_active_at);

-- Existing rows (seeded via tests) had verified_at set already -> treat as active.
UPDATE "public"."barber_profiles" SET activation_state = 'active'
WHERE verified_at IS NOT NULL;
