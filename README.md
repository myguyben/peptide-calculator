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

- **Google** — not automatable from here. Google does not participate in
  IndexNow, and Search Console is OAuth-gated to the account owner. Ben has to:
  1. Add `https://syringecalc.com/` as a URL-prefix property at
     https://search.google.com/search-console
  2. Verify with the HTML meta tag (there is a commented slot in `index.html`
     `<head>` for it), then commit and push
  3. Submit `sitemap.xml` under **Indexing → Sitemaps**
  4. Run **URL Inspection → Request indexing** once for the homepage

## Reading the result

Check **impressions**, not clicks, at 4–6 weeks. Impressions answer the real
question — whether Google will index a new entrant in this niche at all. A few
hundred impressions on the head term by mid-September means there is a way in;
near-zero means the SEO channel is closed and the experiment cost a weekend
rather than a quarter.
