{ config, pkgs, lib, sshKeyPath, gitEmailPath, gpgKeyPath, ... }:

{
  programs.ssh.enable = true;
  programs.ssh.enableDefaultConfig = false;

  programs.ssh.settings = {
    "*" = {
      ForwardAgent = "yes";
    };
  };

  programs.ssh.matchBlocks = {
    "github.com" = {
      hostname = "github.com";
      user = "git";
      identityFile = sshKeyPath;
      forwardAgent = true;
    };
  };

  programs.git = {
    enable = true;

    settings = {
      user.name = "BMWAdam";
      gpg.program = "gpg";
      commit.gpgsign = true;
      tag.gpgsign = true;
    };

    signing = {
      key = "7F18869CB0048B1D";
      signByDefault = true;
    };

    extraConfig = {
      include = {
        path = "~/.gitconfig.local";
      };
    };
  };

  services.ssh-agent.enable = true;

  # -------------------------
  # SYSTEMD USER SERVICES
  # -------------------------

  # 2. GPG setup
  systemd.user.services.gpg-setup = {
    Unit = {
      Description = "Declarative GPG key import";
      After = [ "graphical-session.target" "gpg-agent.service" "sops-nix.service" ];
      ConditionPathExists = gpgKeyPath;
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "gpg-setup" ''
        ${pkgs.coreutils}/bin/mkdir -p ~/.gnupg
        ${pkgs.coreutils}/bin/chmod 700 ~/.gnupg

        for fpr in $(${pkgs.gnupg}/bin/gpg --list-secret-keys --with-colons | ${pkgs.gawk}/bin/awk -F: '/^fpr/ {print $10}'); do
          ${pkgs.gnupg}/bin/gpg --batch --yes --delete-secret-keys "$fpr" || true
          ${pkgs.gnupg}/bin/gpg --batch --yes --delete-keys "$fpr" || true
        done

        ${pkgs.gnupg}/bin/gpg --batch --import "${gpgKeyPath}" || true
      ''}";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
