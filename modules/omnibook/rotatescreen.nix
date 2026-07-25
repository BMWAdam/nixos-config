{ pkgs, config, ... }:
{
  hardware.sensor.iio.enable = true;
  programs.iio-hyprland.enable = true;
  systemd.services.iio-sensor-proxy.serviceConfig.ExecStart = pkgs.lib.mkForce [
  ""
    "${pkgs.iio-sensor-proxy}/libexec/iio-sensor-proxy"
  ];

  boot.kernelModules = [ 
    "amd_sfh"
    "intel_ish_ipc"
    "intel_ish_hid"    
    "hid_sensor_hub"
    "hid_sensor_accel_3d"
  ];

  # Inject the extracted HP proprietary ISH firmware
  hardware.firmware = [
    (pkgs.runCommand "hp-ish-firmware" {} ''
      mkdir -p $out/lib/firmware/intel/ish/
      cp ${./ish_lnlm.bin} $out/lib/firmware/intel/ish/ish_lnlm.bin
    '')
  ];

  services.hardware.bolt.enable = true;
}