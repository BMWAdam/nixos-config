import os
import sys
import subprocess
import openvino_genai as ov_genai

CACHE_BASE = os.path.expanduser("~/.cache/npu-llm-runner")

def get_or_convert_model(hf_repo_id: str) -> str:
    # Safely convert repo ID to a directory name (e.g., "microsoft/Phi-3" -> "microsoft_Phi-3")
    model_name = hf_repo_id.replace("/", "_")
    ir_dir = os.path.join(CACHE_BASE, "ir", model_name)

    if os.path.isdir(ir_dir) and any(f.endswith(".xml") for f in os.listdir(ir_dir)):
        print(f"Using cached OpenVINO IR: {ir_dir}")
        return ir_dir

    print(f"Downloading and Converting {hf_repo_id} to OpenVINO IR (INT4 for NPU)...")
    print(f"Output: {ir_dir}")
    print("(This only happens once per model — may take a few minutes)\n")

    os.makedirs(ir_dir, exist_ok=True)

    result = subprocess.run(
        [
            sys.executable, "-m", "optimum.commands.optimum_cli",
            "export", "openvino",
            "--model", hf_repo_id,
            "--weight-format", "int4",      # 4-bit compression
            "--sym",                        # FORCE SYMMETRIC (Crucial for NPU)
            "--ratio", "1.0",               # Ratio of parameters to quantize
            "--group-size", "128",          # Standard NPU token-grouping layout
            "--trust-remote-code",
            ir_dir
        ],
        env={**os.environ},
        check=False
    )

    if result.returncode != 0:
        print(f"\nError: optimum conversion failed (exit {result.returncode})")
        import shutil
        shutil.rmtree(ir_dir, ignore_errors=True)
        sys.exit(1)

    # Verify something was actually written
    xml_files = [f for f in os.listdir(ir_dir) if f.endswith(".xml")]
    if not xml_files:
        print(f"\nError: conversion produced no .xml files in {ir_dir}")
        import shutil
        shutil.rmtree(ir_dir, ignore_errors=True)
        sys.exit(1)

    print(f"\nConversion complete: {xml_files}")
    return ir_dir

def main():
    if len(sys.argv) < 2:
        print("Usage: npu-llm-runner <huggingface_repo_id> [prompt]")
        print("Example: npu-llm-runner microsoft/Phi-3-mini-4k-instruct")
        sys.exit(1)

    hf_repo_id = sys.argv[1].strip("'\"")
    model_dir = get_or_convert_model(hf_repo_id)

    device = "NPU"
    print(f"Loading OpenVINO IR onto {device}...")

    try:
        # 1. Pass explicit static shape limits via a config dict to satisfy the NPU plugin
        if device == "NPU":
            pipeline_config = {
                "MAX_PROMPT_LEN": 1024,
                "MIN_RESPONSE_LEN": 1
            }
            pipe = ov_genai.LLMPipeline(model_dir, device, pipeline_config)
        else:
            pipe = ov_genai.LLMPipeline(model_dir, device)

        prompt = sys.argv[2] if len(sys.argv) > 2 else "Why is NixOS an incredible distro?"
        
        # 2. Inject TinyLlama's chat structure manually so it doesn't immediately exit on an EOS token
        if "TinyLlama" in model_dir:
            prompt = f"<|system|>\nYou are a helpful assistant.</s>\n<|user|>\n{prompt}</s>\n<|assistant|>\n"

        print(f"\nPrompt: {prompt}\n\nResponse:")

        def streamer(sub_token):
            print(sub_token, end="", flush=True)
            return False

        # 3. Force greedy decoding (do_sample=False) to bypass sampler computation bugs
        pipe.generate(prompt, max_new_tokens=250, streamer=streamer, do_sample=False)
        print("\n")

    except Exception as e:
        print(f"Runtime Execution Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()