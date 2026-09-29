#!/bin/bash
set -e

echo "=== START [VMware + Ly]: Graphics, System & Dev Optimization ==="

# 1. UPDATE AND SYSTEM OPTIMIZATION
echo "--- Updating system, enabling SSD trim and cache cleaning ---"
sudo pacman -Syu --noconfirm
# Fixed: base-devel is now safely installed as a group to guarantee fakeroot/debugedit exist [1]
sudo pacman -S --needed --noconfirm base-devel mesa open-vm-tools linux-headers pacman-contrib

# Enable automatic package cache cleanup (keep only the last 2 versions) [1]
sudo systemctl enable --now paccache.timer
# Enable weekly SSD optimization (FSTRIM) [1]
sudo systemctl enable --now fstrim.timer
# Enable VMware guest services [1]
sudo systemctl enable vmtoolsd.service

# 2. INSTALL GRAPHICAL ENVIRONMENT AND CORE APPLICATIONS
echo "--- Installing Niri, Noctalia and Base Software ---"
sudo pacman -S --noconfirm \
    niri noctalia alacritty ly xwayland-satellite qt5-wayland qt6-wayland \
    pipewire pipewire-pulse wireplumber ttf-nerd-fonts-symbols-mono nwg-look \
    firefox code obsidian telegram-desktop thunar htop fastfetch \
    xdg-desktop-portal-wlr xdg-desktop-portal-gtk

# Fixed: Modern and accurate way to enable Ly display manager [1]
sudo systemctl enable ly

# 3. EXTRA UTILITIES, ARCHIVERS, AND RUNTIMES
echo "--- Installing extra utilities, runtimes and codecs ---"
sudo pacman -S --noconfirm p7zip unrar unzip zip file-roller yazi github-cli evince

# 4. DEVELOPER COMPILERS AND ENVIRONMENTS (C, PYTHON)
echo "--- Installing GCC, GDB, Python, Pip and Virtualenv ---"
sudo pacman -S --noconfirm gcc gdb make python python-pip python-virtualenv nodejs npm

# 5. MONITORING, AUDIO EQUALIZER, SECURITY & FONTS
echo "--- Installing monitoring tools, equalizer stack, fonts and security apps ---"
sudo pacman -S --noconfirm btop ncdu easyeffects lsp-plugins-lv2 calf keepassxc ttf-dejavu ttf-liberation ttf-opensans

# 6. CLIPBOARD AND SCREENSHOT TOOLS WITH SATTY EDITOR
echo "--- Installing clipboard management and screenshot utilities ---"
sudo pacman -S --noconfirm wl-clipboard cliphist grim slurp satty wf-recorder

# 7. INSTALL AUR HELPER (PARU)
echo "--- Installing Paru (AUR helper) ---"
if ! command -v paru &> /dev/null; then
    sudo pacman -S --needed --noconfirm cargo
    # Fixed: Force remove leftover directories to prevent Git errors [1]
    rm -rf /tmp/paru
    cd /tmp && git clone https://archlinux.org && cd paru
    makepkg -si --noconfirm
    cd ~
fi

# 8. INSTALL EXTRA SOFTWARE FROM AUR (STABLE REPOS)
echo "--- Installing font replacements and OnlyOffice ---"
# Fixed: Replaced loop-device breaking ttf-ms-win11 with stable msttcorefonts for VMware
paru -S --noconfirm onlyoffice-bin msttcorefonts

# 9. GENERATE CONFIGURATIONS AND ENVIRONMENT VARIABLES
echo "--- Generating config files ---"
mkdir -p ~/.config/niri ~/.config/alacritty ~/.config/environment.d

# Fix screen sharing (Discord/Telegram) under Wayland [1]
cat > ~/.config/environment.d/10-wayland.conf << 'EOF'
XDG_CURRENT_DESKTOP=niri
XDG_SESSION_TYPE=wayland
EOF

# Niri configuration [1]
cat > ~/.config/niri/config.kdl << 'EOF'
spawn-at-startup "noctalia"
spawn-at-startup "xwayland-satellite"
spawn-at-startup "wl-paste" "--watch" "cliphist" "store"

layout {
    gaps 10
    center-focused-column "never"
    focus-ring { 
        width 2
        active-color "#a6e3a1" 
        inactive-color "#313244" 
    }
    border { off }
}

