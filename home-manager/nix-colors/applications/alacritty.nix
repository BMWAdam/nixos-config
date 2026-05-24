{ pkgs, config, ... }:

let
  p = config.colorScheme.palette;

  hexMap = {
    "0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4; "5" = 5; "6" = 6; "7" = 7;
    "8" = 8; "9" = 9; "a" = 10; "b" = 11; "c" = 12; "d" = 13; "e" = 14; "f" = 15;
    "A" = 10; "B" = 11; "C" = 12; "D" = 13; "E" = 14; "F" = 15;
  };

  hexToDec = hexStr: 
    let
      c1 = builtins.substring 0 1 hexStr;
      c2 = builtins.substring 1 1 hexStr;
    in
      (hexMap.${c1} * 16) + hexMap.${c2};

  decToHex = dec:
    let
      intDiv = dec / 16;
      rem = dec - (intDiv * 16);
      hexChars = [ "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "a" "b" "c" "d" "e" "f" ];
    in
      "${builtins.elemAt hexChars intDiv}${builtins.elemAt hexChars rem}";

  clamp = val: if val > 255 then 255 else (if val < 0 then 0 else val);

  scaleColor = factor: hex6:
    let
      rDec = hexToDec (builtins.substring 0 2 hex6);
      gDec = hexToDec (builtins.substring 2 2 hex6);
      bDec = hexToDec (builtins.substring 4 2 hex6);
      
      rScaled = clamp (builtins.floor (rDec * factor));
      gScaled = clamp (builtins.floor (gDec * factor));
      bScaled = clamp (builtins.floor (bDec * factor));
    in
      "${decToHex rScaled}${decToHex gScaled}${decToHex bScaled}";

  scaleFactor = if config.colorScheme.variant == "light" then 1.35 else 1.20;
  adjust = scaleColor scaleFactor;
in
{
  programs.alacritty.enable = true;
  programs.alacritty.settings = {
    window = {
      padding = {
        x = 12; # Pixels of padding on the left and right sides
        y = 12; # Pixels of padding on the top and bottom sides
      };
    };

    colors = {
      primary = {
        background = "0x${p.base00}";
        foreground = "0x${p.base06}";
      };

      cursor = {
        cursor = "0x${p.base06}";
        text = "0x${p.base06}";
      };

      normal = {
        black   = "0x${p.base00}";
        red     = "0x${p.base08}";
        green   = "0x${p.base0B}";
        yellow  = "0x${p.base0A}";
        blue    = "0x${p.base0D}";
        magenta = "0x${p.base0E}";
        cyan    = "0x${p.base0C}";
        white   = "0x${p.base06}";
      };

      bright = {
        black   = "0x${adjust p.base03}";
        red     = "0x${adjust p.base08}";
        green   = "0x${adjust p.base0B}";
        yellow  = "0x${adjust p.base0A}";
        blue    = "0x${adjust p.base0D}";
        magenta = "0x${adjust p.base0E}";
        cyan    = "0x${adjust p.base0C}";
        white   = "0x${adjust p.base06}";
      };
    };
  };
}
