import os
import base64
import requests
import json
from time import sleep
from datetime import datetime

IMAGE_DIR = os.path.expanduser("~/smart_glasses/images")
PROCESSED_DIR = os.path.expanduser("~/smart_glasses/processed")
MEMORY_FILE = os.path.expanduser("~/smart_glasses/memory.json")

MODEL_NAME = "google/gemma-4-e4b"  # <-- change if LM Studio uses different ID

# load memory if exists
if os.path.exists(MEMORY_FILE):
    with open(MEMORY_FILE, "r") as f:
        memory = json.load(f)
else:
    memory = []

def save_memory():
    with open(MEMORY_FILE, "w") as f:
        json.dump(memory, f, indent=2)

def encode_image(path):
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode()

# 👁️ Image → structured productivity analysis
def analyze_image(image_path):
    img = encode_image(image_path)

    prompt = """
Analyze this image for a productivity tracking system.

Return ONLY valid JSON:
{
  "activity": "...",
  "productive": true/false,
  "reason": "short explanation"
}
Do not include anything else.
"""

    res = requests.post(
        "http://localhost:1234/v1/chat/completions",
        json={
            "model": MODEL_NAME,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{img}"
                            }
                        }
                    ]
                }
            ],
            "temperature": 0.2
        }
    )

    content = res.json()["choices"][0]["message"]["content"]

    # 🧹 Clean markdown formatting if present
    cleaned = content.strip()

    if cleaned.startswith("```"):
        cleaned = cleaned.split("```")[1]  # remove ```json
        if cleaned.startswith("json"):
            cleaned = cleaned[4:]  # remove 'json'
        cleaned = cleaned.strip()

    try:
        return json.loads(cleaned)
    except Exception as e:
        print("Parse error:", e)
        print("Raw content:", content)

        return {
            "activity": content,
            "productive": False,
            "reason": "Failed to parse"
        }

# 🧠 End-of-day summary (same model now)
def generate_summary():
    print("Generating summary...")
    prompt = f"""
You are a productivity coach.

Here is a structured log of a person's day:
{json.dumps(memory, indent=2)}

Do:
1. Summarize the day clearly
2. Identify productive vs distracted periods
3. Explain patterns (time, behavior)
4. Give 3 SPECIFIC improvements

Keep it concise and practical.
"""

    res = requests.post(
        "http://localhost:1234/v1/chat/completions",
        json={
            "model": MODEL_NAME,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.4
        }
    )

    return res.json()["choices"][0]["message"]["content"]

if __name__ == "__main__":
# 🔁 MAIN LOOP
    while True:
        files = os.listdir(IMAGE_DIR)

        for file in files:
            path = os.path.join(IMAGE_DIR, file)

            try:
                result = analyze_image(path)

                entry = {
                    "time": datetime.now().strftime("%H:%M"),
                    "activity": result.get("activity"),
                    "productive": result.get("productive"),
                    "reason": result.get("reason")
                }

                memory.append(entry)
                save_memory()

                print("\nNew Entry:")
                print(entry)

                os.rename(path, os.path.join(PROCESSED_DIR, file))

            except Exception as e:
                print("Error:", e)

    sleep(10)