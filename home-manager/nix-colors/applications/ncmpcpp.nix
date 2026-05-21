{ pkgs, config, ... }:

{
  programs.ncmpcpp.enable = true;
  programs.ncmpcpp.mpdMusicDir = "/home/bmwadam/Music";
  services.mpd.enable = true;
  services.mpd.musicDirectory = "/home/bmwadam/Music";
}
