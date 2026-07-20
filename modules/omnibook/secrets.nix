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

      sony_bt = {
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
    };
  };

  environment.variables = {
    DEFAULT_PASSWORD_PATH = defaultPasswordPath;
  };
}
