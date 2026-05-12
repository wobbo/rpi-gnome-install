#!/usr/bin/env bash

# Script information.
#
# This installer prepares a full GNOME desktop experience for Raspberry Pi OS Lite.
# The date below shows the script version, and the links point to the forum thread
# and source project where updates or discussion can be found.
#
# 2026-05-12 UTC
# Ernst Lanser <ernst.lanser@wobbo.org>
# https://forums.raspberrypi.com/viewtopic.php?t=373028
# https://github.com/wobbo/rpi-gnome-install

# WARNING.
#
# Run this script only on a fresh Raspberry Pi OS Lite installation.
# The installer changes system packages, desktop settings, services, and user
# configuration. Running it on an already customized system may overwrite choices
# or create conflicts that are harder to undo later.

# Manual download and start.
#
# Use these commands when you want to download the installer first, make it
# executable, and then start it manually from the terminal.
#
# wget -O install-gnome.sh https://wobbo.org/install/2026-05-12/install-gnome.sh
# chmod +x install-gnome.sh
# ./install-gnome.sh

# All-in-one SSH command.
#
# This removes an older local installer and temporary installer folder, downloads
# a fresh copy, makes it executable, and starts it. It is useful when installing
# through SSH and you want one copy-paste command.
#
# rm -f ./install-gnome.sh && rm -rf ./.install_gnome && wget https://wobbo.org/install/2026-05-12/install-gnome.sh && chmod +x install-gnome.sh && ./install-gnome.sh

# Stop immediately when a command fails.
#
# This keeps the installer from continuing after an important error. Without this,
# a failed package command or missing file could be ignored and the script might
# continue in a broken state.
set -e






# Ask for administrator access at the start.
#
# Most installation steps need sudo. Asking here makes the requirement clear before
# the installer starts creating files or changing the system.
clear
printf "\n"
printf '\033[1mInstall GNOME on Raspberry Pi\033[0m\n'
printf "Administrator privileges required.\n"
printf "\n"
sudo -v
clear





# Make sure whiptail is available.
#
# Whiptail is used for the text-based menus and message boxes. Raspberry Pi OS
# Lite may not have it installed yet, so the installer installs it automatically
# before showing the main menus.
if ! command -v whiptail >/dev/null 2>&1; then
    printf "\n"
    printf "  The package \033[1mwhiptail\033[0m is not found. Installing...\n"
    printf "\n"

    sudo apt update
    sudo apt install -y whiptail

    if ! command -v whiptail >/dev/null 2>&1; then
        printf "  Failed to install \033[1mwhiptail\033[0m.\n"
        exit 1
    fi
fi
clear







# Installer state directory and files.
#
# The installer is split into multiple steps and reboots between them. These files
# let the main script remember where it should continue and which choices the user
# made earlier.
#
# INSTALL_DIR   stores temporary installer data in the user's home folder.
# STATE_FILE    stores the next step to run after reboot.
# OPTIONAL_FILE stores optional software selected in Step 2.
# DESKTOP_FILE  stores the selected desktop style.
INSTALL_DIR="$HOME/.install_gnome"
STATE_FILE="$INSTALL_DIR/state"
OPTIONAL_FILE="$INSTALL_DIR/optional"
DESKTOP_FILE="$INSTALL_DIR/desktop"

# Create a private installer workspace.
#
# The folder stores generated step scripts and small state files. Permission 700
# means only the current user can read, write, or enter this directory.
mkdir -p "$INSTALL_DIR"
chmod 700 "$INSTALL_DIR"



















# ==============================================================================
# GENERATE STEP 1: User Identity & Locale
# ==============================================================================
# This creates the script that will run Step 1 later.
#
# Step 1 asks for the user's display name and configures locale settings. It is
# generated as a separate script so the installer can reboot and then continue
# cleanly from the next step.
cat > "$INSTALL_DIR/step1.sh" <<'EOF'
#!/usr/bin/env bash
set -e

clear
printf "\n"
printf '\033[1mInstall GNOME on Raspberry Pi - Step 1 of 3\033[0m\n'
printf "Administrator privileges required.\n"
printf "\n"
sudo -v
clear




# Step 1 state files.
#
# Step 1 only needs the installer directory and state file. After it finishes
# successfully, it writes STEP=2 so the main installer knows what to run after
# the reboot.
INSTALL_DIR="$HOME/.install_gnome"
STATE_FILE="$INSTALL_DIR/state"




# Read the current full name from the user account.
#
# Linux stores a human-readable full name in the account information. This value
# is used as the default text in the dialog, so the user can keep it or change it.
CURRENT_FULLNAME="$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1)"




