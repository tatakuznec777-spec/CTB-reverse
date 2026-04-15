#!/bin/bash
echo "🔍 Проверка окружения СТВ..."
[ -f ~/ctf/bin/activate ] && echo "✅ venv" || echo "❌ venv"
python3 -c "from pwn import *" 2>/dev/null && echo "✅ pwntools" || echo "❌ pwntools"
which burpsuite >/dev/null && echo "✅ Burp" || echo "❌ Burp"
which ghidraRun >/dev/null && echo "✅ Ghidra" || echo "❌ Ghidra"
which vol >/dev/null && echo "✅ Volatility" || echo "❌ Volatility"
echo "📁 ~/ctf_kit exists: $([ -d ~/ctf_kit ] && echo ✅ || echo ❌)"
# проверка окружения за 30 секунд