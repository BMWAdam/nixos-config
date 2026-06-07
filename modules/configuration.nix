{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
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
    extraGroups = [ "wheel" "networkmanager" "video" "input" "uinput" "render" ];
    shell = pkgs.zsh;
  };

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", \
      RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", \
      RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
  '';

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
      firefox-addons = inputs.firefox-addons;
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

    greeters.gtk = {
      enable = true;

      theme = {
        name = "Adwaita-dark";
        package = pkgs.gnome-themes-extra;
      };

      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };

      cursorTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
        size = 24;
      };

      extraConfig = ''
        icon-theme-name=Papirus-Dark
        background=${pkgs.nixos-artwork.wallpapers.simple-dark-gray-bottom.gnomeFilePath}

        # Ultra HiDPI scaling
        xft-dpi=288
        Gdk/WindowScalingFactor=3
        gtk-font-name=Sans 20
      '';
    };
  };

  programs.hyprland.enable = true;
  programs.hyprland.package = pkgs.hyprland;

  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };

  environment.systemPackages = with pkgs; [
    nh
    gnupg
    git
    mpv
    calibre
    chromium
    iio-sensor-proxy
    pamixer
    nicotine-plus
    keepassxc
    mpc
    ocl-icd
    opencl-headers
    opencl-clhpp
    onetbb
    ollama
    fprintd
    lxqt.lxqt-policykit
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

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
  };

  networking.firewall.allowedTCPPorts = [ 2234 2235 ];

  boot.loader.grub.theme = inputs.nixos-grub-themes.packages.${pkgs.system}.nixos;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.enableRedistributableFirmware = true;
  
  boot.loader.efi.canTouchEfiVariables = true;
  hardware.uinput.enable = true;

  environment.sessionVariables = {
    EDITOR = "nvim";
    MOZ_DISABLE_WAYLAND = "1";

    # Tell the OpenVINO backend to target the NPU.
    GGML_OPENVINO_DEVICE = "NPU";
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-curses;
  };

  systemd.services.ydotoold = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.ydotool}/bin/ydotoold";
      Group = "uinput";
    };
  };

  system.stateVersion = "25.11";
}
