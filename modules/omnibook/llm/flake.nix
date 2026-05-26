{
  description = "OpenVINO GenAI NPU LLM Runner";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs   = import nixpkgs { inherit system; config.allowUnfree = true; };
    python = pkgs.python312;
    libs   = pkgs.lib.makeLibraryPath (with pkgs; [
      stdenv.cc.cc.lib
      zlib
      libGL
      glib
      tbb
      numactl
      level-zero
    ]);
  in {
    packages.${system}.default = pkgs.writeShellApplication {
      name = "npu-llm-runner";
      runtimeInputs = with pkgs; [
        (python.withPackages (ps: [ ps.pip ]))
        rustc
        cargo
        gcc
        pkg-config
      ];
      text = ''
        export LD_LIBRARY_PATH="${libs}:''${LD_LIBRARY_PATH:-}"
        export PACKAGES_DIR="$HOME/.cache/npu-llm-runner/packages"
        export PYTHONPATH="$PACKAGES_DIR:''${PYTHONPATH:-}"
        export PATH="$PACKAGES_DIR/bin:''${PATH:-}"
        if [ ! -f "$PACKAGES_DIR/.installed" ]; then
          echo "Installing OpenVINO and Optimum libraries to $PACKAGES_DIR..."
          mkdir -p "$PACKAGES_DIR"
          python3 -m pip install \
            --target="$PACKAGES_DIR" \
            --quiet \
            --disable-pip-version-check \
            "torch==2.3.1" \
            "transformers==4.40.2" \
            "tokenizers==0.19.1" \
            "optimum==1.21.4" \
            "optimum-intel[openvino]==1.18.0" \
            "openvino==2024.3.0" \
            "openvino-genai==2024.3.0" \
            "openvino-tokenizers==2024.3.0.0" \
            "nncf==2.11.0" \
            "gguf" \
          && touch "$PACKAGES_DIR/.installed"
        fi
        exec python3 ${./main.py} "$@"
      '';
    };
    apps.${system}.default = {
      type    = "app";
      program = "${self.packages.${system}.default}/bin/npu-llm-runner";
    };
  };
}