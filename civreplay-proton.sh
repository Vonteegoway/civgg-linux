#!/usr/bin/env bash
# civreplay-proton: install and run CivReplay (the civgg uploader) on Linux,
# inside Civilization VI's own Proton prefix so it finds the saves, logs and
# game database.
#
#   civreplay-proton.sh install [setup.exe]   install (or update) + add a menu shortcut
#   civreplay-proton.sh run                   launch CivReplay
#   civreplay-proton.sh uninstall             remove CivReplay and the shortcut
#
# Without a setup.exe, install downloads the latest release from
# https://github.com/bartsake/civreplay-releases
set -euo pipefail

CIV_APPID=289070
RELEASES=https://github.com/bartsake/civreplay-releases/releases/latest/download
APP_EXE='C:\users\steamuser\AppData\Local\CivReplay\app.exe'
BIN_DIR="$HOME/.local/bin"
BIN="$BIN_DIR/civreplay-proton"
DESKTOP="$HOME/.local/share/applications/civreplay-proton.desktop"

die() { echo "civreplay-proton: $*" >&2; exit 1; }
info() { echo "civreplay-proton: $*"; }

# Find the Steam library holding Civ VI's Proton prefix (compatdata/289070).
find_prefix() {
    local root lib vdf
    for root in "$HOME/.steam/steam" "$HOME/.local/share/Steam" \
                "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"; do
        [ -d "$root/steamapps" ] || continue
        STEAM_ROOT=$(readlink -f "$root")
        vdf="$root/steamapps/libraryfolders.vdf"
        for lib in "$root" $( [ -f "$vdf" ] && grep -oP '"path"\s+"\K[^"]+' "$vdf" ); do
            if [ -d "$lib/steamapps/compatdata/$CIV_APPID/pfx" ]; then
                COMPAT="$lib/steamapps/compatdata/$CIV_APPID"
                return 0
            fi
        done
    done
    die "Civ VI's Proton prefix wasn't found. Run Civ VI once through Steam with Proton, then try again."
}

# Find the Proton build that created Civ's prefix (Steam records it in config_info).
find_proton() {
    local dir
    if [ -f "$COMPAT/config_info" ]; then
        dir=$(sed -n '2p' "$COMPAT/config_info")
        dir=${dir%/files/share/fonts/}
        [ -x "$dir/proton" ] && { PROTON="$dir/proton"; return 0; }
    fi
    # Fallback: the newest Proton next to Civ's library.
    dir=$(ls -d "$STEAM_ROOT"/steamapps/common/Proton* "${COMPAT%/compatdata/*}"/common/Proton* 2>/dev/null | sort -V | tail -1 || true)
    [ -n "$dir" ] && [ -x "$dir/proton" ] || die "no Proton install found."
    PROTON="$dir/proton"
}

proton_run() {
    STEAM_COMPAT_DATA_PATH="$COMPAT" \
    STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_ROOT" \
    WINEDLLOVERRIDES="winemenubuilder.exe=d" \
        "$PROTON" run "$@"
}

civ_running() { pgrep -f 'CivilizationVI(_DX12)?\.exe' >/dev/null; }

cmd_install() {
    local setup="${1:-}" tmp=""
    civ_running && die "close Civilization VI first."
    if [ -z "$setup" ]; then
        command -v curl >/dev/null || die "curl is needed to download the installer."
        tmp=$(mktemp -d)
        local url
        url=$(curl -fsSL "$RELEASES/latest.json" | grep -oP '"url":\s*"\K[^"]+\.exe') \
            || die "couldn't read the latest release."
        info "downloading ${url##*/}"
        curl -fL --progress-bar -o "$tmp/${url##*/}" "$url"
        setup="$tmp/${url##*/}"
    fi
    [ -f "$setup" ] || die "$setup not found."

    info "installing into $COMPAT (Proton: ${PROTON%/proton})"
    proton_run "$(readlink -f "$setup")" /S
    [ -n "$tmp" ] && rm -rf "$tmp"
    [ -f "$COMPAT/pfx/drive_c/users/steamuser/AppData/Local/CivReplay/app.exe" ] \
        || die "the installer finished but app.exe is missing."

    # Install this script and a menu shortcut that launches through it.
    mkdir -p "$BIN_DIR" "$(dirname "$DESKTOP")"
    [ "$(readlink -f "$0")" = "$BIN" ] || install -m 755 "$0" "$BIN"
    cat > "$DESKTOP" <<EOF
[Desktop Entry]
Type=Application
Name=CivReplay (civgg)
Comment=Civ VI replays and civgg uploads (via Proton)
Exec="$BIN" run
Icon=steam_icon_$CIV_APPID
Categories=Game;
Terminal=false
EOF
    info "done. Start CivReplay from your app menu, or run: $BIN run"
}

cmd_run() {
    [ -f "$COMPAT/pfx/drive_c/users/steamuser/AppData/Local/CivReplay/app.exe" ] \
        || die "CivReplay isn't installed. Run: $0 install"
    # CivReplay sometimes crashes a few seconds after starting under Wine;
    # a relaunch usually works, so retry quick crashes.
    local try start status
    for try in 1 2 3; do
        start=$SECONDS
        status=0
        proton_run "$APP_EXE" || status=$?
        [ "$status" -eq 0 ] && return 0
        [ $((SECONDS - start)) -ge 20 ] && return "$status"
        info "CivReplay exited early (code $status), relaunching ($try/3)"
    done
    die "CivReplay keeps crashing at startup."
}

cmd_uninstall() {
    local un="$COMPAT/pfx/drive_c/users/steamuser/AppData/Local/CivReplay/uninstall.exe"
    [ -f "$un" ] && proton_run 'C:\users\steamuser\AppData\Local\CivReplay\uninstall.exe' /S
    rm -f "$DESKTOP"
    info "CivReplay removed. Delete $BIN too if you no longer want this script."
}

find_prefix
find_proton
case "${1:-}" in
    install)   shift; cmd_install "$@" ;;
    run)       cmd_run ;;
    uninstall) cmd_uninstall ;;
    *) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
