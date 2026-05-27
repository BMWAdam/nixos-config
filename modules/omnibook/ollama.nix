{ pkgs, config, ... }:
let 
  weak_qwen = pkgs.fetchurl {
    url = "https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF/resolve/main/Qwen3.5-0.8B-Q8_0.gguf";
    sha256 = "sha256-CtiF/9S7Ai/E8NM6Mwj6EI74YTFZ07OmfiOrygVremw=";
  };

  strong_qwen = pkgs.fetchurl {
    url = "https://huggingface.co/unsloth/Qwen3.5-9B-GGUF/resolve/main/Qwen3.5-9B-Q5_K_M.gguf";
    sha256 = "sha256-3Co5rvKR+RqRFq0hQFjaDYbrZIdDoSS9jDM3h8S5yRw=";
  };
in
{
  environment.etc."models/qwen3.5_0.8B.gguf".source = weak_qwen;
  environment.etc."models/qwen3.5_9B.gguf".source = strong_qwen;

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

  # --- BACKEND 1: Llama-cpp (For Speculative Decoding & WebUI) ---
  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp.override { vulkanSupport = true; };
    model = "/etc/models/qwen3.5_9B.gguf";
    extraFlags = [
      "--model-draft" "/etc/models/qwen3.5_0.8B.gguf"
      "-ngl" "99"

      "--ctx-size" "4096"        # Limits the RAM allocated for text memory
      "--batch-size" "256"       # Lowers the processing chunk size to save RAM
      "--no-mmap"                # Forces it to release unused file memory
    ];
  };

  services.open-webui = {
    enable = true;
    environment = {
      OPENAI_API_BASE_URL = "http://127.0.0.1:8080/v1";
      OPENAI_API_KEY = "sk-dummykey"; 
    };
  };

  services.ollama = {
    enable = true;
    loadModels = [ "llama3.2:3b" ]; 
    package = pkgs.ollama-vulkan;
    syncModels = true;
  };
}