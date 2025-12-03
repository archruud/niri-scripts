#!/bin/bash
# Niri installasjon for EKSISTERENDE Arch Linux system
# Beholder din nåværende display manager (SDDM/GDM)

set -e

echo "=========================================="
echo "  Niri - Installer på eksisterende system"
echo "=========================================="
echo ""
echo "Dette skriptet:"
echo "  ✓ Installerer niri ved siden av Hyprland"
echo "  ✓ Beholder din display manager (SDDM/GDM)"
echo "  ✓ Lar deg velge mellom Hyprland og niri ved login"
echo ""
read -p "Trykk Enter for å fortsette..."

# Sjekk om vi kjører som root
if [ "$EUID" -eq 0 ]; then 
    echo "FEIL: Ikke kjør dette skriptet som root!"
    exit 1
fi

# Oppdater systemet først
echo "[1/7] Oppdaterer systemet..."
sudo pacman -Syu --noconfirm

# Installer grunnpakker (hopp over hvis allerede installert)
echo "[2/7] Installerer grunnpakker..."
sudo pacman -S --needed --noconfirm \
    base-devel \
    git \
    rust \
    cargo \
    wget \
    curl

# Installer paru hvis ikke installert
echo "[3/7] Sjekker paru..."
if ! command -v paru &> /dev/null; then
    echo "Installerer paru..."
    cd /tmp
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd ~
else
    echo "Paru er allerede installert ✓"
fi

# Installer niri
echo "[4/7] Installerer niri..."
paru -S --noconfirm niri

# Installer nødvendige pakker (hopp over de som finnes)
echo "[5/7] Installerer nødvendige pakker..."
paru -S --needed --noconfirm \
    alacritty \
    fuzzel \
    waybar \
    swaybg \
    mako \
    wl-clipboard \
    grim \
    slurp \
    swaylock \
    swayidle \
    xdg-desktop-portal-wlr \
    polkit-gnome \
    firefox \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber \
    pavucontrol \
    bluez \
    bluez-utils \
    blueman \
    network-manager-applet

# Dolphin er allerede installert fra Hyprland-oppsettet

# Aktiver pipewire og bluetooth (hvis ikke allerede)
echo "Aktiverer tjenester..."
systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
sudo systemctl enable bluetooth.service 2>/dev/null || true
sudo systemctl start bluetooth.service 2>/dev/null || true

# Installer skrifter (hvis ikke finnes)
echo "[6/7] Installerer skrifter..."
sudo pacman -S --needed --noconfirm \
    ttf-jetbrains-mono-nerd \
    ttf-font-awesome \
    noto-fonts \
    noto-fonts-emoji \
    papirus-icon-theme

# Opprett konfigurasjonsmapper
echo "[7/7] Oppretter niri konfigurasjon..."
mkdir -p ~/.config/niri
mkdir -p ~/.config/waybar-niri

# Waybar konfigurasjon for niri (separat fra Hyprland)
cat > ~/.config/waybar-niri/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "spacing": 0,
    
    "modules-left": ["custom/launcher", "niri/workspaces", "niri/window"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "bluetooth", "network", "battery"],

    "custom/launcher": {
        "format": "󰣇",
        "on-click": "fuzzel",
        "tooltip": false
    },

    "niri/workspaces": {
        "format": "{icon}",
        "format-icons": {
            "1": "1",
            "2": "2",
            "3": "3",
            "4": "4",
            "5": "5",
            "active": "",
            "default": ""
        },
        "on-click": "activate"
    },

    "niri/window": {
        "format": "{title}",
        "max-length": 50,
        "icon": true,
        "icon-size": 16
    },

    "clock": {
        "interval": 60,
        "format": "{:%H:%M}",
        "format-alt": "{:%A, %d. %B %Y - %H:%M}",
        "tooltip-format": "<tt><small>{calendar}</small></tt>",
        "calendar": {
            "mode": "month",
            "mode-mon-col": 3,
            "weeks-pos": "right",
            "on-scroll": 1
        }
    },

    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": "󰖁 Muted",
        "format-icons": {
            "default": ["", "", ""]
        },
        "on-click": "pavucontrol",
        "scroll-step": 5
    },

    "bluetooth": {
        "format": " {status}",
        "format-disabled": "",
        "format-connected": " {num_connections}",
        "on-click": "blueman-manager"
    },

    "network": {
        "format-wifi": " {essid}",
        "format-ethernet": "󰈀 Connected",
        "format-disconnected": "󰖪 Disconnected",
        "on-click": "nm-connection-editor"
    },

    "battery": {
        "interval": 60,
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{icon} {capacity}%",
        "format-charging": " {capacity}%",
        "format-plugged": " {capacity}%",
        "format-icons": ["", "", "", "", ""]
    }
}
EOF

# Waybar style
cat > ~/.config/waybar-niri/style.css << 'EOF'
* {
    font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free";
    font-size: 13px;
    font-weight: 600;
    min-height: 0;
}

