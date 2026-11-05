#!/usr/bin/env bash
# aws-reports regression tests: manifests, layout rules, both examples, negative checks.
# usage: bash tests/run-all.sh        (needs node 18+, python3; uv + matplotlib for the chart test)
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
S="$ROOT/shared/scripts"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0
ok()  { pass=$((pass + 1)); echo "  ok   $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL $1"; [ -n "${2:-}" ] && echo "$2" | sed 's/^/       /' | head -20; }
check() { if eval "$2" >/dev/null 2>&1; then ok "$1"; else bad "$1"; fi; }

echo "== setup"
bash "$S/setup.sh" >/dev/null 2>&1 && ok "setup.sh" || bad "setup.sh"

echo "== manifests and layout"
check "plugin.json is valid JSON" "python3 -m json.tool '$ROOT/.claude-plugin/plugin.json'"
check "marketplace.json is valid JSON" "python3 -m json.tool '$ROOT/.claude-plugin/marketplace.json'"
check "style_terms.json is valid JSON" "python3 -m json.tool '$S/style_terms.json'"
VER=$(python3 -c "import json;print(json.load(open('$ROOT/.claude-plugin/plugin.json'))['version'])")
check "README badge matches version $VER" "grep -q 'Version-$VER-' '$ROOT/README.md'"
check "CHANGELOG has [$VER]" "grep -q '^## \[$VER\]' '$ROOT/CHANGELOG.md'"
for d in hooks commands agents bin; do check "no root $d/ (would run for every user)" "[ ! -e '$ROOT/$d' ]"; done
check "no root settings.json" "[ ! -e '$ROOT/settings.json' ]"
check "no .mcp.json with servers" "[ ! -s '$ROOT/.mcp.json' ]"
for sk in benchmark-report poc-report; do
  f="$ROOT/skills/$sk/SKILL.md"
  check "$sk: frontmatter name" "grep -q '^name: $sk$' '$f'"
  check "$sk: description present" "grep -q '^description: .\{80,\}' '$f'"
  check "$sk: no CLAUDE.md inside the skill" "[ ! -e '$ROOT/skills/$sk/CLAUDE.md' ]"
  check "$sk: no old user-level paths" "! grep -q '~/.claude/skills/benchmark-report' '$f'"
  for ref in $(grep -o 'references/[a-z-]*\.md' "$f" | sort -u); do check "$sk: $ref exists" "[ -f '$ROOT/skills/$sk/$ref' ]"; done
  for ref in $(grep -o '\$R/[a-z_./-]*\.\(md\|py\|mjs\|sh\)' "$f" | sort -u); do check "$sk: ${ref} exists" "[ -f '$ROOT/shared/${ref#\$R/}' ]"; done
done
check "no '고객 권고' outside the rule tables" "[ \$(grep -rn '고객 권고' '$ROOT/skills' '$ROOT/shared' --include=*.md | grep -v -e '\"고객 권고\" →' -e '박스 제목 \"고객 권고\"' -e '\"고객 권고\"라고' | wc -l) -eq 0 ]"

echo "== layout rules (tests/fixtures/layout.md)"
node "$S/report.mjs" "$ROOT/tests/fixtures/layout.md" --out-dir "$TMP/layout" >/dev/null 2>&1 && ok "build layout fixture" || bad "build layout fixture"
python3 - "$TMP/layout/layout.docx" "$TMP/layout/layout.html" > "$TMP/layout.txt" 2>&1 <<'PY'
import re, sys, zipfile
doc = zipfile.ZipFile(sys.argv[1]).read("word/document.xml").decode()
html = open(sys.argv[2], encoding="utf-8").read()
tbls = re.findall(r"<w:tbl>.*?</w:tbl>", doc, re.S)
def head(t): return re.findall(r"<w:tc>.*?</w:tc>", re.findall(r"<w:tr[ >].*?</w:tr>", t, re.S)[0], re.S)
def sizes(t): return set(re.findall(r'<w:sz w:val="(\d+)"/>', t))
res = []
h11, h7, h3, hbr = (head(t) for t in tbls[:4])
res.append(("11-col table text 6.5 pt", sizes(tbls[0]) <= {"13", "12"}))
res.append(("11-col headers centered", all('<w:jc w:val="center"/>' in c for c in h11)))
res.append(("7-col: unit on second line", "<w:br/>" in h7[2] and ">On-Demand<" in h7[2]))
res.append(("7-col headers centered", all('<w:jc w:val="center"/>' in c for c in h7)))
res.append(("3-col headers keep column alignment", '<w:jc w:val="center"/>' not in "".join(h3) and '<w:jc w:val="right"/>' in h3[1]))
res.append(("<br> header splits and centers", "<w:br/>" in hbr[1] and all('<w:jc w:val="center"/>' in c for c in hbr)))
res.append(("html: same split", "On-Demand<br>(USD/시간)" in html and "JVM 사용<br>코어" in html))
res.append(("html: short note centered, long note not", '<p class="br-capnote one">짧은' in html and '<p class="br-capnote">아주 긴' in html))
for name, okv in res: print(("ok   " if okv else "FAIL ") + name)
PY
while read -r st name; do [ "$st" = ok ] && ok "${name}" || bad "${name}"; done < <(sed 's/^ok   /ok /; s/^FAIL /FAIL /' "$TMP/layout.txt")
out=$(python3 "$S/check_report.py" "$TMP/layout/layout.docx" "$TMP/layout/layout.html")
[ $? -eq 0 ] && ok "check_report passes the layout fixture" || bad "check_report passes the layout fixture" "$out"

