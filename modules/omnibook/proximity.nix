{ pkgs, lib, config, ... }:
{
  systemd.services.iio-sensor-proxy = {
    description = "IIO Sensor Proxy";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.iio-sensor-proxy}/libexec/iio-sensor-proxy";
    };
  };
}