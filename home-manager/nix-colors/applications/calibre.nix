{ pkgs, config, ... }:

{
  home.file.".config/calibre/viewer.css".text = ''
    body {
      background: #${config.colorScheme.palette.base03};
      color: #${config.colorScheme.palette.base00};
    }

    a {
      color: #${config.colorScheme.palette.base0D};
    }

    ::selection {
      background: #${config.colorScheme.palette.base02};
      color: #${config.colorScheme.palette.base01};
    }
  '';
}