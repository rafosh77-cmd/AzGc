import os
import json
import requests
from pathlib import Path

def call_llm(prompt: str) -> str:
    """Send prompt to OpenAI API and return model output"""
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise ValueError("❌ OPENAI_API_KEY environment variable not set")

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    data = {
        "model": "gpt-4o-mini",  # You can use gpt-4-turbo or gpt-4o
        "messages": [
            {"role": "system", "content": "You are a compliance enforcer for IaC. Fix code to meet security standards."},
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.2
    }

    response = requests.post("https://api.openai.com/v1/chat/completions",
                             headers=headers, json=data)
    if not response.ok:
        print(f"❌ API Error {response.status_code}: {response.text}")
        response.raise_for_status()

    return response.json()["choices"][0]["message"]["content"]

def main(iac_file: str, report: str):
    """Read IaC + Checkov report, send to model, save fixed version"""
    iac_code = Path(iac_file).read_text(encoding="utf-8")
    failed = json.loads(Path(report).read_text(encoding="utf-8")).get("results", {}).get("failed_checks", [])

    # Build contextual prompt
    issues = "\n".join([f"- {c['check_id']}: {c['check_name']}" for c in failed])
    prompt = (
        "You are a compliance enforcer for IaC. "
        "Fix the following Terraform code to resolve these Checkov findings:\n\n"
        f"Findings:\n{issues}\n\n"
        f"Code:\n{iac_code}\n\n"
        "Only output the corrected Terraform code."
    )

    print("🧠 Submitting to model...")
    fixed_code = call_llm(prompt)

    output_file = Path(iac_file).with_name(Path(iac_file).stem + "_fixed.tf")
    output_file.write_text(fixed_code, encoding="utf-8")
    print(f"✅ Fixed IaC written to {output_file}")

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 3:
        print("Usage: python fix_iac.py <iac_file> <checkov_report.json>")
        sys.exit(1)

    main(sys.argv[1], sys.argv[2])