binds {
    // === START APPLICATIONS ===
    Mod+Return { spawn "alacritty"; }
    Mod+D { spawn "noctalia" "launcher"; }
    
    // === UTILITIES AND SCREENSHOTS ===
    Mod+Print { spawn "sh" "-c" "grim -g \"$(slurp)\" - | satty --filename -"; }
    Mod+V { spawn "cliphist" "list" "|" "noctalia" "launcher"; }

    // === WINDOW MANAGEMENT ===
    Mod+Q { close-window; }
    Mod+Shift+E { quit; }
    Mod+F { maximize-column; }
    Mod+Shift+F { toggle-window-floating; }

    // === NAVIGATION (Arrows and HJKL) ===
    Mod+Left  { focus-column-left; }
    Mod+Right { focus-column-right; }
    Mod+H     { focus-column-left; }
    Mod+L     { focus-column-right; }
    
    Mod+Up    { focus-window-or-monitor-up; }
    Mod+Down  { focus-window-or-monitor-down; }
    Mod+K     { focus-window-or-monitor-up; }
    Mod+J     { focus-window-or-monitor-down; }

    // === MOVE WINDOWS ===
    Mod+Shift+Left  { move-column-left; }
    Mod+Shift+Right { move-column-right; }
    Mod+Shift+H     { move-column-left; }
    Mod+Shift+L     { move-column-right; }

    // === RESIZING AND SPLITS ===
    Mod+Minus { consume-window-into-column; }
    Mod+Equal { expel-window-from-column; }
    Mod+R { switch-preset-column-width; }
    Mod+Shift+R { reset-window-materially; }

    // === WORKSPACES ===
    Mod+1 { focus-workspace 1; }
    Mod+2 { focus-workspace 2; }
    Mod+3 { focus-workspace 3; }
    Mod+4 { focus-workspace 4; }
    Mod+5 { focus-workspace 5; }
    Mod+6 { focus-workspace 6; }
    Mod+7 { focus-workspace 7; }
    Mod+8 { focus-workspace 8; }
    Mod+9 { focus-workspace 9; }

    Mod+Shift+1 { move-column-to-workspace 1; }
    Mod+Shift+2 { move-column-to-workspace 2; }
    Mod+Shift+3 { move-column-to-workspace 3; }
    Mod+Shift+4 { move-column-to-workspace 4; }
    Mod+Shift+5 { move-column-to-workspace 5; }
    Mod+Shift+6 { move-column-to-workspace 6; }
    Mod+Shift+7 { move-column-to-workspace 7; }
    Mod+Shift+8 { move-column-to-workspace 8; }
    Mod+Shift+9 { move-column-to-workspace 9; }

    Mod+WheelScrollDown      { focus-workspace-down; }
    Mod+WheelScrollUp        { focus-workspace-up; }
}
EOF

# Config Alacritty [1]
cat > ~/.config/alacritty/alacritty.toml << 'EOF'
[font]
size = 11.0
[font.normal]
family = "JetBrainsMono Nerd Font"
style = "Regular"
[window]
padding = { x = 10, y = 10 }
opacity = 0.95
EOF

# 10. DEFAULT GIT CONFIGURATION (INTERACTIVE INPUT) [1]
echo "--- Setting up global Git config ---"
git config --global init.defaultBranch main

if [ -z "$(git config --global user.name)" ]; then
    read -p "Enter your Git user name (e.g. Ivan Ivanov): " git_name
    git config --global user.name "$git_name"
fi

if [ -z "$(git config --global user.email)" ]; then
    read -p "Enter your Git email address (e.g. email@example.com): " git_email
    git config --global user.email "$git_email"
fi

# 11. TERMINAL STARTUP GREETING SETUP [1]
echo "--- Configuring shell greeting (Fastfetch) ---"
if ! grep -q "fastfetch" ~/.bashrc; then
cat << 'EOF' >> ~/.bashrc

# Custom greeting on terminal startup
if [ -x "$(command -v fastfetch)" ]; then
    echo -e "\n  \e[1;36mWelcome to Arch Linux, $USER!\e[0m"
    echo -e "  \e[37mSession started at: $(date +'%H:%M:%S')\e[0m\n"
    fastfetch --logo-color-1 "cyan" --logo-color-2 "white"
fi
EOF
fi

echo "=== SUCCESS: VM Setup complete! ==="

# 12. INTERACTIVE REBOOT PROMPT [1]
read -p "Installation finished. Do you want to reboot now? (y/n): " reboot_choice
case "$reboot_choice" in 
    [yY][eE][sS]|[yY]) 
        echo "Rebooting system..."
        sudo reboot
        ;;
    *)
        echo "Reboot canceled. You can reboot manually later using 'sudo reboot'."
        ;;
esac
