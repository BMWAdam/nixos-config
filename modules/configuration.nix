{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
let
in {
  imports = [
    inputs.home-manager.nixosModules.default
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  users.users.bmwadam = {
    isNormalUser = true;
    home = "/home/bmwadam";
    description = "BMWAdam";
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
    shell = pkgs.zsh;
  };

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
      sshKeyPath = config.sops.secrets.ssh_key.path;
      gitEmailPath = config.sops.secrets.git_email.path;
      gpgKeyPath = config.sops.secrets.gpg_key.path;
    };

    users = {
      "bmwadam" = import ../home-manager/home.nix;
    };
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  services.xserver.enable = true;
  services.xserver.displayManager.lightdm = {
    enable = true;
    greeters.gtk.enable = true;
    background = pkgs.nixos-artwork.wallpapers.simple-dark-gray-bottom.gnomeFilePath;
  };

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  environment.systemPackages = with pkgs; [
    nh
    gnupg
    git
    mpv
    calibre
    chromium
  ];

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      texlivePackages.cm
      cm_unicode
      nerd-fonts.lilex
      nerd-fonts.agave
      nerd-fonts.tinos
      nerd-fonts.symbols-only
    ];
  };

  networking = {
    hostName = "omnibook";
  };

  security.polkit.enable = true;
  programs.zsh.enable = true;
  time.timeZone = "Europe/Prague";

  services.libinput.mouse.accelSpeed = "-0.5";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  hardware.uinput.enable = true;

  environment.sessionVariables = {
    NH_FLAKE = "/home/bmwadam/nixos-config";
    EDITOR = "nvim";
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-curses;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}