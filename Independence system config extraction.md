# Independence System Config Extraction

These steps show one PTZ camera's **system settings** in a PowerShell window. Nothing is changed on the
camera and nothing is saved to the computer: the settings are only printed on screen.

## Before you start

- Use a Windows computer connected to the building's church network (the same network as the cameras).
- Have the camera's `guest` login password ready.
- The camera can be in use. Reading its settings does not interrupt video or restart it.

## Which camera

| Camera | Address | Where it is |
|---|---|---|
| Left camera | 192.168.111.245 | Every building. In a one-camera building, this is the only camera. |
| Right camera | 192.168.111.246 | Two-camera buildings only. |

## Step 1: Open PowerShell

Click **Start**, type **PowerShell**, and click **Windows PowerShell**.

## Step 2: Copy and paste the command for the camera

Copy the whole block for the camera you want, paste it into PowerShell (right-click pastes), and press
**Enter**. It asks for the `guest` password. The password does not show while you type it, which is
normal. Press **Enter** after typing it.

### Left camera (192.168.111.245)

```powershell
$p = Read-Host "Camera password for guest" -AsSecureString
curl.exe -s --connect-timeout 5 -w "`nstatus=%{http_code}`n" --digest -u ("guest:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.245/cgi-bin/param.cgi?get_system_conf"
Remove-Variable p
```

### Right camera (192.168.111.246)

```powershell
$p = Read-Host "Camera password for guest" -AsSecureString
curl.exe -s --connect-timeout 5 -w "`nstatus=%{http_code}`n" --digest -u ("guest:" + [Net.NetworkCredential]::new('', $p).Password) "http://192.168.111.246/cgi-bin/param.cgi?get_system_conf"
Remove-Variable p
```

## Step 3: Read the result

The last line says whether it worked:

| Last line | Meaning | What to do |
|---|---|---|
| `status=200` | It worked. The settings are shown above it. | Nothing. |
| `status=401` | The `guest` password is wrong. | Paste the block again and re-enter the password. |
| `status=000` | The camera was not reached. | Check that this computer is on the church network and the camera is plugged in and powered. In a one-camera building there is no right camera, so this is expected for it. |

A successful read looks like this (values differ between cameras):

```text
username="admin"
userpasswd="..."
guestname="guest"
guestpasswd="..."
workmode="rtspserver"
tallymode="redclosegreenclose"
status=200
```

What each line is:

| Setting | Meaning |
|---|---|
| `username` / `userpasswd` | The camera's admin login name and password |
| `guestname` / `guestpasswd` | The camera's guest login name and password |
| `workmode` | How the camera streams video |
| `tallymode` | How the camera's tally light behaves |

> **The output includes the camera's passwords.** Treat it like any other password: don't post it in a
> group chat, a shared document or an email thread. Close the PowerShell window when you are done.

## Notes

- Type `curl.exe` exactly as shown, not `curl`. In Windows PowerShell, plain `curl` is a different
  command and the command fails.
- The command only reads (`get_system_conf`). It does not change any camera setting.
