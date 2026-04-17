#!/bin/bash
###############################################################################
# CTF Auto-Solver v1.2 - FULLY FIXED
# Автоматическое сканирование уязвимостей для CyberCTB
# Java + Python | Semgrep | Bandit | Trivy | ODC | ZAP | Nikto | SQLMap
###############################################################################

# === FIX: Locale для корректной работы с именами ===
export LC_ALL=C
export LANG=C
export PYTHONIOENCODING=utf-8

set -o pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

LOG_FILE=""; REPORT_DIR=""; TASK_NAME=""; TARGET_DIR=""
DEFECTDOJO_URL="http://localhost:8080"; DEFECTDOJO_API_KEY=""

# === ЛОГИРОВАНИЕ ===
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; [ -n "$LOG_FILE" ] && echo "[INFO] $(date '+%F %T') $1" >> "$LOG_FILE"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; [ -n "$LOG_FILE" ] && echo "[OK] $(date '+%F %T') $1" >> "$LOG_FILE"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; [ -n "$LOG_FILE" ] && echo "[!] $(date '+%F %T') $1" >> "$LOG_FILE"; }
log_error() { echo -e "${RED}[ERR]${NC} $1"; [ -n "$LOG_FILE" ] && echo "[ERR] $(date '+%F %T') $1" >> "$LOG_FILE"; }
log_tool() { echo -e "${CYAN}[TOOL]${NC} $1"; [ -n "$LOG_FILE" ] && echo "[TOOL] $(date '+%F %T') $1" >> "$LOG_FILE"; }

# === ПРОВЕРКА ИНСТРУМЕНТОВ (исправлено - без дублей) ===
check_tools() {
    log_info "Проверка инструментов..."
    local miss=0
    for t in semgrep trivy bandit git curl; do
        if command -v "$t" &>/dev/null; then
            log_success "$t: OK"
        else
            log_warning "$t: NOT FOUND (продолжим без него)"
            ((miss++))
        fi
    done
    command -v dependency-check.sh &>/dev/null && log_success "ODC: OK" || log_warning "ODC: skip"
    (command -v zaproxy &>/dev/null || command -v zap.sh &>/dev/null) && log_success "ZAP: OK" || log_warning "ZAP: skip"
    command -v nikto &>/dev/null && log_success "Nikto: OK" || log_warning "Nikto: skip"
    command -v sqlmap &>/dev/null && log_success "SQLMap: OK" || log_warning "SQLMap: skip"
    [ $miss -gt 10 ] && log_error "Критически мало инструментов" && return 1
    return 0
}

# === ИНИЦИАЛИЗАЦИЯ (исправлено - санитизация имени) ===
init_task() {
    echo -e "${CYAN}=== CTF Auto-Solver v1.2 ===${NC}"
    read -p "Task name (ASCII only, Enter=auto): " TASK_NAME
    [ -z "$TASK_NAME" ] && TASK_NAME=$(basename "$PWD")
    TASK_NAME=$(echo "$TASK_NAME" | tr -cd 'a-zA-Z0-9_-' | tr '[:upper:]' '[:lower:]')
    [ -z "$TASK_NAME" ] && TASK_NAME="ctf_task_$(date +%s)"
    
    REPORT_DIR="./ctf_reports/${TASK_NAME}"; mkdir -p "$REPORT_DIR"
    LOG_FILE="${REPORT_DIR}/scan.log"; TARGET_DIR="${REPORT_DIR}/target"
    
    cat > "${REPORT_DIR}/report.md" << REPORTEOF
# Report: $TASK_NAME | $(date '+%F %T')
## Scan results below
---
REPORTEOF
    log_success "Report dir: $REPORT_DIR"
}

clone_repository() {
    read -p "Git URL (Enter=local scan): " GIT_URL
    if [ -n "$GIT_URL" ]; then
        log_info "Cloning..."
        git clone "$GIT_URL" "$TARGET_DIR" 2>>"$LOG_FILE" && cd "$TARGET_DIR" || { log_error "Clone failed"; return 1; }
    else
        TARGET_DIR="."; log_info "Local scan: $PWD"
    fi
}

