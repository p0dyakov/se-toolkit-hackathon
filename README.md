# Bank Statement Converter

Monorepo with:

- `backend/` - Ruby on Rails API, Google OAuth, OpenRouter conversion, OpenAPI/Scalar docs
- `frontend/` - SvelteKit + Bun + Vite + TypeScript + shadcn-svelte UI
- `deploy/` - nginx, docs host, and `systemd` unit files for production

## Features

- Google sign-in
- Batch PDF upload
- Automatic conversion after upload
- Conversion history with search and filters
- Editable preview before export
- CSV and JSON exports
- User profile with personal API key and code examples

## Local Run

### Backend

```bash
cd backend
bundle install
cp .env.example .env
bin/rails db:prepare
bin/rails server
```

Backend runs at `http://localhost:3000`.

Required variables in `backend/.env`:

- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `OPENROUTER_API_KEY`

### Frontend

```bash
cd frontend
bun install
bun run dev
```

Frontend runs at `http://localhost:5173`.

## Google OAuth

Create a Google OAuth 2.0 Web application and add:

- Authorized JavaScript origin: `http://localhost:5173`
- Authorized JavaScript origin: `http://localhost:3000`
- Authorized redirect URI: `http://localhost:3000/auth/google_oauth2/callback`

## API Docs

- Scalar UI: `http://localhost:3000/api-docs`
- OpenAPI JSON: `http://localhost:3000/openapi/v1/openapi.json`

## Checks

### Backend

```bash
cd backend
bundle exec rspec
```

### Frontend

```bash
cd frontend
bun run check
bun run test
bun run build
bun run lint
```

## Production

Current production layout:

- `statementconverter.ru` -> frontend
- `api.statementconverter.ru` -> Rails API
- `docs.statementconverter.ru` -> Scalar docs

Server stack:

- nginx
- Rails API as `systemd` service
- SvelteKit Node server as `systemd` service
- PostgreSQL

### Production env

Create `.env.production` from `.env.production.example` and fill:

- `FRONTEND_URL`
- `APP_URL`
- `API_BASE_URL`
- `DOCS_URL`
- `SESSION_COOKIE_DOMAIN`
- `ALLOWED_HOSTS`
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `OPENROUTER_API_KEY`
- `DATABASE_URL`
- `RAILS_MASTER_KEY`

### Services

Copy the unit files from `deploy/systemd/` into `/etc/systemd/system/`, then run:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now bank-statement-converter-backend
sudo systemctl enable --now bank-statement-converter-frontend
```

### nginx

Copy:

- `deploy/nginx/nginx.conf`
- `deploy/nginx/conf.d/default.conf`
- `deploy/docs/index.html`

Then reload nginx:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

### Update

```bash
cd frontend
bun install
bun run build

cd ../backend
bundle install
RAILS_ENV=production bundle exec rails db:migrate

sudo systemctl restart bank-statement-converter-frontend
sudo systemctl restart bank-statement-converter-backend
sudo systemctl reload nginx
```

### Logs

```bash
journalctl -u bank-statement-converter-frontend -f
journalctl -u bank-statement-converter-backend -f
sudo tail -f /var/log/nginx/access.log /var/log/nginx/error.log
```

## Data

- uploaded PDFs and generated exports: `backend/storage/`
- docs static host: `/var/www/bank-statement-converter-docs/`
