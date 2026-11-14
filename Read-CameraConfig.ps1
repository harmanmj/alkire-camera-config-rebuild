# Read every config section from an RL500 PTZ camera, print each one, and add each one to a Markdown file
# under its own heading: the same output as the one-at-a-time commands in "read commands.md".
#
# The camera has no "whole config" endpoint, so each settings group is read separately with a get_*
# command on /cgi-bin/param.cgi (HTTP digest auth). These commands only read: nothing is written to the
# camera and it is not restarted.
#
# Password settings (userpasswd, guestpasswd, srt_passstr, sipdevice_ipc_pw) are printed in the terminal
# with their real values, but replaced with {{PASSWORD}} in the saved file. The login password is asked
# for and never saved.
#
# Sections are added to the end of the file, so reading the same camera again adds a second copy with the
# new read time. Use a different -OutFile for each camera.
#
# Example (Alkire):
#   powershell -ExecutionPolicy Bypass -File .\Read-CameraConfig.ps1 -OutFile "alkire read output.md"
param(
    [Parameter(Mandatory)][string]$OutFile,
    [string]$CameraHost = '192.168.111.245',
    [string]$User = 'admin'
)
$ErrorActionPreference = 'Stop'

$sections = @(
    'get_device_conf', 'get_system_conf', 'get_network_conf', 'get_ipcfg_conf',
    'get_image_conf', 'get_advance_image_conf', 'get_media_video', 'get_media_audio',
    'get_overlay_conf', 'get_ndi_info', 'get_language_conf'
)
$passwordKeys = 'userpasswd|guestpasswd|srt_passstr|sipdevice_ipc_pw'

# A relative -OutFile is saved next to this script (the repo folder), wherever it is run from
if (-not [IO.Path]::IsPathRooted($OutFile)) { $OutFile = Join-Path $PSScriptRoot $OutFile }

$p = Read-Host "Camera password for $User" -AsSecureString
$cred = "${User}:" + [Net.NetworkCredential]::new('', $p).Password
Remove-Variable p

try {
    # Check the login first (200 = good)
    $status = curl.exe -s --max-time 10 -o NUL -w '%{http_code}' --digest -u $cred "http://$CameraHost/"
    if ($status -ne '200') { throw "Login to $CameraHost as $User failed (HTTP $status)" }

    foreach ($s in $sections) {
        $out = (curl.exe -s --max-time 15 --digest -u $cred "http://$CameraHost/cgi-bin/param.cgi?$s") -join "`n"
        if ($LASTEXITCODE -ne 0) { Write-Warning "$s failed (curl exit $LASTEXITCODE)"; continue }
        Write-Host "## $s"
        Write-Host $out
        Write-Host ''
        $saved = $out -replace "(?m)^($passwordKeys)=`"[^`"]*`"", '$1="{{PASSWORD}}"'
        "## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $saved, '```', "" |
            Add-Content $OutFile -Encoding UTF8
    }
    Write-Host "Config from $CameraHost added to $OutFile"
} finally {
    Remove-Variable cred
}