# Ask for the display name.
#
# The display name is optional. When entered, it is shown by login screens,
# desktop tools, and applications that read the account's full name field.
FULLNAME=$(
    whiptail \
        --title "Install GNOME on Raspberry Pi - Step 1 of 3" \
        --inputbox "\

 Step 1 of 3.

 This first step configures your user identity,
 system language, and regional preferences.

 Your display name is used on the login screen,
 desktop, and supported applications.

 Language and region settings are applied to
 both the terminal environment and GNOME.

 Your user name:
 $USER

 Full name (optional):" 23 60 "$CURRENT_FULLNAME" \
        3>&1 1>&2 2>&3
)




# Handle Cancel or Back from the dialog.
#
# Whiptail returns a non-zero status when the user cancels. Exit code 2 is used
# here so the main installer can return to the previous bootstrap screen instead
# of treating it like a normal installation failure.
EXITSTATUS=$?

if [ "$EXITSTATUS" -ne 0 ]; then
    clear
    exit 2
fi




# Save the display name when one was entered.
#
# usermod -c changes the account's comment/full-name field. The username itself
# is not changed; only the human-readable display name is updated.
if [ -n "$FULLNAME" ]; then
    sudo usermod -c "$FULLNAME" "$USER"
fi




# Let the user choose system locales.
#
# This opens Debian's locale configuration tool. Locale settings control language,
# regional formatting, and character encoding for terminal programs and GNOME.
clear
sudo dpkg-reconfigure locales




# Ensure a real UTF-8 default locale before Step 2.
#
# Some systems can end up with defaults like None, C, C.UTF-8, or C.utf8. Those
# are technically valid in some contexts, but they can cause ugly or broken
# characters in whiptail and terminal screens. A real language locale, such as
# en_US.UTF-8 or nl_NL.UTF-8, is safer for this installer.
CURRENT_DEFAULT="$(
    awk -F= '/^LANG=/{print $2}' /etc/default/locale 2>/dev/null |
    sed -E 's/^"//; s/"$//'
)"




# Treat weak or missing locale values as unusable.
#
# When one of these values is found, the script clears CURRENT_DEFAULT so the
# fallback code below can choose a better UTF-8 locale.
case "$CURRENT_DEFAULT" in
    ""|"C"|"c"|"C.UTF-8"|"c.UTF-8"|"C.utf8"|"c.utf8"|"None"|"none"|"NONE")
        CURRENT_DEFAULT=""
        ;;
esac




# Find the first enabled real UTF-8 locale.
#
# The script scans /etc/locale.gen for the first uncommented UTF-8 locale that is
# not the generic C locale. This becomes the fallback default when no good default
# locale was already configured.
FIRST_REAL_LOCALE="$(
    awk '
        NF && $1 !~ /^#/ {
            loc=$1
            if (loc ~ /\.UTF-8$/ && loc !~ /^C(\.|$)/ && loc != "None") {
                print loc
                exit
            }
        }
    ' /etc/locale.gen 2>/dev/null
)"




# Create a safe fallback locale when needed.
#
# If there is no usable default and no enabled real UTF-8 locale, the script
# enables en_US.UTF-8 as a reliable fallback. This prevents Step 2 from starting
# with broken terminal text handling.
if [ -z "$CURRENT_DEFAULT" ]; then
    if [ -z "$FIRST_REAL_LOCALE" ]; then
        if grep -qxE '[[:space:]]*#[[:space:]]*en_US\.UTF-8[[:space:]]+UTF-8' /etc/locale.gen 2>/dev/null; then
            sudo sed -i -E 's|^[[:space:]]*#[[:space:]]*(en_US\.UTF-8[[:space:]]+UTF-8)$|\1|' /etc/locale.gen
        elif grep -Fxq 'en_US.UTF-8 UTF-8' /usr/share/i18n/SUPPORTED 2>/dev/null; then
            printf '%s\n' 'en_US.UTF-8 UTF-8' | sudo tee -a /etc/locale.gen >/dev/null
        fi

        FIRST_REAL_LOCALE="en_US.UTF-8"
        sudo locale-gen
    fi




    # Build LANGUAGE from the selected locale.
    #
    # LANG needs the full locale name. LANGUAGE is usually a shorter priority list,
    # for example en_US:en or nl_NL:nl, so translated programs have sensible
    # fallback choices.
    BASE_LANG="$(printf '%s\n' "$FIRST_REAL_LOCALE" | sed -E 's/[.@].*$//')"
    SHORT_LANG="${BASE_LANG%%_*}"

    # Write the default locale.
    #
    # update-locale is the normal Debian tool. If it fails for some reason, the
    # script writes /etc/default/locale directly so the system still has a usable
    # default after reboot.
    sudo update-locale LANG="$FIRST_REAL_LOCALE" LANGUAGE="${BASE_LANG}:${SHORT_LANG}" || {
        printf 'LANG=%s\nLANGUAGE=%s:%s\n' "$FIRST_REAL_LOCALE" "$BASE_LANG" "$SHORT_LANG" | sudo tee /etc/default/locale >/dev/null
    }

    echo "Default locale set to: $FIRST_REAL_LOCALE"
