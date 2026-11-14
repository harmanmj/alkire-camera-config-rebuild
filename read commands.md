# RL500 Camera Config Read Commands

Read each config section from the RL500 PTZ camera at Quail. Each command block below works on its own:

1. It asks for the camera password (it is never typed into a command or saved).
2. It reads one section from the camera.
3. It prints the section to the terminal.
4. It adds the section to `quail read output.md` in this repo (`C:\dev\alkire-camera-config-rebuild`),
   under its own heading. The file is created the first time a block runs.

These are read-only (`get_*` commands): nothing is written to the camera and it is not restarted.

## Read all sections at once

[Read-CameraConfig.ps1](Read-CameraConfig.ps1) runs every block below in one go. It asks for the `admin`
password once, prints each section (passwords included), and saves each one to the output file in the
same layout, with passwords replaced by `{{PASSWORD}}`:

```powershell
cd C:\dev\alkire-camera-config-rebuild
powershell -ExecutionPolicy Bypass -File .\Read-CameraConfig.ps1 -OutFile "alkire read output.md"
```

About the output file:

- **Name it after the camera.** `-OutFile` sets the file name. Use a different name for each camera
  (for example `quail read output.md`, `alkire read output.md`) so the cameras' results stay separate.
- **It is saved in this repo folder**, `C:\dev\alkire-camera-config-rebuild`, wherever the script is run
  from. A full path can be given instead.
- **Sections are added to the end of the file; nothing in it is replaced.** If the file already exists,
  reading the same camera again adds a second copy of every section, with the new read time. To start
  fresh, delete the file first, or use a new name.
- **To read the right camera**, add `-CameraHost 192.168.111.246`.

Paste a whole block into PowerShell at once. Running a block again adds the section to the file a second
time, with the new read time.

## Check the login

This should print `login_status=200`. Any other number means the login failed or the camera was not reached.
This one only prints, it does not save anything.

```powershell
$p = Read-Host "Camera password for admin" -AsSecureString
curl.exe -s -o NUL -w "login_status=%{http_code}`n" --digest -u ("admin:" + [Net.NetworkCredential]::new('', $p).Password) http://192.168.111.245/
Remove-Variable p
```

## Device

```powershell
$s = "get_device_conf"
$p = Read-Host "Camera password for admin" -AsSecureString
$out = (curl.exe -s --digest -u ("admin:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
$saved = $out -replace '(?m)^(userpasswd|guestpasswd|srt_passstr|sipdevice_ipc_pw)="[^"]*"', '$1="{{PASSWORD}}"'
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $saved, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## System

```powershell
$s = "get_system_conf"
$p = Read-Host "Camera password for admin" -AsSecureString
$out = (curl.exe -s --digest -u ("admin:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
$saved = $out -replace '(?m)^(userpasswd|guestpasswd|srt_passstr|sipdevice_ipc_pw)="[^"]*"', '$1="{{PASSWORD}}"'
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $saved, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## Network

```powershell
$s = "get_network_conf"
$p = Read-Host "Camera password for admin" -AsSecureString
$out = (curl.exe -s --digest -u ("admin:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
$saved = $out -replace '(?m)^(userpasswd|guestpasswd|srt_passstr|sipdevice_ipc_pw)="[^"]*"', '$1="{{PASSWORD}}"'
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $saved, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## IP config

```powershell
$s = "get_ipcfg_conf"
$p = Read-Host "Camera password for admin" -AsSecureString
$out = (curl.exe -s --digest -u ("admin:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
$saved = $out -replace '(?m)^(userpasswd|guestpasswd|srt_passstr|sipdevice_ipc_pw)="[^"]*"', '$1="{{PASSWORD}}"'
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $saved, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## Image

```powershell
$s = "get_image_conf"
$p = Read-Host "Camera password for admin" -AsSecureString
$out = (curl.exe -s --digest -u ("admin:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
$saved = $out -replace '(?m)^(userpasswd|guestpasswd|srt_passstr|sipdevice_ipc_pw)="[^"]*"', '$1="{{PASSWORD}}"'
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $saved, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## Advanced image

```powershell
$s = "get_advance_image_conf"
$p = Read-Host "Camera password for admin" -AsSecureString
$out = (curl.exe -s --digest -u ("admin:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
$saved = $out -replace '(?m)^(userpasswd|guestpasswd|srt_passstr|sipdevice_ipc_pw)="[^"]*"', '$1="{{PASSWORD}}"'
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $saved, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## Video

```powershell
$s = "get_media_video"
$p = Read-Host "Camera password for admin" -AsSecureString
$out = (curl.exe -s --digest -u ("admin:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
$saved = $out -replace '(?m)^(userpasswd|guestpasswd|srt_passstr|sipdevice_ipc_pw)="[^"]*"', '$1="{{PASSWORD}}"'
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $saved, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## Audio

```powershell
$s = "get_media_audio"
$p = Read-Host "Camera password for admin" -AsSecureString
$out = (curl.exe -s --digest -u ("admin:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
$saved = $out -replace '(?m)^(userpasswd|guestpasswd|srt_passstr|sipdevice_ipc_pw)="[^"]*"', '$1="{{PASSWORD}}"'
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $saved, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## Overlay

```powershell
$s = "get_overlay_conf"
$p = Read-Host "Camera password for admin" -AsSecureString
$out = (curl.exe -s --digest -u ("admin:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
$saved = $out -replace '(?m)^(userpasswd|guestpasswd|srt_passstr|sipdevice_ipc_pw)="[^"]*"', '$1="{{PASSWORD}}"'
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $saved, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## NDI

```powershell
$s = "get_ndi_info"
$p = Read-Host "Camera password for admin" -AsSecureString
$out = (curl.exe -s --digest -u ("admin:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
$saved = $out -replace '(?m)^(userpasswd|guestpasswd|srt_passstr|sipdevice_ipc_pw)="[^"]*"', '$1="{{PASSWORD}}"'
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $saved, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## Language

```powershell
$s = "get_language_conf"
$p = Read-Host "Camera password for admin" -AsSecureString
$out = (curl.exe -s --digest -u ("admin:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?$s") -join "`n"
Remove-Variable p
$out
$saved = $out -replace '(?m)^(userpasswd|guestpasswd|srt_passstr|sipdevice_ipc_pw)="[^"]*"', '$1="{{PASSWORD}}"'
"## $s", "", "Read $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "", '```text', $saved, '```', "" | Add-Content "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Encoding UTF8
```

## Notes

- Passwords are shown in the terminal but never saved. The terminal shows the camera's real values, so
  close the window when you are done. In the saved file, the value of each password setting
  (`userpasswd`, `guestpasswd`, `srt_passstr`, `sipdevice_ipc_pw`) is replaced with `{{PASSWORD}}`.
  When a section is written back to a camera, each `{{PASSWORD}}` is asked for at that point instead
  of being read from the file.

- Use `curl.exe`, not `curl`. In Windows PowerShell, plain `curl` is a different command and these
  options fail.
- If a section comes back empty or as an error page, that section is probably not supported on this
  camera's firmware. The other sections are not affected.
- To read the Alkire camera later, change `quail read output.md` to `alkire read output.md` in each
  block, so the two cameras' results stay in separate files.
