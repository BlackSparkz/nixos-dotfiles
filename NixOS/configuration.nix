{ config, pkgs, ... }:

{
  imports =
    [
    ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  console.font = "latarcyrheb-sun32";

  networking.hostName = "NixOS";

  documentation.nixos.enable = false;
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;

  time.timeZone = "Asia/Kolkata";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # services.xserver.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users."blackspark" = {
    isNormalUser = true;
    shell = pkgs.fish;
    description = "BlackSparkz";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #neovim
    ];
  };

  programs.fish.enable = true;
  programs.kdeconnect.enable = true;
  programs.hyprland.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    neovim
    git
    fastfetch
    awww
    fish
    bat
    waybar
    rofi
    libnotify
    mako
    android-tools
    cliphist
    cmus
    wl-clipboard
    slurp
    grim
    nwg-look
    foot
    stow
    eza
    yazi
    bluez
    bluez-tools
    bluetui
    playerctl
    librewolf-bin
    brave
    btop
    brightnessctl
    gh
    localsend
    kitty
  ];

  nixpkgs.config.permittedInsecurePackages = [
  "librewolf-bin-151.0.1-2"
  "librewolf-bin-unwrapped-151.0.1-2"
  ];

  networking.firewall.allowedTCPPorts = [ 53317 ];
  networking.firewall.allowedUDPPorts = [ 53317 ];

  system.stateVersion = "26.05";
}
