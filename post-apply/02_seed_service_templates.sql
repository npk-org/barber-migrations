-- Idempotent seed of the system-wide service templates that barbers can
-- adopt and customize. Applied by scripts/migrate.sh after Atlas — Atlas
-- itself only diffs schema state and ignores INSERTs in schema files.

INSERT INTO service_templates (id, code, name_th, name_en, default_duration_minutes, default_buffer_minutes) VALUES
  ('tpl_haircut',      'HAIRCUT',      'ตัดผม',           'Haircut',         50, 10),
  ('tpl_beard',        'BEARD_TRIM',   'แต่งหนวด',         'Beard Trim',      20, 10),
  ('tpl_haircut_wash', 'HAIRCUT_WASH', 'ตัดผม + สระผม',     'Haircut + Wash',  90, 10)
ON CONFLICT (code) DO NOTHING;
