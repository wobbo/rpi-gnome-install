# Detect the real user and home folder.
#
# This block runs as root, but many settings must be written for the normal user
# who started the installer. SUDO_USER gives that username, and getent is used to
# read the correct home directory from the system account database.
sudo -i

REAL_USER="$SUDO_USER" && \
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6) && \

[ -n "$REAL_USER" ] && [ -n "$REAL_HOME" ] && [ -d "$REAL_HOME" ] && \



# Read the desktop style selected in Step 2.
#
# Step 2 saves the desktop choice in the user's installer state folder.
# If the file is missing or empty, the installer falls back to GNOME style.
DESKTOP="$(awk -F= '$1 == "DESKTOP" {print $2; exit}' "$REAL_HOME/.install_gnome/desktop" 2>/dev/null | tr -d '[:space:]')" && \
[ -n "$DESKTOP" ] || DESKTOP="gnome"



# Convert the desktop choice into Dash-to-Dock settings.
#
# GNOME style places the dock at the bottom and keeps icons centered.
# Ubuntu style places the dock on the left.
case "$DESKTOP" in
    gnome)
        DASH_TO_DOCK_STYLE="\nalways-center-icons=true\ndock-position='BOTTOM'"
        ;;
    ubuntu|*)
        DASH_TO_DOCK_STYLE="\nalways-center-icons=false\ndock-position='LEFT'"
        ;;
esac



# Load optional packages selected in Step 2.
#
# Step 2 writes optional software choices as package names in one small file.
# Step 3 reads that file and appends those packages to the main apt install list.
OPTIONAL_PACKAGES="$(cat "$REAL_HOME/.install_gnome/optional" 2>/dev/null || true)" && \



# Check whether Flathub should be enabled.
#
# Flatpak itself is part of the optional package list. When flatpak was selected
# in Step 2, this flag enables the Flathub repository later in this step.
ENABLE_FLATHUB=0
case " $OPTIONAL_PACKAGES " in
    *" flatpak "*) ENABLE_FLATHUB=1 ;;
esac



# Install GNOME and desktop applications.
#
# This is the main package installation step. It installs GNOME Core, Yaru
# themes, fonts, Chromium, media codecs, LibreOffice, desktop utilities,
# Raspberry Pi support packages, and the optional packages selected in Step 2.
apt-mark manual gnome-shell || true && \
apt update && apt install --ignore-missing -y \
  gnome-core \
  yaru-theme-{gnome-shell,gtk,icon,sound,unity} \
  fonts-ubuntu fonts-ubuntu-{title,console} ttf-mscorefonts-installer \
  rpi-chromium-mods chromium chromium-common chromium-driver chromium-l10n gnome-browser-connector \
  rhythmbox rhythmbox-plugins rhythmbox-plugin-alternative-toolbar shortwave vlc vlc-l10n vlc-plugin-access-extra vlc-plugin-video-output vlc-plugin-skins2 \
  gstreamer1.0-plugins-{base,good,bad,ugly} gstreamer1.0-{libav,tools,alsa,pulseaudio,x,gl,vaapi,pipewire} libwidevinecdm0 ffmpeg  libavcodec-extra vainfo libavcodec-extra61 ffmpegthumbnailer \
  libreoffice-{writer,calc,impress,gtk3,gnome} \
  gnome-text-editor simple-scan hplip file-roller \
  network-manager-openvpn-gnome wireguard wireguard-tools \
  gnome-tweaks gnome-calendar gnome-weather \
  plymouth plymouth-themes gnome-shell-extension-dashtodock gnome-shell-extension-desktop-icons-ng gnome-shell-extension-user-theme gnome-shell-extension-freon \
  libopengl0 rpi-keyboard-config rpi-keyboard-fw-update lm-sensors \
  dbus-x11 $OPTIONAL_PACKAGES || true && \



# Create folders for default settings and autostart files.
#
# /etc/skel is used as a template for future users. The current user's autostart
# folder is also created so first-login setup can run for this user.
mkdir -p /etc/skel/.config/autostart /etc/dconf/db/local.d && mkdir -p "$REAL_HOME/.config/autostart" && \



# Create the dconf profile.
#
# GNOME reads user settings from the normal user database and system defaults
# from the local dconf database. This profile makes both available.
echo -e 'user-db:user\nsystem-db:local' | tee /etc/dconf/profile/user >/dev/null && \



