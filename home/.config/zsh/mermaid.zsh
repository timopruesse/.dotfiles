# Render Mermaid diagrams in the browser to eyeball them before pushing to
# GitHub. Uses the same mermaid.js engine GitHub does (loaded from a CDN), so
# what you see here is what GitHub will render. No local install required.
#
#   mermaid diagram.mmd          # a raw .mmd / .mermaid file (one diagram)
#   mermaid README.md            # every ```mermaid block in a markdown file
#   pbpaste | mermaid            # from stdin (also: mermaid -)
#
# Needs a browser + internet on first load (the CDN module is then cached).
function mermaid() {
  emulate -L zsh

  local src="${1:-}" content
  if [[ -n "$src" && "$src" != "-" ]]; then
    [[ -f "$src" ]] || { print -u2 "mermaid: no such file: $src"; return 1; }
    content="$(<"$src")"
  else
    src="stdin"
    content="$(cat)"
  fi

  # Build the <pre class="mermaid"> blocks. mermaid reads each element's
  # decoded textContent, so HTML-escaping & < > round-trips cleanly.
  local body
  if [[ "${src:l}" == *.mmd || "${src:l}" == *.mermaid ]]; then
    body="<pre class=\"mermaid\">$(print -r -- "$content" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')</pre>"
  else
    # Extract fenced ```mermaid blocks from markdown (or stdin).
    body="$(print -r -- "$content" | awk '
      /^[[:space:]]*```[[:space:]]*mermaid[[:space:]]*$/ { inblk=1; print "<pre class=\"mermaid\">"; next }
      inblk && /^[[:space:]]*```[[:space:]]*$/           { print "</pre>"; inblk=0; next }
      inblk { gsub(/&/,"\\&amp;"); gsub(/</,"\\&lt;"); gsub(/>/,"\\&gt;"); print }
    ')"
    if [[ -z "$body" ]]; then
      print -u2 "mermaid: no \`\`\`mermaid blocks found in $src"
      return 1
    fi
  fi

  local tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/mermaid.XXXXXX")" || return 1
  local out="$tmp.html"
  command mv "$tmp" "$out"

  cat > "$out" <<HTML
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>mermaid preview — $src</title>
<style>
  :root { color-scheme: light dark; }
  body {
    margin: 0;
    padding: 2rem;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    background: #ffffff;
    color: #1f2328;
  }
  header { font-size: .8rem; opacity: .6; margin-bottom: 1.5rem; }
  pre.mermaid {
    background: transparent;
    border: 1px solid #d0d7de;
    border-radius: 8px;
    padding: 1.5rem;
    margin: 0 0 1.5rem 0;
    overflow-x: auto;
    text-align: center;
  }
  pre.mermaid[data-processed] { border-color: #d0d7de; }
  @media (prefers-color-scheme: dark) {
    body { background: #0d1117; color: #e6edf3; }
    pre.mermaid { border-color: #30363d; }
  }
</style>
</head>
<body>
<header>mermaid preview — $src</header>
$body
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
  const dark = matchMedia('(prefers-color-scheme: dark)').matches;
  mermaid.initialize({ startOnLoad: true, theme: dark ? 'dark' : 'default' });
</script>
</body>
</html>
HTML

  # Open in the default browser, cross-platform.
  if command -v open >/dev/null 2>&1; then
    open "$out"                         # macOS
  elif [[ -n "$BROWSER" ]]; then
    "$BROWSER" "$out"                   # WSL (wslview) / explicit preference
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$out"                     # Linux
  else
    print -r -- "$out"                  # last resort: print the path
  fi
}
