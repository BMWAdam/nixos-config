{ config, ... }:
{
  services.tlp = {
    enable = true;
  };

  systemd.services.dock-charge-limiter = {
    description = "Continuously monitor for dock and limit battery charging";
    wantedBy = [ "multi-user.target" ];
    after = [ "tlp.service" ]; 
    
    path = with pkgs; [ usbutils tlp gnugrep coreutils ];
    
    script = ''
      DOCK_ID="03f0:04b7"
      
      PREV_STATE="UNKNOWN"

      while true; do
      # Check if the dock is connected via USB
      if lsusb | grep -q "$DOCK_ID"; then
          IS_DOCKED=1
      else
          IS_DOCKED=0
      fi

      # power is connected
      if grep -q "1" /sys/class/power_supply/*/online 2>/dev/null; then
          IS_AC=1
      else
          IS_AC=0
      fi

      # Determine target state
      if [ "$IS_DOCKED" -eq 1 ] && [ "$IS_AC" -eq 1 ]; then
          CUR_STATE="LIMIT"
      else
          CUR_STATE="FULL"
      fi

      # Apply changes
      if [ "$CUR_STATE" != "$PREV_STATE" ]; then
          if [ "$CUR_STATE" = "LIMIT" ]; then
          echo "Dock connected and charging. Limiting charge to 80%."
          tlp setcharge 40 80 BAT0
          else
          echo "Not docked or not on AC. Allowing full charge."
          tlp fullcharge BAT0
          fi
          PREV_STATE="$CUR_STATE"
      fi

      # Wait before checking again
      sleep 10
      done
    '';
  };
}