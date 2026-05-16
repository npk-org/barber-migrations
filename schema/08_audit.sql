-- Owner: every service writes; audit consumer reads. No exclusive owner.
-- Tables: audit_logs

CREATE TABLE IF NOT EXISTS audit_logs (
  id           BIGSERIAL    PRIMARY KEY,
  actor_id     TEXT         REFERENCES users(id) ON DELETE SET NULL,
  action       VARCHAR(60)  NOT NULL,
  entity_type  VARCHAR(30)  NOT NULL,
  entity_id    TEXT         NOT NULL,
  before       JSONB,
  after        JSONB,
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS audit_logs_entity_idx ON audit_logs (entity_type, entity_id, created_at DESC);
CREATE INDEX IF NOT EXISTS audit_logs_actor_idx  ON audit_logs (actor_id, created_at DESC);
CREATE INDEX IF NOT EXISTS audit_logs_action_idx ON audit_logs (action,   created_at DESC);
