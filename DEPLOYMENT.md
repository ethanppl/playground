## Deployment

Notes for deploying this in a self-hosted environment.

1. Install Docker
   1. https://docs.docker.com/engine/install/ubuntu/
   1. https://docs.docker.com/engine/install/linux-postinstall/
1. Build the repo
   1. Clone the repo
   2. In the repo root, build the docker image
      ```bash
      docker buildx build -t playground .
      ```
1. Create DB
   1. Create volume
      ```bash
      docker volume create pgdata
      ```
   1. Create postgres (change the password)
      ```bash
      docker run --name postgres --env=POSTGRES_PASSWORD=ReplaceMe --env=POSTGRES_DB=playground_engine -v pgdata:/var/lib/postgresql/data -p 5432:5432 -d postgres
      ```
1. Set up the DB

   1. Connect the DB

      ```bash
      sudo apt install -y postgresql-client-common postgresql-client-16

      psql postgresql://postgres@localhost:5432/playground_engine
      ```

   1. Set up migrations role, the owner of the schema and tables (change the password)

      ```sql
      -- new owner
      CREATE ROLE playground_migrations WITH LOGIN PASSWORD 'password';

      -- grant all privileges to playground_migrations
      ALTER DATABASE playground_engine OWNER TO playground_migrations;
      GRANT ALL PRIVILEGES ON DATABASE playground_engine TO playground_migrations;

      DO
      $do$
      DECLARE
        sch text;
      BEGIN
        FOR sch IN
          SELECT nspname FROM pg_namespace WHERE nspname NOT ILIKE 'pg_temp_%' AND nspname NOT ILIKE 'pg_toast%'
          AND nspname <> 'pg_catalog' AND nspname <> 'information_schema'
        LOOP
          -- All privileges of schemas
          EXECUTE format($$ GRANT ALL PRIVILEGES ON SCHEMA %I TO playground_migrations $$, sch);
          -- All privileges of sequences
          EXECUTE format($$ GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA %I TO playground_migrations $$, sch);
          -- All privileges of tables
          EXECUTE format($$ GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA %I TO playground_migrations $$, sch);
          -- All privileges of functions
          EXECUTE format($$ GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA %I TO playground_migrations $$, sch);
        END LOOP;
      END;
      $do$;
      ```

   1. Set up `read_access` (no login)

      ```sql
      -- create read access role without login attribute
      CREATE ROLE read_access;

      -- for future read privileges
      ALTER DEFAULT PRIVILEGES FOR ROLE playground_migrations GRANT USAGE ON SCHEMAS TO read_access;
      ALTER DEFAULT PRIVILEGES FOR ROLE playground_migrations GRANT SELECT ON TABLES TO read_access;

      -- Grant privileges to existing DB objects.
      -- This generates all the required statements, copy/paste them in your sql console and execute them.
      SELECT FORMAT('GRANT USAGE ON SCHEMA %I TO %I;', schema_name, 'read_access')
      FROM information_schema.schemata
      WHERE schema_name NOT IN ('pg_toast', 'pg_catalog', 'information_schema');

      SELECT FORMAT('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO %I;', schema_name, 'read_access')
      FROM information_schema.schemata
      WHERE schema_name NOT IN ('pg_toast', 'pg_catalog', 'information_schema');

      -- generated from above
      GRANT USAGE ON SCHEMA public TO read_access;
      GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_access;
      ```

   1. Set up up `write_access` (no login)

      ```sql
      -- create write access role without login attribute
      CREATE ROLE write_access;

      -- Alter default privileges (future tables created by db_migrations role).
      ALTER DEFAULT PRIVILEGES FOR ROLE playground_migrations GRANT USAGE ON SCHEMAS TO write_access;
      ALTER DEFAULT PRIVILEGES FOR ROLE playground_migrations GRANT ALL PRIVILEGES ON TABLES TO write_access;
      ALTER DEFAULT PRIVILEGES FOR ROLE playground_migrations GRANT ALL PRIVILEGES ON SEQUENCES TO write_access;
      ALTER DEFAULT PRIVILEGES FOR ROLE playground_migrations GRANT ALL PRIVILEGES ON ROUTINES TO write_access;

      -- Grant privileges to existing DB objects.
      -- This generates all the required statements, copy/paste them in your sql console and execute them.
      SELECT FORMAT('GRANT USAGE ON SCHEMA %I TO %I;', schema_name, 'write_access')
      FROM information_schema.schemata
      WHERE schema_name NOT IN ('pg_toast', 'pg_catalog', 'information_schema');

      SELECT FORMAT('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA %I TO %I;', schema_name, 'write_access')
      FROM information_schema.schemata
      WHERE schema_name NOT IN ('pg_toast', 'pg_catalog', 'information_schema');

      SELECT FORMAT('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA %I TO %I;', schema_name, 'write_access')
      FROM information_schema.schemata
      WHERE schema_name NOT IN ('pg_toast', 'pg_catalog', 'information_schema');

      SELECT FORMAT('GRANT ALL PRIVILEGES ON ALL ROUTINES IN SCHEMA %I TO %I;', schema_name, 'write_access')
      FROM information_schema.schemata
      WHERE schema_name NOT IN ('pg_toast', 'pg_catalog', 'information_schema');

      -- generated from above 4
      GRANT USAGE ON SCHEMA public TO write_access;
      GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO write_access;
      GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO write_access;
      GRANT ALL PRIVILEGES ON ALL ROUTINES IN SCHEMA public TO write_access;
      ```

   1. Set up role for the app (change password)

      ```sql
      -- playground_backend
      CREATE ROLE playground_backend WITH LOGIN PASSWORD 'password';
      GRANT read_access, write_access TO playground_backend;
      ```

   1. Set up role for the debugging (change password)

      ```sql
      -- engineering
      CREATE ROLE engineering WITH LOGIN PASSWORD 'password';
      GRANT read_access, write_access TO engineering;
      ```

