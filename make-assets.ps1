# Regenerates og.png, favicons and apple-touch-icon for the peptide calculator.
# Run:  powershell -ExecutionPolicy Bypass -File make-assets.ps1
# No external dependencies - uses System.Drawing (Windows PowerShell 5.1).
#
# NOTE: PowerShell variables are case-insensitive. Colour constants are all
# prefixed cl* so they can never collide with local geometry variables.

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

function C([string]$hex){ [System.Drawing.ColorTranslator]::FromHtml($hex) }

$clGround   = C '#E9EDF0'
$clPanel    = C '#FFFFFF'
$clBarrelBg = C '#FBFCFD'
$clInk      = C '#141F28'
$clInkSoft  = C '#5C6B77'
$clInkFaint = C '#8A98A3'
$clFluidTop = C '#1391B3'
$clFluidDeep= C '#0A5D75'
$clHairline = C '#D2D9DF'

# ---- helpers ----
function New-RoundedPath([single]$x,[single]$y,[single]$w,[single]$h,[single]$r){
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  if($r -le 0){
    $rr = New-Object System.Drawing.RectangleF -ArgumentList $x,$y,$w,$h
    $path.AddRectangle($rr)
    return $path
  }
  $d = $r * 2
  $path.AddArc($x,       $y,       $d, $d, 180, 90)
  $path.AddArc($x+$w-$d, $y,       $d, $d, 270, 90)
  $path.AddArc($x+$w-$d, $y+$h-$d, $d, $d,   0, 90)
  $path.AddArc($x,       $y+$h-$d, $d, $d,  90, 90)
  $path.CloseFigure()
  return $path
}

function New-Gfx($bitmap){
  $gg = [System.Drawing.Graphics]::FromImage($bitmap)
  $gg.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $gg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $gg.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $gg.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  return $gg
}

function New-Fnt([string]$family,[single]$px,[string]$style='Regular'){
  New-Object System.Drawing.Font -ArgumentList `
    $family, $px, ([System.Drawing.FontStyle]::$style), ([System.Drawing.GraphicsUnit]::Pixel)
}

function New-Brush($color){
  New-Object System.Drawing.SolidBrush -ArgumentList $color
}

function Fade($color,[int]$alpha){
  [System.Drawing.Color]::FromArgb($alpha, $color.R, $color.G, $color.B)
}

# System.Drawing has no letter-spacing, so advance manually.
function Draw-Tracked($gfx,[string]$text,$font,$brush,[single]$x,[single]$y,[single]$track){
  $tf = [System.Drawing.StringFormat]::GenericTypographic
  foreach($ch in $text.ToCharArray()){
    $s = [string]$ch
    if($s -eq ' '){
      # GenericTypographic measures a lone space as ~0 wide; advance manually.
      $x += $font.Size * 0.32 + $track
      continue
    }
    $gfx.DrawString($s, $font, $brush, $x, $y, $tf)
    $x += $gfx.MeasureString($s, $font, [System.Drawing.PointF]::Empty, $tf).Width + $track
  }
}

# ---------------------------------------------------------------
# The mark: a barrel with the plunger about a third along.
# Deliberately crude geometry - it has to survive 16x16.
# ---------------------------------------------------------------
function Draw-Mark($gfx,[single]$size,[bool]$roundTile){
  $u = $size / 32.0
  $tileR = 0
  if($roundTile){ $tileR = 6 * $u }

  $tilePath = New-RoundedPath 0 0 $size $size $tileR
  $tb = New-Brush $clFluidDeep
  $gfx.FillPath($tb, $tilePath)
  $tb.Dispose(); $tilePath.Dispose()

  $mx = 5*$u; $my = 11*$u; $mw = 22*$u; $mh = 10*$u
  $barrelPath = New-RoundedPath $mx $my $mw $mh (3*$u)

  $ghost = New-Brush ([System.Drawing.Color]::FromArgb(64,255,255,255))
  $gfx.FillPath($ghost, $barrelPath)
  $ghost.Dispose()

  # fluid - clipped to the barrel so its right edge stays square
  $prevClip = $gfx.Clip
  $gfx.SetClip($barrelPath)
  $fb = New-Brush ([System.Drawing.Color]::White)
  $gfx.FillRectangle($fb, $mx, $my, [single](10*$u), $mh)
  $fb.Dispose()
  $gfx.Clip = $prevClip
  $barrelPath.Dispose()
}

function Save-Icon([int]$size,[string]$file,[bool]$roundTile){
  $bm = New-Object System.Drawing.Bitmap -ArgumentList `
          $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $gg = New-Gfx $bm
  Draw-Mark $gg $size $roundTile
  $gg.Dispose()
  $bm.Save((Join-Path $root $file), [System.Drawing.Imaging.ImageFormat]::Png)
  $bm.Dispose()
  Write-Output "  $file  ${size}x${size}"
}

