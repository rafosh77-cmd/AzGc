import os, json, requests
from pathlib import Path

USE_AZURE = bool(os.getenv("AZURE_OPENAI_ENDPOINT"))
MODEL = os.getenv("AZURE_OPENAI_DEPLOYMENT") or "gpt-4o-mini"

def call_llm(prompt):
    if USE_AZURE:
        url = f"{os.environ['AZURE_OPENAI_ENDPOINT'].rstrip('/')}/openai/deployments/{MODEL}/chat/completions?api-version=2024-08-01-preview"
        headers = {"api-key": os.environ["AZURE_OPENAI_API_KEY"], "Content-Type": "application/json"}
    else:
        url = "https://api.openai.com/v1/chat/completions"
        headers = {"Authorization": f"Bearer {os.environ['OPENAI_API_KEY']}", "Content-Type": "application/json"}
    r = requests.post(url, headers=headers,
                      json={"messages":[{"role":"user","content":prompt}],"temperature":0})
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"]

iac_file = "iac/main.tf"
report = "checkov_report.json"

iac = Path(iac_file).read_text(encoding="utf-8")
failed = json.loads(Path(report).read_text()).get("results", {}).get("failed_checks", [])
if failed:
    prompt = f"Fix these Checkov issues:\n{json.dumps(failed,indent=2)}\n\nTerraform:\n```\n{iac}\n```"
    fixed = call_llm(prompt)
    Path("iac/main_fixed.tf").write_text(fixed, encoding="utf-8")
    print("✅ Fixed file written to iac/main_fixed.tf")
else:
    print("✅ No failed checks found.")
