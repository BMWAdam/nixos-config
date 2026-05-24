{ pkgs, inputs, ... }:
{
  imports = [
    inputs.nix-colors.homeManagerModules.default
    ./hyprland/hyprland.nix
    ./applications/firefox/firefox.nix
    ./applications/ncmpcpp.nix
    ./applications/alacritty.nix
    ./applications/calibre.nix
    ./applications/neovim.nix
  ];

  #colorScheme = inputs.nix-colors.colorSchemes.nord;
  colorScheme = inputs.nix-colors.colorSchemes.kanagawa;
  #colorScheme = inputs.nix-colors.colorSchemes.gruvbox-dark-medium;
}