Write-Output "icons:"
Save-Icon 16  'favicon-16.png'       $true
Save-Icon 32  'favicon-32.png'       $true
Save-Icon 180 'apple-touch-icon.png' $false   # iOS applies its own mask

# ---- favicon.ico wrapping the 32px PNG (Vista+ reads PNG payloads) ----
$pngBytes = [System.IO.File]::ReadAllBytes((Join-Path $root 'favicon-32.png'))
$ms = New-Object System.IO.MemoryStream
$wr = New-Object System.IO.BinaryWriter -ArgumentList $ms
$wr.Write([uint16]0); $wr.Write([uint16]1); $wr.Write([uint16]1)   # ICONDIR
$wr.Write([byte]32);  $wr.Write([byte]32)                          # w, h
$wr.Write([byte]0);   $wr.Write([byte]0)                           # palette, reserved
$wr.Write([uint16]1); $wr.Write([uint16]32)                        # planes, bpp
$wr.Write([uint32]$pngBytes.Length); $wr.Write([uint32]22)         # size, offset
$wr.Write($pngBytes); $wr.Flush()
[System.IO.File]::WriteAllBytes((Join-Path $root 'favicon.ico'), $ms.ToArray())
$wr.Dispose(); $ms.Dispose()
Write-Output "  favicon.ico  32x32"

