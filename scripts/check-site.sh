#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE_DIR="${ROOT_DIR}/_site"

"${ROOT_DIR}/scripts/build-site.sh"

fail=0

report_failure() {
  echo "check failed: $1" >&2
  fail=1
}

if find "$SITE_DIR" -type f \( -name '*.js' -o -name 'package.json' -o -name 'package-lock.json' -o -name 'pnpm-lock.yaml' -o -name 'yarn.lock' \) | grep -q .; then
  report_failure "public site contains JavaScript or package-manager files"
fi

if grep -RIn --include='*.html' '\[TODO:' "$SITE_DIR"; then
  report_failure "public HTML contains TODO placeholders"
fi

while IFS= read -r route; do
  [[ -n "$route" ]] || continue
  if [[ "$route" == "/" ]]; then
    page="${SITE_DIR}/index.html"
  else
    route_path="${route#/}"
    route_path="${route_path%/}"
    page="${SITE_DIR}/${route_path}/index.html"
  fi
  [[ -f "$page" ]] || report_failure "sitemap route is not staged: ${route}"
done < <(sed -n 's#.*<loc>https://mcgeer.dev\(/[^<]*\)</loc>.*#\1#p' "${ROOT_DIR}/sitemap.xml")

while IFS= read -r html; do
  canonical="$(sed -n 's#.*<link rel="canonical" href="https://mcgeer.dev\([^"]*\)".*#\1#p' "$html" | head -n 1)"
  [[ -z "$canonical" ]] && continue
  if ! grep -q "<loc>https://mcgeer.dev${canonical}</loc>" "${ROOT_DIR}/sitemap.xml"; then
    report_failure "canonical URL is missing from sitemap: ${canonical} (${html#"$SITE_DIR"/})"
  fi
done < <(find "$SITE_DIR" -name '*.html' -not -path "${SITE_DIR}/404.html" | sort)

if grep -RIn --include='*.html' -E 'href="/#selected-work"|href="/projects/"' "$SITE_DIR" | awk '
  /href="\/#selected-work"/ { selected = 1 }
  /href="\/projects\/"/ { projects = 1 }
  END { exit !(selected && projects) }
'; then
  report_failure "public nav mixes /#selected-work and /projects/ project targets"
fi

exit "$fail"