# === SEMGREP ===
run_semgrep() {
    log_tool "Semgrep..."
    local rpt="${REPORT_DIR}/semgrep.txt" json="${REPORT_DIR}/semgrep.json"
    local cfg="--config=auto"
    [ -f "semgrep-rules.yaml" ] && cfg="--config semgrep-rules.yaml" && log_info "Using local rules"
    [ -f "${REPORT_DIR}/../semgrep-rules.yaml" ] && cfg="--config ${REPORT_DIR}/../semgrep-rules.yaml"
    
    echo "=== SEMGREP $(date) ===" > "$rpt"
    if timeout 90 semgrep $cfg --json -o "$json" . 2>>"$LOG_FILE"; then
        log_success "Semgrep OK"
        [ -f "$json" ] && command -v jq &>/dev/null && jq -r '.results[]?|"[\(.severity)] \(.path):\(.start.line)"' "$json" >> "$rpt" 2>/dev/null
    else
        log_warning "Semgrep fallback -> grep"
        grep -rn "StringBuilder.*SELECT\|Runtime.exec\|cursor.execute.*f\"" . --include="*.java" --include="*.py" 2>/dev/null >> "$rpt" || echo "No matches" >> "$rpt"
    fi
    echo -e "\n## Semgrep\n\`\`\`\n$(head -50 "$rpt")\n\`\`\`\n" >> "${REPORT_DIR}/report.md"
}

# === BANDIT ===
run_bandit() {
    log_tool "Bandit..."
    local rpt="${REPORT_DIR}/bandit.txt" json="${REPORT_DIR}/bandit.json"
    find . -name "*.py" -type f | grep -q . || { log_warning "No Python files"; return 0; }
    echo "=== BANDIT $(date) ===" > "$rpt"
    if timeout 90 bandit -r . -lll -f json -o "$json" 2>>"$LOG_FILE"; then
        log_success "Bandit OK"
        [ -f "$json" ] && command -v jq &>/dev/null && jq -r '.results[]?|"[\(.issue_severity)] \(.filename):\(.line_number)"' "$json" >> "$rpt" 2>/dev/null
    fi
    echo -e "\n## Bandit\n\`\`\`\n$(head -30 "$rpt")\n\`\`\`\n" >> "${REPORT_DIR}/report.md"
}

# === TRIVY ===
run_trivy() {
    log_tool "Trivy..."
    local rpt="${REPORT_DIR}/trivy.txt"
    echo "=== TRIVY $(date) ===" > "$rpt"
    timeout 120 trivy fs . --severity CRITICAL,HIGH --format table >> "$rpt" 2>>"$LOG_FILE" && log_success "Trivy OK" || log_warning "Trivy skip"
    echo -e "\n## Trivy\n\`\`\`\n$(head -30 "$rpt")\n\`\`\`\n" >> "${REPORT_DIR}/report.md"
}

# === DEPENDENCY-CHECK ===
run_odc() {
    log_tool "ODC..."
    command -v dependency-check.sh &>/dev/null || { log_warning "ODC not found"; return 0; }
    timeout 180 dependency-check.sh --project "$TASK_NAME" --scan . --format HTML --out "$REPORT_DIR" 2>>"$LOG_FILE" && \
        log_success "ODC OK" || log_warning "ODC skip"
}

