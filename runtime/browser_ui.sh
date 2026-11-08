#!/bin/bash
# Browser UI: XFCE4 + dock en bas (docklike), connexion Xvfb + x11vnc

set -e

PORT="${NIHIL_BROWSER_UI_PORT:-6901}"
MARKER="/opt/nihil/.browser_ui_installed_v10"
NOVNC_DIR="/opt/nihil/novnc"
NOVNC_VERSION="v1.6.0"
XFCE_CONF="/root/.config/xfce4/xfconf/xfce-perchannel-xml"
XFCE_PANEL_CONF="/root/.config/xfce4/panel"

# Retry a check for up to 10s instead of sleeping a fixed time.
wait_for() {
    for _ in $(seq 100); do
        "$@" >/dev/null 2>&1 && return 0
        sleep 0.1
    done
    return 1
}

install_browser_ui_deps() {
    echo "[NIHIL] Ensuring browser UI dependencies (XFCE4 + Docklike)..."
    if command -v pacman >/dev/null 2>&1; then
        if [[ ! -f "$MARKER" ]]; then
            # xfce4-panel-compiz (chaotic-aur) peut avoir une signature inconnue et
            # conflicte avec xfce4-panel. On utilise une config sans chaotic-aur pour
            # forcer l'install du xfce4-panel standard.
            grep -v 'chaotic' /etc/pacman.conf > /tmp/pacman_no_chaotic.conf || cp /etc/pacman.conf /tmp/pacman_no_chaotic.conf
            # Pas de -Syu : sur l'image full, une mise à jour complète bute sur les fichiers
            # installés hors pacman (règles hashcat, paquets pip) et n'installe rien.
            pacman -Sy --config /tmp/pacman_no_chaotic.conf --noconfirm 2>/dev/null || true
            pacman -S --config /tmp/pacman_no_chaotic.conf --noconfirm --needed \
                xorg-server-xvfb \
                x11vnc \
                xfce4 \
                xfce4-docklike-plugin \
                xfce4-terminal \
                xfce4-appfinder \
                thunar \
                firefox \
                noto-fonts-cjk \
                dbus \
                python-pip || true
            fc-cache -f >/dev/null 2>&1 || true
            rm -f /tmp/pacman_no_chaotic.conf
        fi
    else
        echo "[NIHIL] browser-ui: unsupported base OS (expected Arch/pacman)."
        return 1
    fi

    if command -v dbus-uuidgen >/dev/null 2>&1; then
        if [[ ! -s /etc/machine-id ]]; then
            dbus-uuidgen > /etc/machine-id
        fi
        if [[ ! -e /var/lib/dbus/machine-id ]]; then
            mkdir -p /var/lib/dbus
            ln -sf /etc/machine-id /var/lib/dbus/machine-id
        fi
    fi

    # websockify et noVNC ne sont pas dans les dépôts officiels Arch.
    if ! command -v websockify >/dev/null 2>&1; then
        pip install --no-cache-dir --break-system-packages websockify >/tmp/nihil_websockify_pip.log 2>&1 || \
            echo "[NIHIL] browser-ui: websockify install failed"
    fi

    if [[ ! -d "$NOVNC_DIR" ]]; then
        echo "[NIHIL] Fetching noVNC..."
        git clone --depth=1 --branch "$NOVNC_VERSION" https://github.com/novnc/noVNC.git "$NOVNC_DIR" >/tmp/nihil_novnc.log 2>&1 || true
    fi

    # Panel XFCE: barre en haut (menu + horloge) + barre en bas (docklike uniquement)
    mkdir -p "$XFCE_CONF" "$XFCE_PANEL_CONF"
    cat > "$XFCE_CONF/xfce4-panel.xml" <<'PANELXML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <value type="int" value="2"/>
    <property name="dark-mode" type="bool" value="true"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="28"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
        <value type="int" value="13"/>
        <value type="int" value="12"/>
      </property>
      <property name="background-style" type="uint" value="1"/>
      <property name="background-rgba" type="array">
        <value type="double" value="0.043"/>
        <value type="double" value="0.090"/>
        <value type="double" value="0.188"/>
        <value type="double" value="0.92"/>
      </property>
    </property>
    <property name="panel-2" type="empty">
      <property name="position" type="string" value="p=10;x=640;y=672"/>
      <property name="size" type="uint" value="48"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="2"/>
      </property>
      <property name="length" type="uint" value="1"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="background-style" type="uint" value="1"/>
      <property name="background-rgba" type="array">
        <value type="double" value="0.043"/>
        <value type="double" value="0.090"/>
        <value type="double" value="0.188"/>
        <value type="double" value="0.85"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu">
      <property name="button-icon" type="string" value="/usr/share/pixmaps/nihil.png"/>
      <property name="button-title" type="string" value="Nihil"/>
      <property name="show-button-title" type="bool" value="true"/>
    </property>
    <property name="plugin-3" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
    </property>
    <property name="plugin-4" type="string" value="pager"/>
    <property name="plugin-12" type="string" value="clock"/>
    <property name="plugin-13" type="string" value="separator">
      <property name="expand" type="bool" value="false"/>
    </property>
    <property name="plugin-2" type="string" value="docklike"/>
  </property>
</channel>
PANELXML

    # Docklike: applis épinglées (menu, terminal, fichiers, navigateur)
    cat > "$XFCE_PANEL_CONF/docklike-2.rc" <<'DOCKRC'
[user]
indicatorStyle=0
indicatorColor=rgb(56,189,248)
pinned=/usr/share/applications/xfce4-appfinder.desktop;/usr/share/applications/xfce4-terminal.desktop;/usr/share/applications/thunar.desktop;/usr/share/applications/firefox.desktop;
indicatorOrientation=1
inactiveIndicatorStyle=0
inactiveColor=rgb(29,78,216)
indicatorColorFromTheme=false
forceIconSize=true
iconSize=32
DOCKRC

    # Wallpaper: xfdesktop ignore xfconf (Failed to get system bus) et charge le fallback
    # xfce-x.svg. On remplace ce fallback par notre image.
    WALLPAPER_SRC="/opt/nihil/runtime/wallpaper.png"
    WALLPAPER_DEST="/usr/share/backgrounds/nihil/default.png"
    XFCE_FALLBACK="/usr/share/backgrounds/xfce/xfce-x.svg"
    mkdir -p /usr/share/backgrounds/nihil
    if [[ -f "$WALLPAPER_SRC" ]]; then
        cp -f "$WALLPAPER_SRC" "$WALLPAPER_DEST"
        [[ -f "$XFCE_FALLBACK" ]] && cp -f "$WALLPAPER_SRC" "$XFCE_FALLBACK"
    else
        echo 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==' | base64 -d > "$WALLPAPER_DEST" 2>/dev/null || true
    fi

    # xfce4-desktop.xml: plusieurs moniteurs (Xvfb=Virtual-0, TigerVNC=monitorVNC-0, etc.)
    MONITOR_XML() {
        local m="$1"
        echo "      <property name=\"$m\" type=\"empty\">
        <property name=\"workspace0\" type=\"empty\">
          <property name=\"color-style\" type=\"int\" value=\"0\"/>
          <property name=\"image-style\" type=\"int\" value=\"5\"/>
          <property name=\"last-image\" type=\"string\" value=\"$WALLPAPER_DEST\"/>
          <property name=\"backdrop-cycle-enable\" type=\"bool\" value=\"false\"/>
        </property>
      </property>"
    }
    {
        echo '<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">'
        MONITOR_XML "monitorVNC-0"
        MONITOR_XML "Virtual-0"
        MONITOR_XML "default"
        MONITOR_XML "monitor0"
        echo '    </property>
    <property name="single-workspace-mode" type="bool" value="true"/>
    <property name="single-workspace-number" type="int" value="0"/>
  </property>
  <property name="last" type="empty">
    <property name="window-width" type="int" value="626"/>
    <property name="window-height" type="int" value="506"/>
  </property>
  <property name="desktop-icons" type="empty">
    <property name="file-icons" type="empty">
      <property name="show-trash" type="bool" value="false"/>
      <property name="show-filesystem" type="bool" value="false"/>
      <property name="show-home" type="bool" value="false"/>
      <property name="show-removable" type="bool" value="false"/>
    </property>
  </property>
</channel>'
    } > "$XFCE_CONF/xfce4-desktop.xml"

    cp -f /opt/nihil/runtime/logo.png /usr/share/pixmaps/nihil.png 2>/dev/null || true

    # Terminal aux couleurs de TheNullPigeons (fond slate-950, curseur cyan)
    cat > "$XFCE_CONF/xfce4-terminal.xml" <<'TERMXML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-terminal" version="1.0">
  <property name="color-use-theme" type="bool" value="false"/>
  <property name="color-background" type="string" value="#020617"/>
  <property name="color-foreground" type="string" value="#e2e8f0"/>
  <property name="color-cursor-use-default" type="bool" value="false"/>
  <property name="color-cursor" type="string" value="#38bdf8"/>
  <property name="color-selection-use-default" type="bool" value="false"/>
  <property name="color-selection-background" type="string" value="#1d4ed8"/>
  <property name="color-palette" type="string" value="#0f172a;#f87171;#4ade80;#facc15;#3b82f6;#c084fc;#22d3ee;#cbd5e1;#475569;#fca5a5;#86efac;#fde047;#60a5fa;#d8b4fe;#67e8f9;#f8fafc"/>
</channel>
TERMXML

    # Sélection et éléments actifs en bleu dans les applis GTK3
    mkdir -p /root/.config/gtk-3.0
    cat > /root/.config/gtk-3.0/gtk.css <<'GTKCSS'
@define-color theme_selected_bg_color #2563eb;
@define-color theme_selected_fg_color #ffffff;
GTKCSS

    # Thème GTK sombre (Adwaita-dark est fourni par gtk3, installé avec xfce4)
    cat > "$XFCE_CONF/xsettings.xml" <<'XSETTINGS'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Adwaita-dark"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="ApplicationPreferDarkTheme" type="bool" value="true"/>
  </property>
</channel>
XSETTINGS

    # Le marqueur n'est posé que si tout est en place, sinon on réessaie au prochain démarrage.
    local missing=()
    for cmd in Xvfb x11vnc startxfce4 websockify; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    [[ -f "$NOVNC_DIR/vnc.html" ]] || missing+=("noVNC")
    if (( ${#missing[@]} )); then
        echo "[NIHIL] browser-ui: missing ${missing[*]}, will retry on next start."
        return 1
    fi
    mkdir -p "$(dirname "$MARKER")"
    touch "$MARKER"
}

start_browser_ui() {
    export DISPLAY=:99
    export USER=root
    export HOME=/root
    export NO_AT_BRIDGE=1
    # Session D-Bus: évite "Unable to contact settings server"
    export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/nihil-runtime}"
    mkdir -p "$XDG_RUNTIME_DIR" /tmp/dbus-session
    chmod 700 "$XDG_RUNTIME_DIR" /tmp/dbus-session 2>/dev/null || true

    # Xvfb (stable)
    if ! pgrep -x Xvfb >/dev/null 2>&1; then
        Xvfb :99 -screen 0 1280x720x24 >/tmp/nihil_xvfb.log 2>&1 &
        wait_for test -S /tmp/.X11-unix/X99
    fi

    # Bus D-Bus session explicite pour que xfce4-settings-daemon puisse se connecter
    if [[ -z "${DBUS_SESSION_BUS_ADDRESS}" ]] || ! kill -0 "$(cat /tmp/dbus-session/pid 2>/dev/null)" 2>/dev/null; then
        rm -rf /tmp/dbus-session
        mkdir -p /tmp/dbus-session
        dbus-daemon --session --address=unix:path=/tmp/dbus-session/bus --nofork --print-pid >/tmp/dbus-session/pid 2>/dev/null &
        wait_for test -S /tmp/dbus-session/bus
        export DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/dbus-session/bus
    fi

    # Copier le wallpaper + remplacer le fallback xfce (xfdesktop charge xfce-x.svg)
    mkdir -p /usr/share/backgrounds/nihil
    if [[ -f /opt/nihil/runtime/wallpaper.png ]]; then
        cp -f /opt/nihil/runtime/wallpaper.png /usr/share/backgrounds/nihil/default.png
        [[ -f /usr/share/backgrounds/xfce/xfce-x.svg ]] && cp -f /opt/nihil/runtime/wallpaper.png /usr/share/backgrounds/xfce/xfce-x.svg
    fi

    # Mot de passe de session : affiché par le wrapper (nihil start / nihil info), jamais
    # sur la page web, qui est servie sans authentification.
    VNC_RFBAUTH_FILE="/tmp/nihil_x11vnc_rfbauth"
    if ! pgrep -x x11vnc >/dev/null 2>&1; then
        PASSWORD="${NIHIL_BROWSER_UI_PASSWORD:-$(openssl rand -base64 12)}"
        (umask 077; echo "$PASSWORD" > /opt/nihil/.session_password)
        x11vnc -storepasswd "$PASSWORD" "$VNC_RFBAUTH_FILE" 2>/dev/null
        sync
        # -localhost: x11vnc is only ever meant to be reached through the websockify/noVNC
        # proxy below, never directly. Without this it also listens on every interface,
        # which is a second, unauthenticated-looking raw VNC port exposed alongside noVNC
        # (worse in --network host, where "every interface" means the host's).
        x11vnc -display :99 -rfbport 5901 -rfbauth "$VNC_RFBAUTH_FILE" -forever -shared -localhost >/tmp/nihil_x11vnc.log 2>&1 &
    fi

    # Ouvre directement le bureau. Le titre "Nihil" sert au wrapper pour savoir que la page est prête.
    if [[ -d "$NOVNC_DIR" ]]; then
        cat > "$NOVNC_DIR/index.html" << 'INDEXEOF'
<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Nihil</title>
<meta http-equiv="refresh" content="0; url=vnc.html?autoconnect=1&amp;resize=scale">
</head><body></body></html>
INDEXEOF
    fi

    # XFCE4 (panel + docklike): demarrage direct, pas de greeter tk
    if ! pgrep -x xfce4-session >/dev/null 2>&1; then
        startxfce4 >/tmp/nihil_xfce.log 2>&1 &
        wait_for pgrep -x xfdesktop
    fi

    if command -v websockify >/dev/null 2>&1 && [[ -d "$NOVNC_DIR" ]]; then
        # In --network host, this bind address is the host's: NIHIL_BROWSER_UI_BIND is set
        # by the nihil wrapper to 127.0.0.1 in that case so noVNC isn't reachable from the
        # whole LAN. Defaults to every interface, needed for Docker's own port publishing
        # to work in bridge mode, and when run outside the wrapper.
        BIND="${NIHIL_BROWSER_UI_BIND:-0.0.0.0}"
        websockify --web "$NOVNC_DIR" "${BIND}:${PORT}" localhost:5901 >/tmp/nihil_websockify_ui.log 2>&1 &
        echo "[NIHIL] Browser UI on port $PORT (noVNC, bound to $BIND)."
    else
        echo "[NIHIL] browser-ui: websockify or noVNC missing."
    fi
}

install_browser_ui_deps || exit 0
start_browser_ui