# Create a first-login settings script.
#
# Some GNOME and application settings are easiest to apply after the user logs in.
# This generated script runs once from autostart, writes user preferences, starts
# Chromium once to create its profile, writes VLC defaults, and then removes itself.
sh -c 'mkdir -p /etc/skel/.config/autostart && printf %b "#!/bin/bash\n\n# Nautilus & File Chooser\ngsettings set org.gtk.Settings.FileChooser sort-directories-first true\ngsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true\ngsettings set org.gnome.nautilus.preferences sort-directories-first true\ngsettings set org.gnome.nautilus.preferences default-folder-viewer '\''list-view'\''\ngsettings set org.gnome.nautilus.list-view use-tree-view true\n\n# Desktop Icons (DING)\ngsettings set org.gnome.shell.extensions.ding icon-size '\''small'\''\ngsettings set org.gnome.shell.extensions.ding show-home true\ngsettings set org.gnome.shell.extensions.ding show-trash true\ngsettings set org.gnome.shell.extensions.ding show-volumes false\ngsettings set org.gnome.shell.extensions.ding show-network-volumes false\n\n# General GNOME\ngsettings set org.gnome.calculator refresh-interval 0\ngsettings set org.gnome.mutter dynamic-workspaces false\ngsettings set org.gnome.desktop.wm.preferences num-workspaces 2\ngsettings set org.gnome.desktop.background picture-uri \"file:///usr/share/backgrounds/gnome/blobs-l.svg\"\ngsettings set org.gnome.desktop.background picture-uri-dark \"file:///usr/share/backgrounds/gnome/blobs-d.svg\"\ngsettings set org.gnome.desktop.background primary-color \"#241f31\"\ngsettings set org.gnome.desktop.interface accent-color \"orange\"\ngsettings set org.gnome.desktop.interface gtk-theme \"Yaru\"\ngsettings set org.gnome.desktop.interface icon-theme \"Yaru\"\ngsettings set org.gnome.desktop.interface cursor-theme \"Yaru\"\ngsettings set org.gnome.shell.extensions.user-theme name \"Yaru\"\n\n# Enabled Extensions\ngsettings set org.gnome.shell enabled-extensions \"['\''dash-to-dock@micxgx.gmail.com'\'','\''ding@rastersoft.com'\'','\''user-theme@gnome-shell-extensions.gcampax.github.com'\'','\''gnome-fuzzy-app-search@gnome-shell-extensions.Czarlie.gitlab.com'\'','\''add-to-desktop@tommimon.github.com'\'']\"\n\n# Favorites\ngsettings set org.gnome.shell favorite-apps \"['\''chromium.desktop'\'','\''org.gnome.Nautilus.desktop'\'','\''libreoffice-writer.desktop'\'','\''org.gnome.Software.desktop'\'','\''yelp.desktop'\'','\''org.gnome.Settings.desktop'\'']\"\n\n# Start Chromium tmp\nchromium --no-startup-window --user-data-dir=\"\$HOME/.config/chromium\" --enable-zero-copy --enable-gpu-rasterization --no-first-run --no-default-browser-check >/dev/null 2>&1 &\n\n# Wait for Preferences\nPREF=\"\$HOME/.config/chromium/Default/Preferences\"\nfor i in {1..400}; do\n  [ -f \"\$PREF\" ] && break\n  sleep 0.05\ndone\n\n# Change Preferences\nperl -MJSON::PP -0777 -i -e '\''\n  my \$f = shift;\n\n  open my \$in, \"<\", \$f or exit 0;\n  local \$/; my \$txt = <\$in>;\n  close \$in;\n\n  my \$j = eval { decode_json(\$txt) } || {};\n\n  # extensions.theme.system_theme = 0\n  \$j->{extensions} = {} unless ref(\$j->{extensions}) eq \"HASH\";\n  \$j->{extensions}{theme} = {} unless ref(\$j->{extensions}{theme}) eq \"HASH\";\n  \$j->{extensions}{theme}{system_theme} = 0;\n\n  # browser.theme = {\"is_grayscale2\": true}\n  \$j->{browser} = {} unless ref(\$j->{browser}) eq \"HASH\";\n  \$j->{browser}{theme} = { is_grayscale2 => JSON::PP::true };\n\n  open my \$out, \">\", \$f or die \"write: \$!\";\n  print \$out encode_json(\$j);\n  close \$out;\n'\'' \"\$PREF\"\n\n# Start Chromium background\nnohup chromium --no-startup-window --user-data-dir=\"\$HOME/.config/chromium\" --enable-zero-copy --enable-gpu-rasterization --no-first-run --no-default-browser-check --remote-debugging-address=127.0.0.1 --remote-debugging-port=9222 >/dev/null 2>&1 </dev/null &\n\n# Make autostart\nmkdir -p \"\$HOME/.config/autostart\"\ncat > \"\$HOME/.config/autostart/chromium-background.desktop\" <<'\''EOF'\''\n[Desktop Entry]\nType=Application\nName=Chromium\nExec=/bin/bash -lc '\''nohup chromium --no-startup-window --user-data-dir=\"\$HOME/.config/chromium\" --enable-zero-copy --enable-gpu-rasterization --no-first-run --no-default-browser-check --remote-debugging-address=127.0.0.1 --remote-debugging-port=9222 >/dev/null 2>&1 </dev/null &'\''\nIcon=chromium\nX-GNOME-Autostart-enabled=true\nNoDisplay=true\nEOF\n\n# VLC defaults\nmkdir -p \"\$HOME/.config/vlc\"\nprintf %b \"[qt]\nqt-system-tray=0\nqt-video-autoresize=0\nvideo-title-show=0\nvideo-title-timeout=0\nqt-bgcone=0\n\" > \"\$HOME/.config/vlc/vlcrc\"\nprintf %b \"[MainWindow]\nQtStyle=Fusion\nToolbarPos=false\nadv-controls=0\npl-dock-status=true\nplaylist-visible=false\nstatus-bar-visible=false\ntoolbar-profile=Trixie\nAdvToolbar=\\\"12;11;13;14;\\\"\nFSCtoolbar=\\\"20-4;65;3-4;0-2;4-4;65-4;8;\\\"\nInputToolbar=\\\"43;33-4;44;\\\"\nMainToolbar1=\\\"64;39;64;38;65;\\\"\nMainToolbar2=\\\"20;65-4;22-4;0-2;23-4;65;7;\\\"\n\n[OpenDialog]\nadvanced=false\n\" > \"\$HOME/.config/vlc/vlc-qt-interface.conf\"\n\n# Quit and remove setting.desktop and setting.sh\nrm -f \"\$HOME/.config/autostart/settings.desktop\"\nrm -- \"\$0\"\n" > /etc/skel/.config/autostart/settings.sh && chmod 755 /etc/skel/.config/autostart/settings.sh' && install -D -m 755 /etc/skel/.config/autostart/settings.sh "$REAL_HOME/.config/autostart/settings.sh" && \




