# 정적 파일만 제공하는 초소형 HTTP 서버 (Launcher가 종료 시 프로세스를 죽임)
param(
  [Parameter(Mandatory = $true)][string]$Root,
  [Parameter(Mandatory = $true)][int]$Port
)

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path -LiteralPath $Root).Path

function Get-Mime([string]$ext) {
  switch ($ext.ToLowerInvariant()) {
    ".html" { "text/html; charset=utf-8" }
    ".htm" { "text/html; charset=utf-8" }
    ".css" { "text/css; charset=utf-8" }
    ".js" { "application/javascript; charset=utf-8" }
    ".json" { "application/json; charset=utf-8" }
    ".png" { "image/png" }
    ".jpg" { "image/jpeg" }
    ".jpeg" { "image/jpeg" }
    ".gif" { "image/gif" }
    ".svg" { "image/svg+xml" }
    ".ico" { "image/x-icon" }
    ".csv" { "text/csv; charset=utf-8" }
    ".txt" { "text/plain; charset=utf-8" }
    ".woff" { "font/woff" }
    ".woff2" { "font/woff2" }
    default { "application/octet-stream" }
  }
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
try {
  $listener.Start()
} catch {
  Write-Error "포트 $Port 바인딩 실패: $_"
  exit 1
}

while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
  } catch {
    break
  }
  $req = $ctx.Request
  $res = $ctx.Response
  try {
    $path = [Uri]::UnescapeDataString($req.Url.AbsolutePath)
    if ([string]::IsNullOrWhiteSpace($path) -or $path -eq "/") {
      $rel = "BattingReport_v3.html"
    } else {
      $rel = $path.TrimStart("/").Replace("/", [string][IO.Path]::DirectorySeparatorChar)
    }
    $candidate = [IO.Path]::GetFullPath((Join-Path $Root $rel))
    $rootBound = $Root.TrimEnd("\") + "\"
    if (-not $candidate.StartsWith($rootBound, [StringComparison]::OrdinalIgnoreCase) -and
        -not $candidate.Equals($Root, [StringComparison]::OrdinalIgnoreCase)) {
      $res.StatusCode = 403
      $buf = [Text.Encoding]::UTF8.GetBytes("403")
      $res.OutputStream.Write($buf, 0, $buf.Length)
    } elseif (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
      $res.StatusCode = 404
      $buf = [Text.Encoding]::UTF8.GetBytes("404")
      $res.OutputStream.Write($buf, 0, $buf.Length)
    } else {
      $ext = [IO.Path]::GetExtension($candidate)
      $res.ContentType = Get-Mime $ext
      $bytes = [IO.File]::ReadAllBytes($candidate)
      $res.ContentLength64 = $bytes.LongLength
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
    }
  } finally {
    $res.Close()
  }
}
