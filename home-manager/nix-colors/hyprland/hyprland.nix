{ pkgs,
  config,
  inputs,
  ...
}:
let
  colorsPath = "${config.home.homeDirectory}/.config/eww/_colors.scss";
  mod = "SUPER";
  wallpaper = toString ../../../wallpapers/planet.jpg;

  recoloredWallpaper = pkgs.runCommand "theme-wallpaper.jpg" {
    nativeBuildInputs = [ pkgs.imagemagick ];
  } ''
    # The +level-colors flag maps black to black, and white to your hex color.
    # Gray pixels (like anti-aliased edges or dim stars) will be tinted beautifully.
    magick ${../../../wallpapers/planet.jpg} +level-colors "black,#${config.colorScheme.palette.base0D}" $out
  '';

  recoloredWallpaperPath = toString recoloredWallpaper;

  abstractWallpaper = pkgs.runCommand "abstract-wallpaper.jpg" {
    # Added imagemagick to the build inputs
    buildInputs = [ pkgs.python3 pkgs.imagemagick ];
  } ''
    cat << 'EOF' > generate.py
    import random

    # Seed the random generator with the theme colors so it's deterministic for Nix,
    # but generates a totally unique layout whenever you change themes!
    random.seed("${config.colorScheme.palette.base00}${config.colorScheme.palette.base05}")

    width, height = 736, 736
    colors = [
        "#${config.colorScheme.palette.base01}", "#${config.colorScheme.palette.base02}", "#${config.colorScheme.palette.base03}",
        "#${config.colorScheme.palette.base04}", "#${config.colorScheme.palette.base05}", "#${config.colorScheme.palette.base06}",
        "#${config.colorScheme.palette.base07}", "#${config.colorScheme.palette.base08}", "#${config.colorScheme.palette.base09}",
        "#${config.colorScheme.palette.base0A}", "#${config.colorScheme.palette.base0B}", "#${config.colorScheme.palette.base0C}",
        "#${config.colorScheme.palette.base0D}", "#${config.colorScheme.palette.base0E}", "#${config.colorScheme.palette.base0F}"
    ]

    # Start SVG with base00 as the background
    svg = f'<svg width="{width}" height="{height}" xmlns="http://www.w3.org/2000/svg" style="background-color:#${config.colorScheme.palette.base00}">'

    # Generate 60 abstract geometric shapes with varying opacities
    for _ in range(60):
        shape_type = random.choice(["circle", "rect", "polygon"])
        color = random.choice(colors)
        opacity = random.uniform(0.1, 0.5) # Blends shapes nicely

        if shape_type == "circle":
            cx = random.randint(0, width)
            cy = random.randint(0, height)
            r = random.randint(50, 400)
            svg += f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{color}" fill-opacity="{opacity}" />'

        elif shape_type == "rect":
            x = random.randint(0, width)
            y = random.randint(0, height)
            w = random.randint(100, 600)
            h = random.randint(100, 600)
            # Optional: add a slight rotation for abstract flavor
            transform = f'transform="rotate({random.randint(0, 90)} {x} {y})"'
            svg += f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{color}" fill-opacity="{opacity}" {transform} />'

        elif shape_type == "polygon":
            # Generates a random abstract triangle
            points = " ".join(f"{random.randint(0, width)},{random.randint(0, height)}" for _ in range(3))
            svg += f'<polygon points="{points}" fill="{color}" fill-opacity="{opacity}" />'

    svg += '</svg>'

    # Write to a local temporary file name
    with open("abstract.svg", "w") as f:
        f.write(svg)
    EOF

    # Run the script to generate the SVG
    python3 generate.py
    
    # Use ImageMagick to convert the SVG to a JPG and write it directly to the Nix output
    magick abstract.svg $out
  '';
