cd ~/NixOS-dotfiles/NixOS/
sudo nix flake update
sudo nixos-rebuild switch --flake ~/NixOS-dotfiles/NixOS#NixOS
