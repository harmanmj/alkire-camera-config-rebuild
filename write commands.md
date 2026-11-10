# RL500 Camera Config Write Instructions

How to copy the Quail camera's settings, saved in [quail read output.md](quail%20read%20output.md), onto a
different RL500 camera (the **target camera**), one section at a time.

The camera has no "import whole config" command. Each settings section is written separately, the same
way the camera's own web page saves it when you click **Save** on that page. Because the exact write format
for this firmware is not published, step 2 finds it in the camera's web page code. Step 5 then compares the
two cameras and builds a ready-to-run write command for each section that differs. Every step is done in
PowerShell.

## 1. Before you start

- **Use a computer on the target building's network.** Every building's left or only camera is at
  `192.168.111.245`, so these commands reach whichever camera is on the network you are connected to.
- **Don't do this during a meeting.** Some settings (video format, output) can briefly drop or restart
  the video.
- **Check that it is the same camera model and firmware.** Run the **Device** read command from
  [read commands.md](read%20commands.md) against the target camera and compare with Quail:

  | Setting | Quail value |
  |---|---|
  | `devtype` | `VX752A` |
  | `device_model` | `G50.CT` |
  | `versioninfo` | `SOC v2.0.05 - ARM 6.1.69S` |

  If any of these differ, stop: settings and their value codes may not mean the same thing on a
  different model or firmware.

## 2. Find the write format (once)

The camera's web page is plain HTML and JavaScript, and that code is what builds each section's
`post_*` write request when you click **Save**. This command downloads the web page's files from the
target camera and lists every write command they use, and the file each one is in. It only downloads
(read-only): nothing is changed on the camera.

```powershell
$p = Read-Host "Camera password for guest" -AsSecureString
$u = "guest:" + [Net.NetworkCredential]::new('', $p).Password
$cam = "http://192.168.111.245"
$dir = "C:\dev\alkire-camera-config-rebuild\camera-web"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$seen = @{ '/' = $true }
$todo = New-Object Collections.Generic.Queue[string]
$todo.Enqueue('/')
while ($todo.Count -gt 0 -and $seen.Count -lt 300) {
    $path = $todo.Dequeue()
    $out = if ($path -eq '/') { "$dir\index.html" } else { Join-Path $dir ($path.TrimStart('/') -replace '/', '\') }
    New-Item -ItemType Directory -Force -Path (Split-Path $out) | Out-Null
    curl.exe -s --max-time 15 --digest -u $u "$cam$path" -o $out
    if (-not (Test-Path $out)) { continue }
    $base = if ($path -match '\.js$') { "$cam/" } else { "$cam$path" }
    foreach ($m in (Select-String -Path $out -Pattern '["''/=]([\w./-]+\.(?:js|html?))\b' -AllMatches).Matches) {
        $abs = ([Uri]::new([Uri]$base, $m.Groups[1].Value)).AbsolutePath
        if (-not $seen.ContainsKey($abs)) { $seen[$abs] = $true; $todo.Enqueue($abs) }
    }
}
Remove-Variable p, u
Write-Host "Downloaded $($seen.Count) files to $dir"
Get-ChildItem $dir -Recurse -File | Select-String -Pattern 'post_\w+' -AllMatches | ForEach-Object {
    foreach ($m in $_.Matches) { [pscustomobject]@{ Command = $m.Value; File = $_.Path.Substring($dir.Length + 1) } }
} | Sort-Object Command, File -Unique | Format-Table -AutoSize
```

What it does: it downloads the camera's start page, follows every page and script it links to (including
frames and pages named inside scripts), and stops after 300 files. Each download gives up after 15 seconds.

- **A table of `post_...` commands** means it worked. Each write command and the file that builds it are
  listed, for example `post_image_conf   js\image.js`.
- **"Downloaded 1 files" and no table** means the start page did not link to anything that was found.
  Open `camera-web\index.html` to see what it loads instead (for example a login page or a redirect).
- **No table, but several files** means the write commands are built in a way the search did not catch.
  Search the `camera-web` folder for `param.cgi` instead:

  ```powershell
  Get-ChildItem "C:\dev\alkire-camera-config-rebuild\camera-web" -Recurse -File | Select-String -Pattern 'param\.cgi' | Select-Object -First 40
  ```

### Record the format in write-format.json

[write-format.json](write-format.json) tells the compare script (step 5) how each section is written. Fill
in one entry per write command from the code in `camera-web` (Claude can do this from the folder):

```json
{
    "user": "admin",
    "commands": [
        { "command": "post_image_conf", "section": "get_image_conf", "method": "POST", "fields": ["bright", "contrast"] }
    ]
}
```

- `user`: the login used to write. The `guest` login may only be allowed to read.
- `command`: the `post_` command the web page sends.
- `section`: the read section its values come from.
- `method`: `POST` (settings sent as form data) or `GET` (settings in the URL).
- `fields` (optional): the setting names the web page sends. Without it, every setting in the section is
  sent except camera-specific ones.

