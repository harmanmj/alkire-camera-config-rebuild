# RL500 Camera Config Read Commands

Read each config section from the RL500 PTZ camera at Quail. Each command block below works on its own:

1. It asks for the camera password (it is never typed into a command or saved).
2. It reads one section from the camera.
3. It prints the section to the terminal.
4. It adds the section to `quail read output.md` in this repo (`C:\dev\alkire-camera-config-rebuild`),
   under its own heading. The file is created the first time a block runs.

These are read-only (`get_*` commands): nothing is written to the camera and it is not restarted.

Paste a whole block into PowerShell at once. Running a block again adds the section to the file a second
time, with the new read time.

## Check the login

This should print `login_status=200`. Any other number means the login failed or the camera was not reached.
This one only prints, it does not save anything.

```powershell
$p = Read-Host "Camera password for guest" -AsSecureString
curl.exe -s -o NUL -w "login_status=%{http_code}`n" --digest -u ("guest:" + [Net.NetworkCredential]::new('', $p).Password) http://192.168.111.245/
Remove-Variable p
```

## Device

```powershell
$s = "get_device_conf"
$p = Read-Host "Camera password for guest" -AsSecureString
$out = (curl.exe -s --digest -u ("guest:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $out, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## System

```powershell
$s = "get_system_conf"
$p = Read-Host "Camera password for guest" -AsSecureString
$out = (curl.exe -s --digest -u ("guest:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $out, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## Network

```powershell
$s = "get_network_conf"
$p = Read-Host "Camera password for guest" -AsSecureString
$out = (curl.exe -s --digest -u ("guest:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $out, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## IP config

```powershell
$s = "get_ipcfg_conf"
$p = Read-Host "Camera password for guest" -AsSecureString
$out = (curl.exe -s --digest -u ("guest:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $out, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## Image

```powershell
$s = "get_image_conf"
$p = Read-Host "Camera password for guest" -AsSecureString
$out = (curl.exe -s --digest -u ("guest:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $out, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## Advanced image

```powershell
$s = "get_advance_image_conf"
$p = Read-Host "Camera password for guest" -AsSecureString
$out = (curl.exe -s --digest -u ("guest:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $out, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## Video

```powershell
$s = "get_media_video"
$p = Read-Host "Camera password for guest" -AsSecureString
$out = (curl.exe -s --digest -u ("guest:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $out, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## Audio

```powershell
$s = "get_media_audio"
$p = Read-Host "Camera password for guest" -AsSecureString
$out = (curl.exe -s --digest -u ("guest:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $out, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## Overlay

```powershell
$s = "get_overlay_conf"
$p = Read-Host "Camera password for guest" -AsSecureString
$out = (curl.exe -s --digest -u ("guest:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $out, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## NDI

```powershell
$s = "get_ndi_info"
$p = Read-Host "Camera password for guest" -AsSecureString
$out = (curl.exe -s --digest -u ("guest:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $out, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## Language

```powershell
$s = "get_language_conf"
$p = Read-Host "Camera password for guest" -AsSecureString
$out = (curl.exe -s --digest -u ("guest:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $out, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## Notes

- Use `curl.exe`, not `curl`. In Windows PowerShell, plain `curl` is a different command and these
  options fail.
- If a section comes back empty or as an error page, that section is probably not supported on this
  camera's firmware. The other sections are not affected.
- To read the Alkire camera later, change `quail read output.md` to `alkire read output.md` in each
  block, so the two cameras' results stay in separate files.
