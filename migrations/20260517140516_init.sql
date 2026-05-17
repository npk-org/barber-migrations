-- Create "auth_signing_keys" table
CREATE TABLE "public"."auth_signing_keys" (
  "id" text NOT NULL,
  "kid" character varying(64) NOT NULL,
  "algorithm" character varying(16) NOT NULL,
  "public_jwk" jsonb NOT NULL,
  "private_pem" bytea NOT NULL,
  "is_active" boolean NOT NULL DEFAULT false,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "rotated_at" timestamptz NULL,
  "retired_at" timestamptz NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "auth_signing_keys_algorithm_check" CHECK ((algorithm)::text = ANY ((ARRAY['RS256'::character varying, 'EdDSA'::character varying])::text[]))
);
-- Create index "auth_signing_keys_kid_uq" to table: "auth_signing_keys"
CREATE UNIQUE INDEX "auth_signing_keys_kid_uq" ON "public"."auth_signing_keys" ("kid");
-- Create index "auth_signing_keys_one_active" to table: "auth_signing_keys"
CREATE UNIQUE INDEX "auth_signing_keys_one_active" ON "public"."auth_signing_keys" ((true)) WHERE (is_active = true);
-- Create "users" table
CREATE TABLE "public"."users" (
  "id" text NOT NULL,
  "role" character varying(16) NOT NULL,
  "email" character varying(255) NOT NULL,
  "phone" character varying(20) NOT NULL,
  "phone_verified" boolean NOT NULL DEFAULT false,
  "password_hash" text NOT NULL,
  "display_name" character varying(80) NOT NULL,
  "language" character varying(8) NOT NULL DEFAULT 'th',
  "status" character varying(16) NOT NULL DEFAULT 'pending',
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "deleted_at" timestamptz NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "users_language_check" CHECK ((language)::text = ANY ((ARRAY['th'::character varying, 'en'::character varying])::text[])),
  CONSTRAINT "users_role_check" CHECK ((role)::text = ANY ((ARRAY['customer'::character varying, 'barber'::character varying, 'shop_owner'::character varying, 'admin'::character varying])::text[])),
  CONSTRAINT "users_status_check" CHECK ((status)::text = ANY ((ARRAY['active'::character varying, 'suspended'::character varying, 'pending'::character varying])::text[]))
);
-- Create index "users_email_uq" to table: "users"
CREATE UNIQUE INDEX "users_email_uq" ON "public"."users" ("email");
-- Create index "users_phone_uq" to table: "users"
CREATE UNIQUE INDEX "users_phone_uq" ON "public"."users" ("phone");
-- Create index "users_role_idx" to table: "users"
CREATE INDEX "users_role_idx" ON "public"."users" ("role");
-- Create "audit_logs" table
CREATE TABLE "public"."audit_logs" (
  "id" bigserial NOT NULL,
  "actor_id" text NULL,
  "action" character varying(60) NOT NULL,
  "entity_type" character varying(30) NOT NULL,
  "entity_id" text NOT NULL,
  "before" jsonb NULL,
  "after" jsonb NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "audit_logs_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE SET NULL
);
-- Create index "audit_logs_action_idx" to table: "audit_logs"
CREATE INDEX "audit_logs_action_idx" ON "public"."audit_logs" ("action", "created_at" DESC);
-- Create index "audit_logs_actor_idx" to table: "audit_logs"
CREATE INDEX "audit_logs_actor_idx" ON "public"."audit_logs" ("actor_id", "created_at" DESC);
-- Create index "audit_logs_entity_idx" to table: "audit_logs"
CREATE INDEX "audit_logs_entity_idx" ON "public"."audit_logs" ("entity_type", "entity_id", "created_at" DESC);
-- Create "auth_refresh_tokens" table
CREATE TABLE "public"."auth_refresh_tokens" (
  "id" text NOT NULL,
  "user_id" text NOT NULL,
  "token_hash" bytea NOT NULL,
  "issued_at" timestamptz NOT NULL DEFAULT now(),
  "expires_at" timestamptz NOT NULL,
  "revoked_at" timestamptz NULL,
  "replaced_by_id" text NULL,
  "user_agent" character varying(255) NULL,
  "ip_address" inet NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "auth_refresh_tokens_replaced_by_id_fkey" FOREIGN KEY ("replaced_by_id") REFERENCES "public"."auth_refresh_tokens" ("id") ON UPDATE NO ACTION ON DELETE SET NULL,
  CONSTRAINT "auth_refresh_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "auth_refresh_tokens_hash_uq" to table: "auth_refresh_tokens"
CREATE UNIQUE INDEX "auth_refresh_tokens_hash_uq" ON "public"."auth_refresh_tokens" ("token_hash");
-- Create index "auth_refresh_tokens_user_active_idx" to table: "auth_refresh_tokens"
CREATE INDEX "auth_refresh_tokens_user_active_idx" ON "public"."auth_refresh_tokens" ("user_id", "expires_at") WHERE (revoked_at IS NULL);
-- Create "barber_profiles" table
CREATE TABLE "public"."barber_profiles" (
  "user_id" text NOT NULL,
  "bio" text NULL,
  "photo_url" text NULL,
  "verified_at" timestamptz NULL,
  "avg_rating" numeric(3,2) NULL,
  "review_count" integer NOT NULL DEFAULT 0,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY ("user_id"),
  CONSTRAINT "barber_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create "shops" table
CREATE TABLE "public"."shops" (
  "id" text NOT NULL,
  "owner_id" text NOT NULL,
  "name" character varying(120) NOT NULL,
  "photo_url" text NULL,
  "address_line" character varying(255) NOT NULL,
  "district" character varying(80) NOT NULL,
  "province" character varying(80) NOT NULL,
  "postcode" character varying(10) NOT NULL,
  "latitude" numeric(9,6) NULL,
  "longitude" numeric(9,6) NULL,
  "contact_phone" character varying(20) NOT NULL,
  "line_id" character varying(60) NULL,
  "verified_at" timestamptz NULL,
  "avg_rating" numeric(3,2) NULL,
  "review_count" integer NOT NULL DEFAULT 0,
  "is_active" boolean NOT NULL DEFAULT true,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "shops_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE RESTRICT
);
-- Create index "shops_district_idx" to table: "shops"
CREATE INDEX "shops_district_idx" ON "public"."shops" ("district");
-- Create index "shops_owner_idx" to table: "shops"
CREATE INDEX "shops_owner_idx" ON "public"."shops" ("owner_id");
-- Create "chairs" table
CREATE TABLE "public"."chairs" (
  "id" text NOT NULL,
  "shop_id" text NOT NULL,
  "name" character varying(60) NOT NULL,
  "is_active" boolean NOT NULL DEFAULT true,
  "display_order" smallint NOT NULL DEFAULT 0,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "deleted_at" timestamptz NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "chairs_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "chairs_shop_idx" to table: "chairs"
CREATE INDEX "chairs_shop_idx" ON "public"."chairs" ("shop_id") WHERE (deleted_at IS NULL);
-- Create "service_templates" table
CREATE TABLE "public"."service_templates" (
  "id" text NOT NULL,
  "code" character varying(40) NOT NULL,
  "name_th" character varying(120) NOT NULL,
  "name_en" character varying(120) NOT NULL,
  "default_duration_minutes" integer NOT NULL,
  "default_buffer_minutes" integer NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "service_templates_buffer_check" CHECK (default_buffer_minutes >= 0),
  CONSTRAINT "service_templates_duration_check" CHECK (default_duration_minutes > 0)
);
-- Create index "service_templates_code_uq" to table: "service_templates"
CREATE UNIQUE INDEX "service_templates_code_uq" ON "public"."service_templates" ("code");
-- Create "services" table
CREATE TABLE "public"."services" (
  "id" text NOT NULL,
  "barber_id" text NOT NULL,
  "template_code" character varying(40) NULL,
  "name" character varying(120) NOT NULL,
  "description" text NULL,
  "price_satang" bigint NOT NULL,
  "duration_minutes" integer NOT NULL,
  "buffer_minutes" integer NOT NULL DEFAULT 10,
  "is_active" boolean NOT NULL DEFAULT true,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "deleted_at" timestamptz NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "services_barber_id_fkey" FOREIGN KEY ("barber_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "services_template_code_fkey" FOREIGN KEY ("template_code") REFERENCES "public"."service_templates" ("code") ON UPDATE NO ACTION ON DELETE SET NULL,
  CONSTRAINT "services_buffer_check" CHECK (buffer_minutes >= 0),
  CONSTRAINT "services_duration_check" CHECK (duration_minutes > 0),
  CONSTRAINT "services_price_check" CHECK (price_satang > 0)
);
-- Create index "services_barber_idx" to table: "services"
CREATE INDEX "services_barber_idx" ON "public"."services" ("barber_id") WHERE (deleted_at IS NULL);
-- Create "bookings" table
CREATE TABLE "public"."bookings" (
  "id" text NOT NULL,
  "code" character varying(16) NOT NULL,
  "customer_id" text NOT NULL,
  "shop_id" text NOT NULL,
  "service_id" text NOT NULL,
  "source" character varying(16) NOT NULL,
  "is_locked" boolean NOT NULL DEFAULT false,
  "locked_to_barber_id" text NULL,
  "assigned_barber_id" text NULL,
  "chair_id" text NULL,
  "status" character varying(24) NOT NULL,
  "scheduled_start" timestamptz NOT NULL,
  "scheduled_end" timestamptz NOT NULL,
  "current_start" timestamptz NOT NULL,
  "current_end" timestamptz NOT NULL,
  "started_at" timestamptz NULL,
  "finished_at" timestamptz NULL,
  "price_satang" bigint NOT NULL,
  "payment_mode" character varying(16) NOT NULL,
  "note" text NULL,
  "created_by_user_id" text NOT NULL,
  "cancelled_at" timestamptz NULL,
  "cancelled_by" character varying(16) NULL,
  "cancel_reason" text NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "no_overlap_per_barber" EXCLUDE USING GIST ("assigned_barber_id" WITH =, (tstzrange(current_start, current_end)) WITH &&) WHERE (((status)::text = ANY ((ARRAY['CONFIRMED'::character varying, 'IN_PROGRESS'::character varying])::text[])) AND (assigned_barber_id IS NOT NULL)),
  CONSTRAINT "no_overlap_per_chair" EXCLUDE USING GIST ("chair_id" WITH =, (tstzrange(current_start, current_end)) WITH &&) WHERE (((status)::text = 'IN_PROGRESS'::text) AND (chair_id IS NOT NULL)),
  CONSTRAINT "bookings_assigned_barber_id_fkey" FOREIGN KEY ("assigned_barber_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT "bookings_chair_id_fkey" FOREIGN KEY ("chair_id") REFERENCES "public"."chairs" ("id") ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT "bookings_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT "bookings_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT "bookings_locked_to_barber_id_fkey" FOREIGN KEY ("locked_to_barber_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT "bookings_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "public"."services" ("id") ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT "bookings_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops" ("id") ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT "bookings_cancelled_by_check" CHECK ((cancelled_by IS NULL) OR ((cancelled_by)::text = ANY ((ARRAY['customer'::character varying, 'barber'::character varying, 'shop'::character varying, 'system'::character varying])::text[]))),
  CONSTRAINT "bookings_locked_consistency" CHECK (((is_locked = false) AND (locked_to_barber_id IS NULL)) OR ((is_locked = true) AND (locked_to_barber_id IS NOT NULL) AND (assigned_barber_id = locked_to_barber_id))),
  CONSTRAINT "bookings_payment_mode_check" CHECK ((payment_mode)::text = ANY ((ARRAY['MOCK_APP'::character varying, 'ON_SITE'::character varying])::text[])),
  CONSTRAINT "bookings_price_check" CHECK (price_satang > 0),
  CONSTRAINT "bookings_source_check" CHECK ((source)::text = ANY ((ARRAY['APP'::character varying, 'MANUAL'::character varying])::text[])),
  CONSTRAINT "bookings_status_check" CHECK ((status)::text = ANY ((ARRAY['PENDING_PAYMENT'::character varying, 'CONFIRMED'::character varying, 'IN_PROGRESS'::character varying, 'COMPLETED'::character varying, 'CANCELLED'::character varying, 'CANCELLING'::character varying, 'NO_SHOW'::character varying])::text[])),
  CONSTRAINT "bookings_time_order_check" CHECK ((scheduled_end > scheduled_start) AND (current_end > current_start))
);
-- Create index "bookings_code_uq" to table: "bookings"
CREATE UNIQUE INDEX "bookings_code_uq" ON "public"."bookings" ("code");
-- Create index "idx_bookings_barber_day" to table: "bookings"
CREATE INDEX "idx_bookings_barber_day" ON "public"."bookings" ("assigned_barber_id", "current_start") WHERE (assigned_barber_id IS NOT NULL);
-- Create index "idx_bookings_customer" to table: "bookings"
CREATE INDEX "idx_bookings_customer" ON "public"."bookings" ("customer_id", "scheduled_start" DESC);
-- Create index "idx_bookings_locked" to table: "bookings"
CREATE INDEX "idx_bookings_locked" ON "public"."bookings" ("locked_to_barber_id", "current_start") WHERE (is_locked = true);
-- Create index "idx_bookings_shop_day" to table: "bookings"
CREATE INDEX "idx_bookings_shop_day" ON "public"."bookings" ("shop_id", "current_start");
-- Create index "one_active_per_customer_shop" to table: "bookings"
CREATE UNIQUE INDEX "one_active_per_customer_shop" ON "public"."bookings" ("customer_id", "shop_id") WHERE ((status)::text = ANY ((ARRAY['PENDING_PAYMENT'::character varying, 'CONFIRMED'::character varying, 'IN_PROGRESS'::character varying])::text[]));
-- Create "capacity_shortage_responses" table
CREATE TABLE "public"."capacity_shortage_responses" (
  "id" text NOT NULL,
  "booking_id" text NOT NULL,
  "trigger_barber_id" text NOT NULL,
  "notified_at" timestamptz NOT NULL DEFAULT now(),
  "response_deadline" timestamptz NOT NULL,
  "choice" character varying(24) NULL,
  "responded_at" timestamptz NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "capacity_shortage_responses_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "capacity_shortage_responses_trigger_barber_id_fkey" FOREIGN KEY ("trigger_barber_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT "capacity_shortage_choice_check" CHECK ((choice IS NULL) OR ((choice)::text = ANY ((ARRAY['KEEP'::character varying, 'CANCEL_REFUND'::character varying, 'AUTO_KEEP'::character varying, 'AUTO_CANCEL'::character varying])::text[])))
);
-- Create index "capacity_shortage_booking_uq" to table: "capacity_shortage_responses"
CREATE UNIQUE INDEX "capacity_shortage_booking_uq" ON "public"."capacity_shortage_responses" ("booking_id");
-- Create "notifications" table
CREATE TABLE "public"."notifications" (
  "id" text NOT NULL,
  "user_id" text NOT NULL,
  "type" character varying(40) NOT NULL,
  "channel" character varying(16) NOT NULL,
  "payload" jsonb NOT NULL DEFAULT '{}',
  "sent_at" timestamptz NULL,
  "read_at" timestamptz NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "notifications_channel_check" CHECK ((channel)::text = ANY ((ARRAY['push'::character varying, 'sms'::character varying, 'email'::character varying, 'inapp'::character varying])::text[]))
);
-- Create index "notifications_unsent_idx" to table: "notifications"
CREATE INDEX "notifications_unsent_idx" ON "public"."notifications" ("created_at") WHERE (sent_at IS NULL);
-- Create index "notifications_user_idx" to table: "notifications"
CREATE INDEX "notifications_user_idx" ON "public"."notifications" ("user_id", "created_at" DESC);
-- Create index "notifications_user_unread_idx" to table: "notifications"
CREATE INDEX "notifications_user_unread_idx" ON "public"."notifications" ("user_id") WHERE (read_at IS NULL);
-- Create "payments" table
CREATE TABLE "public"."payments" (
  "id" text NOT NULL,
  "booking_id" text NOT NULL,
  "amount_satang" bigint NOT NULL,
  "status" character varying(16) NOT NULL,
  "method" character varying(24) NOT NULL DEFAULT 'MOCK',
  "authorized_at" timestamptz NULL,
  "captured_at" timestamptz NULL,
  "refunded_at" timestamptz NULL,
  "metadata" jsonb NOT NULL DEFAULT '{}',
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "payments_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings" ("id") ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT "payments_amount_check" CHECK (amount_satang > 0),
  CONSTRAINT "payments_status_check" CHECK ((status)::text = ANY ((ARRAY['PENDING'::character varying, 'SUCCEEDED'::character varying, 'FAILED'::character varying, 'REFUNDED'::character varying])::text[]))
);
-- Create index "payments_booking_uq" to table: "payments"
CREATE UNIQUE INDEX "payments_booking_uq" ON "public"."payments" ("booking_id");
-- Create index "payments_status_idx" to table: "payments"
CREATE INDEX "payments_status_idx" ON "public"."payments" ("status");
-- Create "reviews" table
CREATE TABLE "public"."reviews" (
  "id" text NOT NULL,
  "booking_id" text NOT NULL,
  "customer_id" text NOT NULL,
  "barber_id" text NOT NULL,
  "shop_id" text NOT NULL,
  "stars" smallint NOT NULL,
  "comment" text NULL,
  "editable_until" timestamptz NOT NULL,
  "is_hidden" boolean NOT NULL DEFAULT false,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "reviews_barber_id_fkey" FOREIGN KEY ("barber_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT "reviews_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "reviews_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT "reviews_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops" ("id") ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT "reviews_stars_check" CHECK ((stars >= 1) AND (stars <= 5))
);
-- Create index "reviews_barber_idx" to table: "reviews"
CREATE INDEX "reviews_barber_idx" ON "public"."reviews" ("barber_id") WHERE (is_hidden = false);
-- Create index "reviews_booking_uq" to table: "reviews"
CREATE UNIQUE INDEX "reviews_booking_uq" ON "public"."reviews" ("booking_id");
-- Create index "reviews_shop_idx" to table: "reviews"
CREATE INDEX "reviews_shop_idx" ON "public"."reviews" ("shop_id") WHERE (is_hidden = false);
-- Create "schedule_exceptions" table
CREATE TABLE "public"."schedule_exceptions" (
  "id" text NOT NULL,
  "barber_id" text NOT NULL,
  "date" date NOT NULL,
  "is_closed" boolean NOT NULL,
  "open_time" time NULL,
  "close_time" time NULL,
  "breaks" jsonb NOT NULL DEFAULT '[]',
  "reason" character varying(255) NULL,
  "triggered_cascade" boolean NOT NULL DEFAULT false,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "schedule_exceptions_barber_id_fkey" FOREIGN KEY ("barber_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "schedule_exceptions_uq" to table: "schedule_exceptions"
CREATE UNIQUE INDEX "schedule_exceptions_uq" ON "public"."schedule_exceptions" ("barber_id", "date");
-- Create "shop_opening_hours" table
CREATE TABLE "public"."shop_opening_hours" (
  "id" text NOT NULL,
  "shop_id" text NOT NULL,
  "weekday" smallint NOT NULL,
  "is_closed" boolean NOT NULL DEFAULT false,
  "open_time" time NULL,
  "close_time" time NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "shop_opening_hours_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "shop_opening_hours_times_check" CHECK ((is_closed = true) OR ((open_time IS NOT NULL) AND (close_time IS NOT NULL) AND (open_time < close_time))),
  CONSTRAINT "shop_opening_hours_weekday_check" CHECK ((weekday >= 0) AND (weekday <= 6))
);
-- Create index "shop_opening_hours_uq" to table: "shop_opening_hours"
CREATE UNIQUE INDEX "shop_opening_hours_uq" ON "public"."shop_opening_hours" ("shop_id", "weekday");
-- Create "shop_staff" table
CREATE TABLE "public"."shop_staff" (
  "id" text NOT NULL,
  "shop_id" text NOT NULL,
  "barber_id" text NOT NULL,
  "role" character varying(24) NOT NULL,
  "joined_at" timestamptz NOT NULL DEFAULT now(),
  "left_at" timestamptz NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "shop_staff_barber_id_fkey" FOREIGN KEY ("barber_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT "shop_staff_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "shop_staff_role_check" CHECK ((role)::text = ANY ((ARRAY['senior'::character varying, 'junior'::character varying, 'apprentice'::character varying])::text[]))
);
-- Create index "shop_staff_active_barber_uq" to table: "shop_staff"
CREATE UNIQUE INDEX "shop_staff_active_barber_uq" ON "public"."shop_staff" ("barber_id") WHERE (left_at IS NULL);
-- Create index "shop_staff_shop_idx" to table: "shop_staff"
CREATE INDEX "shop_staff_shop_idx" ON "public"."shop_staff" ("shop_id");
-- Create "walkin_queue_entries" table
CREATE TABLE "public"."walkin_queue_entries" (
  "id" text NOT NULL,
  "customer_id" text NOT NULL,
  "shop_id" text NOT NULL,
  "service_id" text NOT NULL,
  "status" character varying(16) NOT NULL,
  "joined_at" timestamptz NOT NULL DEFAULT now(),
  "called_at" timestamptz NULL,
  "started_at" timestamptz NULL,
  "finished_at" timestamptz NULL,
  "position" integer NOT NULL,
  "estimated_call_time" timestamptz NULL,
  "converted_booking_id" text NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "walkin_queue_entries_converted_booking_id_fkey" FOREIGN KEY ("converted_booking_id") REFERENCES "public"."bookings" ("id") ON UPDATE NO ACTION ON DELETE SET NULL,
  CONSTRAINT "walkin_queue_entries_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT "walkin_queue_entries_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "public"."services" ("id") ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT "walkin_queue_entries_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops" ("id") ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT "walkin_queue_status_check" CHECK ((status)::text = ANY ((ARRAY['WAITING'::character varying, 'CALLED'::character varying, 'IN_PROGRESS'::character varying, 'COMPLETED'::character varying, 'LEFT'::character varying, 'REMOVED'::character varying])::text[]))
);
-- Create index "walkin_queue_shop_waiting_idx" to table: "walkin_queue_entries"
CREATE INDEX "walkin_queue_shop_waiting_idx" ON "public"."walkin_queue_entries" ("shop_id", "joined_at") WHERE ((status)::text = ANY ((ARRAY['WAITING'::character varying, 'CALLED'::character varying])::text[]));
-- Create "working_hours" table
CREATE TABLE "public"."working_hours" (
  "id" text NOT NULL,
  "barber_id" text NOT NULL,
  "weekday" smallint NOT NULL,
  "is_closed" boolean NOT NULL DEFAULT false,
  "open_time" time NULL,
  "close_time" time NULL,
  "breaks" jsonb NOT NULL DEFAULT '[]',
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "working_hours_barber_id_fkey" FOREIGN KEY ("barber_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "working_hours_times_check" CHECK ((is_closed = true) OR ((open_time IS NOT NULL) AND (close_time IS NOT NULL) AND (open_time < close_time))),
  CONSTRAINT "working_hours_weekday_check" CHECK ((weekday >= 0) AND (weekday <= 6))
);
-- Create index "working_hours_uq" to table: "working_hours"
CREATE UNIQUE INDEX "working_hours_uq" ON "public"."working_hours" ("barber_id", "weekday");
