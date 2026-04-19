mv ~/nixos-dotfiles ~/NixOS-dotfiles
sudo mv /etc/nixos/configuration.nix /etc/nixos/configuration.nix.bak
rm -rf ~/NixOS-dotfiles/NixOS/hardware-configuration.nix
sudo mv /etc/nixos/hardware-configuration.nix ~/NixOS-dotfiles/NixOS/
cd ~/NixOS-dotfiles/ && mkdir -p ~/.config && stow -t ~/.config Configs 
mkdir -p ~/.local/share/fonts
mkdir -p ~/.local/share/icons
cp -r ~/NixOS-dotfiles/Configs/Resources/fonts/* ~/.local/share/fonts
cp -r ~/NixOS-dotfiles/Configs/Resources/Wallpapers/ ~/Wallpapers
cp -r ~/NixOS-dotfiles/Configs/Resources/Bibata-Modern-Ice/ ~/.local/share/icons/
rm -rf ~/.local/share/nvim/lazy/lazy.nvim
git clone --filter=blob:none \
        https://github.com/folke/lazy.nvim.git \
        --branch=stable \
        ~/.local/share/nvim/lazy/lazy.nvim
sudo rfkill unblock bluetooth
cd ~/NixOS-dotfiles/NixOS/
sudo nix flake update
sudo nixos-rebuild switch --flake ~/NixOS-dotfiles/NixOS#NixOS
kitty -e nvim &