# Install Chromium extensions system-wide.
#
# This installs GNOME Shell Integration and uBlock Origin Lite by Chromium policy.
# It does not touch Chromium Preferences, themes, background startup,
# or user profile settings.
mkdir -p /etc/chromium/policies/managed && \
cat > /etc/chromium/policies/managed/chromium-extensions.json <<'EOF_CHROMIUM_EXTENSIONS'
{
  "ExtensionInstallForcelist": [
    "gphhapmejobijbbhgpjhcjognlahblep;https://clients2.google.com/service/update2/crx",
    "ddkjiahejlhfcafbddmgiahcphecmpfh;https://clients2.google.com/service/update2/crx"
  ]
}
EOF_CHROMIUM_EXTENSIONS
chmod 644 /etc/chromium/policies/managed/chromium-extensions.json && \



# Create the autostart launcher for the first-login settings script.
#
# GNOME starts this desktop file after login. The desktop file then runs
# settings.sh, which removes the launcher after it has finished.
sh -c 'mkdir -p /etc/skel/.config/autostart && printf %b "[Desktop Entry]\nType=Application\nName=Settings\nExec=/bin/bash -lc \"sleep 1; \$HOME/.config/autostart/settings.sh\"\nIcon=org.gnome.Nautilus\nX-GNOME-Autostart-enabled=true\nNoDisplay=true\n" > /etc/skel/.config/autostart/settings.desktop && chmod 644 /etc/skel/.config/autostart/settings.desktop' && \
install -D -m 644 /etc/skel/.config/autostart/settings.desktop "$REAL_HOME/.config/autostart/settings.desktop" && \



# Write system-wide Mutter defaults.
#
# This enables Raspberry Pi friendly GNOME scaling support through Mutter's
# experimental scale-monitor-framebuffer feature.
echo -e "[org/gnome/mutter]\nexperimental-features=['scale-monitor-framebuffer']" | tee /etc/dconf/db/local.d/01-gnome-mutter >/dev/null && \



# Write system-wide GNOME Shell defaults.
#
# This enables the selected extensions, configures Dash-to-Dock, sets desktop
# icons, applies the Yaru shell theme, and pins the default favorite apps.
echo -e "[org/gnome/shell]\nenabled-extensions=['dash-to-dock@micxgx.gmail.com','ding@rastersoft.com','user-theme@gnome-shell-extensions.gcampax.github.com','gnome-fuzzy-app-search@gnome-shell-extensions.Czarlie.gitlab.com','add-to-desktop@tommimon.github.com']\n\n[org/gnome/shell/extensions/dash-to-dock]$DASH_TO_DOCK_STYLE\nextend-height=true\ndash-max-icon-size=64\nshow-trash=false\nintellihide-mode='ALL_WINDOWS'\nrunning-indicator-style='DOTS'\n\n[org/gnome/shell/extensions/ding]\nicon-size='small'\nshow-home=true\nshow-trash=true\nshow-volumes=false\nshow-network-volumes=false\n\n[org/gnome/shell/extensions/user-theme]\nname='Yaru'\n\n[org/gnome/shell]\nfavorite-apps=['chromium.desktop','org.gnome.Nautilus.desktop','libreoffice-writer.desktop','org.gnome.Software.desktop','yelp.desktop','org.gnome.Settings.desktop']" | tee /etc/dconf/db/local.d/02-gnome-shell >/dev/null && \



# Write system-wide desktop appearance defaults.
#
# This sets the Yaru GTK, icon, and cursor themes, Ubuntu fonts, window buttons,
# wallpaper, and disables hot corners for a more familiar desktop layout.
echo -e "[org/gnome/desktop/interface]\ngtk-theme='Yaru'\nicon-theme='Yaru'\ncursor-theme='Yaru'\nfont-name='Ubuntu 11'\ndocument-font-name='Ubuntu 11'\nmonospace-font-name='Ubuntu Mono 13'\n\n[org/gnome/desktop/wm/preferences]\nbutton-layout=':minimize,maximize,close'\n\n[org/gnome/desktop/background]\npicture-uri='file:///usr/share/backgrounds/gnome/blobs-l.svg'\n\n[org/gnome/desktop/interface]\nenable-hot-corners=false" | tee /etc/dconf/db/local.d/03-gnome-desktop >/dev/null && \



# Write system-wide file manager defaults.
#
# This makes Nautilus use list view and keeps folders sorted before files.
# The same folder-first behavior is also applied to GTK file chooser dialogs.
echo -e "[org/gnome/nautilus/preferences]\ndefault-folder-viewer='list-view'\nsort-directories-first=true\n\n[org/gtk/Settings/FileChooser]\nsort-directories-first=true\n\n[org/gtk/gtk4/Settings/FileChooser]\nsort-directories-first=true" | tee /etc/dconf/db/local.d/04-gnome-nautilus >/dev/null && \

cat > /usr/local/sbin/gnome-language-support-sync <<'EOF_SYNC'
#!/usr/bin/env bash
set -e



# Synchronize GNOME language support.
#
# GNOME and Debian store language information in different places.
#
# GNOME stores per-user language choices in:
#   /var/lib/AccountsService/users/*
#
# Debian stores system-wide locale settings in:
#   /etc/default/locale
#   /etc/locale.gen
#
# This helper brings those settings together. It detects the languages selected
# in GNOME and the system locale files, enables the matching UTF-8 locales, and
# installs useful language support packages such as spellcheck dictionaries,
# hyphenation rules, and LibreOffice language/help packages when available.

echo "Sync GNOME user languages and language support..."



# Track whether /etc/locale.gen was changed.
#
# locale-gen is only needed when a locale was added or uncommented. Running it
# every time is harmless, but unnecessary. This keeps the helper quieter and
# faster.
changed=0



