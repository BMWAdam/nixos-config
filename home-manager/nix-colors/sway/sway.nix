{ pkgs,
  config,
  inputs,
  ...
}:
let
  colorsPath = "${config.home.homeDirectory}/.config/eww/_colors.scss";
in {
  programs.ranger.enable = true;
  programs.fuzzel.enable = true;

  programs.eww = {
    enable = true;
    yuckConfig = builtins.readFile ./eww-config/eww.yuck;
    scssConfig = builtins.readFile ./eww-config/eww.scss;
  };

  home.file.".config/eww/bar/bar.yuck" = {
    source = ./eww-config/bar/bar.yuck;
    # recursive = true;
  };

  home.file.".config/eww/scripts" = {
    source = ./eww-config/scripts;
    recursive = true;
  };

  home.file.".config/eww/bar/bar.scss" = {
    text = ''
      @use "${colorsPath}" as colors;
      ${builtins.readFile ./eww-config/bar/bar.scss}
    '';
  };

  home.file.".config/eww/_colors.scss" = {
    text = ''
      $base00: #${config.colorScheme.palette.base00};
      $base01: #${config.colorScheme.palette.base01};
      $base02: #${config.colorScheme.palette.base02};
      $base03: #${config.colorScheme.palette.base03};
      $base04: #${config.colorScheme.palette.base04};
      $base05: #${config.colorScheme.palette.base05};
      $base06: #${config.colorScheme.palette.base06};
      $base07: #${config.colorScheme.palette.base07};
      $base08: #${config.colorScheme.palette.base08};
      $base09: #${config.colorScheme.palette.base09};
      $base0a: #${config.colorScheme.palette.base0A};
      $base0b: #${config.colorScheme.palette.base0B};
      $base0c: #${config.colorScheme.palette.base0C};
      $base0d: #${config.colorScheme.palette.base0D};
      $base0e: #${config.colorScheme.palette.base0E};
      $base0f: #${config.colorScheme.palette.base0F};
    '';
  };

  home.sessionVariables.NIXOS_OZONE_WL = "1";

  wayland.windowManager.sway = {
    enable = true;

    config = rec {
      focus.followMouse = true;

      modifier = "Mod4";
      terminal = "alacritty";

      startup = [
        { command = "eww open bar"; }
        { command = "swaymsg workspace 1"; }
      ];

      bars = [];

      fonts = {
        names = [ "CMU Serif" "Symbols Nerd Font" ];
        style = "Serif";
        size = 20.0;
      };

      gaps = {
        smartGaps = false;
        smartBorders = "off";
        inner = 10;
        outer = 10;
      };

      window.titlebar = false;

      # Keyboard settings
      input."*" = {
        xkb_layout = "us,cz";
        xkb_options = "grp:alt_shift_toggle";
        xkb_numlock = "enabled";
      };

      input."type:touchpad" = {
        natural_scroll = "enabled";
        tap = "enabled";
        dwt = "enabled"; # disable while typing
      };
    };
  };
}
