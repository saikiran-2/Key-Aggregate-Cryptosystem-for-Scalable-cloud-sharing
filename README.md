# Key-Aggregate Cryptosystem - Multi-Admin Cloud Sharing App

JSP + Java, Tomcat 9, MySQL, Dropbox. Any number of admins (doctors,
teachers, staff - anyone who shares files) can register, get approved by
one main admin, then upload and share files with users under a single
aggregate key per share - one key can unlock many files at once.

---

## 1. Opening this in NetBeans

This zip is source-only (no `build/`, `dist/`, or machine-specific
`nbproject/private/` folder) - those were part of why it wouldn't open
cleanly before; they either get regenerated automatically or pointed at
files that no longer exist. To open it:

1. NetBeans -> **File -> Open Project** -> pick the `Medical_care` folder.
2. NetBeans will ask you to pick a **Tomcat 9** server instance the first
   time (Services tab -> Servers -> Add Server, if you don't have one registered).
3. Right-click the project -> **Properties -> Libraries** - you should see
   exactly two jars (`mail.jar`, `mysql-connector-java-5.1.13-bin.jar`),
   both resolved from the project's own `lib/` folder. If NetBeans still
   complains about a missing library, it's stale IDE cache - Clean and Build once.
4. Copy `src/java/config.properties.example` to `src/java/config.properties`
   and fill in your DB password, admin login, and Dropbox settings (see
   sections 4-5). NetBeans copies this file into the build output
   automatically since it sits alongside the `.java` sources.
5. Run `schema.sql` against your MySQL server.
6. Right-click the project -> **Run**.

---

## 2. Design note

The UI is intentionally plain - one small `css/simple.css`, no JS
frameworks, no images - so every page stays easy to read and easy to
change. It's been given a bit more visual polish (spacing, a consistent
accent color, subtle shadows/hover states) without turning it into a
themed template.

---

## 3. How sharing actually works now (one key, many files)

```
share_batches            share_batch_files            uploaded_files
(one row per key)   -->  (links a key to many   -->   (each file has its
 id, username,            files: batch_id, file_id)    own separate DES
 agg_key, owner_admin)                                 key, kept server-side)
```

- Admin picks any number of their own files (checkboxes on **My Files**)
  and one registered user, then clicks **Grant Access**. A single random
  aggregate key is generated (or reused, if the admin pastes in a key they
  already issued that same user) and linked to every checked file.
- The user logs in, enters **just that one key**, and sees every file it
  covers - each downloaded file is decrypted server-side with its own
  original key, which the user never has to know or handle.
- To share MORE files with the same user later without issuing a new key,
  the admin just checks more files and pastes the same aggregate key into
  "Add to existing key."
- One admin's key can never be used against another admin's files (checked
  server-side on every share and every download).

---

## 4. Multi-admin with approval (works for any kind of provider - doctors, teachers, staff, anyone)

- **One main admin** logs in with the `admin.username`/`admin.password`
  from `config.properties` - this identity is fixed at deploy time, not a
  database row.
- **Anyone else** clicks "Register as an admin" on the admin login page,
  which creates a `pending` row in the `admins` table.
- The main admin sees a **Approvals** tab (only visible to them) listing
  every admin account with a search box (filter by name/username) and
  Approve/Reject actions.
- Once approved, that admin can log in and upload/share files - but they
  only ever see and manage **their own** uploaded files (`owner_admin`
  column scopes every query). Two admins can each have a file with the
  same name and never see each other's.
- This generalizes past "hospital" - a school could use the main admin as
  a head teacher approving individual teachers, each of whom shares
  report cards only with their own students; a company could use it for
  managers sharing documents with their own clients, etc.

---

## 5. Deploying somewhere real (and why not Vercel)

**Vercel doesn't run this kind of app at all.** Vercel hosts serverless
functions and static/Next.js sites - it has no Tomcat, no servlet
container, and can't execute a `.war` file. A JSP/Servlet app like this
needs somewhere that actually runs Java + Tomcat.

A `Dockerfile` and `docker-compose.yml` are included at the project root
(sibling to `Medical_care/`) so you can deploy the same way on any
Docker-capable host.

