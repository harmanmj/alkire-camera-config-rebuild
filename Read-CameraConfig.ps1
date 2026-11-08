# Read every config section from an RL500 PTZ camera and save each one to its own file.
#
# The camera has no "whole config" endpoint, so each settings group is read separately with a
# get_* command on /cgi-bin/param.cgi (HTTP digest auth). These commands only read: nothing is
# written to the camera and it is not restarted.
#
# Example (Quail):
#   powershell -ExecutionPolicy Bypass -File .\Read-CameraConfig.ps1 -CameraHost 192.168.111.245 -OutDir .\configs\quail
#
# The password is asked for when -Password is not given, and is never saved.
param(
    [Parameter(Mandatory)][string]$CameraHost,
    [Parameter(Mandatory)][string]$OutDir,
    [string]$User = 'guest',
    [string]$Password
)
$ErrorActionPreference = 'Stop'

if (-not $Password) {
    $secure = Read-Host "Password for $User@$CameraHost" -AsSecureString
    $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
}
$cred = "${User}:$Password"
$base = "http://$CameraHost/cgi-bin/param.cgi"

$sections = @(
    'get_device_conf', 'get_system_conf', 'get_network_conf', 'get_ipcfg_conf',
    'get_image_conf', 'get_advance_image_conf', 'get_media_video', 'get_media_audio',
    'get_overlay_conf', 'get_ndi_info', 'get_language_conf'
)

# Check the login first (200 = good)
$status = curl.exe -s -o NUL -w '%{http_code}' --digest -u $cred "http://$CameraHost/"
if ($status -ne '200') { throw "Login to $CameraHost failed (HTTP $status)" }

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$combined = New-Object Collections.Generic.List[string]
foreach ($s in $sections) {
    $text = (curl.exe -s --digest -u $cred "$base`?$s") -join "`n"
    if ($LASTEXITCODE -ne 0) { Write-Warning "$s failed (curl exit $LASTEXITCODE)"; continue }
    Set-Content -Path (Join-Path $OutDir "$s.txt") -Value $text -Encoding UTF8
    $combined.Add("[$s]")
    $combined.Add($text)
    $combined.Add('')
    Write-Host "  $s saved"
}
Set-Content -Path (Join-Path $OutDir 'combined.txt') -Value $combined -Encoding UTF8
Write-Host "Config from $CameraHost saved to $OutDir"
