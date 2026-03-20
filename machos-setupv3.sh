#!/bin/bash
# =============================================================
#  MachOS Setup Script v3 - Fedora 43
#  Führe aus mit: bash machos-setup.sh
# =============================================================

set -e

echo "================================================"
echo "   MachOS Setup v3 startet..."
echo "================================================"
sleep 2

echo ">>> Phase 1: System Update..."
sudo dnf update -y

echo ">>> Phase 2: Basis Tools..."
sudo dnf install -y git wget curl unzip nano vim

echo ">>> Phase 3: Repos..."
# RPM Fusion
sudo dnf install -y \
  https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-43.noarch.rpm \
  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-43.noarch.rpm || true

# Hyprland (funktioniert auf Fedora 43)
sudo dnf copr enable -y sdegler/hyprland

# QuickShell (funktioniert auf Fedora 43)
sudo dnf copr enable -y avengemedia/danklinux

# VS Code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo tee /etc/yum.repos.d/vscode.repo << 'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

sudo dnf makecache -y

echo ">>> Phase 4: Hyprland..."
sudo dnf install -y \
  hyprland \
  xdg-desktop-portal-hyprland \
  xdg-desktop-portal-gtk \
  wayland-utils wl-clipboard polkit-gnome \
  grim slurp swappy \
  hyprlock hypridle hyprpaper \
  sddm

echo ">>> Phase 5: Caelestia Shell..."
sudo dnf install -y \
  quickshell foot fish starship \
  papirus-icon-theme adw-gtk3-theme \
  jetbrains-mono-fonts \
  google-noto-fonts-common \
  google-noto-emoji-fonts \
  fastfetch btop

sudo chsh -s /usr/bin/fish $USER
git clone https://github.com/caelestia-dots/shell ~/.config/caelestia || true

echo ">>> Phase 6: Audio..."
sudo dnf install -y \
  pipewire pipewire-alsa pipewire-pulseaudio \
  pipewire-jack wireplumber pavucontrol

echo ">>> Phase 7: Gaming..."
sudo dnf install -y \
  steam gamemode gamescope \
  mangohud lutris wine winetricks protontricks

# Proton-GE
mkdir -p ~/.steam/root/compatibilitytools.d
PROTON_URL=$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest \
  | grep browser_download_url | grep tar.gz | cut -d '"' -f 4)
wget -O /tmp/proton-ge.tar.gz "$PROTON_URL"
tar -xzf /tmp/proton-ge.tar.gz -C ~/.steam/root/compatibilitytools.d/

echo ">>> Phase 8: Dev Tools..."
sudo dnf install -y \
  code github-cli nodejs npm \
  python3 python3-pip \
  gcc make cmake \
  docker docker-compose podman

sudo systemctl enable --now docker
sudo usermod -aG docker $USER

echo ">>> Phase 9: Performance..."
sudo dnf install -y zram-generator

sudo tee /etc/systemd/zram-generator.conf << 'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF

sudo tee /etc/sysctl.d/99-machos.conf << 'EOF'
vm.swappiness=10
vm.dirty_ratio=10
vm.dirty_background_ratio=5
vm.vfs_cache_pressure=50
net.core.rmem_max=134217728
net.core.wmem_max=134217728
kernel.nmi_watchdog=0
kernel.sched_autogroup_enabled=1
EOF

sudo sysctl --system
sudo systemctl disable --now cups 2>/dev/null || true
sudo systemctl disable --now avahi-daemon 2>/dev/null || true
sudo systemctl enable --now fstrim.timer
sudo systemctl enable --now bluetooth 2>/dev/null || true

echo ">>> Phase 10: Configs..."
mkdir -p ~/.config/hypr
cat > ~/.config/hypr/hyprland.conf << 'EOF'
monitor=,preferred,auto,1

exec-once = hyprpaper
exec-once = quickshell -c caelestia
exec-once = hypridle
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1

env = LIBVA_DRIVER_NAME,radeonsi
env = WLR_RENDERER,vulkan
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
env = QT_QPA_PLATFORM,wayland
env = GDK_BACKEND,wayland

input {
    kb_layout = de
    follow_mouse = 1
    sensitivity = 0
    touchpad {
        natural_scroll = true
        tap-to-click = true
    }
}

general {
    gaps_in = 4
    gaps_out = 8
    border_size = 1
    col.active_border = rgba(FFFFFFcc)
    col.inactive_border = rgba(FFFFFF22)
    layout = dwindle
}

decoration {
    rounding = 8
    blur {
        enabled = true
        size = 6
        passes = 2
    }
    drop_shadow = true
    shadow_range = 12
    shadow_color = rgba(00000066)
}

animations {
    enabled = true
    bezier = smooth, 0.05, 0.9, 0.1, 1.0
    animation = windows, 1, 4, smooth
    animation = windowsOut, 1, 4, smooth
    animation = fade, 1, 4, default
    animation = workspaces, 1, 4, smooth
}

dwindle {
    pseudotile = true
    preserve_split = true
}

$mod = SUPER
bind = $mod, Return, exec, foot
bind = $mod, Q, killactive
bind = $mod, F, fullscreen
bind = $mod, Space, exec, quickshell -c caelestia launcher
bind = $mod, L, exec, hyprlock
bind = $mod SHIFT, S, exec, grim -g "$(slurp)" - | swappy -f -
bind = $mod, 1, workspace, 1
bind = $mod, 2, workspace, 2
bind = $mod, 3, workspace, 3
bind = $mod, 4, workspace, 4
bind = $mod, 5, workspace, 5
bind = $mod SHIFT, 1, movetoworkspace, 1
bind = $mod SHIFT, 2, movetoworkspace, 2
bind = $mod SHIFT, 3, movetoworkspace, 3
bind = $mod SHIFT, 4, movetoworkspace, 4
bind = $mod SHIFT, 5, movetoworkspace, 5
bindm = $mod, mouse:272, movewindow
bindm = $mod, mouse:273, resizewindow
EOF

mkdir -p ~/.config/fish
cat > ~/.config/fish/config.fish << 'EOF'
set fish_greeting ""
starship init fish | source
alias ls "ls --color=auto"
alias ll "ls -la"
alias update "sudo dnf update"
function gaming
    gamemodectl start
    echo "Gaming Mode aktiviert"
end
EOF

cat > ~/.config/starship.toml << 'EOF'
format = """
[╭─](white)$directory$git_branch$git_status$cmd_duration$line_break\
[╰─](white)$character"""

[directory]
style = "white"
truncation_length = 3

[git_branch]
symbol = " "
style = "white"

[character]
success_symbol = "[❯](white)"
error_symbol = "[❯](red)"
EOF

sudo systemctl enable sddm

echo ">>> Phase 11: Flatpak..."
sudo dnf install -y flatpak
flatpak remote-add --if-not-exists flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo

echo ">>> Phase 12: Linux Live Kit..."
git clone https://github.com/Tomas-M/linux-live /tmp/linux-live
sed -i 's/LIVEKITNAME=.*/LIVEKITNAME="MachOS"/' /tmp/linux-live/config

echo ""
echo "================================================"
echo "   MachOS Setup fertig!"
echo "================================================"
echo "Jetzt: sudo reboot"
echo "Danach: cd /tmp/linux-live && sudo ./build"
echo "================================================"
