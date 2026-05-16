-- Owner: review-svc
-- Tables: reviews
--
-- Reviews are attached to BOTH the assigned barber and the shop. The trigger
-- below refreshes denormalized rating aggregates on barber_profiles and shops.

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


CREATE OR REPLACE FUNCTION refresh_rating_aggregates() RETURNS TRIGGER AS $$
BEGIN
  UPDATE barber_profiles
    SET avg_rating   = (SELECT AVG(stars)::numeric(3,2) FROM reviews
                        WHERE barber_id = NEW.barber_id AND is_hidden = FALSE),
        review_count = (SELECT COUNT(*)                FROM reviews
                        WHERE barber_id = NEW.barber_id AND is_hidden = FALSE)
    WHERE user_id = NEW.barber_id;

  UPDATE shops
    SET avg_rating   = (SELECT AVG(stars)::numeric(3,2) FROM reviews
                        WHERE shop_id = NEW.shop_id AND is_hidden = FALSE),
        review_count = (SELECT COUNT(*)                FROM reviews
                        WHERE shop_id = NEW.shop_id AND is_hidden = FALSE)
    WHERE id = NEW.shop_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_reviews_aggregate ON reviews;
CREATE TRIGGER trg_reviews_aggregate
AFTER INSERT OR UPDATE OF stars, is_hidden ON reviews
FOR EACH ROW EXECUTE FUNCTION refresh_rating_aggregates();