# Normalize a locale name.
#
# Input values can appear in several forms:
#   nl_NL.UTF-8
#   nl_NL@euro
#   nl-NL
#   en_US.UTF-8
#
# For locale.gen handling, this function reduces them to a clean base form:
#   nl_NL
#   en_US
#
# It also removes spaces, strips encoding/modifier parts, and converts dashes to
# underscores.
normalize_locale() {
    printf '%s\n' "$1" |
        sed -E 's/[[:space:]]+//g' |
        sed -E 's/[.@].*$//' |
        awk 'NF{gsub("-","_"); print}'
}



# Check whether Debian supports a UTF-8 locale.
#
# /usr/share/i18n/SUPPORTED contains the locale names Debian knows how to
# generate. This prevents the script from adding made-up or unsupported locale
# lines to /etc/locale.gen.
supported_utf8_locale() {
    local loc="$1"
    [ -n "$loc" ] || return 1
    grep -Fxq "${loc}.UTF-8 UTF-8" /usr/share/i18n/SUPPORTED 2>/dev/null
}



# Enable one locale in /etc/locale.gen.
#
# This function handles three cases:
#
# 1. Locale is already enabled:
#      nl_NL.UTF-8 UTF-8
#    → do nothing
#
# 2. Locale exists but is commented:
#      # nl_NL.UTF-8 UTF-8
#    → uncomment it
#
# 3. Locale is supported but missing from the file:
#    → append it
#
# Unsupported locales are skipped instead of causing the installer to fail.
enable_locale_gen() {
    local loc="$1"
    local line="${loc}.UTF-8 UTF-8"

    [ -f /etc/locale.gen ] || touch /etc/locale.gen

    # Already enabled in /etc/locale.gen.
    #
    # If an active matching line already exists, there is nothing to change.
    if awk -v loc="${loc}.UTF-8" 'NF && $1 !~ /^#/ && $1 == loc && $2 == "UTF-8" {found=1} END{exit !found}' /etc/locale.gen; then
        return 0
    fi

    # Present but commented out.
    #
    # Uncomment the existing line instead of adding a duplicate.
    if grep -qxE "[[:space:]]*#[[:space:]]*${loc}\.UTF-8[[:space:]]+UTF-8" /etc/locale.gen; then
        sed -i -E "s|^[[:space:]]*#[[:space:]]*(${loc}\.UTF-8[[:space:]]+UTF-8)$|\1|" /etc/locale.gen
        echo "  ✔ enabled locale: $line"
        changed=1
        return 0
    fi

    # Missing from /etc/locale.gen.
    #
    # Only add it when Debian lists it as supported.
    if supported_utf8_locale "$loc"; then
        printf '%s\n' "$line" >> /etc/locale.gen
        echo "  ✔ added locale: $line"
        changed=1
    else
        echo "  ⚠ unsupported locale skipped: ${loc}.UTF-8"
    fi
}



# Collect GNOME and system locales.
#
# Sources:
#
# 1. GNOME AccountsService user files:
#      Language=
#      Languages=
#      FormatsLocale=
#
# 2. Debian system locale file:
#      LANG=
#      LANGUAGE=
#
# LANGUAGE can contain multiple entries separated by colons, for example:
#   LANGUAGE=nl_NL:nl:en_US:en
#
# AccountsService Languages can contain multiple values separated by semicolons.
#
# Every value is normalized, generic values such as C/POSIX/None are ignored, and
# duplicates are removed.
readarray -t USER_LOCALES < <(
    {
        # Read GNOME per-user language settings, if AccountsService user files exist.
        if compgen -G "/var/lib/AccountsService/users/*" >/dev/null; then
            awk -F= '
                /^Language=/ && $2 != "" {print $2}
                /^Languages=/ && $2 != "" {print $2}
                /^FormatsLocale=/ && $2 != "" {print $2}
            ' /var/lib/AccountsService/users/* 2>/dev/null | tr ';' '\n'
        fi

        # Read Debian system language settings.
        #
        # LANG usually contains one locale.
        # LANGUAGE can contain a priority list separated by colons.
        grep -E '^(LANG|LANGUAGE)=' /etc/default/locale 2>/dev/null |
            sed 's/.*=//' |
            tr ':' '\n'
    } |
    while read -r loc; do
        loc="$(normalize_locale "$loc")"

        # Ignore generic or unusable locale values.
        #
        # These are not real user languages and should not be added to
        # /etc/locale.gen.
        case "$loc" in
            ""|"C"|"c"|"C_UTF-8"|"c_UTF-8"|"C.UTF-8"|"c.UTF-8"|"C.utf8"|"c.utf8"|"None"|"none"|"NONE"|"POSIX"|"posix") continue ;;
        esac

        printf '%s\n' "$loc"
    done |
    awk '!seen[$0]++'
)



# Fallback when no useful language was detected.
#
# A fresh or minimal system can sometimes have no real language locale yet.
# en_US.UTF-8 is used as a safe default because it is widely supported and avoids
# broken terminal/whiptail text handling.
if [ "${#USER_LOCALES[@]}" -eq 0 ]; then
    USER_LOCALES=("en_US")
    echo "No real GNOME/system language locale detected; falling back to en_US.UTF-8 as default."
fi

echo "Detected GNOME/system locales: ${USER_LOCALES[*]}"



# Make sure every detected locale is enabled in /etc/locale.gen.
for loc in "${USER_LOCALES[@]}"; do
    enable_locale_gen "$loc"
done



# Read the current default LANG from /etc/default/locale.
#
# Quotes are stripped so values like:
#   LANG="nl_NL.UTF-8"
#
# become:
#   nl_NL.UTF-8
CURRENT_DEFAULT="$(
    awk -F= '/^LANG=/{print $2}' /etc/default/locale 2>/dev/null |
    sed -E 's/^"//; s/"$//'
)"