window#waybar {
    background: rgba(26, 27, 38, 0.95);
    color: #cdd6f4;
    border-bottom: 2px solid rgba(137, 180, 250, 0.3);
}

#custom-launcher {
    color: #89b4fa;
    font-size: 20px;
    padding: 0 15px;
}

#custom-launcher:hover {
    background: rgba(137, 180, 250, 0.2);
}

#workspaces button {
    padding: 0 10px;
    margin: 0 2px;
    color: #6c7086;
}

#workspaces button.active {
    color: #89b4fa;
    background: rgba(137, 180, 250, 0.15);
    border-bottom: 2px solid #89b4fa;
}

#window {
    padding: 0 15px;
    color: #cdd6f4;
}

#clock {
    padding: 0 20px;
    color: #f5e0dc;
    font-weight: bold;
}

#pulseaudio { color: #f9e2af; }
#bluetooth { color: #89b4fa; }
#network { color: #a6e3a1; }
#battery { color: #94e2d5; }

#battery.warning:not(.charging) { color: #f9e2af; }
#battery.critical:not(.charging) { 
    color: #f38ba8;
    animation: blink 1s linear infinite;
}

@keyframes blink {
    to { opacity: 0.5; }
}
EOF

# Niri konfigurasjon
if [ ! -f ~/.config/niri/config.kdl ]; then
    cat > ~/.config/niri/config.kdl << 'EOF'
input {
    keyboard {
        xkb {
            layout "no"
        }
    }
    
    touchpad {
        tap
        natural-scroll
        accel-speed 0.2
    }
}

output "eDP-1" {
    mode "1920x1080@60"
    scale 1.0
}

layout {
    gaps 8
    center-focused-column "never"
    
    preset-column-widths {
        proportion 0.33333
        proportion 0.5
        proportion 0.66667
    }
    
    default-column-width { proportion 0.5; }
}

spawn-at-startup "waybar" "--config" "~/.config/waybar-niri/config" "--style" "~/.config/waybar-niri/style.css"
spawn-at-startup "mako"
spawn-at-startup "swaybg" "-i" "/usr/share/backgrounds/archlinux/simple.png"

prefer-no-csd

binds {
    Mod+Return { spawn "alacritty"; }
    Mod+D { spawn "fuzzel"; }
    Mod+Q { close-window; }
    
    Mod+Left { focus-column-left; }
    Mod+Right { focus-column-right; }
    Mod+Up { focus-window-up; }
    Mod+Down { focus-window-down; }
    
    Mod+Shift+Left { move-column-left; }
    Mod+Shift+Right { move-column-right; }
    Mod+Shift+Up { move-window-up; }
    Mod+Shift+Down { move-window-down; }
    
    Mod+1 { focus-workspace 1; }
    Mod+2 { focus-workspace 2; }
    Mod+3 { focus-workspace 3; }
    Mod+4 { focus-workspace 4; }
    Mod+5 { focus-workspace 5; }
    
    Mod+Shift+1 { move-window-to-workspace 1; }
    Mod+Shift+2 { move-window-to-workspace 2; }
    Mod+Shift+3 { move-window-to-workspace 3; }
    Mod+Shift+4 { move-window-to-workspace 4; }
    Mod+Shift+5 { move-window-to-workspace 5; }
    
    Mod+Shift+E { quit; }
    
    Print { spawn "grim" "-g" "$(slurp)" "$(xdg-user-dir PICTURES)/screenshot-$(date +%Y%m%d-%H%M%S).png"; }
}

cursor {
    xcursor-theme "Adwaita"
    xcursor-size 24
}
EOF
fi

# Lag desktop entry for display manager
echo "Lager desktop entry..."
sudo tee /usr/share/wayland-sessions/niri.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Niri
Comment=Scrollable-tiling Wayland compositor
Exec=niri
Type=Application
DesktopNames=niri
EOF

echo ""
echo "=========================================="
echo "  Installasjon fullført!"
echo "=========================================="
echo ""
echo "Niri er nå installert ved siden av Hyprland!"
echo ""
echo "For å teste niri:"
echo "  1. Logg ut fra Hyprland"
echo "  2. Velg 'Niri' i display manager"
echo "  3. Logg inn"
echo ""
echo "For å bytte tilbake til Hyprland:"
echo "  1. Logg ut fra niri (Mod+Shift+E)"
echo "  2. Velg 'Hyprland' i display manager"
echo ""
echo "Konfigurasjonsfiler:"
echo "  Hyprland: ~/.config/hypr/"
echo "  Niri:     ~/.config/niri/"
echo "  Waybar (niri): ~/.config/waybar-niri/"
echo ""
echo "Waybar for niri bruker egen konfig i:"
echo "  ~/.config/waybar-niri/"
echo "  (kolliderer IKKE med Hyprland waybar)"
echo ""
