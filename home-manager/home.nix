{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./zsh.nix
    ./direnv.nix
    ./nix-colors/nix-colors.nix
    ./git.nix
  ];

  nixpkgs.config.allowUnfree = true;

  home = {
    username = "bmwadam";
    homeDirectory = "/home/bmwadam";
  };

  programs.vscode = {
    enable = true;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      sainnhe.gruvbox-material
      yzhang.markdown-all-in-one
    ];
  };

  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
  };

  home.packages = with pkgs; [
    feh
  ];

  systemd.user.startServices = "sd-switch";
  home.stateVersion = "25.11";
}