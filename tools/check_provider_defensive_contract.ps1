param(
  [string]$Root = "lib/framework/provider"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Root)) {
  Write-Host "Path not found: $Root"
  exit 2
}

$files = Get-ChildItem $Root -Recurse -File -Filter *.dart |
  Where-Object { $_.FullName -notlike '*.g.dart' }

$rules = @(
  @{
    Name = "Nullable collection query signature"
    Pattern = '^(\s*)(List|Map|Set)<[^>]+>\?\s+[a-zA-Z0-9_]+\s*\(Ref\s+ref'
  },
  @{
    Name = "Null loading fallback"
    Pattern = 'loading:\s*\(\)\s*=>\s*null'
  },
  @{
    Name = "Null orElse fallback"
    Pattern = 'orElse:\s*\(\)\s*=>\s*null'
  }
)

$violations = @()

foreach ($file in $files) {
  foreach ($rule in $rules) {
    $matches = Select-String -Path $file.FullName -Pattern $rule.Pattern
    foreach ($m in $matches) {
      $violations += [PSCustomObject]@{
        Rule = $rule.Name
        File = $file.FullName
        Line = $m.LineNumber
        Text = $m.Line.Trim()
      }
    }
  }
}

if ($violations.Count -eq 0) {
  Write-Host "Provider defensive contract check passed."
  exit 0
}

Write-Host "Provider defensive contract violations:"
$violations | ForEach-Object {
  Write-Host ("[{0}] {1}:{2}: {3}" -f $_.Rule, $_.File, $_.Line, $_.Text)
}

exit 1