# Treat generic values as missing.
#
# C, C.UTF-8, None, and similar values are technically usable in some situations,
# but they are not good desktop language defaults for GNOME.
case "$CURRENT_DEFAULT" in
    ""|"C"|"c"|"C.UTF-8"|"c.UTF-8"|"C.utf8"|"c.utf8"|"None"|"none"|"NONE")
        CURRENT_DEFAULT=""
        ;;
esac



# Set a real default locale when the system does not have one.
#
# The first detected GNOME/system locale is used as the default.
#
# Example:
#   USER_LOCALES[0]=nl_NL
#
# Results in:
#   LANG=nl_NL.UTF-8
#   LANGUAGE=nl_NL:nl
if [ -z "$CURRENT_DEFAULT" ]; then
    DEFAULT_LOCALE="${USER_LOCALES[0]}.UTF-8"
    BASE_LANG="${USER_LOCALES[0]}"
    SHORT_LANG="${BASE_LANG%%_*}"

    update-locale LANG="$DEFAULT_LOCALE" LANGUAGE="${BASE_LANG}:${SHORT_LANG}" || {
        printf 'LANG=%s\nLANGUAGE=%s:%s\n' "$DEFAULT_LOCALE" "$BASE_LANG" "$SHORT_LANG" > /etc/default/locale
    }

    echo "  ✔ default locale set: LANG=$DEFAULT_LOCALE"
fi



# Generate locales only if /etc/locale.gen changed.
#
# locale-gen creates the actual locale data used by the system.
if [ "$changed" -eq 1 ]; then
    echo "Generating locales..."
    locale-gen || true
else
    echo "No locale.gen changes needed."
fi



# Build a package install list.
#
# PKGS is kept as a string because it is later passed package-by-package to
# apt-get install. Duplicate package names are filtered before adding.
PKGS=""



# Detect language codes for package names.
#
# Locale names use underscores:
#   nl_NL
#
# Debian language packages usually use lowercase dashes:
#   nl-nl
#   nl
#
# This block collects language codes from:
#   - active /etc/locale.gen entries
#   - /etc/default/locale
#   - GNOME AccountsService user files
#   - current LANG and LANGUAGE environment variables
#
# Then it converts them to package-friendly form and removes duplicates.
readarray -t CODES < <(
    {
        # Active generated locale lines.
        [ -f /etc/locale.gen ] && awk 'NF && $1 !~ /^#/ {print $1}' /etc/locale.gen

        # System locale settings.
        grep -E '^(LANG|LANGUAGE)=' /etc/default/locale 2>/dev/null |
            sed 's/.*=//' |
            tr ':' '\n'

        # GNOME user language settings.
        if compgen -G "/var/lib/AccountsService/users/*" >/dev/null; then
            awk -F= '
                /^Language=/ && $2 != "" {print $2}
                /^Languages=/ && $2 != "" {print $2}
                /^FormatsLocale=/ && $2 != "" {print $2}
            ' /var/lib/AccountsService/users/* 2>/dev/null | tr ';' '\n'
        fi

        # Current shell environment.
        [ -n "${LANG:-}" ] && echo "$LANG"
        [ -n "${LANGUAGE:-}" ] && printf '%s\n' $LANGUAGE
    } |
    sed -E 's/[[:space:]]+//g' |
    sed -E 's/[.@].*$//' |
    awk 'NF{gsub("_","-"); print tolower($0)}' |
    awk '$0 != "c" && $0 != "posix" && $0 != "none"' |
    awk '!seen[$0]++'
)

echo "Detected languages: ${CODES[*]}"



# Decide which language package families to install.
#
# Always try:
#   hunspell-*  spellcheck dictionaries
#   hyphen-*    hyphenation rules
#
# Only when LibreOffice is installed, also try:
#   libreoffice-l10n-*   LibreOffice UI language pack
#   libreoffice-help-*   LibreOffice offline help
#
# This avoids installing LibreOffice language packages on systems where
# LibreOffice itself is not installed.
if dpkg-query -W -f='${Status}' libreoffice-core 2>/dev/null | grep -q "install ok installed"; then
    WANT=(hunspell hyphen libreoffice-l10n libreoffice-help)
else
    WANT=(hunspell hyphen)
    echo "ℹ LibreOffice is not installed; skipping LibreOffice language/help packages."
fi



# Find matching language packages.
#
# For every detected language code, try both, exaple:
#   full code:   hunspell-nl-nl
#   short code:  hunspell-nl
#
# Some Debian packages use full region codes, others only use the short language
# code. Because naturally this could not be consistent. That would be too kind.
for code in "${CODES[@]}"; do
    echo "➡ Language: $code"
    L="${code%%-*}"

    for typ in "${WANT[@]}"; do
        # LibreOffice does not need a separate l10n package for en-us in this
        # context, so skip that specific combination.
        if [ "$typ" = "libreoffice-l10n" ] && [ "$code" = "en-us" ]; then
            echo "  ↷ skip $typ for en-us"
            continue
        fi

        found=""

        # First try exact/common package names.
        for cand in "$typ-$code" "$typ-$L"; do
            if apt-cache show "$cand" >/dev/null 2>&1 && ! apt-cache policy "$cand" | grep -q 'Candidate: (none)'; then
                found="$cand"
                break
            fi
        done

        # If no direct package name exists, search alternatives that start with
        # the short language code.
        #
        # Example:
        #   libreoffice-help-pt-br
        #   libreoffice-help-pt
        if [ -z "$found" ]; then
            while read -r alt; do
                [[ -z "$alt" ]] && continue
                [[ "$alt" =~ ^$typ- ]] || continue

                if apt-cache policy "$alt" | grep -qv 'Candidate: (none)'; then
                    found="$alt"
                    break
                fi
            done < <(apt-cache search "^$typ-$L-" | awk '{print $1}')
        fi

        # Add the package once.
        #
        # The same package can be found through multiple locale sources, so this
        # avoids duplicate apt-get install attempts.
        if [ -n "$found" ]; then
            case " $PKGS " in
                *" $found "* ) : ;;
                * )
                    PKGS+=" $found"
                    echo "  ✔ $typ → $found"
                    ;;
            esac
        else
            echo "  ⚠ No package found for $typ ($code)"
        fi
    done
