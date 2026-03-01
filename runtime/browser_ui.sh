#!/bin/bash
# Browser UI: XFCE4 + dock en bas (docklike), connexion Xvfb + x11vnc

set -e

PORT="${NIHIL_BROWSER_UI_PORT:-6901}"
MARKER="/opt/nihil/.browser_ui_installed_v8"
NOVNC_DIR="/opt/nihil/novnc"
XFCE_CONF="/root/.config/xfce4/xfconf/xfce-perchannel-xml"
XFCE_PANEL_CONF="/root/.config/xfce4/panel"

install_browser_ui_deps() {
    echo "[NIHIL] Ensuring browser UI dependencies (XFCE4 + Docklike)..."
    if command -v pacman >/dev/null 2>&1; then
        if [[ ! -f "$MARKER" ]]; then
            pacman -Sy --noconfirm
            pacman -S --noconfirm --needed \
                xorg-server-xvfb \
                x11vnc \
                xfce4 \
                xfce4-docklike-plugin \
                xfce4-terminal \
                xfce4-appfinder \
                thunar \
                firefox \
                dbus \
                python-pip \
                python-pipx || true
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

    if ! command -v websockify >/dev/null 2>&1; then
        pacman -S --noconfirm --needed websockify python-websockify >/tmp/nihil_websockify.log 2>&1 || true
    fi
    if ! command -v websockify >/dev/null 2>&1; then
        if command -v pipx >/dev/null 2>&1; then
            pipx install websockify >/tmp/nihil_websockify_pipx.log 2>&1 || true
        fi
    fi
    if ! command -v websockify >/dev/null 2>&1; then
        pip install --no-cache-dir --break-system-packages websockify >/tmp/nihil_websockify_pip.log 2>&1 || \
            echo "[NIHIL] browser-ui: websockify install failed"
    fi

    if [[ ! -d "$NOVNC_DIR" ]]; then
        echo "[NIHIL] Fetching noVNC..."
        git clone --depth=1 https://github.com/novnc/noVNC.git "$NOVNC_DIR" >/tmp/nihil_novnc.log 2>&1 || true
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
        <value type="double" value="0.082353"/>
        <value type="double" value="0.082353"/>
        <value type="double" value="0.082353"/>
        <value type="double" value="0.9"/>
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
        <value type="double" value="0.082353"/>
        <value type="double" value="0.082353"/>
        <value type="double" value="0.082353"/>
        <value type="double" value="0.85"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu"/>
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
indicatorColor=rgb(76,166,230)
pinned=/usr/share/applications/xfce4-appfinder.desktop;/usr/share/applications/xfce4-terminal.desktop;/usr/share/applications/thunar.desktop;/usr/share/applications/firefox.desktop;
indicatorOrientation=1
inactiveIndicatorStyle=0
inactiveColor=rgb(26,95,180)
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

    mkdir -p "$(dirname "$MARKER")"
    touch "$MARKER"
}