# === WEB SCANS ===
run_web() {
    read -p "Web URL (Enter=skip): " URL
    [ -z "$URL" ] && return 0
    log_tool "ZAP+Nikto for $URL"
    echo -e "\n## Web: $URL\n" >> "${REPORT_DIR}/report.md"
    
    command -v nikto &>/dev/null && timeout 120 nikto -h "$URL" -output "${REPORT_DIR}/nikto.txt" 2>>"$LOG_FILE" && \
        echo -e "\`\`\`\n$(head -20 "${REPORT_DIR}/nikto.txt")\n\`\`\`\n" >> "${REPORT_DIR}/report.md"
    
    grep -qi "sql.*injection" "${REPORT_DIR}"/*.txt 2>/dev/null && \
        echo -e "**SQLi found!** Check: \`sqlmap -u \"$URL\" --batch\`\n" >> "${REPORT_DIR}/report.md"
}

# === PATCH RECOMMENDATIONS (fixed heredoc) ===
generate_patches() {
    log_info "Generating patch recommendations..."
    local f="${REPORT_DIR}/patches.md"
    cat > "$f" << 'PATCHEOF'
# PATCHEOF - Java/Python vulnerabilities and fixes

## JAVA
[SQLi] StringBuilder+SQL -> PreparedStatement with ? parameters
[CMDi] Runtime.exec(user) -> ProcessBuilder("cmd", user)  
[XXE] DocumentBuilderFactory -> setFeature(disallow-doctype-decl, true)
[Path] new File(input) -> Paths.get(base).resolve(input).normalize()

## PYTHON
[SQLi] cursor.execute(f"SELECT {x}") -> cursor.execute("SELECT %s", (x,))
[CMDi] os.system(cmd) -> subprocess.run([cmd], check=True)
[Eval] eval(user) -> ast.literal_eval(user)
[Pickle] pickle.loads(data) -> json.loads(data)
[YAML] yaml.load(data) -> yaml.safe_load(data)
[Secrets] password="xxx" -> os.environ.get("PASSWORD")

## QUICK FIXES (sed examples)
# Java SQLi: replace concatenation with ?
# Python f-string SQL: replace with %s and parameter tuple
# Comment out eval/exec: sed -i 's/eval(/#eval(/g' file.py
PATCHEOF
    log_success "Patches: $f"
}

# === AUTO-PATCHING ===
auto_patch() {
    log_info "Auto-patching..."
    > "${REPORT_DIR}/manual.txt"
    
    # Java files
    while IFS= read -r f; do
        [ -f "$f" ] || continue
        cp "$f" "${f}.bak" 2>/dev/null
        grep -q "StringBuilder.*SELECT\|StringBuilder.*INSERT" "$f" 2>/dev/null && \
            echo "[JAVA SQLi] $f" >> "${REPORT_DIR}/manual.txt"
        grep -q "Runtime.getRuntime().exec" "$f" 2>/dev/null && \
            sed -i 's/Runtime\.getRuntime()\.exec(/\/\/FIXME:ProcessBuilder(/g' "$f" 2>/dev/null
    done < <(find . -name "*.java" -type f 2>/dev/null)
    
    # Python files
    while IFS= read -r f; do
        [ -f "$f" ] || continue
        cp "$f" "${f}.bak" 2>/dev/null
        grep -q 'cursor\.execute.*f"' "$f" 2>/dev/null && \
            echo "[PY SQLi] $f" >> "${REPORT_DIR}/manual.txt"
        grep -q "eval(\|exec(" "$f" 2>/dev/null && \
            sed -i 's/eval(/#EVAL(/g; s/exec(/#EXEC(/g' "$f" 2>/dev/null
        grep -q "os\.system(" "$f" 2>/dev/null && \
            sed -i 's/os\.system(/#SYSTEM(/g' "$f" 2>/dev/null
    done < <(find . -name "*.py" -type f 2>/dev/null)
    
    log_success "Patching done"
}

# === DEFECTDOJO IMPORT ===
import_dd() {
    [ -z "$DEFECTDOJO_API_KEY" ] && return 0
    log_tool "DefectDojo import..."
    [ -f "${REPORT_DIR}/semgrep.json" ] && curl -s -X POST "${DEFECTDOJO_URL}/api/v2/import-scan/" \
        -H "Authorization: Token ${DEFECTDOJO_API_KEY}" \
        -F "scan_type=Semgrep JSON Report" -F "file=@${REPORT_DIR}/semgrep.json" \
        -F "product_name=${TASK_NAME}" >> "${REPORT_DIR}/dd.log" 2>&1 &
}

# === FINAL REPORT ===
final_report() {
    log_info "Final report..."
    local crit=$(grep -ci "critical\|error" "${REPORT_DIR}"/*.txt 2>/dev/null || echo 0)
    local high=$(grep -ci "high\|warning" "${REPORT_DIR}"/*.txt 2>/dev/null || echo 0)
    
    cat > "${REPORT_DIR}/FINAL.md" << FINALEOF
# [OK] REPORT: $TASK_NAME
**Vulnerabilities:** [CRITICAL:$crit] [HIGH:$high]

**Files:**
- [Semgrep](./semgrep.txt) [Bandit](./bandit.txt) [Trivy](./trivy.txt)
- [Patches](./patches.md) [Manual fixes](./manual.txt)

**Quick commands:**
\`\`\`bash
grep -rn "eval(\|exec(" . --include="*.py"
grep -rn "Runtime.exec\|StringBuilder.*SELECT" . --include="*.java"
\`\`\`
FINALEOF
    echo -e "\n${GREEN}=== DONE ===${NC}\n${CYAN}Report: ${REPORT_DIR}/FINAL.md${NC}\n"
}

# === MAIN ===
main() {
    echo -e "${CYAN}[START] CTF Auto-Solver v1.2${NC}"
    check_tools || log_warning "Some tools missing - continuing anyway"
    init_task
    clone_repository || exit 1
    
    run_semgrep || true
    run_bandit || true
    run_trivy || true
    run_odc || true
    run_web || true
    
    generate_patches
    auto_patch
    import_dd
    final_report
    
    echo -e "${GREEN}[COMPLETE]${NC} ${YELLOW}Reports: $REPORT_DIR${NC}"
}

# === RUN ===
main "$@"