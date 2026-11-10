# NDI Indicators in the Camera Config

Which settings in the RL500 camera reads point to NDI being **available** on the camera (licensed and
shown in the web page) and NDI being **turned on** (actually sending video). Use it to troubleshoot a
camera whose NDI stream isn't showing up.

None of these settings are documented by the camera maker. What each one means is worked out from its name
and from the Quail camera, whose NDI stream works. The **How sure** column says how solid that is.

## Check a camera now

This reads the five sections that hold NDI-related settings from the camera at `192.168.111.245` and
prints only those settings in the terminal. It only reads, and saves nothing. No passwords are printed.

```powershell
$p = Read-Host "Camera password for guest" -AsSecureString
$u = "guest:" + [Net.NetworkCredential]::new('', $p).Password
$pattern = '^\s*\{?(isndi|isdante|streaming|workmode|ndi\w*|channelName|group|discovery_\w+|transmit_protocol|multicast_\w+|fullndi_en|versioninfo|devname)\s*[=:]'
foreach ($s in 'get_device_conf', 'get_system_conf', 'get_media_video', 'get_ndi_info', 'get_language_conf') {
    curl.exe -s --max-time 10 --digest -u $u "http://192.168.111.245/cgi-bin/param.cgi?$s" |
        Select-String -Pattern $pattern | ForEach-Object { "{0,-18} {1}" -f $s, $_.Line.Trim() }
}
Remove-Variable p, u
```

For the right camera of a two-camera building, change `192.168.111.245` to `192.168.111.246`.

To pull the same settings out of a saved read file instead (no camera needed):

```powershell
$pattern = '^\s*\{?(isndi|isdante|streaming|workmode|ndi\w*|channelName|group|discovery_\w+|transmit_protocol|multicast_\w+|fullndi_en|versioninfo|devname)\s*[=:]'
Select-String -Path "C:\dev\alkire-camera-config-rebuild\quail read output.md" -Pattern $pattern | ForEach-Object { $_.Line.Trim() }
```

## Is NDI available on the camera?

These describe the camera itself: whether it has NDI at all. They can't be fixed by copying Quail's values.

| Setting | Section | Quail (working) | What it likely means | How sure |
|---|---|---|---|---|
| `isndi` | `get_language_conf` | `1` | The camera has NDI, and the web page shows the NDI menu. This section looks like the list of flags the web page uses to decide which menus to show (next to `isdante`, `streaming`, `is_root_user`). | Likely. Not confirmed whether `0` only hides the menu or means NDI is unavailable. |
| `ndi_license` | `get_ndi_info` | `1` | The camera has an NDI license. Without one, NDI would probably not run. | Likely |
| `ndimacid` | `get_ndi_info` | `1501…5c00` | The camera's NDI identity, tied to its license. Unique to each camera; never copy it. | Likely |
| `ndi` | `get_ndi_info` | `CL6.1.1` | The NDI software version built into the camera. Missing or blank would suggest no NDI. | Likely |
| `ndiserialnum` | `get_device_conf` | `SOC 2.0.05` | Despite the name, this matches the firmware version. Present on Quail. | Unclear |
| `versioninfo` | `get_device_conf` | `SOC v2.0.05 - ARM 6.1.69S` | Firmware version. Different firmware may have NDI behave differently, or not have it. | Certain this is the firmware |
| `isdante` | `get_language_conf` | `0` | Dante (audio-over-network) is not on this camera. Not NDI, but a useful comparison for how these flags work. | Likely |

**If `isndi`, `ndi_license` and `ndi` all point to no NDI** (`0`, `0`, blank) on a camera, the cause is
most likely the camera's license or firmware, not a setting. Writing `isndi=1` almost certainly won't
fix it.

## Is NDI turned on, and how is it set up?

These are settings someone chose. They can differ between cameras and can be copied.