fi

clear




# Update state only after Step 1 succeeds.
#
# The state file is changed at the end, not at the beginning. This prevents the
# installer from skipping Step 1 after a failed or cancelled configuration.
echo "STEP=2" > "$STATE_FILE"
chmod 600 "$STATE_FILE"




# Show a reboot countdown.
#
# Locale changes are safest after a reboot. The gauge gives the user a visible
# countdown before the system restarts and tells them to run the installer again.
{
    for i in $(seq 0 10 100); do
        echo "$i"
        sleep 1
    done
} | whiptail \
    --title "System Reboot Required" \
    --gauge "\

 Step 1 completed successfully.

 The system will automatically 
 reboot in 10 seconds.

 After reboot, run:

 ./install-gnome.sh

" 15 50 0

sudo reboot
EOF
chmod +x "$INSTALL_DIR/step1.sh"










# ==============================================================================
# GENERATE STEP 2: System Settings, Updates & Optional Software
# ==============================================================================
# This creates the script that will run Step 2 later.
#
# Step 2 handles keyboard, timezone, package updates, desktop style, and optional
# software choices. It saves choices so the user can go back in the menus without
# losing selections.
cat > "$INSTALL_DIR/step2.sh" <<'EOF'
#!/usr/bin/env bash
set -e

clear
printf "\n"
printf '\033[1mInstall GNOME on Raspberry Pi - Step 2 of 3\033[0m\n'
printf "Administrator privileges required.\n"
printf "\n"
sudo -v
clear




# Step 2 state and choice files.
#
# Step 2 reads and writes the same installer files as the main script. The files
# make it possible to remember optional software and desktop style choices between
# screens and after the next reboot.
INSTALL_DIR="$HOME/.install_gnome"
STATE_FILE="$INSTALL_DIR/state"
OPTIONAL_FILE="$INSTALL_DIR/optional"
DESKTOP_FILE="$INSTALL_DIR/desktop"




# Load saved Step 2 choices.
#
# Default choices are set first. If a saved desktop file exists, valid values from
# that file replace the defaults. Invalid or unknown values are ignored so a
# damaged file does not break the menu.
load_step2_choices() {
    DESKTOP="gnome"
    FLATHUB_STATE=ON
    GAMES_STATE=ON
    GRAPHICS_STATE=OFF
    AUDIO_EDITOR_STATE=OFF
    CODE_EDITOR_STATE=OFF
    REMOTE_GAMING_STATE=OFF
    RASPBERRY_PI_STATE=OFF

    if [ -f "$DESKTOP_FILE" ]; then
        while IFS='=' read -r KEY VALUE; do
            VALUE="$(printf '%s' "$VALUE" | tr -d '[:space:]')"

            case "$KEY" in
                DESKTOP)
                    case "$VALUE" in
                        gnome|ubuntu) DESKTOP="$VALUE" ;;
                    esac
                    ;;
                FLATHUB_STATE|GAMES_STATE|GRAPHICS_STATE|AUDIO_EDITOR_STATE|CODE_EDITOR_STATE|REMOTE_GAMING_STATE|RASPBERRY_PI_STATE)
                    case "$VALUE" in
                        ON|OFF) printf -v "$KEY" '%s' "$VALUE" ;;
                    esac
                    ;;
            esac
        done < "$DESKTOP_FILE"
    fi
}




# Save Step 2 menu choices.
#
# This writes the selected desktop style and optional software states to one small
# file. The same file is read again when Step 2 is reopened, so whiptail can show
# the user's previous choices instead of starting from scratch.
save_step2_choices() {
    cat > "$DESKTOP_FILE" <<DESKTOP_EOF
DESKTOP=$DESKTOP
FLATHUB_STATE=$FLATHUB_STATE
GAMES_STATE=$GAMES_STATE
GRAPHICS_STATE=$GRAPHICS_STATE
AUDIO_EDITOR_STATE=$AUDIO_EDITOR_STATE
CODE_EDITOR_STATE=$CODE_EDITOR_STATE
REMOTE_GAMING_STATE=$REMOTE_GAMING_STATE
RASPBERRY_PI_STATE=$RASPBERRY_PI_STATE
DESKTOP_EOF
    chmod 600 "$DESKTOP_FILE"
}




