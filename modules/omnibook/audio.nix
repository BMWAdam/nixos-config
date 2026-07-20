{ pkgs, config, inputs, ... }:
{
  imports = [
    inputs.nix-eq.nixosModules.default
  ];

  services.nix-eq = {
    enable = true;
    presets = {
      sony = ./apo/sony.txt; 
    };
  };

  systemd.user.services.nix-eqd.postStart = ''
    sleep 2
    /run/current-system/sw/bin/nix-eq toggle sony
  '';

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        FastConnectable = true;
        JustWorksRepairing = "always";
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  systemd.services.auto-connect-sony = {
    description = "Auto-connect Sony headphones";
    wantedBy = [ "multi-user.target" ];
    after = [ "bluetooth.service" "sops-nix.service" ];
    requires = [ "bluetooth.service" ];

    path = with pkgs; [ bluez gnugrep coreutils ];

    script = ''
      # Read the MAC address and strip any accidental newlines/spaces from the secret
      MAC=$(tr -d '[:space:]' < "${config.sops.secrets.sony_bt.path}")
      
      while true; do
        # If 'Connected: yes' is not found in the device info, attempt connection
        if ! bluetoothctl info "$MAC" | grep -q "Connected: yes"; then
          # Output is routed to /dev/null to prevent massive journal spam when headphones are off
          bluetoothctl connect "$MAC" > /dev/null 2>&1 || true
        fi
        
        sleep 10
      done
    '';

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "5";
    };
  };

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.blueman.enable = true;
}