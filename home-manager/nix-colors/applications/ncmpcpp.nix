{ pkgs, config, ... }:

{
  programs.ncmpcpp = {
    enable = true;
    package = pkgs.ncmpcpp.override { 
      visualizerSupport = true; # Enable visualizer if compiled with fftw
      taglibSupport = true;
    };

    # Corresponds to ~/.config/ncmpcpp/config
    settings = {
      mpd_host = "localhost";
      mpd_port = 6600;

      visualizer_data_source = "/tmp/mpd.fifo";
      visualizer_output_name = "mypipewire";
      visualizer_in_stereo = "yes";
      visualizer_type = "spectrum";

      progressbar_look = "─·";
      song_list_format = "{$7 %a - %t $R{$8 %l $9}}";
      user_interface = "alternative";

      # Maps to: base0D, base0C, base0B, base0A, base0E, base08
      visualizer_color = "blue, cyan, green, yellow, magenta, red";
      
      # List format: width [color]{tag}
      song_columns_list_format = "(20)[green]{a} (35)[white]{t} (30)[cyan]{b} (10)[magenta]{l}";

      # Color of the currently playing track
      current_item_prefix = "$(red)$r";
      current_item_suffix = "$/r$(end)";

      # General UI colors (Inheriting from the terminal's Base16 ANSI colors)
      colors_enabled = "yes";
      main_window_color = "white";
      header_window_color = "cyan";
      statusbar_color = "white";
      progressbar_color = "cyan";
    };

    # Corresponds to ~/.config/ncmpcpp/bindings
    bindings = [
      { key = "j"; command = "scroll_down"; }
      { key = "k"; command = "scroll_up"; }
    ];

    mpdMusicDir = "${config.home.homeDirectory}/Music";
  };

  services.mpd = {
    enable = true;

    musicDirectory = "${config.home.homeDirectory}/Music";

    network.listenAddress = "127.0.0.1";
    network.port = 6600;

    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire Output"
      }

      audio_output {
        type "fifo"
        name "Visualizer FIFO"
        path "/tmp/mpd.fifo"
        format "44100:16:2"
      }

      filesystem_charset "UTF-8"
      id3v1_encoding "UTF-8"

      auto_update "yes"
      auto_update_depth "10"
      follow_outside_symlinks "yes"
      follow_inside_symlinks "yes"
    '';
  };

  home.file.".config/ncmpcpp/colors".text = ''
    # ncmpcpp color definitions from nix-colors

    header_window_color = "#${config.colorScheme.palette.base0D}"
    volume_color = "#${config.colorScheme.palette.base0B}"
    state_line_color = "#${config.colorScheme.palette.base0C}"
    progressbar_color = "#${config.colorScheme.palette.base09}"
    statusbar_color = "#${config.colorScheme.palette.base0A}"
    song_list_color = "#${config.colorScheme.palette.base0E}"
    selected_item_color = "#${config.colorScheme.palette.base08}"
  '';
}