echo "== examples"
for sk in benchmark-report:benchmark poc-report:poc; do
  name=${sk%%:*}; prof=${sk##*:}
  node "$S/report.mjs" "$ROOT/skills/$name/assets/example/example.md" --out-dir "$TMP/$name" > "$TMP/$name.log" 2>&1 && ok "$name: build example" || bad "$name: build example" "$(cat "$TMP/$name.log")"
  check "$name: no converter warnings" "grep -q 'warnings=0' '$TMP/$name.log'"
  out=$(python3 "$S/check_report.py" "$TMP/$name/example.docx" "$TMP/$name/example.html" --profile $prof)
  if [ $? -eq 0 ] && [ "$(echo "$out" | grep -c '   OK')" -eq 2 ]; then ok "$name: check --profile $prof clean"; else bad "$name: check --profile $prof clean" "$out"; fi
done
out=$(python3 "$S/check_report.py" "$TMP/poc-report/example.docx" --profile benchmark)
echo "$out" | grep -q '첫 번째 섹션이 측정 환경' && ok "profiles differ: poc example warns under benchmark" || bad "profiles differ" "$out"

echo "== negative checks"
mkdir -p "$TMP/neg" && cp "$TMP/layout/layout.docx" "$TMP/neg/n.docx" && (cd "$TMP/neg" && unzip -q n.docx word/document.xml)
python3 - "$TMP/neg/word/document.xml" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding="utf-8").read()
i = s.index("<w:tbl>"); j = s.index("</w:tr>", i)
s = s[:i] + s[i:j].replace('<w:jc w:val="center"/>', '<w:jc w:val="left"/>') + s[j:]
k = s.index("짧은 주석"); a = max(s.rfind("<w:p>", 0, k), s.rfind("<w:p ", 0, k))
s = s[:a] + s[a:k].replace('<w:jc w:val="center"/>', "") + s[k:]
open(p, "w", encoding="utf-8").write(s)
PY
(cd "$TMP/neg" && zip -q n.docx word/document.xml)
out=$(python3 "$S/check_report.py" "$TMP/neg/n.docx")
[ $? -ne 0 ] && ok "uncentered two-line header fails" || bad "uncentered two-line header fails" "$out"
echo "$out" | grep -q "two-line table header" && ok "  reports the header rule" || bad "  reports the header rule" "$out"
echo "$out" | grep -q "caption note alignment" && ok "  reports the caption note rule" || bad "  reports the caption note rule" "$out"
sed -e 's/<th class="ctr">인스턴스<\/th>/<th>인스턴스<\/th>/' -e 's/br-capnote one/br-capnote/' "$TMP/layout/layout.html" > "$TMP/neg/n.html"
out=$(python3 "$S/check_report.py" "$TMP/neg/n.html")
[ $? -ne 0 ] && echo "$out" | grep -q "two-line" && echo "$out" | grep -q "caption note" && ok "html: header and note rules fail" || bad "html: header and note rules fail" "$out"

node "$S/report.mjs" "$ROOT/tests/fixtures/poc-bad.md" --out-dir "$TMP/bad" >/dev/null 2>&1
out=$(python3 "$S/check_report.py" "$TMP/bad/poc-bad.docx" "$TMP/bad/poc-bad.html" --profile poc)
for want in '판정 "PASS"' '판정 "거의 충족"' '용어 "PASS"' '용어 "성공적으로"' '용어 "고객 권고"' '첫 번째 섹션이 PoC 개요가 아님' '성공 기준 섹션이 없음' '마지막 섹션이 종합 평가와 다음 단계가 아님' '전체 판정'; do
  echo "$out" | grep -q -- "$want" && ok "poc: warns $want" || bad "poc: warns $want" "$out"
done
out=$(python3 "$S/check_report.py" "$TMP/bad/poc-bad.docx" --profile benchmark)
echo "$out" | grep -q '용어 "PASS"' && bad "benchmark profile skips poc-only terms" "$out" || ok "benchmark profile skips poc-only terms"
echo "$out" | grep -q '용어 "고객 권고"' && ok "benchmark profile warns 고객 권고" || bad "benchmark profile warns 고객 권고" "$out"

echo "== charts"
if command -v uv >/dev/null; then
  cp -r "$ROOT/skills/poc-report/assets/example" "$TMP/ex" && mkdir -p "$TMP/plug/skills/poc-report/assets" && mv "$TMP/ex" "$TMP/plug/skills/poc-report/assets/example" && ln -s "$ROOT/shared" "$TMP/plug/shared"
  out=$(cd "$TMP/plug/skills/poc-report/assets/example" && rm -f charts/*.png && uv run --quiet --no-project --with matplotlib python make_charts.py 2>&1)
  echo "$out" | grep -q "필수 5개 중 충족 4개" && ok "poc example verdicts computed from data" || bad "poc example verdicts" "$out"
  check "criteria chart written" "[ -s '$TMP/plug/skills/poc-report/assets/example/charts/chart-criteria.png' ]"
else
  echo "  skip charts (uv not found)"
fi

echo
echo "passed $pass, failed $fail"
[ "$fail" -eq 0 ]
