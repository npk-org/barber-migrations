-- Applied by scripts/migrate.sh after Atlas finishes, since Atlas's free
-- tier does not diff/manage functions, procedures, or triggers.
--
-- Refreshes denormalized rating aggregates on barber_profiles and shops
-- whenever a review row is inserted or its stars/is_hidden changes.

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
