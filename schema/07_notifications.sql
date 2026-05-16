-- Owner: notification-svc
-- Tables: notifications

CREATE TABLE IF NOT EXISTS notifications (
  id          TEXT         PRIMARY KEY,
  user_id     TEXT         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type        VARCHAR(40)  NOT NULL,
  channel     VARCHAR(16)  NOT NULL,
  payload     JSONB        NOT NULL DEFAULT '{}'::jsonb,
  sent_at     TIMESTAMPTZ,
  read_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),

  CONSTRAINT notifications_channel_check CHECK (channel IN ('push','sms','email','inapp'))
);

CREATE INDEX IF NOT EXISTS notifications_user_idx        ON notifications (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS notifications_unsent_idx      ON notifications (created_at) WHERE sent_at IS NULL;
CREATE INDEX IF NOT EXISTS notifications_user_unread_idx ON notifications (user_id)    WHERE read_at IS NULL;
