[![CI](https://github.com/McGeerDev/portfolio/actions/workflows/ci.yml/badge.svg)](https://github.com/McGeerDev/portfolio/actions/workflows/ci.yml)

# mcgeer.dev &mdash; Devan McGeer

Source for [mcgeer.dev](https://mcgeer.dev/) &mdash; personal portfolio and SRE résumé site.

## Stack

Hand-written HTML + CSS. Zero JavaScript by default, no framework, no package manifest. `mise` provides the local task interface. Deployed to GitHub Pages.

## Project Structure

- `index.html` &mdash; home page
- `404.html` &mdash; GitHub Pages 404 fallback
- `style.css` &mdash; all styles, single file
- `resume/index.html` &mdash; `/resume/` page
- `projects/index.html` &mdash; `/projects/` page
- `blog/index.html` &mdash; `/blog/` landing page
- `favicon.svg`, `og-image.png` &mdash; site icons and social card
- `robots.txt`, `sitemap.xml` &mdash; crawler directives
- `CNAME` &mdash; custom domain (`mcgeer.dev`)
- `fonts/` &mdash; self-hosted `woff2` (Lekton 400/700, Lexend Zetta 400)
- `assets/` &mdash; résumé PDF and headshot
- `.impeccable.md` &mdash; brand, users, and design principles
- `.mise.toml` &mdash; local task definitions
- `scripts/` &mdash; build and guardrail scripts
- `.github/workflows/` &mdash; `ci.yml` and `deploy.yml`

## Local preview

```sh
mise run serve
```

Then open <http://localhost:8000/>.

## Local tasks

```sh
mise run check
mise run build
mise run build:minified
mise run serve
```

## CI/CD

- `ci.yml` &mdash; runs site guardrails, validates HTML, and checks links on pull requests.
- `deploy.yml` &mdash; stages the sitemap-listed public surface into `_site/`, minifies and hashes static assets, then publishes to GitHub Pages on push to `main`.

## Static-site rules

- Keep runtime JavaScript at zero unless a change has a specific progressive-enhancement reason.
- Keep CSS in `style.css`; do not add a frontend framework or bundler.
- Pages listed in `sitemap.xml` are the published surface. Draft files are not public unless added there.
- Run `mise run check` before handing off changes.

## License

MIT &mdash; see [`LICENSE`](./LICENSE) at the repo root.
