# 📦 ПОЛНЫЙ ГАЙД ДЛЯ CYBERCTB (JAVA + PYTHON)

# Проверка всех инструментов
bandit --version && semgrep --version && trivy --version && zaproxy -version && nikto --help | head -1


📋 АЛГОРИТМ РЕШЕНИЯ ЗАДАЧИ


ШАГ 1: ПОЛУЧЕНИЕ (30 сек)
1. Открой ZeroTrace → выбери задачу
2. Скопируй ссылку на Git репозиторий
3. Запиши номер задачи в общий чат команды или таблицу Гугл

ШАГ 2: КЛОНИРОВАНИЕ (1 мин)
cd ~/ctf_tasks
git clone <СКОПИРОВАННАЯ_ССЫЛКА>
cd <ПАПКА_ЗАДАЧИ>

ШАГ 3: АВТОМАТИЧЕСКОЕ СКАНИРОВАНИЕ (3-5 мин)
# Для Java:
semgrep --config=auto . > semgrep.txt &
trivy fs . > trivy.txt & wait

или semgrep --config semgrep-rules.yaml . > semgrep.txt
trivy fs . > trivy.txt & wait

# Для Python:
bandit -r . -lll > bandit.txt &
semgrep --config=auto . > semgrep.txt & wait

или semgrep --config semgrep-rules.yaml . > semgrep.txt
bandit -r . -lll > bandit.txt

ШАГ 4: АНАЛИЗ (5 мин)
1. cat semgrep.txt | grep -E "HIGH|CRITICAL|ERROR"
2. cat bandit.txt (смотри Severity: HIGH)
3. Открой указанные файлы в IDE (VS Code / IntelliJ)
4. Найди строку с уязвимостью

ШАГ 5: ИСПРАВЛЕНИЕ (5-7 мин)
1. Примени патч
2. Сохрани файл
3. Проверь решение на Скилл трэк

ШАГ 6: ПОЛУЧЕНИЕ И СДАЧА ФЛАГА (2 мин)
1. Скопируй флаг формата flag{...}
2. Вставь в ZeroTrace → "Завершить упражнение"
3. Запиши баллы и решение в чат или таблицу


🧰 ШПАРГАЛКИ ПО ИНСТРУМЕНТАМ

[SEMGREP]
semgrep --config=auto .               # Автоправила (быстро)
semgrep --config semgrep-rules.yaml . # Локальные правила
semgrep --config=p/java .             # Только Java
semgrep --config=p/python .           # Только Python
semgrep -e "eval(...)" --lang=py .    # Поиск конкретного паттерна

[BANDIT] (Python)
bandit -r .                           # Рекурсивно
bandit -r . -lll                      # Только HIGH/CRITICAL
bandit -r . -f json -o report.json    # JSON отчет

[TRIVY] (Зависимости + секреты)
trivy fs .                            # Сканирование кода
trivy fs --severity CRITICAL,HIGH .   # Только критичные
trivy fs --secret-config .            # Поиск секретов

[OWASP ZAP] (Веб-интерфейсы)
GUI: Quick Start → URL → Attack → Alerts
CLI: zaproxy.sh -daemon -port 8080

[NIKTO] (Веб-серверы)
nikto -h http://<IP>                  # Базовое сканирование
nikto -h http://<IP> -o report.txt    # Сохранить отчет

[SQLMAP] (SQL Injection)
sqlmap -u "http://<IP>/page?id=1"     # Проверка параметра
sqlmap -u "URL" --dbs                 # Получить базы
sqlmap -u "URL" --dump                # Выгрузить данные

[ODC / DEPENDENCY-CHECK]
dependency-check.sh --scan . --format HTML  # HTML отчет по зависимостям


👥 РАСПРЕДЕЛЕНИЕ РОЛЕЙ 

👤 JAVA EXPERT
- Берет только Java задачи
- Инструменты: semgrep (java), trivy, ODC
- Чек-лист: SQLi (StringBuilder), RCE (Runtime.exec), XXE, Path Traversal
- Действие: semgrep --config=p/java . → cat semgrep.txt → grep ERROR → правим код → флаг

👤 PYTHON EXPERT
- Берет только Python задачи
- Инструменты: bandit, semgrep (python), trivy
- Чек-лист: SQLi (f-string/%), eval/exec, os.system, pickle, yaml
- Действие: bandit -r . -lll → cat bandit.txt → правим код → флаг

👤 WEB / DYNAMIC
- Берет задачи с веб-интерфейсом/API
- Инструменты: ZAP, nikto, sqlmap, jwt_tool
- Чек-лист: XSS, LFI/RFI, SSRF, JWT без подписи, SQLi через формы
- Действие: ZAP Quick Scan → nikto -h URL → ручная проверка форм → флаг

👤 COORDINATOR + DEPS
- Координирует, ведет общий файл/чат
- Сканирует зависимости обоих сервисов: trivy fs . && dependency-check.sh --scan .
- Импортирует отчеты в DefectDojo (если время позволит)
- Собирает флаги, контролирует таймер, помогает с grep-поиском

⏱️ ТАЙМ-МЕНЕДЖМЕНТ (3 ЧАСА)

00:00-00:15 | Регистрация, клонирование первых 4 задач, запуск сканеров
00:15-01:15 | Активное решение (по 2 задачи на Java/Python эксперта)
01:15-02:00 | Веб-эксперт + координатор добивают сложные задачи
02:00-02:40 | Дорешивание, проверка патчей, сбор флагов
02:40-03:00 | Финальная сверка, сдача последних флагов, отправка

