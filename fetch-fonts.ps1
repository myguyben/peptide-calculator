[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$dest = "C:\Users\benst\OneDrive\Desktop\Subscription Websites\peptide-calculator\fonts"
if(-not (Test-Path $dest)){ New-Item -ItemType Directory -Path $dest | Out-Null }

# Chrome UA so Google serves woff2 rather than ttf.
$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
$url = "https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;600&family=Instrument+Sans:wght@400..700&display=swap"

$css = (Invoke-WebRequest -Uri $url -UserAgent $ua -UseBasicParsing).Content
Write-Output "--- fetched css, $($css.Length) bytes ---"

# Split into @font-face blocks and keep only the basic-latin ones.
$blocks = [regex]::Matches($css, '@font-face\s*\{[^}]*\}')
Write-Output "blocks: $($blocks.Count)"

$out = New-Object System.Collections.ArrayList
foreach($b in $blocks){
  $t = $b.Value
  if($t -notmatch 'unicode-range:[^;]*U\+0000-00FF'){ continue }   # latin only
  $fam = ([regex]::Match($t, "font-family:\s*'([^']+)'")).Groups[1].Value
  $wgt = ([regex]::Match($t, 'font-weight:\s*([0-9 ]+)')).Groups[1].Value.Trim()
  $src = ([regex]::Match($t, 'url\((https://[^)]+\.woff2)\)')).Groups[1].Value
  if(-not $src){ continue }
  $slug = ($fam -replace '\s','') + '-' + ($wgt -replace '\s','-')
  $file = "$slug.woff2"
  Invoke-WebRequest -Uri $src -UserAgent $ua -UseBasicParsing -OutFile (Join-Path $dest $file)
  $size = [Math]::Round((Get-Item (Join-Path $dest $file)).Length / 1KB, 1)
  Write-Output "  $file  ${size} KB   ($fam $wgt)"
  [void]$out.Add([pscustomobject]@{ family=$fam; weight=$wgt; file=$file })
}

Write-Output ""
Write-Output "--- @font-face css ---"
foreach($f in $out){
  $w = $f.weight
  Write-Output "@font-face{font-family:'$($f.family)';font-style:normal;font-weight:$w;font-display:swap;src:url('fonts/$($f.file)') format('woff2');}"
}
