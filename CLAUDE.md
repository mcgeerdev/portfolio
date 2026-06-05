# mcgeer.dev Portfolio

Personal portfolio and résumé site for Devan McGeer (SRE). Deployed to GitHub Pages at mcgeer.dev.

## Stack

Hand-written HTML + CSS · zero JavaScript by default · no framework · `mise` task runner · GitHub Pages

## Layout

| Path | Purpose |
|---|---|
| `index.html` | Home page |
| `404.html` | GitHub Pages 404 fallback (standalone page, not SPA) |
| `style.css` | All styles, single file |
| `resume/index.html` | `/resume/` page |
| `projects/index.html` | `/projects/` page |
| `blog/index.html` | `/blog/` landing page |
| `blog/*/index.html` | Draft posts; not published unless added to `sitemap.xml` |
| `fonts/` | Self-hosted woff2 (lekton-400, lekton-700, lexend-zetta-400) |
| `assets/` | `devan-mcgeer-cv.pdf`, `headshot.webp` |
| `favicon.svg`, `og-image.png` | Site icons + social card |
| `robots.txt`, `sitemap.xml` | Crawler hints |
| `CNAME` | Pins custom domain `mcgeer.dev` |
| `_headers` | Cache-Control rules for Cloudflare Pages migration (no-op on GitHub Pages) |
| `.mise.toml` | Local task interface for agents, CI, and deploy |
| `scripts/build-site.sh` | Stages sitemap-listed public pages into `_site/`, then hashes assets |
| `scripts/check-site.sh` | Static-site guardrails for public output |
| `.impeccable.md` | Design context — brand, users, principles |

## Local preview

```sh
mise run serve
# open http://localhost:8000/
```

## Local tasks

```sh
mise run check
mise run build
mise run build:minified
mise run serve
```

## CI/CD

- `ci.yml` — runs `mise run check`, validates HTML, and checks links on every PR
- `deploy.yml` — runs `mise run build:minified`, uploads `_site/`, and publishes to GitHub Pages on push to `main`; daily cron rebuild gated on whether there were commits in the last 24h

## Key Patterns

- **Single CSS file:** `style.css`. No preprocessor, no framework.
- **Smallest static site:** keep runtime JavaScript at zero unless a change has an explicit progressive-enhancement justification. Do not add `package.json`, bundlers, client frameworks, or external runtime CDNs.
- **Public surface:** pages listed in `sitemap.xml` are published by `scripts/build-site.sh`. Draft files may exist in the repo, but they are not public unless they are added to `sitemap.xml`.
- **404 handling:** `404.html` is a real standalone page. GitHub Pages serves it on unmatched paths — not a SPA fallback.
- **Fonts:** Self-hosted woff2 in `/fonts/`, preloaded with `crossorigin` from `index.html`. No CDN, no SRI needed.
- **CSP:** Hard-coded in each HTML file's `<meta http-equiv="Content-Security-Policy">` tag. No build-time substitution.
- **Custom domain:** `CNAME` pins `mcgeer.dev`. DNS is proxied through Cloudflare (`Server: cloudflare` on every response); the GitHub Pages backend is the origin.
- **Cache headers:** GitHub Pages serves all assets with `Cache-Control: max-age=600` and ignores any per-file config. The `_headers` file is dormant on the current host but ready for a Cloudflare Pages migration. `scripts/build-site.sh` appends immutable rules for hashed CSS, font, favicon, and social-card assets.
- **Canonical URLs:** Indexable pages carry `<link rel="canonical">` pointing to the `https://mcgeer.dev/...` form with trailing slash. `404.html` deliberately omits canonical per Google's guidance for intentional 404 pages. Internal `<a href>` always uses the canonical trailing-slash form so in-site clicks never hit a redirect.
- **Project links:** Internal navigation points to `/projects/`, not `/#selected-work`.
- **Guardrails:** `mise run check` must pass before handoff. It rejects public TODO placeholders, unexpected JavaScript/package-manager files in `_site/`, missing sitemap pages, and sitemap/canonical drift.
- **Redirects (unavoidable):** Three redirects cannot be removed in repo code. (1) `http://*` → `https://*` is a security baseline. (2) `https://www.mcgeer.dev/*` → `https://mcgeer.dev/*` is canonical-host enforcement, configured in Cloudflare. (3) `https://mcgeer.dev/<dir>` → `https://mcgeer.dev/<dir>/` is GitHub Pages directory canonicalization. The only redundant chain is `http://www.mcgeer.dev/*` (HTTP+www → HTTPS+www → apex, two hops); collapsing it requires a Cloudflare Page Rule, not a repo change.
- **Design decisions:** Consult `.impeccable.md` before changing visuals — brand, users, and design principles live there.

## Authority

Global persona, tutoring, and SRE calibration live in `~/.claude/CLAUDE.md`. This file is local HOW-TO only.