# Build the optional package list.
#
# The checklist stores choices as ON or OFF values. This function translates those
# choices into real Debian package names that can be installed later in Step 3.
build_optional_packages() {
    INSTALL_PACKAGES=()

    if [ "$FLATHUB_STATE" = "ON" ]; then
        INSTALL_PACKAGES+=(
            flatpak
            gnome-software-plugin-flatpak
        )
    fi

    if [ "$GAMES_STATE" = "ON" ]; then
        INSTALL_PACKAGES+=(
            gnome-chess
            gnome-mahjongg
            gnome-mines
            gnome-sudoku
            gnome-tetravex
            supertuxkart
            0ad
            aisleriot
        )
    fi

    if [ "$GRAPHICS_STATE" = "ON" ]; then
        INSTALL_PACKAGES+=(
            gimp
            inkscape
            gcolor3
        )
    fi

    if [ "$AUDIO_EDITOR_STATE" = "ON" ]; then
        INSTALL_PACKAGES+=(
            audacity
        )
    fi

    if [ "$CODE_EDITOR_STATE" = "ON" ]; then
        INSTALL_PACKAGES+=(
            code
        )
    fi

    if [ "$REMOTE_GAMING_STATE" = "ON" ]; then
        INSTALL_PACKAGES+=(
            steamlink
        )
    fi

    if [ "$RASPBERRY_PI_STATE" = "ON" ]; then
        INSTALL_PACKAGES+=(
            rpi-imager
        )
    fi
}




# Save optional packages for Step 3.
#
# Step 3 performs the actual GNOME installation. This function saves the selected
# optional packages as one line, so Step 3 can append them to its apt install
# command without rebuilding the menu logic.
save_optional_packages() {
    build_optional_packages

    # Save as one line so Step 3 can append it to apt install.
    printf '%s\n' "${INSTALL_PACKAGES[*]}" > "$OPTIONAL_FILE"
    chmod 600 "$OPTIONAL_FILE"
}




# Show the Step 2 introduction screen.
#
# This gives the user a clear summary before system configuration starts. The
# keyboard and timezone tools are interactive, so the user should know that Step 2
# is about to change real system settings.
show_step2_intro() {
    whiptail \
        --title "Install GNOME on Raspberry Pi - Step 2 of 3" \
        --yes-button "Continue" \
        --no-button "Cancel" \
        --yesno "\

 This step will perform system updates
 and basic system preparation.

 You may be asked for your sudo password.

 The installer will:

  â€¢ Configure keyboard layout
  â€¢ Configure timezone and locale
  â€¢ Select optional software
  â€¢ Choose desktop style
  â€¢ Update package lists
  â€¢ Remove unused packages

 Continue with Step 2?
" 22 70
}




# Show optional software checklist.
#
# The user can choose extra software categories. Whiptail returns the selected
# category names, not the package names. The next function converts those category
# names back into ON and OFF state variables.
show_optional_software() {
    PACKAGE_SELECTIONS=$(
        whiptail \
            --title "Optional Software" \
            --ok-button "Continue" \
            --cancel-button "Back" \
            --checklist "\
Select additional software categories to install.

Use SPACE to toggle selections.
Use TAB to navigate.
" 18 61 7 \
            "Flathub"       "Access thousands of desktop apps"  "$FLATHUB_STATE" \
            "Games"         "Classic and 3D games from Debian"  "$GAMES_STATE"  \
            "Graphics"      "GIMP and Inkscape"                 "$GRAPHICS_STATE" \
            "Audio editor"  "Audacity"                          "$AUDIO_EDITOR_STATE" \
            "Code editor"   "Visual Studio Code"                "$CODE_EDITOR_STATE" \
            "Remote gaming" "SteamLink"                         "$REMOTE_GAMING_STATE" \
            "Raspberry Pi"  "Imager to writes SD, USB, NVMe"    "$RASPBERRY_PI_STATE" \
            3>&1 1>&2 2>&3
    )
}




# Apply optional software selections.
#
# All options are reset to OFF first, then selected items are turned back ON. This
# avoids stale choices when the user opens the checklist again and deselects an
# item that used to be enabled.
apply_optional_selection() {
    FLATHUB_STATE=OFF
    GAMES_STATE=OFF
    GRAPHICS_STATE=OFF
    AUDIO_EDITOR_STATE=OFF
    CODE_EDITOR_STATE=OFF
    REMOTE_GAMING_STATE=OFF
    RASPBERRY_PI_STATE=OFF

    if [[ "$PACKAGE_SELECTIONS" == *'"Flathub"'* ]]; then
        FLATHUB_STATE=ON
    fi
    
    if [[ "$PACKAGE_SELECTIONS" == *'"Games"'* ]]; then
        GAMES_STATE=ON
    fi

    if [[ "$PACKAGE_SELECTIONS" == *'"Graphics"'* ]]; then
        GRAPHICS_STATE=ON
    fi

    if [[ "$PACKAGE_SELECTIONS" == *'"Audio editor"'* ]]; then
        AUDIO_EDITOR_STATE=ON
    fi

    if [[ "$PACKAGE_SELECTIONS" == *'"Code editor"'* ]]; then
        CODE_EDITOR_STATE=ON
    fi

    if [[ "$PACKAGE_SELECTIONS" == *'"Remote gaming"'* ]]; then
        REMOTE_GAMING_STATE=ON
    fi

    if [[ "$PACKAGE_SELECTIONS" == *'"Raspberry Pi"'* ]]; then
        RASPBERRY_PI_STATE=ON
    fi

    save_step2_choices
    save_optional_packages
}




