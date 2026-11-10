# Compare two camera read files (made by "read commands.md" or Read-CameraConfig.ps1) and list only the
# settings that differ, section by section. The differences are printed in the terminal and saved as a
# Markdown summary. Nothing is sent to a camera.
#
# When a file has the same section more than once (it was read again), the latest read is used.
# Values that belong to the camera itself (MAC address, serial and license numbers, firmware version) are
# left out, since they always differ and are never copied. Passwords are {{PASSWORD}} in both files, so
# they never show as different.
#
# The summary file is replaced each time the script runs.
#
# When write-format.json says how each section is written, the summary also gets a ready-to-run
# PowerShell write command for each section that differs, with the "from" camera's values. Each command
# asks for the login password, and asks for any {{PASSWORD}} setting (twice) instead of saving it.
#
# Example:
#   powershell -ExecutionPolicy Bypass -File .\Compare-CameraConfig.ps1 -From "quail read output.md" -To "alkire read output.md"
param(
    [Parameter(Mandatory)][string]$From,   # the camera to copy from (Quail)
    [Parameter(Mandatory)][string]$To,     # the camera to copy to (Alkire)
    [string]$OutFile,                      # default: "<from> vs <to> differences.md" in this folder
    [string]$Format = 'write-format.json', # how each section is written; used to build the write commands
    [string]$CameraHost = '192.168.111.245'
)
$ErrorActionPreference = 'Stop'

$cameraOwn = 'macaddr', 'ndimacid', 'ndi_license', 'ndi', 'ndiserialnum', 'versioninfo', 'videoinitdone'

# Whether "write commands.md" step 4 says to copy each section
$copyNote = @{
    get_device_conf        = 'Only `devname`, if wanted.'
    get_system_conf        = 'Copy after the other sections (changes the camera''s logins).'
    get_network_conf       = 'Not copied: set network settings by hand.'
    get_ipcfg_conf         = 'Not copied: set network settings by hand.'
    get_image_conf         = 'Copy.'
    get_advance_image_conf = 'Copy.'
    get_media_video        = 'Copy (may briefly interrupt video).'
    get_media_audio        = 'Copy.'
    get_overlay_conf       = 'Copy.'
    get_ndi_info           = 'Copy, but keep `channelName` unique on the network.'
    get_language_conf      = 'Not copied.'
}

function Resolve-RepoPath($path) {
    if ([IO.Path]::IsPathRooted($path)) { $path } else { Join-Path $PSScriptRoot $path }
}

# Section -> (setting -> value), from a read file. A later copy of a section replaces an earlier one.
function Read-ConfigFile($path) {
    $sections = [ordered]@{}
    $section = $null
    foreach ($line in [IO.File]::ReadAllLines((Resolve-RepoPath $path))) {
        if ($line -match '^## (\S+)') {
            $section = $Matches[1]
            $sections[$section] = [ordered]@{}
        } elseif ($section -and $line -match '^\s*\{?(\w+)\s*[=:]\s*"([^"]*)"') {
            # key="value" lines, and the NDI section's key:"value", lines
            $sections[$section][$Matches[1]] = $Matches[2]
        }
    }
    return $sections
}

function Format-Cell($v) { ($v -replace '\|', '\|') }

$a = Read-ConfigFile $From
$b = Read-ConfigFile $To
$fromName = [IO.Path]::GetFileNameWithoutExtension($From) -replace ' read output$', ''
$toName = [IO.Path]::GetFileNameWithoutExtension($To) -replace ' read output$', ''
if (-not $OutFile) { $OutFile = "$fromName vs $toName differences.md" }
$OutFile = Resolve-RepoPath $OutFile

$md = New-Object Collections.Generic.List[string]
$md.Add("# $fromName vs $toName camera config differences")
$md.Add('')
$md.Add("Compared $(Get-Date -Format 'yyyy-MM-dd HH:mm'): ``$([IO.Path]::GetFileName($From))`` (copy from) and ``$([IO.Path]::GetFileName($To))`` (copy to).")
$md.Add('Only settings that differ are listed. Camera-specific values (MAC, serial, license, firmware) are left out.')
$md.Add('')

