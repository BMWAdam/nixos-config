{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "dotenv" ];
      theme = "robbyrussell";
    };

    initContent = ''
      if [ -n "$IN_NIX_SHELL" ]; then
        export PS1="(nix-shell) $PS1"
      fi
    '';
  };
}