# Show desktop style selection.
#
# Both choices install GNOME. The difference is the dock layout: a more standard
# GNOME-style bottom dock or an Ubuntu-style left dock.
show_desktop_style() {
    GNOME_DESKTOP_STATE=ON
    UBUNTU_DESKTOP_STATE=OFF

    if [ "$DESKTOP" = "ubuntu" ]; then
        GNOME_DESKTOP_STATE=OFF
        UBUNTU_DESKTOP_STATE=ON
    fi

    DESKTOP_STYLE_SELECTION=$(
        whiptail \
            --title "Desktop Style" \
            --ok-button "Continue" \
            --cancel-button "Back" \
            --radiolist "\
Choose your desktop style.

The only difference is the dock position.

GNOME style places the dock at the bottom.
Ubuntu style places the dock on the left.

" 17 60 2 \
            "gnome"  "GNOME style - bottom dock, centered icons" "$GNOME_DESKTOP_STATE" \
            "ubuntu" "Ubuntu style - left dock" "$UBUNTU_DESKTOP_STATE" \
            3>&1 1>&2 2>&3
    )
}




# Apply the selected desktop style.
#
# Only known values are accepted. If whiptail somehow returns something else, the
# installer falls back to the GNOME-style layout.
apply_desktop_selection() {
    case "$DESKTOP_STYLE_SELECTION" in
        gnome|ubuntu) DESKTOP="$DESKTOP_STYLE_SELECTION" ;;
        *) DESKTOP="gnome" ;;
    esac

    save_step2_choices
    save_optional_packages
}




# Step 2 screen flow control.
#
# Step 2 has multiple screens and supports Back navigation. SYSTEM_CONFIG_DONE
# prevents keyboard and timezone configuration from running again when the user
# moves back and forward inside the Step 2 menus.
SYSTEM_CONFIG_DONE=0
STEP2_SCREEN="intro"




# Prepare saved choices before showing menus.
#
# The installer loads any previous Step 2 choices and writes the optional package
# file immediately. This keeps Step 3 safe even when the user keeps all default
# choices without changing the checklist.
load_step2_choices
save_optional_packages




# Step 2 menu loop.
#
# This loop moves between intro, optional software, and desktop style screens.
# Back buttons change STEP2_SCREEN instead of exiting, so the user can review
# choices before the package update starts.
while true; do
    case "$STEP2_SCREEN" in
        intro)
            if ! show_step2_intro; then
                clear
                exit 1
            fi

            if [ "$SYSTEM_CONFIG_DONE" -eq 0 ]; then
                clear
                sudo dpkg-reconfigure keyboard-configuration
                clear
                sudo dpkg-reconfigure tzdata
                clear
                SYSTEM_CONFIG_DONE=1
            fi

            STEP2_SCREEN="optional"
            ;;

        optional)
            set +e
            show_optional_software
            EXITSTATUS=$?
            set -e

            if [ "$EXITSTATUS" -ne 0 ]; then
                STEP2_SCREEN="intro"
                continue
            fi

            apply_optional_selection
            STEP2_SCREEN="desktop"
            ;;

        desktop)
            set +e
            show_desktop_style
            EXITSTATUS=$?
            set -e

            if [ "$EXITSTATUS" -ne 0 ]; then
                STEP2_SCREEN="optional"
                continue
            fi

            apply_desktop_selection
            break
            ;;
    esac
done




# Update the base system.
#
# GNOME is installed in Step 3, but the base Raspberry Pi OS system is updated
# first. This reduces package conflicts and removes unused packages before the
# larger desktop install begins.
clear
sudo apt update
sudo apt -y upgrade
sudo apt autoremove -y




# Update state only after Step 2 succeeds.
#
# The state file is changed at the end, not at the beginning. This prevents the
# installer from skipping Step 2 if system updates or menu choices fail.
echo "STEP=3" > "$STATE_FILE"
chmod 600 "$STATE_FILE"




# Show a reboot countdown.
#
# Step 3 installs the full desktop, so the system reboots first after Step 2. This
# makes sure package updates and system configuration are fully applied.
{
    for i in $(seq 0 10 100); do
        echo "$i"
        sleep 1
    done
} | whiptail \
    --title "System Reboot Required" \
    --gauge "\

 Step 2 completed successfully.

 The system will automatically 
 reboot in 10 seconds.

 After reboot, run:

 ./install-gnome.sh

" 15 50 0

sudo reboot
EOF
chmod +x "$INSTALL_DIR/step2.sh"
















