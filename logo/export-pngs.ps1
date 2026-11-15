# Exports ready-to-use PNG renders of the Sawaab.in logo SVGs using headless Microsoft Edge.
$root   = Split-Path -Parent $MyInvocation.MyCommand.Path
$outDir = Join-Path $root 'png'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$edge = @(
  'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
  'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $edge) { $edge = (Get-Command msedge.exe -ErrorAction SilentlyContinue).Source }
if (-not $edge) { throw 'Microsoft Edge not found. Install Edge or export the SVGs manually.' }

$targets = @(
  @{ svg = 'sawaab-icon.svg';          w = 512;  h = 512; out = 'sawaab-icon-512.png' },
  @{ svg = 'sawaab-icon.svg';          w = 192;  h = 192; out = 'sawaab-icon-192.png' },
  @{ svg = 'sawaab-icon.svg';          w = 64;   h = 64;  out = 'sawaab-icon-64.png' },
  @{ svg = 'sawaab-logo.svg';          w = 1160; h = 380; out = 'sawaab-logo-1160.png' },
  @{ svg = 'sawaab-logo-vertical.svg'; w = 840;  h = 620; out = 'sawaab-logo-vertical-840.png' },
  @{ svg = 'sawaab-logo-dark.svg';     w = 1160; h = 380; out = 'sawaab-logo-dark-1160.png' },
  @{ svg = 'sawaab-logo-mono.svg';     w = 1160; h = 380; out = 'sawaab-logo-mono-1160.png' },
  @{ svg = 'sawaab-social-banner.svg'; w = 1280; h = 640; out = 'sawaab-social-banner-1280.png' }
)

foreach ($t in $targets) {
  $out  = Join-Path $outDir $t.out
  $wrap = Join-Path $outDir ($t.out + '.html')
  if (Test-Path $wrap) { Remove-Item $wrap -Force }
  "<!doctype html><html><body style='margin:0;background:transparent'><img src='../$($t.svg)' width='$($t.w)' height='$($t.h)' style='display:block'></body></html>" |
    Set-Content -Path $wrap -Encoding UTF8
  $url = 'file:///' + ($wrap -replace '\\', '/')
  $argList = @(
    '--headless=new', '--disable-gpu', '--disable-extensions', '--hide-scrollbars', '--no-first-run',
    '--default-background-color=00000000',
    "--user-data-dir=$env:TEMP\edge-hl-$([guid]::NewGuid().ToString('N'))",
    "--window-size=$($t.w),$($t.h)",
    "--screenshot=$out",
    $url
  ) -join ' '
  Start-Process -FilePath $edge -ArgumentList $argList -Wait -WindowStyle Hidden | Out-Null
  if (-not (Test-Path $out -PathType Leaf) -or (Get-Item $out).Length -eq 0) {
    $argListFallback = $argList -replace '^--headless=new', '--headless'
    Start-Process -FilePath $edge -ArgumentList $argListFallback -Wait -WindowStyle Hidden | Out-Null
  }
  if (Test-Path $out -PathType Leaf) {
    Write-Output ("OK   {0}  ({1} bytes)" -f $t.out, (Get-Item $out).Length)
  } else {
    Write-Output ("FAIL {0}" -f $t.out)
  }
  Remove-Item $wrap -Force -ErrorAction SilentlyContinue
}
Write-Output 'DONE'
