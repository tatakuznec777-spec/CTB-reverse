# Сохраните как recon.sh
#!/bin/bash

# Ваша подсеть (поправьте под свою!)
SUBNET="10.60"
YOUR_IP="10.60.7.3"  # ваш IP, чтобы не сканировать себя

echo "[*] Сканирование подсети $SUBNET.0.0/16..."

# Быстрый ping-скан (кто жив?)
for i in {1..20}; do
    TARGET="$SUBNET.$i.3"  # обычно .3 - это команда
    [ "$TARGET" == "$YOUR_IP" ] && continue
    
    if ping -c 1 -W 1 "$TARGET" &>/dev/null; then
        echo "[+] Живой хост: $TARGET"
        
        # Быстрый скан портов (только нужные!)
        nmap -sT -p 80,443,8080,3000,5000 --open "$TARGET" -T4 --max-retries 1 2>/dev/null | \
        grep "open" | while read line; do
            echo "    → $line"
        done
    fi
done

echo "[*] Сканирование завершено"