#!/bin/bash
# Komplett installasjonsskript for niri på Arch Linux
# Med noctalia-shell inspirert konfigurasjon

set -e  # Stopp ved feil

echo "=========================================="
echo "  Niri Window Manager - Installasjon"
echo "=========================================="
echo ""

# Sjekk om vi kjører som root
if [ "$EUID" -eq 0 ]; then 
    echo "FEIL: Ikke kjør dette skriptet som root!"
    exit 1
fi

# Oppdater systemet først
echo "[1/9] Oppdaterer systemet..."
sudo pacman -Syu --noconfirm

# Installer grunnpakker
echo "[2/9] Installerer grunnpakker..."
sudo pacman -S --needed --noconfirm \
    base-devel \
    git \
    rust \
    cargo \
    wget \
    curl

# Installer paru (AUR helper)
echo "[3/9] Installerer paru (AUR helper)..."
if ! command -v paru &> /dev/null; then
    cd /tmp
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd ~
else
    echo "Paru er allerede installert"
fi

# Installer niri
echo "[4/9] Installerer niri..."
paru -S --noconfirm niri

# Installer essensielle pakker
echo "[5/9] Installerer essensielle pakker..."
paru -S --noconfirm \
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
    thunar \
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

# Aktiver pipewire og bluetooth
echo "Aktiverer pipewire og bluetooth..."
systemctl --user enable --now pipewire pipewire-pulse wireplumber
sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service

# Installer skrifter og tema
echo "[6/9] Installerer skrifter og tema..."
sudo pacman -S --noconfirm \
    ttf-jetbrains-mono-nerd \
    ttf-font-awesome \
    noto-fonts \
    noto-fonts-emoji \
    papirus-icon-theme

# Installer KVM/QEMU og virt-manager
echo "[7/9] Installerer KVM/QEMU og virt-manager..."
sudo pacman -S --noconfirm \
    qemu-full \
    virt-manager \
    virt-viewer \
    dnsmasq \
    bridge-utils \
    libguestfs \
    ebtables \
    iptables-nft \
    openbsd-netcat

# Aktiver libvirtd
echo "Aktiverer libvirtd service..."
sudo systemctl enable libvirtd.service
sudo systemctl start libvirtd.service

# Legg brukeren til i libvirt gruppen
echo "Legger $USER til i libvirt og kvm grupper..."
sudo usermod -aG libvirt,kvm $USER

# Konfigurer default network
echo "Konfigurerer default network..."
sudo virsh net-autostart default 2>/dev/null || true
sudo virsh net-start default 2>/dev/null || true

# Opprett konfigurasjonsmapper
echo "[8/9] Oppretter konfigurasjonsmapper..."
mkdir -p ~/.config/niri
mkdir -p ~/.config/alacritty
mkdir -p ~/.config/fuzzel
mkdir -p ~/.config/waybar
mkdir -p ~/.config/mako

# Waybar konfigurasjon
echo "Setter opp Waybar (noctalia-shell stil)..."
cat > ~/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "spacing": 0,
    "margin-top": 0,
    "margin-bottom": 0,
    
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
            "on-scroll": 1,
            "format": {
                "months": "<span color='#ffead3'><b>{}</b></span>",
                "days": "<span color='#ecc6d9'><b>{}</b></span>",
                "weeks": "<span color='#99ffdd'><b>U{}</b></span>",
                "weekdays": "<span color='#ffcc66'><b>{}</b></span>",
                "today": "<span color='#ff6699'><b><u>{}</u></b></span>"
            }
        }
    },

    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": "󰖁 Muted",
        "format-icons": {
            "headphone": "",
            "hands-free": "",
            "headset": "",
            "phone": "",
            "portable": "",
            "car": "",
            "default": ["", "", ""]
        },
        "on-click": "pavucontrol",
        "scroll-step": 5
    },

    "bluetooth": {
        "format": " {status}",
        "format-disabled": "",
        "format-connected": " {num_connections}",
        "tooltip-format": "{controller_alias}\t{controller_address}",
        "tooltip-format-connected": "{controller_alias}\t{controller_address}\n\n{device_enumerate}",
        "tooltip-format-enumerate-connected": "{device_alias}\t{device_address}",
        "on-click": "blueman-manager"
    },

    "network": {
        "format-wifi": " {essid}",
        "format-ethernet": "󰈀 Connected",
        "format-disconnected": "󰖪 Disconnected",
        "tooltip-format": "{ifname}: {ipaddr}/{cidr}",
        "tooltip-format-wifi": "{essid} ({signalStrength}%)\n{ipaddr}/{cidr}",
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
        "format-icons": ["", "", "", "", ""],
        "tooltip-format": "{timeTo}\n{power}W"
    }
}
EOF

