# dots

# Packages
- kitty
- firefox
- niri
- brightnessctl
- neovim
- zoxide
- gcc
- quickshell
- tmux
- zathura
- zathura-pdf-mupdf
- texlive
- tree-sitter-cli
- texlive
- nodejs
- npm
- discord
- texlab
- powertop
- intel-gpu-tools
- dbus-python
- pyright
- xwayland-satellite
- clang

## AUR
- vmware-keymaps
- vmware-workstation
    Added `ibt=off` to `/etc/default/grub` in `GRUB_CMDLINE_LINUX_DEFAULT`
    Had to rebuild dkms
    ```
    sudo dkms autoinstall
    sudo modprobe -a vmw_vmci vmmon
    sudo systemctl enable --now vmware-networks
    ```

## Build
- paru

# TODO
- [ ] Lock screen
- [ ] quickshell
- [ ] fonts