1. Set up docker network

   ```bash
   # Create network
   docker network create playgroundNetwork

   # Connect DB to the network
   docker network connect playgroundNetwork postgres

   # Get the IP address of the postgres container
   # Should find something like 127.18.0.2
   docker netwokr inspect playgroundNetwork
   ```

1. Generate a secret

   ```bash
   mix phx.gen.secret
   ```

   Read more: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Secret.html

1. Run the playground image

   > There is a small downtime with this method, existing connections will be
   > dropped, but not too problematic. The alternative is to start the new
   > container, add to network, run the migration, and then flip the proxy in
   > nginx.

   - Change the password and the IP address for the DB
   - Change the secret to the secret generated in the previous step
   - If the domain name is different, change the `PHX_HOST` env

   ```
   docker run --name playground \
   --env=DATABASE_URL="postgresql://playground_backend:password@172.18.0.2:5432/playground_engine" \
   --env=MIGRATION_DATABASE_URL="postgresql://playground_migrations:password@172.18.0.2:5432/playground_engine" \
   --env=SECRET_KEY_BASE="secret" \
   --env=PHX_HOST="playground.ethanppl.com" \
   -p 4000:4000 \
   -d playground
   ```

   It should fail to connect because the container is not connected to the `playgroundNetwork` network.

   ```bash
   docker network connect playgroundNetwork playground
   ```

   Restart again

   ```bash
   docker start playground
   ```

   Check it's up now

   ```bash
   docker ps
   docker logs playground
   ```

1. Configure DNS

1. Set up Nginx

   1. Install Nginx: https://nginx.org/en/linux_packages.html#Ubuntu
   1. Start Nginx
      ```bash
      sudo systemctl start nginx
      ```
   1. Edit the config:

      - If the domain name is different, change the `server_name`

      ```bash
      sudo vim /etc/nginx/nginx.conf
      ```

      ```
      user  nginx;
      worker_processes  auto;

      # other stuff

      http {

          # other stuff

          server {
              listen 80;
              server_name playground.ethanppl.com;

              location / {
                  proxy_pass http://localhost:4000;
              }
          }
      }
      ```

   1. Test the config file validity

      ```bash
      sudo nginx -t
      ```

   1. Reload the Nginx config

      ```bash
      sudo nginx -s reload
      ```

1. Set up the certificate with Let's Encrypt

   - If using Ubuntu: https://certbot.eff.org/instructions?ws=nginx&os=ubuntufocal
   - Otherwise check the docs: https://letsencrypt.org/getting-started/

Done!