in {
  programs.ranger.enable = true;
  programs.fuzzel.enable = true;

  programs.eww = {
    enable = true;
    yuckConfig = builtins.readFile ./eww-config/eww.yuck;
    scssConfig = builtins.readFile ./eww-config/eww.scss;
  };

  home.file.".config/eww/bar/bar.yuck".source = ./eww-config/bar/bar.yuck;
  home.file.".config/eww/scripts" = {
    source = ./eww-config/scripts;
    recursive = true;
  };

  home.file.".config/eww/music-widget" = {
    source = ./eww-config/music-widget;
    recursive = true;
  };

  home.file.".config/eww/bar/bar.scss".text = ''
    @use "${colorsPath}" as colors;
    ${builtins.readFile ./eww-config/bar/bar.scss}
  '';
  
  home.file.".config/eww/music-widget/eww.scss".text = ''
    @use "${colorsPath}" as colors;
    ${builtins.readFile ./eww-config/music-widget/base.eww.scss}
  '';


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

  home.packages = with pkgs; [
    libnotify
    hyprlock
  ];

  home.file.".config/lock-safe.sh" = {
    executable = true;
    text = ''
#!/usr/bin/env bash
if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    exit 0
fi

if ! pgrep -x hyprlock >/dev/null; then
    hyprlock
fi
    '';
  };

  home.file.".config/dpms-safe.sh" = {
    executable = true;
    text = ''
#!/usr/bin/env bash
ACTION="$1"
if [ "$ACTION" = "off" ]; then
    hyprctl dispatch dpms off
elif [ "$ACTION" = "on" ]; then
    hyprctl dispatch dpms on
fi
    '';
  };

  home.file.".config/hypr/handle-rotation.sh" = {
    text = ''
      #! /usr/bin/env nix-shell
      #! nix-shell -i bash -p jq iio-sensor-proxy

      set_initial_state() {
          ROT=$(hyprctl monitors -j | jq -r '.[] | select(.name == "eDP-1") | .transform')
          if [ "$ROT" = "1" ] || [ "$ROT" = "3" ]; then
              eww open dock 2>/dev/null
          else
              eww close dock 2>/dev/null
          fi
      }

      set_initial_state

      monitor-sensor | while read -r line; do
          if [[ "$line" == *"Accelerometer orientation changed:"* ]]; then
              
              ORIENTATION=$(echo "$line" | awk -F': ' '{print $2}')
              
              if [[ "$ORIENTATION" == "right-up" || "$ORIENTATION" == "left-up" ]]; then
                  echo "opening dock..."
                  eww open dock 2>/dev/null
              elif [[ "$ORIENTATION" == "normal" || "$ORIENTATION" == "bottom-up" ]]; then
                  echo "closing dock"
                  eww close dock 2>/dev/null
              fi
              
          fi
      done
    '';
    executable = true;
  };

  # -----------------------------------------------------------
  # HYPRIDLE CONFIGURATION
  # -----------------------------------------------------------
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        ignore_dbus_inhibit = false;
        lock_cmd = "${config.home.homeDirectory}/.config/lock-safe.sh";
        before_sleep_cmd = "${config.home.homeDirectory}/.config/lock-safe.sh";
        after_sleep_cmd = "${config.home.homeDirectory}/.config/dpms-safe.sh on && ${pkgs.eww}/bin/eww open bar && ${config.home.homeDirectory}/.config/hypr/check-dock.sh";
      };

      listener = [
        {
          timeout = 60;
          on-timeout = "${config.home.homeDirectory}/.config/lock-safe.sh";
        }
        {
          timeout = 80;
          # Turn off the display AND nuke the Eww daemon entirely
          on-timeout = "${config.home.homeDirectory}/.config/dpms-safe.sh off ; pkill eww";
          
          # Turn on the display, spin Eww back up, AND run check-dock.sh
          on-resume = "${config.home.homeDirectory}/.config/dpms-safe.sh on ; pkill eww ; sleep 0.5 ; ${pkgs.eww}/bin/eww open bar ; ${config.home.homeDirectory}/.config/hypr/check-dock.sh";
        }
        {
          # 3. Deep sleep system
          timeout = 300;
          on-timeout = "pkill eww && systemctl suspend";
        }
      ];
    };
  };

  #"sleep 1 && hyprctl hyprpaper preload ${recoloredWallpaperPath}"
  #"sleep 3 && hyprctl hyprpaper wallpaper ',${recoloredWallpaperPath}'"

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    package = pkgs.hyprland;

    settings = {
      monitor = "eDP-1,2880x1800@120,auto,2,vrr,1";

      exec-once = [
        "pkill eww ; sleep 1 ; eww open bar"
        "iio-hyprland &"
        "lxqt-policykit-agent &"
        "hyprctl dispatch workspace 1"
        "${config.home.homeDirectory}/.config/hypr/handle-rotation.sh &"
      ];

      env = [
        "XCURSOR_THEME,Adwaita"
        "XCURSOR_SIZE,20"
      ];

      input = {
        kb_layout = "us,cz";
        kb_options = "grp:alt_shift_toggle";
        numlock_by_default = true;
        follow_mouse = 1;

        touchpad = {
          disable_while_typing = true;
          natural_scroll = true;
          drag_lock = true;
        };
      };

      cursor = {
        no_warps = false;
      };

      gestures = {
        workspace_swipe_forever = true;

        gesture = [
          "4, horizontal, workspace"
          "4, down, close"
          "4, up, fullscreen"
        ];
      };

      general = {
        gaps_in = 10;
        gaps_out = 10;
        border_size = 2;

        "col.active_border" = "rgb(${config.colorScheme.palette.base0D})";
        "col.inactive_border" = "rgb(${config.colorScheme.palette.base01})";
        layout = "dwindle";
      };

      dwindle = {
        preserve_split = true;
        force_split = 2;
      };

      decoration = {
        rounding = 15;

        blur = {
          enabled = true;
          size = 4;
          passes = 4;
          xray = false;
          ignore_opacity = true;
        };

        dim_inactive = true;
        dim_strength = 0.05;

        active_opacity = 1.0;
        inactive_opacity = 0.75;
      };

      animations = {
        enabled = true;

        bezier = [
          "wind, 0.05, 0.9, 0.1, 1.05"
          "winIn, 0.1, 1.1, 0.1, 1.1"
          "winOut, 0.3, -0.3, 0, 1"
          "liner, 1, 1, 1, 1"
        ];

        animation = [
          "windows, 1, 6, wind, slide"
          "windowsIn, 1, 6, winIn, slide"
          "windowsOut, 1, 5, winOut, slide"
          "windowsMove, 1, 5, wind, slide"
          "border, 1, 1, default"
          "borderangle, 1, 30, default, loop"
          "fade, 1, 10, default"
          "workspaces, 1, 5, wind"
        ];
      };

      misc = {
        vrr = 1;

        #force_default_wallpaper = 0;
        #disable_hyprland_logo = true;
      };

      layerrule = [
        "blur on, match:namespace eww"
        "blur on, match:namespace waybar"
        "blur on, match:namespace wofi"
        "blur on, match:namespace gtk-layer-shell"
        "blur on, match:namespace avizo"
        "ignore_alpha 0, match:namespace wofi"
        "ignore_alpha 0, match:namespace avizo"
      ];

      bind = [
        "${mod}, m, exec, ${config.home.homeDirectory}/.config/lock-safe.sh"
        "${mod}, q, killactive,"
        "${mod}, f, fullscreen,"

        "${mod}, left, movefocus, l"
        "${mod}, right, movefocus, r"
        "${mod}, up, movefocus, u"
        "${mod}, down, movefocus, d"

        "${mod}, h, movefocus, l"
        "${mod}, j, movefocus, d"
        "${mod}, k, movefocus, u"
        "${mod}, l, movefocus, r"

        "${mod} SHIFT, h, movewindow, l"
        "${mod} SHIFT, j, movewindow, d"
        "${mod} SHIFT, k, movewindow, u"
        "${mod} SHIFT, l, movewindow, r"

        "${mod}, return, exec, alacritty"
        "${mod}, p, exec, wofi --show drun --allow-images --lines 7 --prompt \"Run:\""
      ] ++ (
        map (n: "${mod}, ${toString n}, workspace, ${toString n}") (builtins.genList (x: x + 1) 9)
      ) ++ (
        map (n: "${mod} SHIFT, ${toString n}, movetoworkspace, ${toString n}") (builtins.genList (x: x + 1) 9)
      );

      # -----------------------------------------------------------
      # MEDIA & BRIGHTNESS KEYS
      # -----------------------------------------------------------
      bindel = [
        # Volume
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        
        # Brightness
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];

      bindl = [
        # Mute
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        
        # Optional: Media control keys (Play/Pause, Next, Previous)
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioNext, exec, playerctl next"
      ];
    };
  };

  programs.wofi = {
    enable = true;

    settings = {
      show = "drun";
      allow_images = true;
      prompt = "Run:";
      term = "alacritty";
      width = "600px";
      height = "400px";
      lines = 15;
      location = "center";
      hide_scroll = false;
      insensitive = true;

      key_down = "Ctrl-n";
      key_up = "Ctrl-p";
    };

    style = ''
      window {
        margin: 0px;
        border: 2px solid #${config.colorScheme.palette.base02};
        background-color: #${config.colorScheme.palette.base00};
        border-radius: 12px;
        color: #${config.colorScheme.palette.base05};
      }

      #input {
        margin: 10px;
        padding: 8px;
        border-radius: 8px;
        background-color: #${config.colorScheme.palette.base01};
        color: #${config.colorScheme.palette.base05};
        border: 1px solid #${config.colorScheme.palette.base02};
      }

      #entry {
        padding: 6px;
        margin: 4px;
        border-radius: 6px;
        background-color: transparent;
        color: #${config.colorScheme.palette.base05};
      }

      #entry:selected {
        background-color: #${config.colorScheme.palette.base02};
        color: #${config.colorScheme.palette.base0D};
      }

      image {
        margin-right: 8px;
      }
    '';
  };

  # -----------------------------------------------------------
  # HYPRLOCK CONFIGURATION
  # -----------------------------------------------------------
  home.file.".config/hypr/hyprlock.conf".text = ''
    background {
        monitor =
        path = screenshot
        color = rgb(${config.colorScheme.palette.base00})
        blur_passes = 2
        blur_size = 8
    }

    input-field {
        monitor =
        size = 250, 60
        outline_thickness = 3
        dots_size = 0.2
        dots_spacing = 0.2
        dots_center = true
        outer_color = rgb(${config.colorScheme.palette.base0D})
        inner_color = rgb(${config.colorScheme.palette.base02})
        font_color = rgb(${config.colorScheme.palette.base06})
        fade_on_empty = false
        placeholder_text =
        hide_input = false
        position = 0, -50
        halign = center
        valign = center
    }

    label {
        monitor =
        text = cmd[update:1000] echo "$(date +"%H:%M")"
        color = rgb(${config.colorScheme.palette.base06})
        font_size = 80
        font_family = Agave Nerd Font
        position = 0, 100
        halign = center
        valign = center
    }

    auth { 
      fingerprint:enabled = true
      pam:enabled = true
    }
  '';

  home.file.".config/swaync/config.json".text = ''
    {
      "position": "top-right",
      "layer": "overlay",
      "cssPriority": "user"
    }
  '';

  home.file.".config/swaync/widgets/notifications".text = ''
    max=50
  '';

  home.file.".config/swaync/widgets/title".text = ''
    visible=true
  '';

  home.file.".config/swaync/widgets/dnd".text = ''
    visible=true
  '';

  home.file.".config/eww/music-widget/assets/default.jpg".source = abstractWallpaper;

  home.file.".config/hypr/check-dock.sh" = {
    executable = true;
    text = ''
      #! /usr/bin/env nix-shell
      #! nix-shell -i bash -p jq
      
      # Give Eww a brief moment to finish launching the daemon and bar
      sleep 0.5
      
      ROT=$(hyprctl monitors -j | jq -r '.[] | select(.name == "eDP-1") | .transform')
      
      if [ "$ROT" = "1" ] || [ "$ROT" = "3" ]; then
          eww open dock 2>/dev/null
      else
          eww close dock 2>/dev/null
      fi
    '';
  };

  home.file.".config/swaync/style.css".text = ''
    @define-color base00 #${config.colorScheme.palette.base00};
    @define-color base01 #${config.colorScheme.palette.base01};
    @define-color base02 #${config.colorScheme.palette.base02};
    @define-color base03 #${config.colorScheme.palette.base03};
    @define-color base04 #${config.colorScheme.palette.base04};
    @define-color base05 #${config.colorScheme.palette.base05};
    @define-color base06 #${config.colorScheme.palette.base06};
    @define-color base07 #${config.colorScheme.palette.base07};
    @define-color base08 #${config.colorScheme.palette.base08};
    @define-color base09 #${config.colorScheme.palette.base09};
    @define-color base0A #${config.colorScheme.palette.base0A};
    @define-color base0B #${config.colorScheme.palette.base0B};
    @define-color base0C #${config.colorScheme.palette.base0C};
    @define-color base0D #${config.colorScheme.palette.base0D};
    @define-color base0E #${config.colorScheme.palette.base0E};
    @define-color base0F #${config.colorScheme.palette.base0F};

    .notification {
      background-color: @base00;
      border: 1px solid @base02;
      color: @base05;
      border-radius: 8px;
      padding: 10px;
    }

    .notification-title {
      color: @base0D;
      font-weight: bold;
    }

    .notification-body {
      color: @base05;
    }

    button {
      background-color: @base02;
      color: @base05;
      border-radius: 6px;
      padding: 4px 8px;
    }

    button:hover {
      background-color: @base03;
    }
  '';

  systemd.user.services.swaync = {
    Unit = {
      Description = "Sway Notification Center";
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
      Restart = "on-failure";
      Environment = "PATH=${pkgs.swaynotificationcenter}/bin:${pkgs.coreutils}/bin";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [
        "${recoloredWallpaperPath}"
      ];
      wallpaper = [
        # By display
        # {
        #   monitor = "DP-2";
        #   path = "~/wallpapers/wallpaper2.jpg";
        # }
        # By default/fallback
        {
          monitor = "";
          path = "${recoloredWallpaperPath}"; 
        }
      ];
    };
  };
}