done



# Install the collected packages.
#
# Each package is installed separately. If one package fails, the helper continues
# with the next one. Language support is useful, but it should not break the whole
# GNOME installation.
if [ -n "$PKGS" ]; then
    echo "Installing:$PKGS"

    for p in $PKGS; do
        if apt-cache madison "$p" 2>/dev/null | grep -q .; then
            apt-get install -y "$p" || true
        else
            echo "  ⚠ Skip without candidate: $p"
        fi
    done

    echo "Done."
else
    echo "Nothing to do."
fi



# Note about locales-all.
#
# When locales-all is installed, "locale -a" shows all locales as available even
# if this installer did not enable them in /etc/locale.gen.
#
# That is why this helper reads /etc/locale.gen, /etc/default/locale, and GNOME
# AccountsService files directly instead of relying on "locale -a".
(dpkg -l locales-all 2>/dev/null | grep -q '^ii' && echo "ℹ 'locales-all' is installed; we deliberately avoid 'locale -a'.") || true
EOF_SYNC

# Install the language support helper and create its systemd service.
# The service can run after account and network services are ready. It is useful
# because language package detection may depend on GNOME account settings.
chmod 755 /usr/local/sbin/gnome-language-support-sync && \
cat > /etc/systemd/system/gnome-language-support-sync.service <<'EOF_SYNC_SERVICE'
[Unit]
Description=Sync GNOME user languages and install language support
After=accounts-daemon.service network-online.target
Wants=accounts-daemon.service network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/gnome-language-support-sync

[Install]
WantedBy=multi-user.target
EOF_SYNC_SERVICE

# Enable the language support service.
# The service is enabled for future boots and also run once immediately. The
# immediate run is allowed to fail so language package problems do not stop the
# whole desktop installation.
chmod 644 /etc/systemd/system/gnome-language-support-sync.service && \
systemctl daemon-reload && \
systemctl enable gnome-language-support-sync.service && \
( /usr/local/sbin/gnome-language-support-sync || true ) && \


# Install extra GNOME Shell extensions.
# These extensions are downloaded from extensions.gnome.org and installed
# system-wide, so they are available before the user opens GNOME for the first
# time.
wget -O /tmp/gnome-fuzzy-app-search.zip https://extensions.gnome.org/extension-data/gnome-fuzzy-app-searchgnome-shell-extensions.Czarlie.gitlab.com.v26.shell-extension.zip && rm -rf /usr/share/gnome-shell/extensions/gnome-fuzzy-app-search@gnome-shell-extensions.Czarlie.gitlab.com && unzip -o /tmp/gnome-fuzzy-app-search.zip -d /usr/share/gnome-shell/extensions/gnome-fuzzy-app-search@gnome-shell-extensions.Czarlie.gitlab.com && chmod -R a+rX /usr/share/gnome-shell/extensions/gnome-fuzzy-app-search@gnome-shell-extensions.Czarlie.gitlab.com && \
wget -O /tmp/add-to-desktop.zip https://extensions.gnome.org/extension-data/add-to-desktoptommimon.github.com.v15.shell-extension.zip && rm -rf /usr/share/gnome-shell/extensions/add-to-desktop@tommimon.github.com && unzip -o /tmp/add-to-desktop.zip -d /usr/share/gnome-shell/extensions/add-to-desktop@tommimon.github.com && chmod -R a+rX /usr/share/gnome-shell/extensions/add-to-desktop@tommimon.github.com && \

# Install Yaru icon themes for LibreOffice.
# LibreOffice uses separate image zip files for its toolbar icons. This block
# installs the Yaru icon sets and prepares dark variants as well.
wget -O /tmp/libreoffice_yaru-themes_2025-09-23.zip https://raw.githubusercontent.com/wobbo/libreoffice-yaru-themes/main/libreoffice_yaru-themes_2025-09-23.zip && unzip -o /tmp/libreoffice_yaru-themes_2025-09-23.zip -d /usr/lib/libreoffice/share/config/ 'images_yaru*.zip' && cd /usr/lib/libreoffice/share/config/ && for f in images_yaru*.zip; do [[ "$f" == *_dark.zip ]] && continue; mv -f "$f" "${f%.zip}_dark.zip"; done && unzip -o /tmp/libreoffice_yaru-themes_2025-09-23.zip -d /usr/lib/libreoffice/share/config/ && chmod -R a+rX /usr/lib/libreoffice/share/config/images_yaru* && ls -1 images_yaru*_dark.zip | wc -l && rm -f /tmp/libreoffice_yaru-themes_2025-09-23.zip && cd ~ && \

