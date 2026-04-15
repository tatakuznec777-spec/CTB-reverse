# Поиск флага в директории
find . -type f -exec grep -ilE "flag\{.*\}|CTF\{.*\}" {} \; 2>/dev/null

# Открытые порты + процесс
ss -tulnp | grep -v "^State"

# Строки из бинарника с фильтром
strings "$1" 2>/dev/null | grep -iE "flag|key|admin|pass" | head -10

# Быстрый анализ зависимостей
[ -f requirements.txt ] && pip-audit -r requirements.txt --skip-editable
[ -f package.json ] && npm audit --audit-level=high

# DNS TXT записи (часто там флаг)
dig "$1" TXT +short 2>/dev/null