**Honesty check:** I wrote and reasoned through this `Dockerfile` carefully,
but I could not actually run `docker build` in my own sandbox (its network
is locked to a small allowlist that doesn't include Docker Hub), so it
has not been build-tested end-to-end. Run `docker build -t keyagg .`
yourself first and fix anything that comes up before deploying - it
*should* work, but "should" isn't "confirmed."

### Fastest path: Railway (Docker + managed MySQL together)
1. Push this project to GitHub (see earlier in this conversation for
   the git steps, or `railway up` can deploy straight from a local folder
   without GitHub too).
2. On [railway.app](https://railway.app): **New Project -> Deploy from
   GitHub repo** (or `railway init` + `railway up` locally). Railway
   detects the `Dockerfile` automatically.
3. **New -> Database -> Add MySQL** in the same project. Railway gives you
   connection details as variables like `MYSQLHOST`, `MYSQLPASSWORD`, etc.
4. On your app service -> **Variables** tab, set:
   `DB_URL=jdbc:mysql://${{MySQL.MYSQLHOST}}:${{MySQL.MYSQLPORT}}/`,
   `DB_PASSWORD=${{MySQL.MYSQLPASSWORD}}`, plus `ADMIN_USERNAME`,
   `ADMIN_PASSWORD`, and the `DROPBOX_*` / `MAIL_*` ones from section 4/7 below.
5. Open a one-off shell or connect with the MySQL client Railway provides
   and run `schema.sql` against that database once.
6. Railway builds the Dockerfile and gives you a public URL - visit it.

### VPS path (full control, cheapest long term)
1. `git clone` the repo onto the VPS, `cd` into it.
2. Create a `.env` file (not committed) with `DB_PASSWORD=...`,
   `ADMIN_USERNAME=...`, etc. - matching the variables `docker-compose.yml` expects.
3. `docker compose up -d --build` - this builds the app image AND starts
   a MySQL container together, running `schema.sql` automatically on first start.
4. Point a domain at the VPS's IP on port 8080 (or put Nginx in front for port 80/443 + TLS).

### Render path
Same Dockerfile, but Render has no built-in MySQL - use a separate managed
MySQL (Aiven, PlanetScale, or Railway's MySQL on its own) and set the
`DB_*` environment variables in Render's dashboard to point at it.


**How credentials work without committing them anywhere:** `AppConfig`
now checks **environment variables first**, before `config.properties`.
An env var name is just the property name, uppercased, with `.` replaced
by `_` - e.g. `db.password` -> `DB_PASSWORD`, `dropbox.refresh.token` ->
`DROPBOX_REFRESH_TOKEN`. Every hosting platform above has a place in its
dashboard to set environment variables for your app/container. Set them
there; leave `config.properties` on the server with blank/placeholder
values (or don't even include it - env vars alone are enough, since every
`AppConfig` getter has a fallback default). This means:

- Your GitHub repo never contains a real secret.
- Different deployments (your laptop, a staging server, production) can
  point at different databases/Dropbox apps without touching code.

Example on a platform with an env var UI, you'd set:
```
DB_URL=jdbc:mysql://your-db-host:3306/
DB_PASSWORD=...
ADMIN_USERNAME=...
ADMIN_PASSWORD=...
DROPBOX_APP_KEY=...
DROPBOX_APP_SECRET=...
DROPBOX_REFRESH_TOKEN=...
MAIL_ENABLED=true
MAIL_USERNAME=...
MAIL_PASSWORD=...
```

---

## 6. Dropbox setup (one-time, per deployment)

1. <https://www.dropbox.com/developers/apps> -> **Create app** -> Scoped
   access -> "App folder" is simplest. Name it anything.
2. **Permissions** tab -> enable `files.content.write` and
   `files.content.read` -> Submit.
3. **Settings** tab -> copy **App key** and **App secret**.
4. Visit (replace `APP_KEY`):
   `https://www.dropbox.com/oauth2/authorize?client_id=APP_KEY&response_type=code&token_access_type=offline`
   Click Allow, copy the short code shown.
5. Exchange it once for a refresh token:
   ```
   curl https://api.dropbox.com/oauth2/token \
     -d code=AUTH_CODE -d grant_type=authorization_code \
     -d client_id=APP_KEY -d client_secret=APP_SECRET
   ```
   Copy the `"refresh_token"` from the response - that's the only manual step, ever.

## 7. Email setup (optional)

Leave `mail.enabled=false` and keys just show on-screen after sharing -
no email needed to fully test the app. To send real email: a Gmail
**App Password** (Google Account -> Security -> 2-Step Verification ->
App passwords) - your normal Gmail password won't work for SMTP.

---

## 8. Setup / run summary

1. `mysql -u root -p < schema.sql`
2. `cp Medical_care/src/java/config.properties.example Medical_care/src/java/config.properties` and fill it in (or use environment variables for a real deployment - see section 5).
3. Build the WAR (NetBeans, or manually - below) and deploy to **Tomcat 9**
   (this is `javax.servlet`, not `jakarta.servlet` - it will not load on Tomcat 10+).
4. Visit `http://localhost:8080/<context>/`.

### Manual WAR build (no NetBeans needed)
```
javac -d build -cp "lib/*:/path/to/tomcat9/lib/servlet-api.jar" $(find src/java -name '*.java')
mkdir -p war/WEB-INF/classes war/WEB-INF/lib
cp -r web/. war/
cp -r build/* war/WEB-INF/classes/
cp src/java/config.properties war/WEB-INF/classes/
cp lib/*.jar war/WEB-INF/lib/
cd war && jar -cf ../app.war .
```

---

## 9. Test files

`Medical_care/test/` has two plain Java files (no JUnit needed - just a
`main()` method each). In NetBeans, right-click either file -> **Run
File**. From the command line, after building:
```
javac -cp build/web/WEB-INF/classes -d /tmp/testout Medical_care/test/*.java
java -cp /tmp/testout:build/web/WEB-INF/classes TestCipherRoundtrip
java -cp /tmp/testout:build/web/WEB-INF/classes TestConfigLoad
```
- **TestCipherRoundtrip** - encrypts then decrypts sample text, confirms
  the correct key recovers it and the wrong key never does.
- **TestConfigLoad** - prints every config value as resolved (env var or
  properties file) and flags if Dropbox isn't configured yet, so you can
  sanity-check setup before touching Tomcat/MySQL at all.

---

## 10. What this is (and isn't) cryptographically

The encryption is plain single-key DES (`DES/ECB/PKCS5Padding`) per file.
The "aggregate key" is a real *access-control* mechanism (one credential,
many files, enforced server-side) but not real key-aggregate/broadcast
*cryptography* - a genuine KAC scheme derives one mathematical key that
directly decrypts a chosen ciphertext subset (needs a bilinear-pairing
construction, e.g. Chu et al. 2014). Worth stating plainly in a viva:
this simulates the access-control workflow such a scheme provides.

## 11. Known simplifications

- Uploads/downloads buffer the whole file in memory before hitting
  Dropbox - fine for typical assignment-sized files; very large files
  would want Dropbox's chunked upload-session API instead.
- No file-delete feature.
- Admin passwords are stored in plain text in the `admins` table (matches
  the original project's approach for `users`) - for anything beyond a
  class project, hash passwords (e.g. BCrypt) before storing them.