# Install patched Yaru theme packages and Geary.
# These packages come from the project repositories instead of the normal Debian
# repository. They are installed and then held to prevent apt from replacing them
# with incompatible versions during normal upgrades.
tmpdir=$(mktemp -d); cd "$tmpdir"; wget https://github.com/wobbo/yaru-themes-debian-trixie/releases/download/v1/yaru-theme-gnome-shell_25.04.1-0ubuntu1_all.deb https://github.com/wobbo/yaru-themes-debian-trixie/releases/download/v1/yaru-theme-gtk_25.04.1-0ubuntu1_all.deb https://github.com/wobbo/yaru-themes-debian-trixie/releases/download/v1/yaru-theme-icon_25.04.1-0ubuntu1_all.deb https://github.com/wobbo/yaru-themes-debian-trixie/releases/download/v1/yaru-theme-sound_25.04.1-0ubuntu1_all.deb https://github.com/wobbo/geary-44.1-for-debian-trixie-arm64/raw/main/geary_44.1-1wobbo1_arm64_20251202.deb; apt-mark unhold yaru-theme-gnome-shell yaru-theme-gtk yaru-theme-icon yaru-theme-sound geary || true && apt install -y ./yaru-theme-*.deb ./geary_44.1-1wobbo1_arm64_20251202.deb && apt-mark hold yaru-theme-gnome-shell yaru-theme-gtk yaru-theme-icon yaru-theme-sound geary && apt-mark hold yaru-theme-gnome-shell yaru-theme-gtk yaru-theme-icon yaru-theme-sound geary; apt-cache policy geary | grep Installed; cd ~; rm -rf "$tmpdir" && \

# Install Geary background helper.
# This user service checks GNOME Online Accounts at login.
# If a mail-capable account exists, it enables Geary background mode.
# If Geary is removed later, it silently cleans up the autostart file.
cat > /usr/local/bin/geary-background <<'EOF_GEARY_BACKGROUND'
#!/usr/bin/env bash
set -euo pipefail

AUTOSTART="$HOME/.config/autostart/geary-background.desktop"

has_enabled_mail() {
    paths="$(gdbus call \
        --session \
        --dest org.gnome.OnlineAccounts \
        --object-path /org/gnome/OnlineAccounts \
        --method org.freedesktop.DBus.ObjectManager.GetManagedObjects \
        2>/dev/null | grep -o "/org/gnome/OnlineAccounts/Accounts/[A-Za-z0-9_/-]*" | sort -u || true)"

    [ -n "$paths" ] || return 1

    for path in $paths; do
        disabled="$(gdbus call \
            --session \
            --dest org.gnome.OnlineAccounts \
            --object-path "$path" \
            --method org.freedesktop.DBus.Properties.Get \
            org.gnome.OnlineAccounts.Account MailDisabled \
            2>/dev/null || true)"

        if printf "%s\n" "$disabled" | grep -q "false"; then
            return 0
        fi
    done

    return 1
}

# If these tools are missing, do nothing.
# This keeps login clean and avoids visible errors.
command -v gdbus >/dev/null 2>&1 || exit 0
command -v gsettings >/dev/null 2>&1 || exit 0

# If Geary was removed, clean up old autostart and stop without error.
command -v geary >/dev/null 2>&1 || {
    rm -f "$AUTOSTART"
    exit 0
}

mkdir -p "$HOME/.config/autostart"

if has_enabled_mail; then
    gsettings set org.gnome.Geary run-in-background true || true

    cat > "$AUTOSTART" <<'EOF_GEARY_DESKTOP'
[Desktop Entry]
Type=Application
Name=Geary
Exec=geary --gapplication-service
NoDisplay=true
OnlyShowIn=GNOME;
X-GNOME-Autostart-enabled=true
EOF_GEARY_DESKTOP
else
    gsettings set org.gnome.Geary run-in-background false || true
    rm -f "$AUTOSTART"
fi
EOF_GEARY_BACKGROUND

chmod 755 /usr/local/bin/geary-background && \

# Install Geary background user service.
cat > /etc/systemd/user/geary-background.service <<'EOF_GEARY_SERVICE'
[Unit]
Description=Configure Geary background mode

[Service]
Type=oneshot
ExecStart=/usr/local/bin/geary-background

[Install]
WantedBy=default.target
EOF_GEARY_SERVICE

chmod 644 /etc/systemd/user/geary-background.service && \

# Install the automatic Yaru theme service.
# This user service keeps the GNOME Shell theme aligned with the selected Yaru
# appearance, including light and dark mode changes.
wget -O /usr/local/bin/gnome-auto-yaru.sh https://raw.githubusercontent.com/wobbo/yaru-themes-debian-trixie/main/gnome-auto-yaru_2025-10-07.sh && chmod 755 /usr/local/bin/gnome-auto-yaru.sh && wget -O /etc/systemd/user/gnome-auto-yaru.service https://raw.githubusercontent.com/wobbo/yaru-themes-debian-trixie/main/gnome-auto-yaru_2025-10-07.service && chmod 644 /etc/systemd/user/gnome-auto-yaru.service && \

# Create a small Chromium desktop-file fix.
# This disables StartupNotify in the Chromium launcher. It avoids misleading
# startup feedback after Chromium is started in the background.
sh -c 'printf %b "#!/bin/bash\nsed -i '\''s/^StartupNotify=true/StartupNotify=false/'\'' /usr/share/applications/chromium.desktop\n" > /usr/local/bin/fix_chromium_notify.sh' && chmod 755 /usr/local/bin/fix_chromium_notify.sh && sh -c 'printf %b "[Unit]\nDescription=Fix Chromium.desktop StartupNotify\nAfter=network.target\n[Service]\nType=oneshot\nExecStart=/usr/local/bin/fix_chromium_notify.sh\nRemainAfterExit=true\n[Install]\nWantedBy=multi-user.target\n" > /etc/systemd/system/fix-chromium-notify.service' && chmod 644 /etc/systemd/system/fix-chromium-notify.service && \

