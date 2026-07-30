$ErrorActionPreference = 'Stop'

$root = 'd:\GIT\AnoxiaServer\AnoxiaAdmin\src'
$localeFiles = @(
  'd:\GIT\AnoxiaServer\AnoxiaAdmin\src\locales\zh-CN.ts',
  'd:\GIT\AnoxiaServer\AnoxiaAdmin\src\locales\en.ts',
  'd:\GIT\AnoxiaServer\AnoxiaAdmin\src\locales\ja.ts'
)

$files = Get-ChildItem -Path $root -Recurse -Include *.vue,*.ts,*.js
$regexes = @(
  [regex]"\$t\(\s*'([^']+)'",
  [regex]'\$t\(\s*"([^"]+)"',
  [regex]"\bt\(\s*'([^']+)'",
  [regex]'\bt\(\s*"([^"]+)"'
)

$keys = New-Object System.Collections.Generic.HashSet[string]
foreach ($f in $files) {
  $content = Get-Content -Path $f.FullName -Raw
  foreach ($re in $regexes) {
    foreach ($m in $re.Matches($content)) {
      $k = $m.Groups[1].Value
      if (-not [string]::IsNullOrWhiteSpace($k)) {
        [void]$keys.Add($k)
      }
    }
  }
}

function Test-KeyExists([string]$content, [string]$key) {
  $parts = $key.Split('.')
  if ($parts.Length -eq 0) { return $false }

  $start = 0
  for ($i = 0; $i -lt $parts.Length; $i++) {
    $p = [regex]::Escape($parts[$i])
    if ($i -lt $parts.Length - 1) {
      $re = [regex]("\b" + $p + "\s*:\s*\{")
    } else {
      $re = [regex]("\b" + $p + "\s*:")
    }

    $m = $re.Match($content, $start)
    if (-not $m.Success) { return $false }
    $start = $m.Index + $m.Length
  }

  return $true
}

$missing = @()
foreach ($k in $keys) {
  foreach ($lf in $localeFiles) {
    $lc = Get-Content -Path $lf -Raw
    if (-not (Test-KeyExists $lc $k)) {
      $missing += [pscustomobject]@{
        key = $k
        locale = [System.IO.Path]::GetFileName($lf)
      }
    }
  }
}

$reportPath = 'd:\GIT\AnoxiaClient\tmp_i18n_missing_report.txt'
$lines = @()
$lines += "TOTAL_KEYS=$($keys.Count)"
$lines += "MISSING_COUNT=$($missing.Count)"
$lines += ''
$lines += 'MISSING DETAILS:'
$lines += ($missing | Sort-Object key, locale | Format-Table -AutoSize | Out-String -Width 300)

Set-Content -Path $reportPath -Value $lines -Encoding utf8
Write-Output "REPORT=$reportPath"
Write-Output "TOTAL_KEYS=$($keys.Count)"
Write-Output "MISSING_COUNT=$($missing.Count)"