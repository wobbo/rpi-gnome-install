#!/usr/bin/env bash
set -e

# 2026-03-10 19:57 UTC
# Ernst Lanser <ernst.lanser@wobbo.org>
# https://forums.raspberrypi.com/viewtopic.php?t=373028#post_content2233233

# WARNING: 
# Run this script only on a 
# fresh Raspberry Pi OS Lite installation.

# Download:
# wget -O install-gnome.sh https://wobbo.org/install/2026-03-10/install-gnome.sh
# chmod +x install-gnome.sh
# ./install-gnome.sh

# All-in-one copy-paste SSH:
# rm -f ./install-gnome.sh && rm -rf ./.install_gnome && wget https://wobbo.org/install/2026-03-10/install-gnome.sh && chmod +x install-gnome.sh && ./install-gnome.sh


# ==============================================================================
# BOOTSTRAP INSTALLER
# ==============================================================================
# Triggers the setup of the installation directory and generates the sub-scripts.
# ==============================================================================


INSTALL_DIR="$HOME/.install_gnome"

clear
printf "\n"
# Titel
printf "  \033[1mWelcome to the GUIDE GNOME Installer\033[0m.\n"
printf "\n"
printf "  Transform your Raspberry Pi 4/5 into a sleek,\n"
printf "  Ubuntu-styled workstation. 2026-03-10\n"
printf "\n"
# Technische basis (Debian + Raspberry Pi debs)
printf "  Built on \033[1mDebian 13\033[0m using \033[1mRaspberry Pi packages\033[0m for\n"
printf "  optimal hardware usage, video codecs, and a\n"
printf "  fully accelerated Chromium browser.\n"
printf "\n"
# Wobbe extra's
printf "  Refined with Wobbe exclusives like the\n"
printf "  Yaru theme and a patched Geary client.\n"
printf "\n"
printf "  Raspberry Pi Forum:\n"
printf "  \033[3mhttps://forums.raspberrypi.com/viewtopic.php?t=373028\033[0m\n"
printf "\n\n"
sleep 1
# Het kader
printf "  ╔═════════════ \033[1mGUIDE GNOME – Bootstrap\033[0m ═════════════════╗\n"
printf "  ║                                                       ║\n"
printf "  ║   Initializes a secure workspace to store             ║\n"
printf "  ║   temporary installation files:                       ║\n"
printf "  ║                                                       ║\n"
printf "  ╟─▫ \033[3m.install_gnome/state\033[0m                                ║\n"
printf "  ╟─▫ \033[3m.install_gnome/step1.sh\033[0m                             ║\n"
printf "  ╟─▫ \033[3m.install_gnome/step2.sh\033[0m                             ║\n"
printf "  ╟─▫ \033[3m.install_gnome/step3.sh\033[0m                             ║\n"
printf "  ║                                                       ║\n"
printf "  ║   Note: Installation files are automatically          ║\n"
printf "  ║   deleted after the process finishes.                 ║\n"
printf "  ║                                                       ║\n"
printf "  ╙───────────────────────────────────────────────────────╜\n"
printf "\n"
sleep 1

printf "    ▫ Creating installer directory:\n"
printf "      \033[3m$INSTALL_DIR\033[0m\n"
printf "\n"

mkdir -p "$INSTALL_DIR"
chmod 700 "$INSTALL_DIR"

sleep 1

# ==============================================================================
# GENERATE STEP 1: User Identity & Locale
# ==============================================================================
cat > "$INSTALL_DIR/step1.sh" <<'EOF'
#!/usr/bin/env bash
set -e

STATE_FILE="$HOME/.install_gnome/state"

clear
printf "\n\n"
printf "  ╔═══════ \033[1mGUIDE GNOME Installer – Step 1 of 3\033[0m ═══════════╗\n"
printf "  ║                                                       ║\n"
printf "  ╟─▫ Sets your system-wide display name for the login    ║\n"
printf "  ║   screen, desktop, and applications.                  ║\n"
printf "  ║                                                       ║\n"
printf "  ╟─▫ Configures the fundamental system language and      ║\n"
printf "  ║   region for both the terminal and GNOME.             ║\n"
printf "  ║                                                       ║\n"
printf "  ╙───────────────────────────────────────────────────────╜\n"
printf "\n"

printf "    ▹ Current user: \033[1m$USER\033[0m\n"
printf "\n"

# --- Ask for full name (editable, pre-filled) ---
CURRENT_FULLNAME="$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1)"
read -e -i "$CURRENT_FULLNAME" \
  -p $'    ▹ Your full name (optional): \033[1m' FULLNAME
printf "\033[0m\n"

# --- Apply the name ---
if [ -n "$FULLNAME" ]; then
  printf "    ▫ Saving full name. "
  sudo usermod -c "$FULLNAME" "$USER"
  printf "\n\n"
fi
sleep 3	

printf "    ▫ Package configuration. "
sleep 3	