# Prepare Plymouth boot splash settings.
# The current Raspberry Pi boot command line is backed up before adding quiet
# splash options and hiding the text cursor during boot.
cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup && \
dconf update && printf "[Daemon]\nTheme=spinner\nShowDelay=0\n" | tee /etc/plymouth/plymouthd.conf >/dev/null && plymouth-set-default-theme spinner && cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup && grep -q 'plymouth.ignore-serial-consoles' /boot/firmware/cmdline.txt || sed -i '1 s/^/quiet splash plymouth.ignore-serial-consoles vt.global_cursor_default=0 /' /boot/firmware/cmdline.txt && update-initramfs -u -k all && \

# Enable Flathub when Flatpak was selected in Step 2.
# Flathub is only added when the optional Flatpak package was selected. This keeps
# the install smaller for users who do not want Flatpak support.
if [ "$ENABLE_FLATHUB" -eq 1 ]; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi && \

# Remove packages that are not part of this GNOME preset.
# This keeps the final desktop cleaner by removing duplicate or unwanted tools
# that would otherwise appear in the application menu.
apt remove -y imagemagick* zutty firefox firefox-esr im-config showtime totem mpv htop && apt autoremove -y && \

# Enable desktop services and boot into graphical mode.
# The Yaru user service and Chromium fix service are enabled, and the system
# default target is changed so the Pi boots into the graphical desktop.
systemctl daemon-reload && \
systemctl enable --global gnome-auto-yaru.service && \
systemctl enable --global geary-background.service && \
systemctl enable --now fix-chromium-notify.service && \
systemctl set-default graphical.target && \

# Hide the GDM logo if the setting exists.
# This comments out the logo setting in GDM's greeter defaults to keep the login
# screen cleaner.
sed -i '/^logo=/ s/^/#/' /etc/gdm3/greeter.dconf-defaults && \

# Set VLC as the default media player.
# This applies VLC as the default for common audio and video files for the system,
# the current user, and future users created from /etc/skel.
install -d -m 0755 /etc/xdg /etc/skel/.config "$REAL_HOME/.config" /usr/local/share/applications /usr/local/bin && \
# Define default media file associations.
#
# The mimeapps.list content below maps common video and audio MIME types to VLC.
MIMEAPPS_VLC_CONTENT=$'[Default Applications]\nvideo/mp4=vlc.desktop\nvideo/x-matroska=vlc.desktop\nvideo/webm=vlc.desktop\nvideo/quicktime=vlc.desktop\nvideo/mpeg=vlc.desktop\nvideo/x-msvideo=vlc.desktop\naudio/mpeg=vlc.desktop\naudio/mp4=vlc.desktop\naudio/flac=vlc.desktop\naudio/ogg=vlc.desktop\naudio/x-wav=vlc.desktop\naudio/opus=vlc.desktop\n' && \
printf "%s" "$MIMEAPPS_VLC_CONTENT" > /etc/xdg/mimeapps.list && \
printf "%s" "$MIMEAPPS_VLC_CONTENT" > /etc/skel/.config/mimeapps.list && \
printf "%s" "$MIMEAPPS_VLC_CONTENT" > "$REAL_HOME/.config/mimeapps.list" && \
chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/mimeapps.list" && \

# Create a customized VLC launcher.
# The launcher is copied to /usr/local so the system package file is not edited
# directly. It is then renamed slightly, given a generic multimedia icon, and
# pointed to a wrapper script.
SRC="/usr/share/applications/vlc.desktop" && DST="/usr/local/share/applications/vlc.desktop" && NEW_ICON="applications-multimedia" && tmp="$(mktemp)" && \
install -m 0644 "$SRC" "$DST" && \
awk -v newicon="$NEW_ICON" 'BEGIN{FS=OFS="="}$1=="Name"||$1~/^Name\[/{name=$2;gsub(/(^| )VLC( |$)/," ",name);gsub(/ +/," ",name);sub(/^ /,"",name);sub(/ $/,"",name);gsub(/media player/,"Media player",name);print $1,name;next}$1=="Icon"{print "Icon",newicon;next}{print}' "$DST" > "$tmp" && \
install -m 0644 "$tmp" "$DST" && rm -f "$tmp" && \
sed -i -e 's|^Exec=.*|Exec=/usr/local/bin/vlc-x11 --no-one-instance %U|' -e 's|^TryExec=.*|TryExec=/usr/local/bin/vlc-x11|' "$DST" && \

# Create the VLC wrapper.
# VLC is forced to run through X11 because this is more reliable for the selected
# desktop setup. The wrapper also updates VLC's dark palette setting to match the
# current GNOME light or dark preference before starting VLC.
printf '%s\n' '#!/bin/sh' 'unset WAYLAND_DISPLAY' 'export QT_QPA_PLATFORM=xcb' \
'VLC_CONFIG="$HOME/.config/vlc/vlcrc"' \
'scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'\''")' \
'mkdir -p "$HOME/.config/vlc"; touch "$VLC_CONFIG"' \
"sed -i '/^qt-dark-palette=/d;/^#qt-dark-palette=/d' \"\$VLC_CONFIG\"" \
'if [ "$scheme" = "prefer-dark" ]; then echo "qt-dark-palette=1" >> "$VLC_CONFIG"; else echo "qt-dark-palette=0" >> "$VLC_CONFIG"; fi' \
'exec /usr/bin/vlc --no-one-instance "$@"' > /usr/local/bin/vlc-x11 && \
chmod 0755 /usr/local/bin/vlc-x11 && \
update-desktop-database /usr/local/share/applications 2>/dev/null || true && \

# Return ownership of user autostart files to the real user.
# The root block created these files as root. This final ownership fix lets the
# normal user read, update, and remove their own autostart files later.
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/autostart"