# ==============================================================================
# GENERATE STEP 3: GNOME Installation
# ==============================================================================
# This creates the script that will run Step 3 later.
#
# Step 3 performs the actual desktop installation. It installs GNOME, desktop
# applications, themes, extensions, browser defaults, language support, services,
# boot splash settings, media defaults, and final cleanup. This is the largest
# step because it turns the prepared Lite system into the finished desktop.
cat > "$INSTALL_DIR/step3.sh" <<'STEP3'
#!/usr/bin/env bash
set -e

clear
printf "\n"
printf '\033[1mInstall GNOME on Raspberry Pi - Step 3 of 3\033[0m\n'
printf "Administrator privileges required.\n"
printf "\n"
sudo -v
clear




# Step 3 state files.
#
# Step 3 uses the installer directory to read saved choices from Step 2 and to
# remove temporary installer files after GNOME has been installed successfully.
INSTALL_DIR="$HOME/.install_gnome"
STATE_FILE="$INSTALL_DIR/state"




# Show the final confirmation screen.
#
# This is the last chance for the user to cancel before the installer downloads
# packages, changes system-wide settings, enables services, and removes temporary
# installer files.
if ! whiptail \
    --title "Install GNOME on Raspberry Pi - Step 3 of 3" \
    --yes-button "Continue" \
    --no-button "Cancel" \
    --yesno "\

 This is the final step.

 GNOME and related components will
 now be installed.

 The installer will:

  â€¢ Install the GNOME desktop
  â€¢ Install desktop applications
  â€¢ Install optional software
  â€¢ Apply system configuration
  â€¢ Enable autostart and services
  â€¢ Remove temporary install files

 Continue with Step 3?
" 24 60
then
    clear
    exit 1
fi




# Start the installation phase.
#
# From here on, the script runs the large system installation. The screen is
# cleared so package output starts from a clean terminal.
clear






# Root execution block.
#
# Most Step 3 actions change system files, install packages, or enable services.
# They are grouped inside one root shell so the user does not need to prefix every
# command with sudo. The block still keeps track of the real desktop user, because
# some settings must be written to that user's home folder instead of root's home.
#
# Inside this block the script reads the desktop style and optional package list
# from Step 2, installs the desktop packages, writes GNOME defaults, installs
# extra shell extensions, configures language support, enables services, sets VLC
# as the media default, and prepares the first-login settings script.






# --- Root Execution Block ---
sudo bash <<'ROOT'

# Root installation block.
#
# Everything in this heredoc runs as root. It installs GNOME, writes system-wide
# defaults, creates first-login setup files, enables services, and prepares the
# system to boot into the graphical desktop.



# Detect the real user and home folder.
#
# This block runs as root, but many settings must be written for the normal user
# who started the installer. SUDO_USER gives that username, and getent is used to
# read the correct home directory from the system account database.
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
#    â†’ do nothing
#
# 2. Locale exists but is commented:
#      # nl_NL.UTF-8 UTF-8
#    â†’ uncomment it
#
# 3. Locale is supported but missing from the file:
#    â†’ append it
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
        echo "  âœ” enabled locale: $line"
        changed=1
        return 0
    fi

    # Missing from /etc/locale.gen.
    #
    # Only add it when Debian lists it as supported.
    if supported_utf8_locale "$loc"; then
        printf '%s\n' "$line" >> /etc/locale.gen
        echo "  âœ” added locale: $line"
        changed=1
    else
        echo "  âš  unsupported locale skipped: ${loc}.UTF-8"
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

    echo "  âœ” default locale set: LANG=$DEFAULT_LOCALE"
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
    echo "â„¹ LibreOffice is not installed; skipping LibreOffice language/help packages."
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
    echo "âž¡ Language: $code"
    L="${code%%-*}"

    for typ in "${WANT[@]}"; do
        # LibreOffice does not need a separate l10n package for en-us in this
        # context, so skip that specific combination.
        if [ "$typ" = "libreoffice-l10n" ] && [ "$code" = "en-us" ]; then
            echo "  â†· skip $typ for en-us"
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
                    echo "  âœ” $typ â†’ $found"
                    ;;
            esac
        else
            echo "  âš  No package found for $typ ($code)"
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
            echo "  âš  Skip without candidate: $p"
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
(dpkg -l locales-all 2>/dev/null | grep -q '^ii' && echo "â„¹ 'locales-all' is installed; we deliberately avoid 'locale -a'.") || true
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
ROOT




# Return to the normal user shell.
#
# The root block has finished. From here on, the script only shows the final
# reboot message, removes temporary installer files, and restarts the system.
clear
echo




# Final reboot countdown.
#
# GNOME and the system services are now installed, but the new graphical desktop
# is safest to start after a clean reboot. The countdown gives the user a moment
# to read the completion message before the restart.
{
    for i in $(seq 0 10 100); do
        echo "$i"
        sleep 1
    done
} | whiptail \
    --title "System Reboot Required" \
    --gauge "\

 GNOME installation completed successfully.

 The system will automatically 
 reboot in 10 seconds.

