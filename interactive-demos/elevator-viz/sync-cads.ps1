# Copy CAD uploads from fucckincads into assets/ for the web viewer
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path (Split-Path -Parent $root) "fucckincads"
$dst = Join-Path $root "assets"
New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-Item (Join-Path $src "*.stl") $dst -Force
Copy-Item (Join-Path $src "*.STL") $dst -Force
Write-Host "Synced CAD files to $dst"
