# Deploying ROH-ERP to DreamHost

| Part | Domain | Source |
|---|---|---|
| Frontend (Flutter web) | https://test.rohautism.org | `FRONT-END/build/web-production/` |
| Backend (Node.js API) | https://erp-backend.rohautism.org | `BACK-END/` |
| Database (MySQL) | `mysql.rohautism.org` / `roherp` | `BACK-END/schema.sql` |

> **Hosting requirement:** DreamHost runs Node.js only on a **VPS or Dedicated server**, not on shared hosting.
> The frontend is static files and works on any plan. The backend needs a VPS (or another Node host — see the end).

## Live setup (deployed 2026-10-15)

| | Frontend | Backend |
|---|---|---|
| Server | `vps18579.dreamhostps.com` (VPS Enterprise, Apache) | same |
| SSH user | `dh_gp9jnd` | `dh_tdq9bh` |
| Folder | `~/test.rohautism.org` (web root) | `~/roh-erp-api`, deliberately **outside** the web root so `.env` is never served |
| Runtime | static files | Node 20 (nvm, this user only) + pm2 process `roh-erp-api` on port **8010** |
| Public URL | https://test.rohautism.org | https://erp-backend.rohautism.org, via the panel's Proxy Server `/` → 8010 |

- Ports 8000–8007 on this VPS belong to other sites. Don't reuse them.
- A crontab `@reboot` entry for `dh_tdq9bh` runs `pm2 resurrect`, so the API comes back after a server restart.
- The 2020 site that was in `test.rohautism.org` is backed up at `~dh_gp9jnd/test.rohautism.org.backup-20261015.tar.gz`.

## Redeploying (packages in `deploy/`, git-ignored)

Rebuild the packages, then:

```bash
scp deploy/roh-erp-backend.zip dh_tdq9bh@vps18579.dreamhostps.com:~
ssh dh_tdq9bh@vps18579.dreamhostps.com 'export NVM_DIR=$HOME/.nvm; . $NVM_DIR/nvm.sh; cd ~/roh-erp-api && unzip -oq ~/roh-erp-backend.zip && rm ~/roh-erp-backend.zip && npm ci --omit=dev && pm2 restart roh-erp-api && pm2 save'
```

```bash
scp deploy/roh-erp-frontend.zip dh_gp9jnd@vps18579.dreamhostps.com:~
ssh dh_gp9jnd@vps18579.dreamhostps.com 'cd ~/test.rohautism.org && find . -mindepth 1 -maxdepth 1 ! -name .well-known ! -name .dh-diag -exec rm -rf {} + && unzip -oq ~/roh-erp-frontend.zip && rm ~/roh-erp-frontend.zip'
```

Backend logs: `ssh dh_tdq9bh@vps18579.dreamhostps.com 'export NVM_DIR=$HOME/.nvm; . $NVM_DIR/nvm.sh; pm2 logs roh-erp-api --lines 50 --nostream'`

---

## 1. Database

`schema.sql` only uses `CREATE TABLE IF NOT EXISTS`. It never drops tables or touches existing data, so it is safe to run again after every deploy.
Demo data now lives in `seed_demo.sql`. **Do not load it in production**, because it contains test accounts with known passwords.

**Tables are created automatically.** Every time `server.js` starts, it runs `schema.sql` and creates any missing tables. The log shows a line like `📦 Schema check: 23 table(s) created, 23 total`.

1. In the DreamHost panel, go to **MySQL Databases** and open the `roherp` user. If the backend can't connect (`Access denied`), add the VPS's IP under **Allowable hosts**.
2. Production starts with no users. Create the first admin once on the VPS, after step 3:

```bash
ADMIN_NAME="Center Admin" ADMIN_EMAIL="you@rohautism.org" ADMIN_PASSWORD="choose-a-strong-one" node init_db.js
```

An admin is only created if none exists yet.

## 2. Frontend → test.rohautism.org

The production build is already compiled with `API_BASE_URL=https://erp-backend.rohautism.org/`. To rebuild it:

```bash
cd FRONT-END && flutter build web --release --dart-define=API_BASE_URL=https://erp-backend.rohautism.org/ -o build/web-production
```

1. DreamHost panel → **Websites** → `test.rohautism.org`: confirm it is hosted (not redirected) and enable **HTTPS (Let's Encrypt)**.
2. Upload the **contents** of `FRONT-END/build/web-production/` (`index.html` must sit at the top level) to the site folder, usually `~/test.rohautism.org/`, via SFTP:

```bash
rsync -avz --delete FRONT-END/build/web-production/ USER@SERVER.dreamhost.com:~/test.rohautism.org/
```

The app uses `#/` URLs, so no rewrite rules are needed.

## 3. Backend → erp-backend.rohautism.org (DreamHost VPS)

1. Upload the backend, excluding `node_modules` and the local test or demo scripts:

```bash
rsync -avz --exclude node_modules --exclude '.env*' --exclude '*.png' BACK-END/ USER@VPS:~/erp-backend.rohautism.org/app/
scp BACK-END/.env.production USER@VPS:~/erp-backend.rohautism.org/app/.env
```

2. On the VPS:

```bash
cd ~/erp-backend.rohautism.org/app
npm ci --omit=dev
npx pm2 start server.js --name roh-erp-api && npx pm2 save
```

3. DreamHost panel → **Websites** → `erp-backend.rohautism.org` → **Proxy server**: proxy `/` to port `8010`. Enable **HTTPS**.
4. Check that the API is up: `curl https://erp-backend.rohautism.org/` should return `"status":"Operational"`.

`BACK-END/.env.production` holds the DreamHost DB credentials, a generated `JWT_SECRET` and `ALLOWED_ORIGIN=https://test.rohautism.org` (CORS). It is git-ignored, so never commit it.

## 4. If you only have shared hosting

The frontend and database still go on DreamHost as above. Run the backend on a Node host such as Render, Railway or Fly.io:

1. Use the same `.env.production` values.
2. Add that host's outbound IP to the MySQL **Allowable hosts**.
3. Point `erp-backend.rohautism.org` at it with a CNAME record in DreamHost DNS.

## Checklist after deploying

- [ ] `https://erp-backend.rohautism.org/` returns Operational
- [ ] `https://test.rohautism.org` shows the login page and the admin can sign in
- [ ] Browser devtools show no CORS errors and API calls go to `erp-backend.rohautism.org`
- [ ] Admin creates the real director, therapist and parent accounts