" 13 50 0




# Remove temporary installer files.
#
# The downloaded controller script and the ~/.install_gnome workspace are no
# longer needed after Step 3 has completed. Removing them prevents the installer
# from being started again accidentally on the finished system.
rm -f "$HOME/install-gnome.sh"
rm -rf "$INSTALL_DIR"




# Reboot into the finished GNOME desktop.
#
# A short pause gives the cleanup commands time to finish before the system is
# restarted. After reboot, the graphical target and GNOME services should start.
sleep 1
sudo reboot
STEP3
chmod +x "$INSTALL_DIR/step3.sh"











# ==============================================================================
# STATE INITIALIZATION
# ==============================================================================
# Create a fresh installer state.
#
# A fresh bootstrap run always starts at Step 1 and resets saved choices to their
# defaults. The generated step scripts above are already overwritten by cat > ...,
# so this section only needs to reset the small state and choice files.
echo "STEP=1" > "$STATE_FILE"
chmod 600 "$STATE_FILE"

: > "$OPTIONAL_FILE"
chmod 600 "$OPTIONAL_FILE"




# Write the default Step 2 choices.
#
# These defaults are used the first time Step 2 opens. They can still be changed
# by the user in the optional software and desktop style menus.
cat > "$DESKTOP_FILE" <<'DESKTOP_EOF'
DESKTOP=gnome
FLATHUB_STATE=ON
GAMES_STATE=ON
GRAPHICS_STATE=OFF
AUDIO_EDITOR_STATE=OFF
CODE_EDITOR_STATE=OFF
REMOTE_GAMING_STATE=OFF
RASPBERRY_PI_STATE=OFF
DESKTOP_EOF
chmod 600 "$DESKTOP_FILE"














# ==============================================================================
# INSTALLER CONTROLLER REPLACEMENT
# ==============================================================================
# Replace the bootstrap script with a smaller controller.
#
# The first downloaded script is a bootstrapper: it creates the step scripts and
# state files. After that work is done, it replaces itself with a controller that
# reads the state file and runs the correct step after each reboot.

mv "$0" "$0.bootstrap_backup" 2>/dev/null || true




# Write the controller script.
#
# From this point on, ./install-gnome.sh no longer generates files. It simply
# shows the correct menu and starts step1.sh, step2.sh, or step3.sh based on the
# saved installer state.
cat > "./install-gnome.sh" <<'EOF'
#!/usr/bin/env bash
set -e

start_sudo_keepalive() {
    sudo -v

    while true; do
        sudo -n -v 2>/dev/null || exit
        sleep 60
    done &

    SUDO_KEEPALIVE_PID="$!"
    trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
}




# Ask for administrator access before running any step.
#
# The controller itself mostly reads files and starts step scripts, but those step
# scripts need sudo. Asking here keeps the behaviour consistent after every reboot.
clear
printf "\n"
printf '\033[1mInstall GNOME on Raspberry Pi\033[0m\n'
printf "Administrator privileges required.\n"
printf "\n"
start_sudo_keepalive
clear




# Controller state files.
#
# The controller only needs the installer directory and the state file. The state
# file tells it which step is available next.
INSTALL_DIR="$HOME/.install_gnome"
STATE_FILE="$INSTALL_DIR/state"




# Load the current installer state.
#
# The state file is created by the bootstrap script and updated at the end of each
# successful step. If it is missing, the controller cannot safely guess what to do.
load_state() {
    if [ ! -f "$STATE_FILE" ]; then
        whiptail \
            --title "Install GNOME on Raspberry Pi" \
            --msgbox "Installer state not found." 10 45
        exit 1
    fi

    # shellcheck disable=SC1090
    source "$STATE_FILE"
}




# Show the welcome screen.
#
# This is the first screen users see during a fresh install. It explains the goal
# of the installer before any step script is started.
show_welcome() {
    whiptail \
        --title "Install GNOME on Raspberry Pi" \
        --yes-button "Continue" \
        --no-button "Cancel" \
        --yesno "\
 Welcome to the GUIDE GNOME Installer.

 Transform your Raspberry Pi 4/5 into a sleek,
 Ubuntu-styled workstation.

 Built on Debian 13 using Raspberry Pi packages
 for optimal hardware usage, video codecs, and a
 fully accelerated Chromium browser.

 Refined with Wobbe exclusives like the
 Yaru theme and a patched Geary client.

 Raspberry Pi Forum:
 https://forums.raspberrypi.com/viewtopic.php?t=373028

 GitHub:
 https://github.com/wobbo/rpi-gnome
" 25 60
}