$total = 0
$summary = New-Object Collections.Generic.List[string]
foreach ($s in @($a.Keys) + @($b.Keys | Where-Object { -not $a.Contains($_) })) {
    $note = if ($copyNote.ContainsKey($s)) { $copyNote[$s] } else { '' }
    if (-not $a.Contains($s) -or -not $b.Contains($s)) {
        $where = if ($a.Contains($s)) { "Not read from $toName." } else { "Not read from $fromName." }
        Write-Host "## $s`n  $where`n"
        $md.Add("## $s"); $md.Add(''); $md.Add($where); $md.Add('')
        $summary.Add("| ``$s`` | not compared | $note |")
        continue
    }
    $keys = @($a[$s].Keys) + @($b[$s].Keys | Where-Object { -not $a[$s].Contains($_) })
    $rows = @(foreach ($k in $keys) {
        if ($cameraOwn -contains $k) { continue }
        $va = if ($a[$s].Contains($k)) { $a[$s][$k] } else { '(missing)' }
        $vb = if ($b[$s].Contains($k)) { $b[$s][$k] } else { '(missing)' }
        if ($va -cne $vb) { [pscustomobject]@{ Setting = $k; $fromName = $va; $toName = $vb } }
    })
    $summary.Add("| ``$s`` | $($rows.Count) | $note |")
    if ($rows.Count -eq 0) { continue }
    $total += $rows.Count
    Write-Host "## $s ($($rows.Count) different)"
    $rows | Format-Table -AutoSize | Out-String -Width 200 | Write-Host
    $md.Add("## $s ($($rows.Count) different)")
    $md.Add('')
    if ($note) { $md.Add("Step 4: $note"); $md.Add('') }
    $md.Add("| Setting | $fromName | $toName |")
    $md.Add('|---|---|---|')
    foreach ($r in $rows) { $md.Add("| ``$($r.Setting)`` | $(Format-Cell $r.$fromName) | $(Format-Cell $r.$toName) |") }
    $md.Add('')
}

# Ready-to-run write commands, one per write command in write-format.json whose section differs
$diffCount = @{}
foreach ($line in $summary) { if ($line -match '^\| `(\w+)` \| (\d+) \|') { $diffCount[$Matches[1]] = [int]$Matches[2] } }
$formatPath = Resolve-RepoPath $Format
$writes = @()
$user = 'admin'
if (Test-Path $formatPath) {
    $fmt = [IO.File]::ReadAllText($formatPath) | ConvertFrom-Json
    if ($fmt.user) { $user = $fmt.user }
    $all = @($fmt.commands | Where-Object { $_ })
    $writes = @($all | Where-Object { $_.section -ne 'get_system_conf' }) + @($all | Where-Object { $_.section -eq 'get_system_conf' })
}
$pwLabel = @{ userpasswd = 'admin'; guestpasswd = 'guest'; srt_passstr = 'SRT'; sipdevice_ipc_pw = 'SIP device' }
$readNewPassword = @(
    'function Read-NewPassword($name) {',
    '    $a = [Net.NetworkCredential]::new('''', (Read-Host "New $name password to set on the camera" -AsSecureString)).Password',
    '    $b = [Net.NetworkCredential]::new('''', (Read-Host "Type the new $name password again" -AsSecureString)).Password',
    '    if ($a -ne $b) { throw "The two $name passwords don''t match. Nothing was sent." }',
    '    [Uri]::EscapeDataString($a)',
    '}'
)

