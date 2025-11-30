import urllib.request
import json
import os

def lambda_handler(event, context):
    alb_url = os.environ.get("ALB_URL")
    if not alb_url:
        print("ERROR: ALB_URL env var missing")
        return {"status": "error", "detail": "missing ALB_URL"}

    try:
        with urllib.request.urlopen(f"http://{alb_url}/health", timeout=5) as resp:
            body = resp.read().decode()
            print("ALB HEALTH OK:", body)
            return {"status": "ok", "detail": body}
    except Exception as e:
        print("ALB HEALTH ERROR:", str(e))
        return {"status": "error", "detail": str(e)}
