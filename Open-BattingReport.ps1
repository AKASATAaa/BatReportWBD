# BattingReport: 로컬 서버 + 브라우저(앱 창). 이 창을 닫으면 서버 프로세스도 함께 종료됩니다.
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

$port = 8765
for ($t = 0; $t -lt 40; $t++) {
  $c = New-Object System.Net.Sockets.TcpClient
  try {
    $c.Connect("127.0.0.1", $port)
    $c.Close()
    $port++
    continue
  } catch {
    $c.Close()
    break
  }
}

$serverScript = Join-Path $here "BattingReport.TinyServer.ps1"
if (-not (Test-Path -LiteralPath $serverScript)) {
  Write-Host "없음: BattingReport.TinyServer.ps1"
  exit 1
}

$srv = Start-Process -FilePath "powershell.exe" -ArgumentList @(
  "-NoProfile", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden",
  "-File", $serverScript, $here, "$port"
) -PassThru

Start-Sleep -Milliseconds 450
if ($srv.HasExited) {
  Write-Host "서버가 바로 종료됐습니다. 포트나 방화벽을 확인하세요."
  exit 1
}

$url = "http://127.0.0.1:$port/BattingReport.html"
$userData = Join-Path $env:TEMP ("BattingReportApp_" + [Guid]::NewGuid().ToString("N"))

$edge = @(
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
  "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

$chrome = @(
  "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
  "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

$exe = $edge
if (-not $exe) { $exe = $chrome }
if (-not $exe) {
  Stop-Process -Id $srv.Id -Force -ErrorAction SilentlyContinue
  Write-Host "Microsoft Edge 또는 Google Chrome을 설치해 주세요."
  exit 1
}

$args = @(
  "--user-data-dir=$userData",
  "--app=$url",
  "--no-first-run",
  "--disable-extensions",
  "--disable-popup-blocking"
)

$browser = Start-Process -FilePath $exe -ArgumentList $args -PassThru

try {
  Wait-Process -Id $browser.Id -ErrorAction Stop
} catch {
  # 프로세스가 이미 없으면 무시
}

Stop-Process -Id $srv.Id -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 200
Remove-Item -LiteralPath $userData -Recurse -Force -ErrorAction SilentlyContinue
