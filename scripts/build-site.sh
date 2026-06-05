#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE_DIR="${ROOT_DIR}/_site"
MINIFY=0

for arg in "$@"; do
  case "$arg" in
    --minify)
      MINIFY=1
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

hash_file() {
  shasum -a 256 "$1" | awk '{print substr($1, 1, 8)}'
}

verify_archive() {
  local archive="$1"
  local expected="$2"
  local actual

  actual="$(shasum -a 256 "$archive" | awk '{print $1}')"
  if [[ "$actual" != "$expected" ]]; then
    echo "Checksum mismatch for ${archive}" >&2
    echo "expected: ${expected}" >&2
    echo "actual:   ${actual}" >&2
    exit 1
  fi
}

minify_archive_name() {
  local os
  local arch

  case "$(uname -s)" in
    Darwin) os="darwin" ;;
    Linux) os="linux" ;;
    *)
      echo "Unsupported minify OS: $(uname -s)" >&2
      exit 1
      ;;
  esac

  case "$(uname -m)" in
    arm64|aarch64) arch="arm64" ;;
    x86_64|amd64) arch="amd64" ;;
    *)
      echo "Unsupported minify architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac

  printf 'minify_%s_%s.tar.gz' "$os" "$arch"
}

minify_archive_sha256() {
  case "$1" in
    minify_darwin_amd64.tar.gz) printf 'bc5e36e17c7d6e49fa5601b2ba3b211709f06270efb56d6352fa37510e033a74' ;;
    minify_darwin_arm64.tar.gz) printf '9b70745adaeba8d2eb14f5e4fc24d63d0ac95c74e329d64c7a4664157da8dbf1' ;;
    minify_linux_amd64.tar.gz) printf '6cdd5c8c1d605d60f48a2f4a654595235f1fb50f804b107f72f6a6c87240a1bd' ;;
    minify_linux_arm64.tar.gz) printf '927bfbb693985a4671618ff19cd331f348c0a6b79ccd23a04cd9a58e70ce8221' ;;
    *)
      echo "No checksum pinned for minify archive: $1" >&2
      exit 1
      ;;
  esac
}

copy_page() {
  local route="$1"
  local source
  local target

  if [[ "$route" == "/" ]]; then
    source="${ROOT_DIR}/index.html"
    target="${SITE_DIR}/index.html"
  else
    route="${route#/}"
    route="${route%/}"
    source="${ROOT_DIR}/${route}/index.html"
    target="${SITE_DIR}/${route}/index.html"
  fi

  if [[ ! -f "$source" ]]; then
    echo "Sitemap route has no local page: /${route}/ (${source})" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$target")"
  cp "$source" "$target"
}

extract_sitemap_routes() {
  sed -n 's#.*<loc>https://mcgeer.dev\(/[^<]*\)</loc>.*#\1#p' "${ROOT_DIR}/sitemap.xml"
}

rm -rf "$SITE_DIR"
mkdir -p "$SITE_DIR"

cp \
  "${ROOT_DIR}/404.html" \
  "${ROOT_DIR}/style.css" \
  "${ROOT_DIR}/favicon.svg" \
  "${ROOT_DIR}/og-image.png" \
  "${ROOT_DIR}/robots.txt" \
  "${ROOT_DIR}/sitemap.xml" \
  "${ROOT_DIR}/CNAME" \
  "${ROOT_DIR}/_headers" \
  "$SITE_DIR/"

cp -R "${ROOT_DIR}/fonts" "${ROOT_DIR}/assets" "$SITE_DIR/"

while IFS= read -r route; do
  [[ -n "$route" ]] || continue
  copy_page "$route"
done < <(extract_sitemap_routes)

if [[ "$MINIFY" -eq 1 ]]; then
  if command -v minify >/dev/null 2>&1; then
    minify --recursive --match='\.(html|css|svg|xml)$' --output "$SITE_DIR/" "$SITE_DIR/"
  else
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir"' EXIT
    minify_version="2.24.13"
    archive_name="$(minify_archive_name)"
    minify_archive="${tmp_dir}/${archive_name}"

    curl -fsSL -o "$minify_archive" \
      "https://github.com/tdewolff/minify/releases/download/v${minify_version}/${archive_name}"
    verify_archive "$minify_archive" "$(minify_archive_sha256 "$archive_name")"
    tar -xzf "$minify_archive" -C "$tmp_dir" minify
    chmod +x "${tmp_dir}/minify"
    "${tmp_dir}/minify" --recursive --match='\.(html|css|svg|xml)$' --output "$SITE_DIR/" "$SITE_DIR/"
  fi
fi

css_file="${SITE_DIR}/style.css"

rewrite_html() {
  local pattern="$1"
  local replacement="$2"
  find "$SITE_DIR" -name '*.html' -print0 | xargs -0 sed -i.bak "s|${pattern}|${replacement}|g"
}

for font in "${SITE_DIR}"/fonts/*.woff2; do
  hash="$(hash_file "$font")"
  base="$(basename "$font" .woff2)"
  new="${base}.${hash}.woff2"
  mv "$font" "${SITE_DIR}/fonts/${new}"
  sed -i.bak "s|/fonts/${base}\.woff2|/fonts/${new}|g" "$css_file"
  rewrite_html "/fonts/${base}\.woff2" "/fonts/${new}"
done

css_hash="$(hash_file "$css_file")"
mv "$css_file" "${SITE_DIR}/style.${css_hash}.css"
rewrite_html "/style\.css" "/style.${css_hash}.css"

og_hash="$(hash_file "${SITE_DIR}/og-image.png")"
mv "${SITE_DIR}/og-image.png" "${SITE_DIR}/og-image.${og_hash}.png"
rewrite_html "/og-image\.png" "/og-image.${og_hash}.png"

fav_hash="$(hash_file "${SITE_DIR}/favicon.svg")"
mv "${SITE_DIR}/favicon.svg" "${SITE_DIR}/favicon.${fav_hash}.svg"
rewrite_html "/favicon\.svg" "/favicon.${fav_hash}.svg"

find "$SITE_DIR" -name '*.bak' -delete

{
  printf '\n# Hashed assets - immutable caching (appended at build time)\n'
  for font in "${SITE_DIR}"/fonts/*.woff2; do
    printf '\n/fonts/%s\n  Cache-Control: public, max-age=31536000, immutable\n' "$(basename "$font")"
  done
  printf '\n/style.%s.css\n  Cache-Control: public, max-age=31536000, immutable\n  Vary: Accept-Encoding\n' "$css_hash"
  printf '\n/og-image.%s.png\n  Cache-Control: public, max-age=31536000, immutable\n  Vary: Accept-Encoding\n' "$og_hash"
  printf '\n/favicon.%s.svg\n  Cache-Control: public, max-age=31536000, immutable\n  Vary: Accept-Encoding\n' "$fav_hash"
} >> "${SITE_DIR}/_headers"

echo "Built ${SITE_DIR}"
