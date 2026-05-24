{ config, pkgs, lib, ... }:

let
  defaultPasswordPath = config.sops.secrets.user_password.path;
in
{
  sops = {
    age.keyFile = "/etc/.config/sops/keys.txt";
    defaultSopsFile = ../../secrets/encrypted.yaml;

    secrets = {
      user_password = {
        neededForUsers = true;
      };

      ssh_key = {
        owner = "bmwadam";
      };

      git_email = {
        owner = "bmwadam";
        neededForUsers = false;
      };

      "wireless.env" = {
        format = "dotenv";
        sopsFile = ../../secrets/wireless.env;
        neededForUsers = true;
      };

      gpg_key = {
        owner = "bmwadam";
        neededForUsers = false;
      };

      latitude = {
        owner = "bmwadam";
        neededForUsers = false;
      };

      longitude = {
        owner = "bmwadam";
        neededForUsers = false;
      };
    };

    templates = {
      "gitconfig-local" = {
        path = "/home/bmwadam/.gitconfig.local";
        owner = "bmwadam";
        content = ''
          [user]
              email = ${config.sops.placeholder.git_email}
        '';
      };

      "location-env" = {
        path = "/run/location/env";
        owner = "root";
        mode = "0644";
        content = ''
          LATITUDE=${config.sops.placeholder.latitude}
          LONGITUDE=${config.sops.placeholder.longitude}
        '';
      };

      "clight.conf" = {
        path = "/home/bmwadam/.config/clight/clight.conf";
        owner = "bmwadam";
        mode = "0644";
        content = ''
          [sun]
          enable=true
          latitude=${config.sops.placeholder.latitude}
          longitude=${config.sops.placeholder.longitude}

          [backlight]
          enable=true
          min=1
          max=100
          idle_dim=true

          [als]
          enable=false

          [geoclue]
          enable=false
        '';
      };

      "clight.root.conf" = {
        path = "/root/.config/clight/clight.conf";
        owner = "bmwadam";
        mode = "0644";
        content = ''
          [sun]
          enable=true
          latitude=${config.sops.placeholder.latitude}
          longitude=${config.sops.placeholder.longitude}

          [backlight]
          enable=true
          min=1
          max=100
          idle_dim=true

          [als]
          enable=false

          [geoclue]
          enable=false
        '';
      };
    };
  };

  environment.variables = {
    DEFAULT_PASSWORD_PATH = defaultPasswordPath;
  };
}