start_browser_ui() {
    export DISPLAY=:1
    export USER=root
    export HOME=/root
    export NO_AT_BRIDGE=1
    # Session D-Bus – évite "Unable to contact settings server"
    export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/nihil-runtime}"
    mkdir -p "$XDG_RUNTIME_DIR" /tmp/dbus-session
    chmod 700 "$XDG_RUNTIME_DIR" /tmp/dbus-session 2>/dev/null || true

    # Xvfb (stable)
    if ! pgrep -x Xvfb >/dev/null 2>&1; then
        Xvfb :1 -screen 0 1280x720x24 >/tmp/nihil_xvfb.log 2>&1 &
        sleep 2
    fi

    # Bus D-Bus session explicite pour que xfce4-settings-daemon puisse se connecter
    if [[ -z "${DBUS_SESSION_BUS_ADDRESS}" ]] || ! kill -0 "$(cat /tmp/dbus-session/pid 2>/dev/null)" 2>/dev/null; then
        rm -rf /tmp/dbus-session
        mkdir -p /tmp/dbus-session
        dbus-daemon --session --address=unix:path=/tmp/dbus-session/bus --nofork --print-pid >/tmp/dbus-session/pid 2>/dev/null &
        sleep 0.5
        export DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/dbus-session/bus
    fi

    # Copier le wallpaper + remplacer le fallback xfce (xfdesktop charge xfce-x.svg)
    mkdir -p /usr/share/backgrounds/nihil
    if [[ -f /opt/nihil/runtime/wallpaper.png ]]; then
        cp -f /opt/nihil/runtime/wallpaper.png /usr/share/backgrounds/nihil/default.png
        [[ -f /usr/share/backgrounds/xfce/xfce-x.svg ]] && cp -f /opt/nihil/runtime/wallpaper.png /usr/share/backgrounds/xfce/xfce-x.svg
    fi

    # Mot de passe de session (affiché sur la page de connexion HTML + récap wrapper)
    VNC_PASSWORD_FILE="/tmp/nihil_vnc_password"
    if ! pgrep -x x11vnc >/dev/null 2>&1; then
        PASSWORD="${NIHIL_BROWSER_UI_PASSWORD:-$(openssl rand -base64 12)}"
        echo "$PASSWORD" > "$VNC_PASSWORD_FILE"
        echo "$PASSWORD" > /opt/nihil/.session_password
        chmod 600 "$VNC_PASSWORD_FILE" /opt/nihil/.session_password
        sync
        x11vnc -display :1 -rfbport 5901 -nopw -forever -shared >/tmp/nihil_x11vnc.log 2>&1 &
    fi

    # Page de connexion HTML : login affiché, mot de passe à saisir par l'utilisateur (voir récap CLI)
    if [[ -d "$NOVNC_DIR" ]]; then
        cat > "$NOVNC_DIR/index.html" << 'INDEXEOF'
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Nihil — Connexion</title>
  <style>
    * { box-sizing: border-box; }
    body { margin: 0; min-height: 100vh; background: #1a1a1a; color: #e0e0e0; font-family: system-ui, sans-serif; display: flex; align-items: center; justify-content: center; }
    .card { background: #252525; padding: 2rem 2.5rem; border-radius: 8px; text-align: center; min-width: 320px; }
    h1 { margin: 0 0 0.5rem; font-size: 1.75rem; }
    .sub { color: #a0a0a0; margin-bottom: 1.5rem; font-size: 0.95rem; }
    .row { display: flex; justify-content: space-between; align-items: center; gap: 1rem; margin: 0.75rem 0; padding: 0.5rem 0; border-bottom: 1px solid #333; }
    .label { color: #a0a0a0; }
    .value { font-family: monospace; font-size: 0.95rem; }
    .hint { color: #808080; font-size: 0.85rem; margin-top: 0.5rem; }
    a.btn { display: inline-block; margin-top: 1.5rem; padding: 0.6rem 1.5rem; background: #3d6ba3; color: #fff; text-decoration: none; border-radius: 6px; font-weight: 500; }
    a.btn:hover { background: #4a7ab8; }
  </style>
</head>
<body>
  <div class="card">
    <h1>Nihil</h1>
    <p class="sub">Connexion à la session</p>
    <div class="row"><span class="label">Utilisateur</span><span class="value">root</span></div>
    <div class="row"><span class="label">Mot de passe</span><span class="value">— à saisir —</span></div>
    <p class="hint">Le mot de passe a été affiché dans le terminal au démarrage du conteneur (récap « Session (browser) »).</p>
    <a href="vnc_lite.html?autoconnect=1&amp;resize=scale" class="btn">Ouvrir le bureau</a>
  </div>
</body>
</html>
INDEXEOF
    fi

    # XFCE4 (panel + docklike) — démarrage direct, pas de greeter tk
    if ! pgrep -x xfce4-session >/dev/null 2>&1; then
        startxfce4 >/tmp/nihil_xfce.log 2>&1 &
        sleep 5
    fi

    if command -v websockify >/dev/null 2>&1 && [[ -d "$NOVNC_DIR" ]]; then
        websockify --web "$NOVNC_DIR" "$PORT" localhost:5901 >/tmp/nihil_websockify_ui.log 2>&1 &
        echo "[NIHIL] Browser UI on port $PORT (noVNC)."
    else
        echo "[NIHIL] browser-ui: websockify or noVNC missing."
    fi
}

install_browser_ui_deps || exit 0
start_browser_ui