⚠️ ПРАВИЛО: Если задача не решается >15 минут → бросаешь, берешь новую, возвращаешься в конце.


🎯 ЧЕК-ЛИСТЫ: OWASP TOP 10 / CWE TOP 25 / CVE


🔴 OWASP TOP 10 (2021) - ЧТО ГРЕПАТЬ

`A01 Broken Access Control →` 

grep -rn "admin\|role\|@PreAuthorize" .


`A02 Crypto Failures →`

grep -rn "MD5\|SHA1\|DES\|password.*=" .


`A03 Injection →` 

grep -rn "exec(\|eval(\|StringBuilder.*SELECT\|cursor.execute.*f\"" .


`A04 Insecure Design →` 

grep -rn "max_attempts\|rate_limit\|while.*login" .


`A05 Misconfiguration →` 

grep -rn "DEBUG.*True\|CrossOrigin.*\*\|admin/admin" .


`A06 Vuln Components →` 

trivy fs . / dependency-check.sh


`A07 Auth Failures →` 

grep -rn "@login_required\|jwt.decode.*False\|session\[" .


`A08 Integrity →` 

grep -rn "pickle.loads\|yaml.load\|ObjectInputStream" .


`A09 Logging →`

grep -rn "print.*password\|log.*secret\|traceback" .


`A10 SSRF →` 

grep -rn "requests.get\|urllib\|URL.openConnection" .



🔴 CWE TOP 25 - ПАТТЕРНЫ ДЛЯ ПОИСКА

`CWE-89 SQLi →` 

StringBuilder + SQL / f-string в execute

`CWE-78 OS Cmd → `

Runtime.exec / os.system / subprocess shell=True

`CWE-79 XSS →` 

response.getWriter / render_template_string / без escape()

`CWE-22 Path Traversal →` 

new File(user) / open(user_path) / ../

`CWE-502 Deserialization → `

pickle.loads / ObjectInputStream / yaml.load

`CWE-611 XXE →` 

DocumentBuilderFactory без setFeature


`CWE-522 Credentials → `

password= в коде / логируют пароли / http://

`CWE-20 Input Validation → `

нет проверок длины/типа / доверие к клиенту

`CWE-352 CSRF → `

нет токенов / GET меняет состояние / @csrf_exempt

🔴 TOP CVE - ПРОВЕРКА ВЕРСИЙ

`Log4Shell (CVE-2021-44228) → `

grep -rn "log4j.*2\.[0-9]\|2\.1[0-6]" pom.xml build.gradle

`Spring4Shell (CVE-2022-22965) → `

grep -rn "spring.*5\.[0-2]\|boot.*2\.[0-5]" .

`Requests (CVE-2018-18074) →` 

grep -rn "requests.*2\.[0-1]" requirements.txt

`PyYAML (CVE-2020-14343) → `

grep -rn "PyYAML.*[0-4]\|5\.[0-3]" requirements.txt

`Django (<3.2) / Flask (<2.0) →` 

pip list | grep -E "django|flask"

🚀 ЭКСТРЕННЫЕ КОМАНДЫ 


# Быстрый поиск уязвимостей во всей папке

grep -rn "eval(\|exec(\|os.system\|subprocess.*shell" . --include="*.py"


grep -rn "Runtime.exec\|ProcessBuilder\|StringBuilder.*SELECT" . --include="*.java"


grep -rn "cursor.execute.*f\"\|cursor.execute.*%\|query.format" . --include="*.py"


grep -rn "password.*=\|secret.*=\|api_key.*=\|token.*=" . | grep -v ".git"

# Поиск флагов в коде/файлах (иногда флаг hardcoded)

grep -rn "flag{\|FLAG{\|ctf{" .


find . -name "*.txt" -o -name "*.env" -o -name "*.cfg" | xargs grep -l "flag"

# Проверка зависимостей за 10 секунд

trivy fs . --severity CRITICAL,HIGH --format table


pip-audit -r requirements.txt 2>/dev/null || echo "pip-audit не установлен, юзай trivy"

# Если семгреп завис или нет интернета

semgrep --config=auto . --timeout 30

# Или ручной grep по паттернам выше


✅ ФИНАЛЬНЫЙ ЧЕК-ЛИСТ


ДО СТАРТА:
[ ] Общий чат в Телеграм
[ ] Папка ~/CTB-REVERSE склонирована у каждого
[ ] Инструменты проверены: bandit --version, semgrep --version, trivy --version
[ ] Шаблоны патчей открыты в соседней вкладке/файле
[ ] Интернет стабилен, ZeroTrace/SkillTrack доступны

ВО ВРЕМЯ CTF:
[ ] Каждая задача сразу помечается в чате и таблице: "Задача 3 - Java - Ник"

Таблица Гугл:

https://docs.google.com/spreadsheets/d/1W-MIZI8pEiqC2bs4tUkY_iD4oxiLk2PuFtT3Gdo5mWQ/edit?usp=sharing

[ ] Сканеры запускаются параллельно с ручным просмотром кода

[ ] Флаги сразу копируются в общий документ: Задача № | Флаг | Баллы

[ ] Если >15 мин без прогресса → переключаемся

[ ] Координатор каждые 30 мин спрашивает статус и собирает флаги


ПОСЛЕ ЗАДАЧИ:
[ ] Код сохранен
[ ] Флаг сдан в ZeroTrace
[ ] Баллы записаны
[ ] Переход к следующей
