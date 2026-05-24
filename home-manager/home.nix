{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  pythonEvdev = pkgs.python3.withPackages (ps: with ps; [ evdev ]);
in
{
  imports = [
    ./zsh.nix
    ./direnv.nix
    ./nix-colors/nix-colors.nix
    ./git.nix
  ];

  nixpkgs.config.allowUnfree = true;

  home = {
    username = "bmwadam";
    homeDirectory = "/home/bmwadam";
  };

  programs.vscode = {
    enable = true;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      sainnhe.gruvbox-material
      yzhang.markdown-all-in-one
    ];
  };

  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
  };

  home.packages = with pkgs; [
    feh
    procps
    swaylock-effects
    jq
    bc
    swaynotificationcenter
    pythonEvdev
  ];


  home.sessionVariables = {
    CALIBRE_VIEWER_USER_STYLESHEET = "${config.home.homeDirectory}/.config/calibre/viewer.css";
    NH_FLAKE = "${config.home.homeDirectory}/nixos-config";
  };

  home.file.".local/bin/hypr-gesture-cycle.py" = {
    text = ''
      #!${pythonEvdev}/bin/python3
      import subprocess
      import time
      from evdev import InputDevice, ecodes, list_devices

      DEVICE_KEYWORD = "Touchpad"
      CYCLE_DELAY = 0.18
      MIN_SAMPLES = 8
      MAGNITUDE_THRESHOLD = 0.015

      FINGER_CODES = {
          ecodes.BTN_TOOL_FINGER: 1,
          ecodes.BTN_TOOL_DOUBLETAP: 2,
          ecodes.BTN_TOOL_TRIPLETAP: 3,
          ecodes.BTN_TOOL_QUADTAP: 4,
          ecodes.BTN_TOOL_QUINTTAP: 5,
      }

      def find_touchpad(keyword=DEVICE_KEYWORD):
          print("[SCAN] Scanning input devices...", flush=True)
          for path in list_devices():
              dev = InputDevice(path)
              print(f"[SCAN] Found: {dev.name} ({path})", flush=True)
              if keyword.lower() in dev.name.lower():
                  print(f"[INIT] Selected touchpad: {dev.name}", flush=True)
                  return dev
          raise RuntimeError("Touchpad not found.")

      def get_axis_ranges(dev):
          caps = dev.capabilities()
          abs_caps = dict(caps.get(ecodes.EV_ABS, []))
          x_info = abs_caps.get(ecodes.ABS_MT_POSITION_X) or abs_caps.get(ecodes.ABS_X)
          y_info = abs_caps.get(ecodes.ABS_MT_POSITION_Y) or abs_caps.get(ecodes.ABS_Y)
          x_range = float((x_info.max - x_info.min) if x_info else 1000)
          y_range = float((y_info.max - y_info.min) if y_info else 1000)
          print(f"[INIT] Axis ranges: x={x_range}, y={y_range}", flush=True)
          return x_range, y_range

      def cycle(prev=False):
          cmd = ["hyprctl", "dispatch", "cyclenext"]
          if prev:
              cmd.append("prev")
          direction = "prev" if prev else "next"
          print(f"[DISPATCH] cyclenext {direction}", flush=True)
          subprocess.run(cmd)

      def main():
          dev = find_touchpad()
          x_range, y_range = get_axis_ranges(dev)

          active_tools = set()
          fingers = 0

          vectors = []
          last_trigger = 0.0

          last_x = None
          last_y = None
          pending_dx = None

          print("[READY] Listening for events...", flush=True)

          for event in dev.read_loop():
              # -----------------------------
              # FINGER COUNT TRACKING
              # -----------------------------
              if event.type == ecodes.EV_KEY and event.code in FINGER_CODES:
                  if event.value == 1:
                      active_tools.add(event.code)
                  elif event.value == 0 and event.code in active_tools:
                      active_tools.remove(event.code)

                  new_fingers = max([FINGER_CODES[code] for code in active_tools], default=0)

                  if new_fingers != fingers:
                      print(f"[FINGERS] Transition: {fingers} → {new_fingers} fingers", flush=True)
                      fingers = new_fingers

                      if fingers != 3:
                          print("[STATE] Not 3 fingers → resetting", flush=True)
                          vectors.clear()
                          last_x = None
                          last_y = None
                          pending_dx = None
                      else:
                          print("[STATE] 3 FINGERS ACTIVE", flush=True)

              # -----------------------------
              # MOVEMENT — collect normalized (dx, dy) vector samples
              # -----------------------------
              if fingers == 3 and event.type == ecodes.EV_ABS:

                  if event.code == ecodes.ABS_MT_POSITION_X:
                      if last_x is not None:
                          dx = event.value - last_x
                          if abs(dx) < 300:
                              pending_dx = dx / x_range
                      last_x = event.value

                  elif event.code == ecodes.ABS_MT_POSITION_Y:
                      if last_y is not None:
                          dy = event.value - last_y
                          if abs(dy) < 300:
                              norm_dx = pending_dx if pending_dx is not None else 0.0
                              norm_dy = dy / y_range
                              vectors.append((norm_dx, norm_dy))
                              pending_dx = None
                      last_y = event.value

              # -----------------------------
              # THRESHOLD CHECK — fires repeatedly while gesture continues
              # -----------------------------
              if fingers == 3 and len(vectors) >= MIN_SAMPLES:
                  now = time.time()
                  if now - last_trigger >= CYCLE_DELAY:

                      avg_x = sum(v[0] for v in vectors) / len(vectors)
                      avg_y = sum(v[1] for v in vectors) / len(vectors)
                      magnitude = (avg_x ** 2 + avg_y ** 2) ** 0.5

                      if magnitude >= MAGNITUDE_THRESHOLD:
                          dominant = avg_x if abs(avg_x) > abs(avg_y) else avg_y
                          go_prev = dominant < 0
                          direction = "prev" if go_prev else "next"

                          print("[FIRE] avg_x=" + str(round(avg_x, 4)) + " avg_y=" + str(round(avg_y, 4)) + " mag=" + str(round(magnitude, 4)) + " -> cyclenext " + direction, flush=True)

                          cycle(prev=go_prev)
                          last_trigger = now
                      # always clear vectors after checking so we get a fresh
                      # window of samples for the next potential fire
                      vectors.clear()

      if __name__ == "__main__":
          main()
    '';
    executable = true;
  };

  systemd.user.services.hypr-gesture-cycle = {
    Unit = {
      Description = "Hyprland workspace cycling via touchpad gestures";
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pythonEvdev}/bin/python3 ${config.home.homeDirectory}/.local/bin/hypr-gesture-cycle.py";
      Restart = "always";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.startServices = "sd-switch";
  home.stateVersion = "25.11";
}