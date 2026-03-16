# install-gnome.sh

Transform a fresh Raspberry Pi OS Lite (Debian 13 Trixie) installation into a fully configured GNOME workstation optimized for Raspberry Pi hardware.

This setup provides a clean GNOME desktop similar to Ubuntu while remaining fully based on Debian and Raspberry Pi packages to ensure proper hardware acceleration and efficient performance on Raspberry Pi systems. For more information go to the Raspberry Pi forum [GUIDE: Install GNOME on Raspberry Pi OS ↗ ](https://forums.raspberrypi.com/viewtopic.php?t=373028#p2233233)

[![GNOME on Raspberry Pi](https://wobbo.org/screenshots/20250225__373028_Intro_GUIDE_mini.webp)](https://forums.raspberrypi.com/viewtopic.php?t=373028#p2233233)

First install [Raspberry Pi OS Lite \(64-bit\) 487MB ↗ ](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-64-bit). If you are using the [Raspberry Pi Imager ↗ ](https://www.raspberrypi.com/software/) on Windows, Mac or Ubuntu to install Raspberry Pi OS Lite, I recommend filling in the Customization Settings. After installing Raspberry Pi OS Lite \(64-bit\), log in and type:


```bash
wget -O install-gnome.sh https://wobbo.org/install/2026-03-10/install-gnome.sh
chmod +x install-gnome.sh
./install-gnome.sh
```
🤔 Which keyboard do I have? Information about keyboards: [HOWTO: Choose the correct keyboard ↗ ](https://forums.raspberrypi.com/viewtopic.php?t=392681#p2342497) 

⚠️ Important: This script is intended only for a fresh Raspberry Pi OS Lite installation. Do not run it on an existing system.

ℹ️ All additional components required to run [Yaru correctly in GNOME ↗ ](https://forums.raspberrypi.com/viewtopic.php?t=393000#p2344104) are included: Yaru themes for [GNOME](https://github.com/wobbo/debian-yaru/releases/download/v1/yaru-theme-gnome-shell_25.04.1-0ubuntu1_all.deb), [GTK](https://github.com/wobbo/debian-yaru/releases/download/v1/yaru-theme-gtk_25.04.1-0ubuntu1_all.deb), [icons](https://github.com/wobbo/debian-yaru/releases/download/v1/yaru-theme-icon_25.04.1-0ubuntu1_all.deb), [sounds](https://github.com/wobbo/debian-yaru/releases/download/v1/yaru-theme-sound_25.04.1-0ubuntu1_all.deb), [Unity](https://github.com/wobbo/debian-yaru/releases/download/v1/yaru-theme-unity_25.04.1-0ubuntu1_all.deb) and [LibreOffice](https://github.com/wobbo/libreoffice-yaru/raw/refs/heads/main/libreoffice_yaru-themes_2025-09-23.zip); supporting scripts and services that automatically apply and preserve the Yaru appearance; and a pinned Geary version chosen specifically to maintain visual and design consistency with GNOME in Yaru style. 

---

## Overview

This project installs and configures a complete GNOME desktop environment specifically tuned for Raspberry Pi. The system remains based on Debian and Raspberry Pi packages, ensuring hardware acceleration and compatibility with Raspberry Pi firmware while providing a polished desktop experience.

Default GNOME applications are adjusted to better suit Raspberry Pi hardware.Chromium replaces Firefox to enable Raspberry Pi hardware acceleration. Geary is used as the email client with Raspberry Pi compatibility patches. VLC replaces the default GNOME media players to improve media compatibility.

---

## Ubuntu-style GNOME Desktop

The desktop environment is refined to deliver a consistent Ubuntu-style GNOME experience. Custom-built Yaru packages bring Ubuntu’s visual design to Debian. Ubuntu fonts and Microsoft compatibility fonts are included for better document compatibility.

A dedicated script synchronizes GNOME light and dark modes with the Yaru themes so the entire desktop switches appearance consistently. LibreOffice and VLC are visually integrated using the same Yaru theme design.

---

## Preconfigured GNOME Environment

GNOME is fully configured out of the box to provide a consistent desktop workflow on Raspberry Pi systems.

- Dash-to-Dock is enabled to provide a persistent application dock similar to the Ubuntu desktop.
- Desktop icons are enabled for quick access to files and mounted drives.
- Favorite applications are preconfigured so commonly used programs are immediately available in the dock.
- Several useful GNOME extensions are already enabled to improve usability and desktop integration.
- The workspace workflow is tuned for desktop use with fixed workspaces instead of dynamic workspaces.
- The GNOME file manager is configured with improved default settings better suited for desktop usage.
- Automatic language detection installs the correct spelling dictionaries and LibreOffice translations based on the system locale.
- The system also applies default GNOME settings globally so newly created user accounts automatically receive the same desktop configuration.

---

## Theme and Application Integration

- The desktop theme is carefully integrated beyond standard GNOME defaults to provide a consistent Ubuntu-style appearance across the system.
- Custom Yaru theme adjustments are included to improve compatibility with GNOME and to fix theme-related issues present in the default upstream combination.
- A dedicated script synchronizes GNOME light and dark mode behavior with the Yaru theme configuration so theme switching works consistently across the desktop.
- Additional integration is included so GNOME accent color changes are correctly reflected in the Yaru theme, solving the mismatch between GNOME accent color settings and Yaru styling.
- VLC is integrated with automatic light and dark theme switching so it follows GNOME’s system appearance settings and always matches the rest of the desktop.
- Chromium is configured for a cleaner startup experience so it opens directly without the usual delayed loading behavior.
- A complete custom Yaru theme set for LibreOffice is included so LibreOffice matches the rest of the desktop in both light and dark modes.

---

## Result Additional Improvements

The result is a polished Ubuntu-style GNOME desktop experience optimized specifically for Raspberry Pi hardware. Fractional scaling support is enabled. A clean graphical boot experience is provided using Plymouth. System defaults are automatically applied to newly created user accounts to ensure a consistent setup across the system.

---

## Full Guide

Complete installation instructions and background information are available on the Raspberry Pi forum:

[Install GNOME on Raspberry Pi OS Lite (Ubuntu-like) ↗ ](https://forums.raspberrypi.com/viewtopic.php?t=373028#p2233233)

---

## Extro tools and information

### Tool: Keyboard and Locale Configuration

Choose the [correct locale and keyboard layout ↗ ](https://forums.raspberrypi.com/viewtopic.php?t=392681#p2342497) for your system. A complete overview for selecting the correct locale and keyboard layout on Raspberry Pi OS is available here.
This includes information about **ANSI, ISO and JIS keyboards** as well as common layouts such as **QWERTY, AZERTY and QWERTZ**. 

[HOWTO: Choose the correct locale & keyboard (ANSI, ISO, JIS, QWERTY, AZERTY, QWERTZ) ↗ ](https://forums.raspberrypi.com/viewtopic.php?t=392681#p2342497)

![Overview for selecting locale and keyboard layout.](https://wobbo.org/screenshots/20250721_local_language.webp)

---

### Fix: Ubuntu Yaru
I built a small set of Ubuntu Yaru theme packages for Raspberry Pi OS (Debian 13) with GNOME 48 to work around a Debian 13 theming bug. These are plain theme packages (no binaries) and should be architecture-independent. [FIX: Yaru theme .deb for Raspberry Pi OS (Debian 13, GNOME 48) ↗ ](https://forums.raspberrypi.com/viewtopic.php?t=393000#p2344104)

---

### Launches Geary in Background
By simply adding an account in Online Accounts, Geary can immediately access and manage email without requiring additional configuration. You wil then get update bij every new mails. [HOWTO: Email Client Geary and Launches in Background on Startup ↗ ](https://forums.raspberrypi.com/viewtopic.php?t=387502#p2313459) 

---

### LibreOffice Yaru Theme for Raspberry Pi OS Trixie
I’ve prepared the Yaru (Ubuntu) icon theme for LibreOffice so it can be installed easily on Raspberry Pi OS Trixie (Debian 13). It was originally made for Raspberry Pi OS GNOME, but it should also work well with other desktop environments. [LibreOffice Yaru Theme for Raspberry Pi OS Trixie ↗ ](https://forums.raspberrypi.com/viewtopic.php?t=393058#p2344404)

---

### Tip Rasberry forum
- [HOWTO: NordVPN (NordLynx) to Native WireGuard .conf (Raspberry Pi GNOME / Android) ↗ ](https://forums.raspberrypi.com/viewtopic.php?t=395466#p2358920)
- [INSTALL: Signal Desktop for Raspberry Pi OS ↗ ](https://forums.raspberrypi.com/viewtopic.php?t=387491#p2313410)
- [INSTALL: Sunshine and Moonlight instead VPN, RDP, SteamLink ↗ ](https://forums.raspberrypi.com/viewtopic.php?t=387996#p2315741)

---

### GitHub:
- [rpi-gnome-install](https://github.com/wobbo/rpi-gnome-install) – Install GNOME on Raspberry Pi OS Lite for *Debian Trixie*, *GNOME*, *ARM64*.   
- [signal-desktop](https://github.com/wobbo/signal-desktop) – Install Signal Desktop on *Debian Trixie*, *GNOME*, *ARM64*.  
- [geary-debian](https://github.com/wobbo/geary-debian) – Geary 44.1 for *Debian Trixie*, *GNOME*, *ARM64*.
- [nordvpn-wireguard-generator](https://github.com/wobbo/nordvpn-wireguard-generator) – Generate WireGuard configs from NordLynx for *Debian Trixie*, *GNOME*.
- [debian-yaru](https://github.com/wobbo/debian-yaru) – Yaru themes for *Debian Trixie*, *GNOME*.  
- [libreoffice-yaru](https://github.com/wobbo/libreoffice-yaru) – LibreOffice Yaru themes for *Debian Trixie*.