$md.Add('## Write commands')
$md.Add('')
if ($writes.Count -eq 0) {
    $md.Add("No write commands yet: ``$Format`` does not say how the sections are written. Run step 2 of")
    $md.Add('`write commands.md` (find the write format) on a camera, fill in the file, and run this compare again.')
    $md.Add('')
} else {
    $md.Add("Run one block at a time, in this order, and check each section (read it again) before the next.")
    $md.Add("Each block asks for the camera's current ``$user`` password; nothing is saved. ``status=200`` means")
    $md.Add('the camera accepted it. The values are the ones from the "copy from" file.')
    $md.Add('')
    foreach ($w in $writes) {
        $sec = $w.section
        if (-not $a.Contains($sec)) { $md.Add("### $($w.command)"); $md.Add(''); $md.Add("``$sec`` was not read from $fromName, so there are no values to write."); $md.Add(''); continue }
        if ($diffCount[$sec] -eq 0) { $md.Add("### $($w.command)"); $md.Add(''); $md.Add("Nothing to write: ``$sec`` already matches."); $md.Add(''); continue }
        $fields = if ($w.fields) { @($w.fields) } else { @($a[$sec].Keys | Where-Object { $cameraOwn -notcontains $_ }) }
        $missing = @($fields | Where-Object { -not $a[$sec].Contains($_) })
        $pwFields = @($fields | Where-Object { $a[$sec].Contains($_) -and $a[$sec][$_] -eq '{{PASSWORD}}' })
        $pairs = foreach ($f in $fields) {
            if ($missing -contains $f) { continue }
            if ($pwFields -contains $f) { "$([Uri]::EscapeDataString($f))=`$pw_$f" }
            else { "$([Uri]::EscapeDataString($f))=$([Uri]::EscapeDataString($a[$sec][$f]))" }
        }
        $body = $pairs -join '&'
        $block = New-Object Collections.Generic.List[string]
        if ($pwFields) {
            $block.AddRange([string[]]$readNewPassword)
            foreach ($f in $pwFields) {
                $label = if ($pwLabel.ContainsKey($f)) { $pwLabel[$f] } else { $f }
                $block.Add(('$pw_{0} = Read-NewPassword "{1}"' -f $f, $label))
            }
        }
        $block.Add(('$p = Read-Host "Current camera password for {0}" -AsSecureString' -f $user))
        $login = '--digest -u ("{0}:" + [Net.NetworkCredential]::new('''', $p).Password)' -f $user
        if ($w.method -eq 'GET') {
            $block.Add(('curl.exe -s -w "`nstatus=%{{http_code}}`n" {0} "http://{1}/cgi-bin/param.cgi?{2}&{3}"' -f $login, $CameraHost, $w.command, $body))
        } else {
            $block.Add(('curl.exe -s -w "`nstatus=%{{http_code}}`n" {0} -X POST "http://{1}/cgi-bin/param.cgi?{2}" --data "{3}"' -f $login, $CameraHost, $w.command, $body))
        }
        $block.Add('Remove-Variable p' + (($pwFields | ForEach-Object { ", pw_$_" }) -join ''))

        $md.Add("### $($w.command) ($($diffCount[$sec]) different in ``$sec``)")
        $md.Add('')
        if ($sec -eq 'get_system_conf') {
            $md.Add('This changes the camera''s logins: after it, use the **new** passwords. It asks for each new password twice.')
            $md.Add('')
        }
        if ($missing) {
            $names = ($missing | ForEach-Object { '`' + $_ + '`' }) -join ', '
            $md.Add("Not sent, because they are not in $fromName's ``$sec``: $names.")
            $md.Add('')
        }
        $md.Add('```powershell')
        $md.AddRange([string[]]$block)
        $md.Add('```')
        $md.Add('')
    }
}

$headline = if ($total -eq 0) { 'No differences: every setting matches.' } else { "$total settings differ in total." }
Write-Host $headline

# Summary table goes at the top, after the intro
$top = @("**$headline**", '', '| Section | Settings that differ | Copy? (write commands step 4) |', '|---|---|---|') + $summary + @('')
$md.InsertRange(5, [string[]]$top)
Set-Content -Path $OutFile -Value $md -Encoding UTF8
Write-Host "Summary saved to $OutFile"
if ($writes.Count -eq 0) { Write-Host "No write commands added: $Format does not say how the sections are written yet." }
else { Write-Host "Write commands for the sections that differ are at the end of the summary." }
