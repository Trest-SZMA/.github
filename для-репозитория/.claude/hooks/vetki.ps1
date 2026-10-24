# PreToolUse-хук регламента Trest-SZMA: не даёт Claude писать в main и Development,
# делать force-push и сливать PR. Регламент, раздел 8.
# Работает в Windows PowerShell 5.1 и PowerShell 7. Блокировка — код 2 и причина в stderr.
# Файл сохранён в UTF-8 с BOM: без BOM Windows PowerShell 5.1 читает кириллицу как ANSI.

$ErrorActionPreference = 'Stop'
[Console]::InputEncoding  = [Text.Encoding]::UTF8
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$Protected = @('main', 'Development')

function Block([string]$why) {
    [Console]::Error.WriteLine("ЗАБЛОКИРОВАНО регламентом Trest-SZMA: $why Если действие нужно — его выполняет владелец репозитория сам.")
    exit 2
}

$raw = [Console]::In.ReadToEnd()
if (-not $raw.Trim()) { exit 0 }
$data = $raw | ConvertFrom-Json
$cmd = [string]$data.tool_input.command
if (-not $cmd) { exit 0 }
$cwd = [string]$data.cwd
if (-not $cwd) { $cwd = (Get-Location).Path }

# Слияние PR — только владелец.
if ($cmd -match '(?i)\bgh\s+pr\s+merge\b') { Block 'слияние PR (gh pr merge) — только владелец.' }
if ($cmd -match '(?i)\bgh\s+api\b[^|;&\r\n]*/pulls/\d+/merge\b') { Block 'слияние PR через API — только владелец.' }

# Каждая команда git push в строке разбирается отдельно.
$pushes = [regex]::Matches($cmd, '(?i)\bgit(?:\s+-C\s+("[^"]+"|''[^'']+''|\S+))?\s+push\b([^|;&\r\n]*)')
foreach ($m in $pushes) {
    $gitDir = $cwd
    if ($m.Groups[1].Success) { $gitDir = $m.Groups[1].Value.Trim('"', "'") }
    $args_ = @($m.Groups[2].Value.Trim() -split '\s+' | Where-Object { $_ })

    $flags = @($args_ | Where-Object { $_ -like '-*' })
    $words = @($args_ | Where-Object { $_ -notlike '-*' })

    if ($flags | Where-Object { $_ -match '^(--force|--force-with-lease|--force-if-includes|-f|-[a-zA-Z]*f[a-zA-Z]*)(=.*)?$' }) {
        Block 'force-push запрещён во всех ветках.'
    }
    if ($flags -contains '--mirror' -or $flags -contains '--all') { Block 'push --all / --mirror затрагивает общие ветки.' }
    if ($flags -contains '--no-verify') { Block 'push --no-verify обходит хук pre-push регламента.' }

    # words: [remote] [refspec...]
    $refspecs = @()
    if ($words.Count -gt 1) { $refspecs = $words[1..($words.Count - 1)] }

    if ($refspecs.Count -eq 0) {
        # Голый push — уходит текущая ветка.
        $branch = ''
        try { $branch = (& git -C $gitDir rev-parse --abbrev-ref HEAD 2>$null) } catch { }
        if ($Protected -contains $branch) { Block "push из ветки $branch — в main и Development пишет только владелец." }
        continue
    }

    foreach ($r in $refspecs) {
        if ($r.StartsWith('+')) { Block 'force-push (+refspec) запрещён.' }
        $dst = if ($r.Contains(':')) { $r.Split(':')[-1] } else { $r }
        $dst = $dst -replace '^refs/heads/', ''
        if ($dst -eq 'HEAD') {
            try { $dst = (& git -C $gitDir rev-parse --abbrev-ref HEAD 2>$null) } catch { }
        }
        if ($Protected -contains $dst) { Block "push в $dst — в main и Development пишет только владелец." }
        if ($r.StartsWith(':') -or $flags -contains '--delete' -or $flags -contains '-d') {
            Block 'удаление веток на GitHub — только владелец.'
        }
    }
}

exit 0
