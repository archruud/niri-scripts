#!/bin/bash
# Fiks iptables konflikt og installer virt-manager

echo "Fikser iptables konflikt..."

# Fjern gammel iptables hvis den finnes
if pacman -Q iptables 2>/dev/null | grep -v iptables-nft; then
    echo "Fjerner gammel iptables..."
    sudo pacman -Rdd --noconfirm iptables
fi

echo "Installerer virt-manager med iptables-nft..."
paru -S --needed --noconfirm \
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
echo "Aktiverer libvirtd..."
sudo systemctl enable libvirtd.service
sudo systemctl start libvirtd.service

# Legg til bruker i grupper
echo "Legger $USER til i libvirt og kvm grupper..."
sudo usermod -aG libvirt,kvm $USER

# Konfigurer default network
echo "Konfigurerer default network..."
sudo virsh net-autostart default 2>/dev/null || true
sudo virsh net-start default 2>/dev/null || true

echo ""
echo "Ferdig! Logg ut og inn igjen for at gruppene skal aktiveres."
echo "Deretter kan du starte virt-manager."
