-- Owner: review-svc
-- Tables: reviews
--
-- Reviews are attached to BOTH the assigned barber and the shop. A trigger
-- refreshes denormalized avg_rating/review_count on barber_profiles and shops
-- after every insert/update — installed out-of-band from
-- post-apply/01_review_triggers.sql (Atlas free tier does not manage functions).

CREATE TABLE IF NOT EXISTS reviews (
  id                TEXT         PRIMARY KEY,
  booking_id        TEXT         NOT NULL REFERENCES bookings(id)        ON DELETE CASCADE,
  customer_id       TEXT         NOT NULL REFERENCES users(id)           ON DELETE RESTRICT,
  barber_id         TEXT         NOT NULL REFERENCES users(id)           ON DELETE RESTRICT,
  shop_id           TEXT         NOT NULL REFERENCES shops(id)           ON DELETE RESTRICT,
  stars             SMALLINT     NOT NULL,
  comment           TEXT,
  editable_until    TIMESTAMPTZ  NOT NULL,
  is_hidden         BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),

  CONSTRAINT reviews_stars_check CHECK (stars BETWEEN 1 AND 5)
);

CREATE UNIQUE INDEX IF NOT EXISTS reviews_booking_uq ON reviews (booking_id);
CREATE INDEX        IF NOT EXISTS reviews_barber_idx ON reviews (barber_id) WHERE is_hidden = FALSE;
CREATE INDEX        IF NOT EXISTS reviews_shop_idx   ON reviews (shop_id)   WHERE is_hidden = FALSE;