# Waybar style
cat > ~/.config/waybar/style.css << 'EOF'
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
    margin: 0;
}

#custom-launcher:hover {
    background: rgba(137, 180, 250, 0.2);
}

#workspaces {
    margin: 0 5px;
}

#workspaces button {
    padding: 0 10px;
    margin: 0 2px;
    color: #6c7086;
    background: transparent;
    border: none;
    border-radius: 0;
}

#workspaces button.active {
    color: #89b4fa;
    background: rgba(137, 180, 250, 0.15);
    border-bottom: 2px solid #89b4fa;
}

#workspaces button:hover {
    background: rgba(137, 180, 250, 0.1);
    color: #89b4fa;
}

#window {
    padding: 0 15px;
    color: #cdd6f4;
    font-weight: normal;
}

#clock {
    padding: 0 20px;
    color: #f5e0dc;
    font-weight: bold;
    font-size: 14px;
}

#pulseaudio,
#bluetooth,
#network,
#battery {
    padding: 0 12px;
    margin: 0 2px;
}

#pulseaudio {
    color: #f9e2af;
}

#pulseaudio.muted {
    color: #6c7086;
}

#bluetooth {
    color: #89b4fa;
}

#bluetooth.disabled {
    color: #6c7086;
}

#network {
    color: #a6e3a1;
}

#network.disconnected {
    color: #6c7086;
}

#battery {
    color: #94e2d5;
}

#battery.charging {
    color: #a6e3a1;
}

#battery.warning:not(.charging) {
    color: #f9e2af;
}

#battery.critical:not(.charging) {
    color: #f38ba8;
    animation: blink 1s linear infinite;
}

@keyframes blink {
    to {
        opacity: 0.5;
    }
}

#pulseaudio:hover,
#bluetooth:hover,
#network:hover,
#battery:hover {
    background: rgba(137, 180, 250, 0.1);
}

tooltip {
    background: rgba(26, 27, 38, 0.98);
    border: 1px solid rgba(137, 180, 250, 0.3);
    border-radius: 5px;
}

tooltip label {
    color: #cdd6f4;
}
EOF

# Niri konfigurasjon
if [ ! -f ~/.config/niri/config.kdl ]; then
    echo "Oppretter standard niri konfigurasjon..."
    cat > ~/.config/niri/config.kdl << 'EOF'
// Niri konfigurasjon - Noctalia-shell inspirert

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

spawn-at-startup "waybar"
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

window-rule {
    match app-id="Alacritty"
    default-column-width { proportion 0.5; }
}

cursor {
    xcursor-theme "Adwaita"
    xcursor-size 24
}
EOF
    echo "Standard konfigurasjon opprettet i ~/.config/niri/config.kdl"
fi

# Installer greetd display manager
echo "[9/9] Installerer greetd display manager..."
sudo pacman -S --noconfirm greetd greetd-tuigreet

# Konfigurer greetd
sudo mkdir -p /etc/greetd
sudo tee /etc/greetd/config.toml > /dev/null << 'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --cmd niri"
user = "greeter"
EOF

# Aktiver greetd
sudo systemctl enable greetd.service

echo ""
echo "=========================================="
echo "  Installasjon fullført!"
echo "=========================================="
echo ""
echo "For å starte niri:"
echo "  1. Reboot: sudo reboot"
echo "  2. Logg inn via greetd"
echo ""
echo "Waybar konfigurasjon:"
echo "  - Noctalia-shell inspirert design"
echo "  - PipeWire for lyd (ikke PulseAudio)"
echo "  - Moduler: lyd, bluetooth, wifi, batteri"
echo ""
echo "Viktige tastekombinasjoner:"
echo "  Mod+Return  - Terminal (Alacritty)"
echo "  Mod+D       - Launcher (Fuzzel)"
echo "  Mod+Q       - Lukk vindu"
echo "  Mod+Shift+E - Avslutt niri"
echo ""
echo "KVM/Virt-Manager:"
echo "  Etter reboot, logg inn på nytt for at gruppene skal aktiveres"
echo "  Start virt-manager: Mod+D → skriv 'virt-manager'"
echo ""
echo "Konfigurasjonsfiler:"
echo "  ~/.config/niri/config.kdl"
echo "  ~/.config/waybar/config"
echo "  ~/.config/waybar/style.css"
echo ""
