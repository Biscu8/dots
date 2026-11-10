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
    - hardlink .tmux.conf to ~/.tmux.conf
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
- rubygems
- ruby-erb
- ruby-abbrev
- oft-font-awesome
- upower
- ttf-ibmplex-mono-nerd
- bluez
- bluez-utils
    Enable bluetooth.service
- blueman
- ripgrep
- fd
- lua-language-server
- luarocks
- poppler
- imagemagick
- tlp
    ``` bash
    sudo systemctl enable --now tlp.service
    ```
- librewolf

## AUR
- vmware-keymaps
- vmware-workstation
    Added `ibt=off` to `/etc/default/grub` in `GRUB_CMDLINE_LINUX_DEFAULT`
    Had to rebuild dkms
    ``` bash
    sudo dkms autoinstall
    sudo modprobe -a vmw_vmci vmmon
    sudo systemctl enable --now vmware-networks
    ```
- pwvucontrol
- oh-my-posh
    ``` bash
    eval "$(oh-my-posh init bash --config ~/.config/ohmyposh/poisson.omp.json)"
    ```
    in `.bashrc`

### RubyGems
- vimgolf

## Build
- paru

# TODO
- [ ] Lock screen
- [ ] quickshell
- [ ] fonts
