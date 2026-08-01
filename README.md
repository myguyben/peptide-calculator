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
| `render.yaml` | Blueprint, incl. header rules — see caveat below |
| `<64-hex>.txt` | IndexNow ownership key |
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
$old = 'syringecalc.com'
$new = 'your-new-domain.com'
Get-ChildItem index.html, sitemap.xml, robots.txt | ForEach-Object {
  (Get-Content $_ -Raw).Replace($old, $new) | Set-Content $_ -NoNewline -Encoding utf8
}
```

Also bump `<lastmod>` in `sitemap.xml` when the page content changes.

## Deploy

Render static site, publish path `.`, no build command. Auto-deploys on push to
`main`.

- Service: `peptide-calc` (`srv-d9miq6navr4c73eg8l20`), Icey workspace
- Live: https://syringecalc.com

### Header rules are not applied yet

Render ignores Netlify-style `_headers` files — verified against the live
response, where only Render's own `nosniff` came back. The rules now live in
`render.yaml`, but this service was created through the API rather than from a
Blueprint, so they are declarative only.

To actually apply them, either paste the five rules into
**Dashboard → peptide-calc → Settings → Headers**, or recreate the service from
the Blueprint. Low priority: this only costs some repeat-visit font caching, and
Cloudflare already edge-caches at `s-maxage=300`.

## Indexing

`sitemap.xml` is referenced from `robots.txt`, so any crawler that finds the
site will find the sitemap.

- **IndexNow** (Bing, Yandex, Seznam, Naver) — submitted; ownership key is the
  `<64-hex>.txt` file at the site root. Re-submit after content changes:

  ```powershell
  $key = '20c5e17585ea44cc99997c8085c209ae4dc70d61a7c84bbd9fa3c482c554aa6c'
  Invoke-WebRequest -UseBasicParsing -Uri ("https://api.indexnow.org/indexnow" +
    "?url=https://syringecalc.com/&key=$key")
  ```

- **Google** — done 2026-07-31. `https://syringecalc.com/` is a verified
  URL-prefix property, sitemap submitted, and the homepage reports
  **"URL is on Google — Page is indexed"**, discovered via the sitemap, with
  Google selecting our declared canonical. There is no API path for any of
  this: Google does not participate in IndexNow, it retired the sitemap ping
  endpoint in 2023, and the Indexing API only accepts `JobPosting` and
  `BroadcastEvent`. It has to be driven through the Search Console UI.

  Ownership is held by `google2da331979a34076d.html` at the site root plus the
  meta tag in `index.html`. Keep both — verification is re-checked periodically.

  A stale property still exists for `https://peptide-calc.onrender.com/`. That
  host now 404s, so the property is dead weight; harmless, but delete it if it
  gets confusing.

### If the domain ever changes again

Render makes the custom domain primary and starts 404ing the `onrender.com`
subdomain. Anything still pointing at the old host — canonical, `og:url`,
`og:image`, sitemap `<loc>`, `robots.txt` — then references a dead URL, which is
worse for indexing than having no canonical at all. Run the find-replace above
*before* or immediately after the switch, and add a fresh Search Console
property for the new host.

Note for the find-replace: `Get-Content -Raw` in Windows PowerShell 5.1 reads as
ANSI and will mojibake the em dashes in `index.html`. Use
`[System.IO.File]::ReadAllText($path, (New-Object System.Text.UTF8Encoding($false)))`.

## Reading the result

Being indexed is not the same as ranking. Check **impressions**, not clicks, at
4–6 weeks (around mid-September 2026) under **Performance**. A few hundred
impressions on the head term means there is a way in; near-zero means the page
is indexed but invisible, and the SEO channel is effectively closed — which
costs a weekend rather than a quarter to learn.
