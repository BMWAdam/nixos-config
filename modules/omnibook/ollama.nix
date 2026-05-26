{ pkgs, config, ... }:

let
  llama3_2_3b_q4 = pkgs.fetchurl {
    url = "https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf";
    # Re-run `nix-prefetch-url <url>` to get the real sha256 for this file.
    sha256 = "sha256-bBorQRYQMmd74WjTVBI1lMDm5n0rkifITylq0DfHKP8=";
  };

  phi3_mini_q4 = pkgs.fetchurl {
    url = "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf";
    sha256 = "sha256-ioPH+5BJqbLpImb6etBJM7tTqh6FE2t7MPG4AA/y7e8=";
  };
in
{
  environment.etc."models/phi3-mini.gguf".source = phi3_mini_q4;
  environment.etc."models/llama-3.2-3b-q4.gguf".source = llama3_2_3b_q4;

  hardware.enableRedistributableFirmware = true;
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-compute-runtime
      intel-npu-driver
      intel-media-driver
    ];
  };

  hardware.cpu.intel.npu.enable = true;
}