# Show the bootstrap explanation screen.
#
# This screen explains which temporary files were created. It is shown only during
# the first run, before Step 1 starts.
show_bootstrap() {
    whiptail \
        --title "Install GNOME on Raspberry Pi" \
        --yes-button "Continue" \
        --no-button "Back" \
        --yesno "\
 Initializes a secure workspace to store
 temporary installation files:

  â€¢ ~/.install_gnome/state
  â€¢ ~/.install_gnome/desktop
  â€¢ ~/.install_gnome/optional
  â€¢ ~/.install_gnome/step1.sh
  â€¢ ~/.install_gnome/step2.sh
  â€¢ ~/.install_gnome/step3.sh

 Temporary installer files are kept until
 the installation completes. They are removed
 automatically after the final step.
" 21 60
}




# Show the step menu after reboot.
#
# After Step 1 or Step 2, the user runs ./install-gnome.sh again. This menu reads
# the saved state and shows the steps that are available at that point.
show_step_menu() {
    load_state

    if [ "$STEP" = "COMPLETED" ]; then
        whiptail \
            --title "Install GNOME on Raspberry Pi" \
            --msgbox "Installation already completed." 10 45
        exit 0
    fi

    case "$STEP" in
        2)
            MENU_HEIGHT=2
            MENU_INFO=" This step configures system settings,
 prepares updates, and handles optional software."

            MENU_ITEMS=(
                " 1." "User identity and language  "
                " 2." "System setup and optional software  "
            )
            ;;

        3)
            MENU_HEIGHT=3
            MENU_INFO=" This final step installs the GNOME desktop,
 applications, themes, and system integration."

            MENU_ITEMS=(
                " 1." "User identity and language  "
                " 2." "System setup and optional software  "
                " 3." "GNOME desktop and applications  "
            )
            ;;

        *)
            whiptail \
                --title "Install GNOME on Raspberry Pi" \
                --msgbox "Unknown installer state: $STEP" 10 45
            exit 1
            ;;
    esac

    STEP_SELECTION=$( \
        whiptail \
            --title "Install GNOME on Raspberry Pi" \
            --ok-button "Continue" \
            --cancel-button "Cancel" \
            --default-item " $STEP." \
            --menu "\

 Current step $STEP of 3.

$MENU_INFO

" 16 55 "$MENU_HEIGHT" \
            "${MENU_ITEMS[@]}" \
            3>&1 1>&2 2>&3
    )

    EXITSTATUS=$?

    if [ "$EXITSTATUS" -ne 0 ]; then
        clear
        echo "Installation cancelled."
        exit 1
    fi

    STEP_SELECTION="${STEP_SELECTION// /}"
    STEP_SELECTION="${STEP_SELECTION%.}"
}




# Run the selected step script.
#
# The controller does not contain the installation logic itself. It only starts
# the generated step script that matches the menu selection.
run_selected_step() {
    case "$STEP_SELECTION" in
        1) "$INSTALL_DIR/step1.sh" ;;
        2) "$INSTALL_DIR/step2.sh" ;;
        3) "$INSTALL_DIR/step3.sh" ;;
        *)
            clear
            echo "Unknown selected step: $STEP_SELECTION"
            exit 1
            ;;
    esac
}




# Decide what the controller should show first.
#
# On STEP=1, the installer still shows the welcome and bootstrap screens. After
# progress has been made, it goes directly to the step menu so the user can resume
# without repeating the introduction.
load_state

case "$STEP" in
    1)
        # First run only: allow Back from Bootstrap to Welcome,
        # and Back/Cancel from Step 1 back to Bootstrap.
        while true; do
            if ! show_welcome; then
                clear
                echo "Installation cancelled."
                exit 1
            fi

            while true; do
                if ! show_bootstrap; then
                    break
                fi

                STEP_SELECTION="1"

                set +e
                run_selected_step
                STEP_RC=$?
                set -e

                if [ "$STEP_RC" -eq 2 ]; then
                    # Back/Cancel from Step 1: return to Bootstrap.
                    continue
                fi

                exit "$STEP_RC"
            done
        done
        ;;

    2|3)
        # After the installation has progressed, do not return to
        # Introduction or Bootstrap. Cancel means exit.
        show_step_menu
        run_selected_step
        ;;

    COMPLETED)
        whiptail \
            --title "Install GNOME on Raspberry Pi" \
            --msgbox "Installation already completed." 10 45
        exit 0
        ;;

    *)
        whiptail \
            --title "Install GNOME on Raspberry Pi" \
            --msgbox "Unknown installer state: $STEP" 10 45
        exit 1
        ;;
esac
EOF




# Start the new controller.
#
# The bootstrap script has finished its job. The backup is removed, and exec
# replaces the current shell process with the new controller script.
chmod +x ./install-gnome.sh
sleep 1
rm -f "$0.bootstrap_backup"
exec ./install-gnome.sh