# ---------------------------------------------------------------
# og.png - 1200x630 social card, mirrors the page layout
# ---------------------------------------------------------------
$ogW = 1200; $ogH = 630
$card = New-Object System.Drawing.Bitmap -ArgumentList `
          $ogW, $ogH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = New-Gfx $card
$tf = [System.Drawing.StringFormat]::GenericTypographic

$br = New-Brush $clGround
$g.FillRectangle($br, 0, 0, $ogW, $ogH); $br.Dispose()

$panelPath = New-RoundedPath 56 56 1088 518 6
$br = New-Brush $clPanel
$g.FillPath($br, $panelPath); $br.Dispose()
$pen = New-Object System.Drawing.Pen -ArgumentList $clHairline, ([single]1)
$g.DrawPath($pen, $panelPath); $pen.Dispose(); $panelPath.Dispose()

$edge = [single]120     # content left edge

# eyebrow
$dot   = [string][char]0x00B7   # middot
$ndash = [string][char]0x2013   # en dash
$fMono = New-Fnt 'Consolas' 16
$br = New-Brush $clInkFaint
Draw-Tracked $g "FREE $dot NO ACCOUNT $dot NOTHING STORED" $fMono $br $edge 118 2.2
$br.Dispose(); $fMono.Dispose()

# title
$fTitle = New-Fnt 'Segoe UI Semibold' 74
$br = New-Brush $clInk
$g.DrawString('Peptide reconstitution', $fTitle, $br, $edge, [single]152, $tf)
$g.DrawString('calculator',             $fTitle, $br, $edge, [single]232, $tf)
$br.Dispose(); $fTitle.Dispose()

# standfirst
$fSub = New-Fnt 'Segoe UI' 27
$br = New-Brush $clInkSoft
$g.DrawString("Vial size, water, dose $ndash and exactly where the plunger lands.",
              $fSub, $br, $edge, [single]346, $tf)
$br.Dispose(); $fSub.Dispose()

# ---- syringe ----
$axis  = [single]470
$barX  = [single]194
$barW  = [single]816
$barY  = [single]430
$barH  = [single]80

$pen = New-Object System.Drawing.Pen -ArgumentList $clInkFaint, ([single]3)
$g.DrawLine($pen, $edge, $axis, [single]178, $axis); $pen.Dispose()
$br = New-Brush $clHairline
$g.FillRectangle($br, [single]178, [single]($axis-9), [single]16, [single]18); $br.Dispose()

$barrelPath = New-RoundedPath $barX $barY $barW $barH 2
$br = New-Brush $clBarrelBg
$g.FillPath($br, $barrelPath); $br.Dispose()

# the 10-unit default draw on a 30u barrel
$fluidW = [single]($barW * 10.0 / 30.0)

$prevClip = $g.Clip
$g.SetClip($barrelPath)

# Two-point gradient: the (RectangleF, Color, Color, Single) overload is
# ambiguous to PowerShell's binder, PointF..PointF is not.
$ptTop  = New-Object System.Drawing.PointF -ArgumentList @([single]$barX, [single]($barY-1))
$ptBot  = New-Object System.Drawing.PointF -ArgumentList @([single]$barX, [single]($barY+$barH+1))
$gradArgs = @($ptTop, $ptBot, $clFluidTop, $clFluidDeep)
$grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush -ArgumentList $gradArgs
$g.FillRectangle($grad, $barX, $barY, $fluidW, $barH)
$grad.Dispose()

# Stopper goes down before the scale: on a real syringe the gradations are
# printed on the barrel and the stopper slides underneath them.
$br = New-Brush (Fade $clInk 209)
$g.FillRectangle($br, [single]($barX + $fluidW - 1), $barY, [single]10, $barH); $br.Dispose()

# gradations - every unit, majors every 5, matching a 30u barrel
$fTick = New-Fnt 'Consolas' 14
for($n=0; $n -le 30; $n++){
  $tx = [single]($barX + ($barW * $n / 30.0))
  $isMajor = ($n % 5) -eq 0
  $th = 14; $alpha = 110
  if($isMajor){ $th = 26; $alpha = 185 }

  # Gradations sitting on the drawn fluid have to invert or they vanish.
  $overFluid = $tx -le ($barX + $fluidW + 2)
  $tickCol = Fade $clInk $alpha
  $labCol  = $clInkSoft
  if($overFluid){
    $tickCol = [System.Drawing.Color]::FromArgb($alpha, 255, 255, 255)
    $labCol  = [System.Drawing.Color]::FromArgb(235, 255, 255, 255)
  }

  $tpen = New-Object System.Drawing.Pen -ArgumentList $tickCol, ([single]1)
  $g.DrawLine($tpen, $tx, $barY, $tx, [single]($barY + $th)); $tpen.Dispose()
  if($isMajor){
    $lab = [string]$n
    $sz  = $g.MeasureString($lab, $fTick, [System.Drawing.PointF]::Empty, $tf)
    $lx  = [single][Math]::Min([Math]::Max($tx - $sz.Width/2, $barX+3), $barX+$barW-$sz.Width-3)
    $tb  = New-Brush $labCol
    $g.DrawString($lab, $fTick, $tb, $lx, [single]($barY + $barH - $sz.Height - 5), $tf)
    $tb.Dispose()
  }
}
$fTick.Dispose()

$g.Clip = $prevClip
$pen = New-Object System.Drawing.Pen -ArgumentList $clHairline, ([single]1)
$g.DrawPath($pen, $barrelPath); $pen.Dispose(); $barrelPath.Dispose()

# plunger shaft + flange
$br = New-Brush $clHairline
$g.FillRectangle($br, [single]($barX+$barW),    [single]($axis-14), [single]14, [single]28)
$g.FillRectangle($br, [single]($barX+$barW+16), [single]($axis-28), [single]6,  [single]56)
$br.Dispose()

$g.Dispose()
$card.Save((Join-Path $root 'og.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$card.Dispose()
Write-Output "og:"
Write-Output "  og.png  1200x630"
