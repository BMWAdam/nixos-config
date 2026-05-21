{ config, lib, pkgs, ... }:

{
  networking.networkmanager.enable = true;

  networking.networkmanager.ensureProfiles = {
    environmentFiles = [
      config.sops.secrets."wireless.env".path
    ];

    profiles."home" = {
      connection.id = "home";
      connection.type = "wifi";

      wifi.ssid = "$home_ssid";

      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "$home_psk";
      };
    };
  };
}
