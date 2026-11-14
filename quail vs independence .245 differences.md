# quail vs independence .245 camera config differences

Compared 2026-11-14 09:07: `quail read output.md` (copy from) and `independence .245.md` (copy to).
Only settings that differ are listed. Camera-specific values (MAC, serial, license, firmware) are left out.

**12 settings differ in total.**

| Section | Settings that differ | Copy? (write commands step 4) |
|---|---|---|
| `get_device_conf` | 1 | Only `devname`, if wanted. |
| `get_system_conf` | 0 | Copy after the other sections (changes the camera's logins). |
| `get_network_conf` | 0 | Not copied: set network settings by hand. |
| `get_ipcfg_conf` | 0 | Not copied: set network settings by hand. |
| `get_image_conf` | 1 | Copy. |
| `get_advance_image_conf` | 0 | Copy. |
| `get_media_video` | 3 | Copy (may briefly interrupt video). |
| `get_media_audio` | 0 | Copy. |
| `get_overlay_conf` | 0 | Copy. |
| `get_ndi_info` | 2 | Copy, but keep `channelName` unique on the network. |
| `get_language_conf` | 5 | Not copied. |

## get_device_conf (1 different)

Step 4: Only `devname`, if wanted.

| Setting | quail | independence .245 |
|---|---|---|
| `device_model` | G50.CT | G50.V |

## get_image_conf (1 different)

Step 4: Copy.

| Setting | quail | independence .245 |
|---|---|---|
| `hlg_enable` | 0 | (missing) |

## get_media_video (3 different)

Step 4: Copy (may briefly interrupt video).

| Setting | quail | independence .245 |
|---|---|---|
| `advanced` | off | (missing) |
| `vi_framerate` | 30 | 60 |
| `dial_format` | 6 | 0 |

## get_ndi_info (2 different)

Step 4: Copy, but keep `channelName` unique on the network.

| Setting | quail | independence .245 |
|---|---|---|
| `transmit_protocol` | RUDP | (missing) |
| `multicast_en` | (missing) | 0 |

## get_language_conf (5 different)

Step 4: Not copied.

| Setting | quail | independence .245 |
|---|---|---|
| `isndi` | 1 | 0 |
| `isdante` | 0 | (missing) |
| `standby` | 0 | 1 |
| `is_root_user` | 0 | 1 |
| `focusmode` | mfocus | afocus |

## Write commands

Run one block at a time, in this order, and check each section (read it again) before the next.
Each block asks for the camera's current `admin` password; nothing is saved. `status=200` means
the camera accepted it. The values are the ones from the "copy from" file.

### post_image_conf (1 different in `get_image_conf`)

```powershell
$p = Read-Host "Current camera password for admin" -AsSecureString
curl.exe -s -w "`nstatus=%{http_code}`n" --digest -u ("admin:" + [Net.NetworkCredential]::new('', $p).Password) -X POST "http://192.168.111.245/cgi-bin/param.cgi?post_image_conf" --data "cururl=http://&style=0&luminance=7&blackwhite_mode=0&presetautoscan=0&presetfreeze=0&tallymode=0&presetinspection=0&bright=7&saturation=4&contrast=7&sharpness=6&hue=7&ldc=0&flip=0&mirror=0&gamma=0&hlg_enable=0&autotrack=3"
Remove-Variable p
```

### post_media_video (3 different in `get_media_video`)

```powershell
$p = Read-Host "Current camera password for admin" -AsSecureString
curl.exe -s -w "`nstatus=%{http_code}`n" --digest -u ("admin:" + [Net.NetworkCredential]::new('', $p).Password) -X POST "http://192.168.111.245/cgi-bin/param.cgi?post_media_video" --data "cururl=http://&hdmi_sdi=1&vinorm=IMG_1080P30&ndi_mode=off&protocol_1=H264&profile=mainprofile&size_1=PIC_HD1080&bps_1=4096&qfactor_1=80&fps_1=30&gop_1=30&rcmode_1=CBR&imagegrade_1=1&slice_en_1=0&slice_mode_1=1&slice_size1=68&protocol_2=H264&size_2=PIC_640_360&bps_2=2048&qfactor_2=80&fps_2=30&gop_2=30&rcmode_2=CBR&imagegrade_2=1&slice_en_2=0&slice_mode_2=1&slice_size2=23&advanced=off&vi_framerate=30&dial_support_4K_en=1&dial_support_framerate=60&dial_format=6&uhd4k=1"
Remove-Variable p
```

### post_media_audio

Nothing to write: `get_media_audio` already matches.

### post_overlay_conf

Nothing to write: `get_overlay_conf` already matches.

### post_ndi_info (2 different in `get_ndi_info`)

```powershell
$p = Read-Host "Current camera password for admin" -AsSecureString
curl.exe -s -w "`nstatus=%{http_code}`n" --digest -u ("admin:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?post_ndi_info&channelName=NDI%20HX3&group=public&discovery_en=0&discovery_server=192.168.1.2&transmit_protocol=RUDP&multicast_ip=239.255.0.10&multicast_mask=255.255.0.0&multicast_ttl=1&fullndi_en=0"
Remove-Variable p
```

### post_system_conf

Nothing to write: `get_system_conf` already matches.

