# Сохраните как web_recon.py
#!/usr/bin/env python3
import sys, requests, concurrent.futures

TARGET = sys.argv[1]  # IP соперника
PORTS = [80, 443, 8080, 3000, 5000]  # типичные порты
PATHS = [
    "/", "/flag", "/flags", "/api/flag", "/admin", "/debug", 
    "/.git/HEAD", "/.env", "/config.py", "/backup.sql",
    "/api/v1/flag", "/getFlag", "/submit"
]

def check_endpoint(url):
    try:
        r = requests.get(url, timeout=2, allow_redirects=False)
        if r.status_code in [200, 302, 401, 403]:  # интересные коды
            print(f"[{r.status_code}] {url}")
            # Если нашли флаг — сразу печатаем для фермы
            if "=" in r.text or "CTF{" in r.text:
                print(r.text.strip(), flush=True)
    except: pass

def scan_host(ip):
    for port in PORTS:
        base = f"http://{ip}:{port}"
        for path in PATHS:
            check_endpoint(f"{base}{path}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: web_recon.py <target_ip>")
        sys.exit(1)
    scan_host(sys.argv[1])