| Setting | Section | Quail (working) | What it likely means | How sure |
|---|---|---|---|---|
| `ndi_mode` | `get_media_video` | `off` | **Unclear.** Its name suggests NDI on/off, but Quail's NDI works with it `off`. It probably controls a narrower NDI option (a special mode or variant), not whether NDI runs at all. Leave it out of any copy until confirmed. | Unknown |
| `fullndi_en` | `get_ndi_info` | `0` | Full-bandwidth NDI is off, so the camera sends NDI HX (compressed). | Likely |
| `channelName` | `get_ndi_info` | `NDI HX3` | The NDI source name receivers (OBS, NDI Studio Monitor) list for this camera, usually after the camera's name. If two cameras on one network share a name, they can be hard to tell apart. | Likely |
| `devname` | `get_device_conf` | `UHD Camera` | The camera's name. NDI receivers usually show sources as `DEVICE (CHANNEL)`, so likely `UHD Camera (NDI HX3)`. | Likely |
| `group` | `get_ndi_info` | `public` | NDI group. Receivers only see sources in the groups they look in; `public` is the default every receiver sees. Any other value can hide the camera. | Likely |
| `discovery_en` | `get_ndi_info` | `0` | NDI discovery server is not used; receivers find the camera on the local network on their own (mDNS). | Likely |
| `discovery_server` | `get_ndi_info` | `192.168.1.2` | Only used when `discovery_en` is `1`. If it is `1` and this address is wrong, receivers won't find the camera. | Likely |
| `transmit_protocol` | `get_ndi_info` | `RUDP` | How the video is sent (reliable UDP). Other choices (TCP, multicast) can fail on some networks. | Likely |
| `multicast_ip`, `multicast_mask`, `multicast_ttl` | `get_ndi_info` | `239.255.0.10`, `255.255.0.0`, `1` | Only used when `transmit_protocol` is multicast. | Likely |
| `workmode` | `get_system_conf` | `rtspserver` | How the camera streams. Quail's NDI works in `rtspserver`, so this mode doesn't block NDI. | Likely |
| `streaming` | `get_language_conf` | `1` | The camera has streaming features (shows the streaming menu). | Likely |

## If a camera's NDI isn't showing up

Check in this order:

1. **Available?** `isndi`, `ndi_license` and `ndi` should match Quail (`1`, `1`, a version). If not, it is
   a license or firmware issue: contact the camera maker. Copying settings won't fix it.
2. **Same firmware?** Compare `versioninfo` with Quail's `SOC v2.0.05 - ARM 6.1.69S`.
3. **Findable?** `group` should be `public` and `discovery_en` `0` (as on Quail), unless the building
   uses an NDI discovery server.
4. **Sending?** Compare `fullndi_en`, `transmit_protocol` and `ndi_mode` with Quail.
5. **Receiver side.** The computer receiving NDI must be on the same network (subnet) as the camera, and
   its firewall must allow NDI. Look for a source named like `UHD Camera (NDI HX3)`.

## How to confirm what a setting does

- **Change it in the web page and compare.** Read the camera, change the one NDI option in the web page,
  read it again, and compare the two reads with
  [Compare-CameraConfig.ps1](Compare-CameraConfig.ps1). The setting that changed is the one the option
  controls. This is the quickest way to settle what `ndi_mode` does. Change it back afterwards.
- **Search the web page code.** After step 2 of [write commands.md](write%20commands.md) downloads it,
  search for the setting:

  ```powershell
  Get-ChildItem "C:\dev\alkire-camera-config-rebuild\camera-web" -Recurse -File | Select-String -Pattern 'isndi|ndi_mode'
  ```

- **Look inside a backup.** The camera maker's `upgrade.exe` tool can back up a camera's configuration as a
  `.tar.gz` file. That file holds the camera's own config files, which may show where `isndi` and the NDI
  license are stored. Use only **Backup**: **Upgrade** and **Restore** change the camera and reboot it.
