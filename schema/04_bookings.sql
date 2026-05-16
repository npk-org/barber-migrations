-- Owner: booking-svc
-- Tables: bookings, walkin_queue_entries, capacity_shortage_responses
--
-- The bookings table is the heart of the system. The EXCLUDE USING gist
-- constraints below need btree_gist (created in 01_users.sql).

CREATE TABLE IF NOT EXISTS bookings (
  id                   TEXT          PRIMARY KEY,
  code                 VARCHAR(16)   NOT NULL,
  customer_id          TEXT          NOT NULL REFERENCES users(id)    ON DELETE RESTRICT,
  shop_id              TEXT          NOT NULL REFERENCES shops(id)    ON DELETE RESTRICT,
  service_id           TEXT          NOT NULL REFERENCES services(id) ON DELETE RESTRICT,

  source               VARCHAR(16)   NOT NULL,
  is_locked            BOOLEAN       NOT NULL DEFAULT FALSE,
  locked_to_barber_id  TEXT          REFERENCES users(id) ON DELETE RESTRICT,
  assigned_barber_id   TEXT          REFERENCES users(id) ON DELETE RESTRICT,
  chair_id             TEXT          REFERENCES chairs(id) ON DELETE RESTRICT,

  status               VARCHAR(24)   NOT NULL,
  scheduled_start      TIMESTAMPTZ   NOT NULL,
  scheduled_end        TIMESTAMPTZ   NOT NULL,
  current_start        TIMESTAMPTZ   NOT NULL,
  current_end          TIMESTAMPTZ   NOT NULL,
  started_at           TIMESTAMPTZ,
  finished_at          TIMESTAMPTZ,

  price_satang         BIGINT        NOT NULL,
  payment_mode         VARCHAR(16)   NOT NULL,
  note                 TEXT,

  created_by_user_id   TEXT          NOT NULL REFERENCES users(id) ON DELETE RESTRICT,

  cancelled_at         TIMESTAMPTZ,
  cancelled_by         VARCHAR(16),
  cancel_reason        TEXT,

  created_at           TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ   NOT NULL DEFAULT now(),

  CONSTRAINT bookings_source_check       CHECK (source       IN ('APP','MANUAL')),
  CONSTRAINT bookings_status_check       CHECK (status       IN ('PENDING_PAYMENT','CONFIRMED','IN_PROGRESS','COMPLETED','CANCELLED','CANCELLING','NO_SHOW')),
  CONSTRAINT bookings_payment_mode_check CHECK (payment_mode IN ('MOCK_APP','ON_SITE')),
  CONSTRAINT bookings_cancelled_by_check CHECK (cancelled_by IS NULL OR cancelled_by IN ('customer','barber','shop','system')),
  CONSTRAINT bookings_price_check        CHECK (price_satang > 0),
  CONSTRAINT bookings_time_order_check   CHECK (scheduled_end > scheduled_start AND current_end > current_start),

  -- Locked bookings must name the same barber for locked_to and assigned;
  -- non-locked bookings must NOT have a locked_to_barber_id.
  CONSTRAINT bookings_locked_consistency CHECK (
    (is_locked = FALSE AND locked_to_barber_id IS NULL) OR
    (is_locked = TRUE  AND locked_to_barber_id IS NOT NULL
                       AND assigned_barber_id  = locked_to_barber_id)
  )
);

-- Booking code is shown to users (e.g., BK-7H3K9X) and must be unique.
CREATE UNIQUE INDEX IF NOT EXISTS bookings_code_uq ON bookings (code);

-- Prevent double-booking a barber while a booking is active.
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS no_overlap_per_barber;
ALTER TABLE bookings ADD  CONSTRAINT no_overlap_per_barber
  EXCLUDE USING gist (
    assigned_barber_id WITH =,
    tstzrange(current_start, current_end) WITH &&
  ) WHERE (status IN ('CONFIRMED','IN_PROGRESS') AND assigned_barber_id IS NOT NULL);

-- Prevent double-booking a chair while a booking is in progress.
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS no_overlap_per_chair;
ALTER TABLE bookings ADD  CONSTRAINT no_overlap_per_chair
  EXCLUDE USING gist (
    chair_id WITH =,
    tstzrange(current_start, current_end) WITH &&
  ) WHERE (status = 'IN_PROGRESS' AND chair_id IS NOT NULL);

-- A customer can hold at most one active booking per shop.
CREATE UNIQUE INDEX IF NOT EXISTS one_active_per_customer_shop
  ON bookings (customer_id, shop_id)
  WHERE status IN ('PENDING_PAYMENT','CONFIRMED','IN_PROGRESS');

-- Fast lookups
CREATE INDEX IF NOT EXISTS idx_bookings_shop_day     ON bookings (shop_id, current_start);
CREATE INDEX IF NOT EXISTS idx_bookings_barber_day   ON bookings (assigned_barber_id, current_start)
  WHERE assigned_barber_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_bookings_customer     ON bookings (customer_id, scheduled_start DESC);
CREATE INDEX IF NOT EXISTS idx_bookings_locked       ON bookings (locked_to_barber_id, current_start)
  WHERE is_locked = TRUE;


CREATE TABLE IF NOT EXISTS walkin_queue_entries (
  id                    TEXT          PRIMARY KEY,
  customer_id           TEXT          NOT NULL REFERENCES users(id)    ON DELETE RESTRICT,
  shop_id               TEXT          NOT NULL REFERENCES shops(id)    ON DELETE RESTRICT,
  service_id            TEXT          NOT NULL REFERENCES services(id) ON DELETE RESTRICT,
  status                VARCHAR(16)   NOT NULL,
  joined_at             TIMESTAMPTZ   NOT NULL DEFAULT now(),
  called_at             TIMESTAMPTZ,
  started_at            TIMESTAMPTZ,
  finished_at           TIMESTAMPTZ,
  position              INTEGER       NOT NULL,
  estimated_call_time   TIMESTAMPTZ,
  converted_booking_id  TEXT          REFERENCES bookings(id) ON DELETE SET NULL,
  created_at            TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ   NOT NULL DEFAULT now(),

  CONSTRAINT walkin_queue_status_check CHECK (status IN ('WAITING','CALLED','IN_PROGRESS','COMPLETED','LEFT','REMOVED'))
);

CREATE INDEX IF NOT EXISTS walkin_queue_shop_waiting_idx
  ON walkin_queue_entries (shop_id, joined_at)
  WHERE status IN ('WAITING','CALLED');


CREATE TABLE IF NOT EXISTS capacity_shortage_responses (
  id                  TEXT          PRIMARY KEY,
  booking_id          TEXT          NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  trigger_barber_id   TEXT          NOT NULL REFERENCES users(id)    ON DELETE RESTRICT,
  notified_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),
  response_deadline   TIMESTAMPTZ   NOT NULL,
  choice              VARCHAR(24),
  responded_at        TIMESTAMPTZ,
  created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),

  CONSTRAINT capacity_shortage_choice_check
    CHECK (choice IS NULL OR choice IN ('KEEP','CANCEL_REFUND','AUTO_KEEP','AUTO_CANCEL'))
);

CREATE UNIQUE INDEX IF NOT EXISTS capacity_shortage_booking_uq ON capacity_shortage_responses (booking_id);
