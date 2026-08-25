# Repository Guidelines

See `AGENT.md` for the application architecture, commands, and coding conventions.

## Production deployment

The local Docker/Kubernetes deployment at `deva.station` is the production
instance for this repository. Treat its persistent PostgreSQL data as production
data: do not reset it, replace it with development fixtures, or assume a fresh
database.

Deploy with `./build.sh`. It builds and pushes the image, restarts the matching
Kubernetes deployment, runs `bin/rails db:prepare`, and then runs
`bin/rails datawires:clusters:sync`. The sync task idempotently updates base
schemas and affordances in every domain that already has an installed cluster;
this is how base-schema changes propagate to running domains such as
`oregongrye`. Do not use the full `db:seed` task for production propagation.

Cluster schema changes belong in `Clusters::Catalog`. Keep
`Clusters::SeedDomain` idempotent, and add coverage proving that an existing
domain is upgraded without replacing user-authored instance documents.

Schemas may declare `x-datawires-document-key` with Ruby-style placeholders,
for example `#{kind} - #{name}`. Publishing resolves placeholders from fields
in the document body and updates `Document#key`; missing values or duplicate
keys abort the publish transaction.
