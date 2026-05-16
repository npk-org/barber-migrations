# Migration runner: ships Atlas + the schema files. `barber-infra`'s deploy
# script runs this once before every service deploy.
FROM arigaio/atlas:latest

WORKDIR /work

COPY atlas.hcl ./
COPY schema/ ./schema/
COPY migrations/ ./migrations/

# Default to applying pending migrations against the prod env.
# Override the command in compose (e.g., `migrate lint`, `migrate status`).
ENTRYPOINT ["atlas"]
CMD ["migrate", "apply", "--env", "prod"]