List the entries in the order to write them (see **Suggested order** below). `get_system_conf` is always
put last automatically.

This only has to be done once: every RL500 on this firmware uses the same format.

The `camera-web` folder is the camera maker's code. Don't commit it to a public repository.

## 3. Back up the target camera

Read every section from the target camera before changing anything, so its current settings can be put
back:

```powershell
cd C:\dev\alkire-camera-config-rebuild
powershell -ExecutionPolicy Bypass -File .\Read-CameraConfig.ps1 -OutFile "alkire read output.md"
```

(Or use the one-at-a-time blocks in [read commands.md](read%20commands.md), with the file name changed
from `quail read output.md` to `alkire read output.md`.)

## 4. What to copy, and what not to

| Section (read command) | Copy to the target? | Why |
|---|---|---|
| `get_image_conf` | **Yes** | Brightness, saturation, contrast, sharpness, hue, flip, mirror |
| `get_advance_image_conf` | **Yes** | Exposure, white balance, gain, shutter, iris, noise reduction, focus, PTZ speeds, VISCA control |
| `get_media_video` | **Yes** | Video format (`vinorm`), output, stream encoding |
| `get_media_audio` | **Yes** | Audio input and levels |
| `get_overlay_conf` | **Yes** | Text and time overlays (all off at Quail) |
| `get_ndi_info` | **Yes**, but check the name | NDI settings. `channelName` is the name OBS sees; keep it unique if two cameras share a network. `ndimacid`, `ndi_license` and `ndi` belong to the camera and are never sent. |
| `get_device_conf` | Only `devname`, if wanted | The rest describes the camera itself |
| `get_system_conf` | **Yes, after the other sections** | Admin and guest logins, `workmode` and `tallymode`. The passwords are not in the file, so the write command asks for them. Writing it changes the camera's logins. |
| `get_network_conf`, `get_ipcfg_conf` | **No** | IP address, gateway, MAC. Copying them can knock the camera off the network. Set network settings by hand. |
| `get_language_conf` | **No** | Mostly reports what the camera supports |
| PTZ presets | Not in the reads | Presets are stored separately. Re-aim and re-save each preset on the target camera. |

Only sections listed in `write-format.json` get a write command, so leave the "No" sections out of it.

## 5. Compare the cameras and get the write commands

```powershell
cd C:\dev\alkire-camera-config-rebuild
powershell -ExecutionPolicy Bypass -File .\Compare-CameraConfig.ps1 -From "quail read output.md" -To "alkire read output.md"
```

[Compare-CameraConfig.ps1](Compare-CameraConfig.ps1) only reads files; it does not contact a camera. It
prints each section's differing settings in the terminal and saves `quail vs alkire differences.md` in
this folder (replaced each time it runs), which has:

1. **A summary table**: how many settings differ in each section, and whether step 4 says to copy it.
2. **The differences**: each differing setting, with the Quail and Alkire values side by side.
3. **Write commands**: a ready-to-run PowerShell block for each section in `write-format.json` that
   differs, filled in with the Quail values, in the order to run them. Sections that already match say
   "Nothing to write".

It uses the latest read when a file has the same section more than once, and leaves out values that
belong to the camera itself (MAC address, serial and license numbers, firmware version).

If `write-format.json` has not been filled in yet (step 2), the summary says so instead of giving write
commands.

## 6. Write each section

Open `quail vs alkire differences.md`, go to **Write commands**, and run the blocks **one at a time, in
the order shown**:

- Each block asks for the camera's current password. Nothing is saved.
- `status=200` means the camera accepted it.
- After each block, check it (step 7) before running the next.

**The system section (`post_system_conf`) is always last.** Quail's passwords are `{{PASSWORD}}` in the
file, so its block asks for the new admin and guest passwords to set on this camera, each twice, and
stops without sending anything if the two don't match, so a typo can't lock you out. After it, the camera's
logins are the new ones: use the new passwords for everything after it, including the check.

## 7. Check that it took

1. Read the target camera again (step 3). The new reads are added to the end of `alkire read output.md`.
2. Run the compare again (step 5). The compare uses the latest read of each section, so the sections you
   wrote should now show 0 differences, and their write commands say "Nothing to write".
3. Look at the camera's video in OBS to confirm the picture looks right.

If something went wrong, the original values are the first read in `alkire read output.md` (step 3).
Swap `-From` and `-To` in a compare against a copy of that first read to get write commands that put them
back.

## Suggested order

1. `get_image_conf`
2. `get_advance_image_conf`
3. `get_overlay_conf`
4. `get_media_audio`
5. `get_media_video` (most likely to briefly interrupt the video)
6. `get_ndi_info`
7. `get_system_conf` (after the other sections, because it changes the camera's logins)
8. PTZ presets, by hand (use the new login if the web page asks)
