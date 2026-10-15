# civgg-linux

Run **CivReplay**, the uploader for the [civgg](https://civgg-five.vercel.app/) Civilization VI stats site, on Linux.

CivReplay is only released for Windows. It works under Proton when it's installed inside Civ VI's own Proton prefix, because that's where it finds your saves, game logs and game database. This script handles that for you.

> This is an unofficial helper. It isn't affiliated with civgg or CivReplay. It downloads the official installer from [bartsake/civreplay-releases](https://github.com/bartsake/civreplay-releases) and doesn't change it.

## Requirements

- Civilization VI on Steam, already played at least once through Proton
- `curl`

## Install

Close Civ VI, then:

```sh
curl -fsSLO https://raw.githubusercontent.com/Vonteegoway/civgg-linux/main/civreplay-proton.sh
bash civreplay-proton.sh install
```

This will:

1. Find Civ VI's Proton prefix in your Steam libraries (normal or Flatpak Steam).
2. Use the same Proton version Civ VI was set up with.
3. Download the latest CivReplay installer and install it silently into that prefix.
4. Install the command `~/.local/bin/civreplay-proton` and add **CivReplay (civgg)** to your app menu.

If you already downloaded the installer, pass it instead: `bash civreplay-proton.sh install ~/Downloads/CivReplay_0.1.15_x64-setup.exe`.

## Use

Start **CivReplay (civgg)** from your app menu, or run `civreplay-proton run`.

As on Windows, upload a game right after it ends, before you start another one. Civ overwrites its logs with each new game.

## Gotchas

- **Opening a folder of saves:** clicking a folder in the "Select Folder" tree does nothing. Type the folder's full path into **File name**, press **Enter**, then click **Open** with File name empty. The list looks empty because the dialog shows folders, not files. That's expected.
- **Your Linux files are on the `Z:` drive**, for example `Z:\home\<you>\...`. Civ's own saves are under `C:\users\steamuser\Documents\My Games\Sid Meier's Civilization VI\Saves`.
- **Paste doesn't work** in CivReplay's file dialogs, so type paths.
- **It sometimes closes a few seconds after starting.** This is a Wine crash. `civreplay-proton run` relaunches it automatically.
- **"Game database not found"** means CivReplay isn't installed in Civ's prefix. Run `bash civreplay-proton.sh install` again.

## Update and uninstall

- CivReplay updates itself. To reinstall the latest version anyway, run `civreplay-proton install`.
- `civreplay-proton uninstall` removes CivReplay and the menu entry.

## Tested on

Pop!_OS with the COSMIC desktop, Steam (deb), Proton 10.0, CivReplay 0.1.15. Reports from other setups are welcome. Open an issue.

## Credits

All the real work here is theirs:

- [civgg](https://civgg-five.vercel.app/), the Civ VI stats site, by its creators.
- [CivReplay](https://github.com/bartsake/civreplay-releases), the uploader app, by **bartsake**.

This repo only adds a script to run CivReplay on Linux. Please report problems with the Linux setup here, not to them.

## License

MIT for this script. CivReplay itself is a separate program with its own terms.