sudo dpkg-reconfigure locales
printf "\n\n" 

# --- Update state ONLY after success ---
echo "STEP=2" > "$STATE_FILE"

sleep 4

# --- Reboot Countdown ---
COUNT=9
while [ "$COUNT" -ge 0 ]; do
  clear
  printf \
"

  ╔═══════════════ \033[1mSystem will reboot now\033[0m ════════════════╗
  ║                                                       ║
  ║   Step 1 completed successfully!                      ║
  ║                                                       ║
  ║   Reboot in: \033[1m%-2d\033[0m                                       ║
  ║                                                       ║
  ║   After reboot, run:                                  ║
  ║   \033[3m./install-gnome.sh\033[0m                                  ║
  ║                                                       ║
  ╙───────────────────────────────────────────────────────╜

" "$COUNT"
  sleep 1
  COUNT=$((COUNT - 1))
done

sleep 1
sudo reboot
EOF
chmod +x "$INSTALL_DIR/step1.sh"


# ==============================================================================
# GENERATE STEP 2: System Updates & Prep
# ==============================================================================
cat > "$INSTALL_DIR/step2.sh" <<'EOF'
#!/usr/bin/env bash
set -e

clear
printf "\n\n"
printf "  ╔═══════ \033[1mGUIDE GNOME Installer – Step 2 of 3\033[0m ═══════════╗\n"
printf "  ║                                                       ║\n"
printf "  ║   This step will perform system updates and basic     ║\n"
printf "  ║   preparation. You may be asked for your sudo         ║\n"
printf "  ║   password.                                           ║\n"
printf "  ║                                                       ║\n"
printf "  ╟─▫ Configure keyboard layout                           ║\n"
printf "  ╟─▫ Configure timezone and locale                       ║\n"
printf "  ╟─▫ Update package lists                                ║\n"
printf "  ╟─▫ Remove unused packages                              ║\n"
printf "  ║                                                       ║\n"
printf "  ╙───────────────────────────────────────────────────────╜\n"
printf "\n"
sleep 1

printf "    ▹ Press [\033[1mENTER\033[0m] to continue with Step 2, \n"
printf "      or [\033[1mCtrl\033[0m+\033[1mC\033[0m] to cancel the installation: "
read -r STEP_INPUT

sleep 1
clear

# --- Run System Updates ---
sudo dpkg-reconfigure keyboard-configuration && \
sudo dpkg-reconfigure tzdata
clear
sudo apt update && \
sudo apt -y upgrade && \
sudo apt autoremove -y

printf "\n"
printf "    ▫ Step 2 completed successfully.\n"

# --- Update state ONLY after success ---
echo "STEP=3" > "$HOME/.install_gnome/state"

# --- Reboot Countdown ---
COUNT=9
while [ "$COUNT" -ge 0 ]; do
  clear
  printf \
"

  ╔═══════════════ \033[1mSystem will reboot now\033[0m ════════════════╗
  ║                                                       ║
  ║   Step 2 completed successfully!                      ║
  ║                                                       ║
  ║   Reboot in: \033[1m%-2d\033[0m                                       ║
  ║                                                       ║
  ║   After reboot, run:                                  ║
  ║   \033[3m./install-gnome.sh\033[0m                                  ║
  ║                                                       ║
  ╙───────────────────────────────────────────────────────╜

" "$COUNT"
  sleep 1
  COUNT=$((COUNT - 1))
done

sleep 1
sudo reboot
EOF
chmod +x "$INSTALL_DIR/step2.sh"


# ==============================================================================
# GENERATE STEP 3: GNOME Installation
# ==============================================================================
cat > "$INSTALL_DIR/step3.sh" <<'STEP3'
#!/usr/bin/env bash
set -e

INSTALL_DIR="$HOME/.install_gnome"
INSTALL_ENTRY="$PWD/install-gnome.sh"

clear
printf "\n\n"
printf "  ╔═══════ \033[1mGUIDE GNOME Installer – Step 3 of 3\033[0m ════════════╗\n"
printf "  ║                                                       ║\n"
printf "  ║   This is the final step!                             ║\n"
printf "  ║   GNOME and related components will be installed.     ║\n"
printf "  ║                                                       ║\n"
printf "  ╟─▫ Installing GNOME desktop environment                ║\n"
printf "  ╟─▫ Installing desktop applications                     ║\n"
printf "  ╟─▫ Applying system and user configuration              ║\n"
printf "  ╟─▫ Enabling autostart and services                     ║\n"
printf "  ╟─▫ Cleaning temporary install files                    ║\n"
printf "  ║                                                       ║\n"
printf "  ╙───────────────────────────────────────────────────────╜\n"
printf "\n\n"
sleep 1
printf "    ▹ Press [\033[1mENTER\033[0m] to continue with Step 3, \n"
printf "      or [\033[1mCtrl\033[0m+\033[1mC\033[0m] to cancel the installation: "
read -r STEP_INPUT

printf "\n\n"
clear

# --- Root Execution Block ---
sudo bash <<'ROOT'

REAL_USER="$SUDO_USER" && \
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6) && \

# (optioneel maar slim) hard falen als het leeg is
[ -n "$REAL_USER" ] && [ -n "$REAL_HOME" ] && [ -d "$REAL_HOME" ] && \

apt-mark manual gnome-shell || true && \
apt update && apt install --ignore-missing -y \
  gnome-core \
  yaru-theme-{gnome-shell,gtk,icon,sound,unity} \
  fonts-ubuntu fonts-ubuntu-{title,console} ttf-mscorefonts-installer \
  rpi-chromium-mods chromium chromium-common chromium-driver chromium-l10n gnome-browser-connector \
  rhythmbox rhythmbox-plugins rhythmbox-plugin-alternative-toolbar vlc vlc-l10n vlc-plugin-access-extra vlc-plugin-video-output vlc-plugin-skins2 \
  gstreamer1.0-plugins-{base,good,bad,ugly} gstreamer1.0-{libav,tools,alsa,pulseaudio,x,gl,vaapi,pipewire} libwidevinecdm0 ffmpeg  libavcodec-extra vainfo libavcodec-extra61 ffmpegthumbnailer \
  libreoffice-{writer,calc,impress,gtk3,gnome} \
  gnome-text-editor simple-scan hplip file-roller \
  network-manager-openvpn-gnome wireguard wireguard-tools \
  gnome-tweaks gnome-calendar gnome-weather \
  plymouth plymouth-themes gnome-shell-extension-dashtodock gnome-shell-extension-desktop-icons-ng gnome-shell-extensions \
  dbus-x11 || true && \
mkdir -p /etc/skel/.config/autostart /etc/dconf/db/local.d && mkdir -p "$REAL_HOME/.config/autostart" && \
echo -e 'user-db:user\nsystem-db:local' | tee /etc/dconf/profile/user >/dev/null && \
sh -c 'mkdir -p /etc/skel/.config/autostart && printf %b "#!/bin/bash\n\n# Nautilus & File Chooser\ngsettings set org.gtk.Settings.FileChooser sort-directories-first true\ngsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true\ngsettings set org.gnome.nautilus.preferences sort-directories-first true\ngsettings set org.gnome.nautilus.preferences default-folder-viewer '\''list-view'\''\ngsettings set org.gnome.nautilus.list-view use-tree-view true\n\n# Desktop Icons (DING)\ngsettings set org.gnome.shell.extensions.ding icon-size '\''small'\''\ngsettings set org.gnome.shell.extensions.ding show-home true\ngsettings set org.gnome.shell.extensions.ding show-trash true\ngsettings set org.gnome.shell.extensions.ding show-volumes false\ngsettings set org.gnome.shell.extensions.ding show-network-volumes false\n\n# General GNOME\ngsettings set org.gnome.calculator refresh-interval 0\ngsettings set org.gnome.mutter dynamic-workspaces false\ngsettings set org.gnome.desktop.wm.preferences num-workspaces 2\ngsettings set org.gnome.desktop.background picture-uri \"file:///usr/share/backgrounds/gnome/blobs-l.svg\"\ngsettings set org.gnome.desktop.background picture-uri-dark \"file:///usr/share/backgrounds/gnome/blobs-d.svg\"\ngsettings set org.gnome.desktop.background primary-color \"#241f31\"\ngsettings set org.gnome.desktop.interface accent-color \"orange\"\ngsettings set org.gnome.desktop.interface gtk-theme \"Yaru\"\ngsettings set org.gnome.desktop.interface icon-theme \"Yaru\"\ngsettings set org.gnome.desktop.interface cursor-theme \"Yaru\"\ngsettings set org.gnome.shell.extensions.user-theme name \"Yaru\"\n\n# Enabled Extensions\ngsettings set org.gnome.shell enabled-extensions \"['\''dash-to-dock@micxgx.gmail.com'\'','\''ding@rastersoft.com'\'','\''user-theme@gnome-shell-extensions.gcampax.github.com'\'','\''gnome-fuzzy-app-search@gnome-shell-extensions.Czarlie.gitlab.com'\'','\''add-to-desktop@tommimon.github.com'\'']\"\n\n# Favorites\ngsettings set org.gnome.shell favorite-apps \"['\''chromium.desktop'\'','\''org.gnome.Nautilus.desktop'\'','\''libreoffice-writer.desktop'\'','\''org.gnome.Software.desktop'\'','\''yelp.desktop'\'','\''org.gnome.Settings.desktop'\'']\"\n\n# Start Chromium tmp\nchromium --no-startup-window --user-data-dir=\"\$HOME/.config/chromium\" --no-first-run --no-default-browser-check >/dev/null 2>&1 &\n\n# Wait for Preferences\nPREF=\"\$HOME/.config/chromium/Default/Preferences\"\nfor i in {1..400}; do\n  [ -f \"\$PREF\" ] && break\n  sleep 0.05\ndone\n\n# Change Preferences\nperl -MJSON::PP -0777 -i -e '\''\n  my \$f = shift;\n\n  open my \$in, \"<\", \$f or exit 0;\n  local \$/; my \$txt = <\$in>;\n  close \$in;\n\n  my \$j = eval { decode_json(\$txt) } || {};\n\n  # extensions.theme.system_theme = 0\n  \$j->{extensions} = {} unless ref(\$j->{extensions}) eq \"HASH\";\n  \$j->{extensions}{theme} = {} unless ref(\$j->{extensions}{theme}) eq \"HASH\";\n  \$j->{extensions}{theme}{system_theme} = 0;\n\n  # browser.theme = {\"is_grayscale2\": true}\n  \$j->{browser} = {} unless ref(\$j->{browser}) eq \"HASH\";\n  \$j->{browser}{theme} = { is_grayscale2 => JSON::PP::true };\n\n  open my \$out, \">\", \$f or die \"write: \$!\";\n  print \$out encode_json(\$j);\n  close \$out;\n'\'' \"\$PREF\"\n\n# Start Chromium background\nnohup chromium --no-startup-window --user-data-dir=\"\$HOME/.config/chromium\" --no-first-run --no-default-browser-check --remote-debugging-address=127.0.0.1 --remote-debugging-port=9222 >/dev/null 2>&1 </dev/null &\n\n# Make autostart\nmkdir -p \"\$HOME/.config/autostart\"\ncat > \"\$HOME/.config/autostart/chromium-autostart.desktop\" <<'\''EOF'\''\n[Desktop Entry]\nType=Application\nName=Chromium\nExec=/bin/bash -lc '\''nohup chromium --no-startup-window --user-data-dir=\"\$HOME/.config/chromium\" --no-first-run --no-default-browser-check --remote-debugging-address=127.0.0.1 --remote-debugging-port=9222 >/dev/null 2>&1 </dev/null &'\''\nIcon=chromium\nX-GNOME-Autostart-enabled=true\nNoDisplay=true\nEOF\n\n# VLC defaults\nmkdir -p \"\$HOME/.config/vlc\"\nprintf %b \"[qt]\nqt-system-tray=0\nqt-video-autoresize=0\nvideo-title-show=0\nvideo-title-timeout=0\nqt-bgcone=0\n\" > \"\$HOME/.config/vlc/vlcrc\"\nprintf %b \"[MainWindow]\nQtStyle=Fusion\nToolbarPos=false\nadv-controls=0\npl-dock-status=true\nplaylist-visible=false\nstatus-bar-visible=false\ntoolbar-profile=Trixie\nAdvToolbar=\\\"12;11;13;14;\\\"\nFSCtoolbar=\\\"20-4;65;3-4;0-2;4-4;65-4;8;\\\"\nInputToolbar=\\\"43;33-4;44;\\\"\nMainToolbar1=\\\"64;39;64;38;65;\\\"\nMainToolbar2=\\\"20;65-4;22-4;0-2;23-4;65;7;\\\"\n\n[OpenDialog]\nadvanced=false\n\" > \"\$HOME/.config/vlc/vlc-qt-interface.conf\"\n\n# Quit and remove setting.desktop and setting.sh\nrm -f \"\$HOME/.config/autostart/settings.desktop\"\nrm -- \"\$0\"\n" > /etc/skel/.config/autostart/settings.sh && chmod 755 /etc/skel/.config/autostart/settings.sh' && install -D -m 755 /etc/skel/.config/autostart/settings.sh "$REAL_HOME/.config/autostart/settings.sh" && \
sh -c 'mkdir -p /etc/skel/.config/autostart && printf %b "[Desktop Entry]\nType=Application\nName=Settings\nExec=/bin/bash -lc \"sleep 1; \$HOME/.config/autostart/settings.sh\"\nIcon=org.gnome.Nautilus\nX-GNOME-Autostart-enabled=true\nNoDisplay=true\n" > /etc/skel/.config/autostart/settings.desktop && chmod 644 /etc/skel/.config/autostart/settings.desktop' && \
install -D -m 644 /etc/skel/.config/autostart/settings.desktop "$REAL_HOME/.config/autostart/settings.desktop" && \
echo -e "[org/gnome/mutter]\nexperimental-features=['scale-monitor-framebuffer']" | tee /etc/dconf/db/local.d/01-gnome-mutter >/dev/null && \
echo -e "[org/gnome/shell]\nenabled-extensions=['dash-to-dock@micxgx.gmail.com','ding@rastersoft.com','user-theme@gnome-shell-extensions.gcampax.github.com','gnome-fuzzy-app-search@gnome-shell-extensions.Czarlie.gitlab.com','add-to-desktop@tommimon.github.com']\n\n[org/gnome/shell/extensions/dash-to-dock]\ndock-position='LEFT'\nextend-height=true\ndash-max-icon-size=64\nshow-trash=false\nintellihide-mode='ALL_WINDOWS'\nrunning-indicator-style='DOTS'\n\n[org/gnome/shell/extensions/ding]\nicon-size='small'\nshow-home=true\nshow-trash=true\nshow-volumes=false\nshow-network-volumes=false\n\n[org/gnome/shell/extensions/user-theme]\nname='Yaru'\n\n[org/gnome/shell]\nfavorite-apps=['chromium.desktop','org.gnome.Nautilus.desktop','libreoffice-writer.desktop','org.gnome.Software.desktop','yelp.desktop','org.gnome.Settings.desktop']" | tee /etc/dconf/db/local.d/02-gnome-shell >/dev/null && \
echo -e "[org/gnome/desktop/interface]\ngtk-theme='Yaru'\nicon-theme='Yaru'\ncursor-theme='Yaru'\nfont-name='Ubuntu 11'\ndocument-font-name='Ubuntu 11'\nmonospace-font-name='Ubuntu Mono 13'\n\n[org/gnome/desktop/wm/preferences]\nbutton-layout=':minimize,maximize,close'\n\n[org/gnome/desktop/background]\npicture-uri='file:///usr/share/backgrounds/gnome/blobs-l.svg'\n\n[org/gnome/desktop/interface]\nenable-hot-corners=false" | tee /etc/dconf/db/local.d/03-gnome-desktop >/dev/null && \
echo -e "[org/gnome/nautilus/preferences]\ndefault-folder-viewer='list-view'\nsort-directories-first=true\n\n[org/gtk/Settings/FileChooser]\nsort-directories-first=true\n\n[org/gtk/gtk4/Settings/FileChooser]\nsort-directories-first=true" | tee /etc/dconf/db/local.d/04-gnome-nautilus >/dev/null && \
PKGS=""; readarray -t CODES < <( { [ -f /etc/locale.gen ] && awk 'NF && $1 !~ /^#/ {print $1}' /etc/locale.gen; grep -E '^(LANG|LANGUAGE)=' /etc/default/locale 2>/dev/null | sed 's/.*=//' | tr ':' '\n'; [ -f "/var/lib/AccountsService/users/$(id -un)" ] && awk -F= '/^Language=/{print $2}' "/var/lib/AccountsService/users/$(id -un)"; [ -n "${LANG:-}" ] && echo "$LANG"; [ -n "${LANGUAGE:-}" ] && printf '%s\n' $LANGUAGE; } | sed -E 's/[[:space:]]+//g' | sed -E 's/[.@].*$//' | awk 'NF{gsub("_","-"); print tolower($0)}' | awk '!seen[$0]++' ); echo "Detected languages: ${CODES[*]}"; WANT=(hunspell hyphen libreoffice-l10n libreoffice-help); for code in "${CODES[@]}"; do echo "➡ Language: $code"; L="${code%%-*}"; for typ in "${WANT[@]}"; do if [ "$typ" = "libreoffice-l10n" ] && [ "$code" = "en-us" ]; then echo "  ↷ skip $typ for en-us"; continue; fi; found=""; for cand in "$typ-$code" "$typ-$L"; do if apt-cache show "$cand" >/dev/null 2>&1 && ! apt-cache policy "$cand" | grep -q 'Candidate: (none)'; then found="$cand"; break; fi; done; if [ -z "$found" ]; then while read -r alt; do [[ -z "$alt" ]] && continue; [[ "$alt" =~ ^$typ- ]] || continue; if apt-cache policy "$alt" | grep -qv 'Candidate: (none)'; then found="$alt"; break; fi; done < <(apt-cache search "^$typ-$L-" | awk '{print $1}'); fi; if [ -n "$found" ]; then case " $PKGS " in *" $found "* ) : ;; * ) PKGS+=" $found"; echo "  ✔ $typ → $found";; esac; else echo "  ⚠ No package found for $typ ($code)"; fi; done; done; if [ -n "$PKGS" ]; then echo "Installing:$PKGS"; apt-get update -y >/dev/null 2>&1 || true; for p in $PKGS; do if apt-cache madison "$p" 2>/dev/null | grep -q .; then apt-get install -y "$p" || true; else echo "  ⚠ Skip without candidate: $p"; fi; done; echo "Done."; else echo "Nothing to do."; fi; (dpkg -l locales-all 2>/dev/null | grep -q '^ii' && echo "ℹ 'locales-all' is installed; we deliberately avoid 'locale -a'.") || true && \
wget -O /tmp/gnome-fuzzy-app-search.zip https://extensions.gnome.org/extension-data/gnome-fuzzy-app-searchgnome-shell-extensions.Czarlie.gitlab.com.v26.shell-extension.zip && rm -rf /usr/share/gnome-shell/extensions/gnome-fuzzy-app-search@gnome-shell-extensions.Czarlie.gitlab.com && unzip -o /tmp/gnome-fuzzy-app-search.zip -d /usr/share/gnome-shell/extensions/gnome-fuzzy-app-search@gnome-shell-extensions.Czarlie.gitlab.com && chmod -R a+rX /usr/share/gnome-shell/extensions/gnome-fuzzy-app-search@gnome-shell-extensions.Czarlie.gitlab.com && \
wget -O /tmp/add-to-desktop.zip https://extensions.gnome.org/extension-data/add-to-desktoptommimon.github.com.v15.shell-extension.zip && rm -rf /usr/share/gnome-shell/extensions/add-to-desktop@tommimon.github.com && unzip -o /tmp/add-to-desktop.zip -d /usr/share/gnome-shell/extensions/add-to-desktop@tommimon.github.com && chmod -R a+rX /usr/share/gnome-shell/extensions/add-to-desktop@tommimon.github.com && \
wget -O /tmp/libreoffice_yaru-themes_2025-09-23.zip https://raw.githubusercontent.com/wobbo/libreoffice-yaru-themes/main/libreoffice_yaru-themes_2025-09-23.zip && unzip -o /tmp/libreoffice_yaru-themes_2025-09-23.zip -d /usr/lib/libreoffice/share/config/ 'images_yaru*.zip' && cd /usr/lib/libreoffice/share/config/ && for f in images_yaru*.zip; do [[ "$f" == *_dark.zip ]] && continue; mv -f "$f" "${f%.zip}_dark.zip"; done && unzip -o /tmp/libreoffice_yaru-themes_2025-09-23.zip -d /usr/lib/libreoffice/share/config/ && chmod -R a+rX /usr/lib/libreoffice/share/config/images_yaru* && ls -1 images_yaru*_dark.zip | wc -l && rm -f /tmp/libreoffice_yaru-themes_2025-09-23.zip && cd ~ && \
tmpdir=$(mktemp -d); cd "$tmpdir"; wget https://github.com/wobbo/yaru-themes-debian-trixie/releases/download/v1/yaru-theme-gnome-shell_25.04.1-0ubuntu1_all.deb https://github.com/wobbo/yaru-themes-debian-trixie/releases/download/v1/yaru-theme-gtk_25.04.1-0ubuntu1_all.deb https://github.com/wobbo/yaru-themes-debian-trixie/releases/download/v1/yaru-theme-icon_25.04.1-0ubuntu1_all.deb https://github.com/wobbo/yaru-themes-debian-trixie/releases/download/v1/yaru-theme-sound_25.04.1-0ubuntu1_all.deb https://github.com/wobbo/geary-44.1-for-debian-trixie-arm64/raw/main/geary_44.1-1wobbo1_arm64_20251202.deb; apt-mark unhold yaru-theme-gnome-shell yaru-theme-gtk yaru-theme-icon yaru-theme-sound geary || true && apt install -y ./yaru-theme-*.deb ./geary_44.1-1wobbo1_arm64_20251202.deb && apt-mark hold yaru-theme-gnome-shell yaru-theme-gtk yaru-theme-icon yaru-theme-sound geary && apt-mark hold yaru-theme-gnome-shell yaru-theme-gtk yaru-theme-icon yaru-theme-sound geary; apt-cache policy geary | grep Installed; cd ~; rm -rf "$tmpdir" && \
wget -O /usr/local/bin/gnome-auto-yaru.sh https://raw.githubusercontent.com/wobbo/yaru-themes-debian-trixie/main/gnome-auto-yaru_2025-10-07.sh && chmod 755 /usr/local/bin/gnome-auto-yaru.sh && wget -O /etc/systemd/user/gnome-auto-yaru.service https://raw.githubusercontent.com/wobbo/yaru-themes-debian-trixie/main/gnome-auto-yaru_2025-10-07.service && chmod 644 /etc/systemd/user/gnome-auto-yaru.service && \
sh -c 'printf %b "#!/bin/bash\nsed -i '\''s/^StartupNotify=true/StartupNotify=false/'\'' /usr/share/applications/chromium.desktop\n" > /usr/local/bin/fix_chromium_notify.sh' && chmod 755 /usr/local/bin/fix_chromium_notify.sh && sh -c 'printf %b "[Unit]\nDescription=Fix Chromium.desktop StartupNotify\nAfter=network.target\n[Service]\nType=oneshot\nExecStart=/usr/local/bin/fix_chromium_notify.sh\nRemainAfterExit=true\n[Install]\nWantedBy=multi-user.target\n" > /etc/systemd/system/fix-chromium-notify.service' && chmod 644 /etc/systemd/system/fix-chromium-notify.service && \
cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup && \
dconf update && printf "[Daemon]\nTheme=spinner\nShowDelay=0\n" | tee /etc/plymouth/plymouthd.conf >/dev/null && plymouth-set-default-theme spinner && cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup && grep -q 'plymouth.ignore-serial-consoles' /boot/firmware/cmdline.txt || sed -i '1 s/^/quiet splash plymouth.ignore-serial-consoles vt.global_cursor_default=0 /' /boot/firmware/cmdline.txt && update-initramfs -u -k all && \
awk 'BEGIN{sec="";aw=0;pw=0} function ov(l){return l ~ /^\s*#?\s*dtoverlay=vc4-.*v3d/} { if($0 ~ /^\s*\[/){ if(sec=="[all]"&&!aw){print "dtoverlay=vc4-kms-v3d\n";aw=1} if(sec=="[pi5]"&&!pw){print "dtoverlay=vc4-kms-v3d-pi5\n";pw=1} sec=$0; if(NR>1 && prev!~"^$") print ""; print; prev=$0; next } if(ov($0)) next; print; prev=$0; next } END{ if(sec=="[all]"&&!aw){print "dtoverlay=vc4-kms-v3d\n";aw=1} if(sec=="[pi5]"&&!pw){print "dtoverlay=vc4-kms-v3d-pi5\n";pw=1} if(!aw){print "[all]\ndtoverlay=vc4-kms-v3d\n"} if(!pw){print "[pi5]\ndtoverlay=vc4-kms-v3d-pi5\n"} }' /boot/firmware/config.txt | tee /boot/firmware/config.txt.tmp >/dev/null && cp -a /boot/firmware/config.txt /boot/firmware/config.txt.bak && mv /boot/firmware/config.txt.tmp /boot/firmware/config.txt && \
apt remove -y firefox firefox-esr im-config showtime totem mpv htop && apt autoremove -y && \
systemctl daemon-reload && systemctl enable --global gnome-auto-yaru.service && systemctl enable --now fix-chromium-notify.service && systemctl set-default graphical.target && \
sed -i '/^logo=/ s/^/#/' /etc/gdm3/greeter.dconf-defaults && \





# VLC als default voor media MIME types (system + current user + new users)
install -d -m 0755 /etc/xdg /etc/skel/.config "$REAL_HOME/.config" /usr/local/share/applications /usr/local/bin && \
MIMEAPPS_VLC_CONTENT='[Default Applications]
video/mp4=vlc.desktop
video/x-matroska=vlc.desktop
video/webm=vlc.desktop
video/quicktime=vlc.desktop
video/mpeg=vlc.desktop
video/x-msvideo=vlc.desktop
audio/mpeg=vlc.desktop
audio/mp4=vlc.desktop
audio/flac=vlc.desktop
audio/ogg=vlc.desktop
audio/x-wav=vlc.desktop
audio/opus=vlc.desktop
' && \
printf "%s" "$MIMEAPPS_VLC_CONTENT" > /etc/xdg/mimeapps.list && \
printf "%s" "$MIMEAPPS_VLC_CONTENT" > /etc/skel/.config/mimeapps.list && \
printf "%s" "$MIMEAPPS_VLC_CONTENT" > "$REAL_HOME/.config/mimeapps.list" && \
chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/mimeapps.list" && \

SRC="/usr/share/applications/vlc.desktop" && \
DST="/usr/local/share/applications/vlc.desktop" && \
NEW_ICON="applications-multimedia" && \
tmp="$(mktemp)" && \
install -m 0644 "$SRC" "$DST" && \
awk -v newicon="$NEW_ICON" '
BEGIN { FS=OFS="=" }
$1=="Name" || $1 ~ /^Name\[/ {
    name=$2
    gsub(/(^| )VLC( |$)/, " ", name)
    gsub(/  +/, " ", name)
    sub(/^ /,"",name)
    sub(/ $/,"",name)
    gsub(/media player/, "Media player", name)
    print $1, name
    next
}
$1=="Icon" {
    print "Icon", newicon
    next
}
{ print }
' "$DST" > "$tmp" && \
install -m 0644 "$tmp" "$DST" && \
rm -f "$tmp" && \
sed -i \
  -e 's|^Exec=.*|Exec=/usr/local/bin/vlc-x11 --no-one-instance %U|' \
  -e 's|^TryExec=.*|TryExec=/usr/local/bin/vlc-x11|' \
  "$DST" && \
cat > /usr/local/bin/vlc-x11 <<'EOF'
#!/bin/sh

# Forceer X11
unset WAYLAND_DISPLAY
export QT_QPA_PLATFORM=xcb

VLC_CONFIG="$HOME/.config/vlc/vlcrc"

# Lees GNOME dark/light
scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")

# Zorg dat config bestaat
mkdir -p "$HOME/.config/vlc"
touch "$VLC_CONFIG"

# Verwijder bestaande qt-dark-palette regels
sed -i '/^qt-dark-palette=/d' "$VLC_CONFIG"
sed -i '/^#qt-dark-palette=/d' "$VLC_CONFIG"

# Zet juiste waarde
if [ "$scheme" = "prefer-dark" ]; then
    echo "qt-dark-palette=1" >> "$VLC_CONFIG"
else
    echo "qt-dark-palette=0" >> "$VLC_CONFIG"
fi

# Start VLC
exec /usr/bin/vlc --no-one-instance "$@"
EOF
chmod 0755 /usr/local/bin/vlc-x11 && \
update-desktop-database /usr/local/share/applications 2>/dev/null || true && \





chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/autostart"
ROOT

clear
echo

# --- Reboot Countdown ---
COUNT=9
while [ "$COUNT" -ge 0 ]; do
  clear
  printf \
"

  ╔═══════════ \033[1mGUIDE GNOME Installer – 3 of 3\033[0m ════════════╗
  ║                                                       ║
  ║   GNOME installation completed successfully!          ║
  ║                                                       ║
  ║   Reboot in: \033[1m%-2d\033[0m                                       ║
  ║                                                       ║
  ╙───────────────────────────────────────────────────────╜

" "$COUNT"
  sleep 1
  COUNT=$((COUNT - 1))
done

# --- Cleanup ---
rm -f "$HOME/install-gnome.sh"
rm -rf "$INSTALL_DIR"

sleep 1
sudo reboot
STEP3
chmod +x "$INSTALL_DIR/step3.sh"


# ==============================================================================
# STATE INITIALIZATION
# ==============================================================================
echo "STEP=1" > "$INSTALL_DIR/state"
chmod 600 "$INSTALL_DIR/state"


# ==============================================================================
# INSTALLER CONTROLLER REPLACEMENT
# ==============================================================================

# 1. Safety Measure: Rename this running script
# This frees up the name "install-gnome.sh" to be overwritten
# without crashing the currently running process.
mv "$0" "$0.bootstrap_backup" 2>/dev/null || true

# 2. Write the NEW controller (the one the user will interact with)
cat > "./install-gnome.sh" <<'EOF'
#!/usr/bin/env bash
set -e

# Controller Logic
INSTALL_DIR="$HOME/.install_gnome"
STATE_FILE="$INSTALL_DIR/state"

if [ ! -f "$STATE_FILE" ]; then
  printf "Installer state not found.\n"
  exit 1
fi

source "$STATE_FILE"

printf "\n\n"
printf "  ╔════════════════ \033[1mGUIDE GNOME Installer\033[0m ════════════════╗\n"
printf "  ║                                                       ║\n"
printf "  ║   Current step: $STEP of 3                                ║\n"
printf "  ║                                                       ║\n"
printf "  ║                                                       ║\n"
printf "  ║   Enter a step number \033[1m1\033[0m-\033[1m3\033[0m to jump to that step,       ║\n"
printf "  ║   press \033[1mENTER\033[0m to continue with the current step       ║\n"
printf "  ║   or \033[1mCtrl\033[0m+\033[1mC\033[0m to cancel installer.                      ║\n"
printf "  ║                                                       ║\n"
printf "  ║  [\033[1m1\033[0m] Sets user identity and system language.          ║\n"
printf "  ║  [\033[1m2\033[0m] Updates system, kernel, and firmware.            ║\n"
printf "  ║  [\033[1m3\033[0m] Installs GNOME desktop, themes, and apps.        ║\n"
printf "  ║                                                       ║\n"
printf "  ╙───────────────────────────────────────────────────────╜\n"
printf "\n"
sleep 1
printf "    ▹ Press [\033[1mENTER\033[0m] to continue with Step $STEP, \n"
printf "      or [\033[1mCtrl\033[0m+\033[1mC\033[0m] to cancel the installation, \n"
printf "      or select Step [\033[1m1-3\033[0m]: "
read -r STEP_INPUT

if [[ -n "$STEP_INPUT" ]]; then
  case "$STEP_INPUT" in
    1|2|3)
      STEP="$STEP_INPUT"
      ;;
    *)
      printf "\n"
      printf "    ▹ Only option [\033[1mENTER\033[0m], [\033[1mCtrl\033[0m+\033[1mC\033[0m], [\033[1m1\033[0m], [\033[1m2\033[0m] or [\033[1m3\033[0m]. \n"
      printf "\n"
      exit 1
      ;;
  esac
fi

case "$STEP" in
  1) "$INSTALL_DIR/step1.sh" ;;
  2) "$INSTALL_DIR/step2.sh" ;;
  3) "$INSTALL_DIR/step3.sh" ;;
  COMPLETED)
    printf "\n"
    printf "    ▫ Installation already completed.\n"
    ;;
  *)
    printf "\n"
    printf "    ▫ Unknown installer state.\n"
    exit 1
    ;;
esac
EOF

# 3. Make the new controller executable
chmod +x ./install-gnome.sh
sleep 1
printf "    ▫ Starting installe:\n"
printf "      \033[3m$HOME/install-gnome.sh\033[0m\n"
printf "\n"

# 4. Cleanup the old bootstrap file
rm -f "$0.bootstrap_backup"

sleep 1

# 5. Hand over control to the NEW install-gnome.sh
exec ./install-gnome.sh
