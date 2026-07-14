# Site versions (GitHub Pages)

GitHub Pages always serves whatever is currently at `docs/index.html` on `main`.
Older full-page snapshots live here so you can switch without losing anything.

| File | What it is |
|------|------------|
| [`../index.html`](../index.html) | **Live site** (what `squiddyscripts.github.io/ecodrop` shows) |
| [`site-build-first.html`](site-build-first.html) | Build-first / project overview layout (garage photos, plain wording) |
| [`site-manuscript-ECODROP-TR-2026.html`](site-manuscript-ECODROP-TR-2026.html) | Interactive technical-record / manuscript layout |

## Switch which one is live

From the repo root:

```bash
# make the build-first layout live
cp docs/archive/site-build-first.html docs/index.html

# or make the manuscript layout live
cp docs/archive/site-manuscript-ECODROP-TR-2026.html docs/index.html
```

Then commit + push `docs/index.html`. Images still resolve from `docs/assets/` for any snapshot that uses relative `assets/...` paths.

Preview a snapshot locally by opening the HTML file in a browser (some demos need a local server).
