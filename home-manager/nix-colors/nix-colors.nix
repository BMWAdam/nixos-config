{ pkgs, inputs, ... }:
{
  imports = [
    inputs.nix-colors.homeManagerModules.default
    ./sway/sway.nix
    ./applications/firefox/firefox.nix
    ./applications/ncmpcpp.nix
    ./applications/alacritty.nix
  ];

  colorScheme = inputs.nix-colors.colorSchemes.gruvbox-dark-medium;
}