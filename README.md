# Peptide reconstitution calculator

A single-page static tool. Enter vial size, bacteriostatic water and dose; it
returns millilitres and U-100 insulin syringe units, and draws the fill on a
to-scale syringe barrel.

Built as an SEO test: does a new entrant get indexed at all for
"peptide reconstitution calculator" and its long tail?

## Scope

It converts numbers the user types. It does **not** suggest doses, ship a
protocol library, or recommend compounds. That boundary is deliberate — it is
what separates a calculator from a dosing recommendation, and it is what keeps
the page reviewable by ad networks and app stores later.

The disclaimer in the footer is load-bearing. Leave it.

## Files

| Path | What it is |
|---|---|
| `index.html` | The entire site — inline CSS and JS, no build step |
| `fonts/*.woff2` | Self-hosted latin subsets, so the page makes zero third-party requests |
| `og.png` | 1200×630 social card |
| `favicon.ico`, `favicon-16.png`, `favicon-32.png`, `apple-touch-icon.png` | Icons |
| `sitemap.xml`, `robots.txt` | Crawl surface |
| `_headers` | Render header rules (caching, `nosniff`, referrer policy) |
| `make-assets.ps1` | Regenerates og.png and every icon |
| `fetch-fonts.ps1` | Re-downloads the woff2 subsets from Google Fonts |

## Regenerating assets

```powershell
powershell -ExecutionPolicy Bypass -File make-assets.ps1
powershell -ExecutionPolicy Bypass -File fetch-fonts.ps1
```

`make-assets.ps1` uses `System.Drawing` and needs Windows PowerShell 5.1. It has
no package dependencies.

## Changing the domain

The live URL appears in four places. Find and replace all of them together:

- `index.html` — `<link rel="canonical">`, `og:url`, `og:image`, `twitter:image`,
  and the `url` field in the `WebApplication` JSON-LD block
- `sitemap.xml` — `<loc>`
- `robots.txt` — `Sitemap:`

```powershell
$old = 'peptide-calc.onrender.com'
$new = 'your-new-domain.com'
Get-ChildItem index.html, sitemap.xml, robots.txt | ForEach-Object {
  (Get-Content $_ -Raw).Replace($old, $new) | Set-Content $_ -NoNewline -Encoding utf8
}
```

Also bump `<lastmod>` in `sitemap.xml` when the page content changes.

## Deploy

Render static site, publish path `.`, no build command. Auto-deploys on push to
`main`.
