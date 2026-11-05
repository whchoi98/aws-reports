---
name: poc-report
description: PoC(개념 검증), 파일럿, 기술 검증의 결과를 고객과 공유할 보고서로 만든다. 성공 기준마다 목표, 결과, 판정(충족 / 부분 충족 / 미충족 / 측정하지 않음)을 정리하고 전체 판정(진행 / 조건부 진행 / 보류)과 다음 단계를 쓴 원고 하나에서 MS Word(.docx)와 단일 HTML 파일을 같은 스타일로 함께 만들고 검사한다. "PoC 결과 보고서", "PoC 결과 정리", "PoC 보고서 Word로", "PoC 종료 보고", "검증 결과 보고서", "파일럿 결과 보고", "성공 기준 판정", "Go/No-Go 정리", "고객 공유용 PoC 문서", "워드랑 HTML로" 같은 요청에 사용하고, PoC 측정 결과나 메모, 이슈 목록만 주면서 "보고서로 정리해줘"라고 할 때도 사용한다. 성공 기준 없이 인스턴스나 설정의 성능을 비교하는 보고서는 benchmark-report를, 이미 있는 .docx 수정은 docx 스킬을, PoC 제안서나 발표 자료는 다른 스킬을 쓴다.
---

# PoC Report: Markdown → Word + HTML

PoC 결과를 **Word(.docx)와 HTML 두 파일**로 만든다. 둘은 같은 Markdown 원고에서 함께 빌드되므로 문장, 숫자, 판정, 그림·표 번호가 항상 같다. 글꼴, 박스, 캡션, 표 규칙은 benchmark-report와 같은 사내 스타일이고, 구성과 판정 규칙이 PoC에 맞춰져 있다.

빌드 엔진과 공통 규칙은 이 플러그인의 `shared/` 폴더에 있다. 아래 명령의 `$R`은 그 폴더다.

```bash
R="${CLAUDE_SKILL_DIR}/../../shared"
```

| 파일 | 언제 읽나 |
|---|---|
| `references/structure.md` | 원고 뼈대를 잡을 때. 섹션 순서, 섹션 하나의 모양, 차트 고르기 |
| `references/verdict-rules.md` | 판정을 정할 때. 성공 기준, 판정 단어, 전체 판정, 이슈 연결, 권고 |
| `$R/markdown-spec.md` | 원고를 쓸 때. 머리말, 그림·표 캡션, 표 머리글, 박스, 코드, 페이지 나눔 문법 |
| `$R/style-rules.md` | 문장을 쓰고 고칠 때. 사용자가 교정한 표현, 표기 |
| `assets/example/` | 완성된 예(가상의 PoC): `example.md`, 판정 계산과 차트 `make_charts.py`, 데이터 `data.json` |

## 0. 준비

```bash
bash "$R/scripts/setup.sh"
```

npm 패키지, 글꼴(나눔스퀘어OTF, D2Coding, npm `@kfonts/*` OFL-1.1), uv를 확인하고 없는 것만 설치한다. 이미 설치돼 있으면 바로 끝나므로 빌드 전에 매번 실행해도 된다.

## 1. 재료 확인

다음을 모은다. 사용자가 준 파일과 메시지에서 먼저 찾고, 없는 것만 묻는다.

| 재료 | 없으면 |
|---|---|
| 성공 기준(목표값, 단위, 측정 방법, 필수/선택) | **보고서를 쓰기 전에 묻는다.** 판정의 근거라서 대신 만들지 않는다(verdict-rules.md). 기준 없이 인스턴스나 설정의 성능 비교만 있는 PoC라면 benchmark-report가 맞다고 알리고 어느 쪽으로 쓸지 묻는다 |
| 기준별 측정 결과 | 그 기준은 "측정하지 않음"으로 쓰고 이유를 묻거나 적는다 |
| PoC 목적, 범위, 기간, 참여 조직 | 주어진 만큼만 쓴다. 사람 이름은 사용자가 준 경우에만 |
| 이슈와 조치, 상태 | 메모에서 찾는다. 없으면 이슈 표를 비우지 말고 "이슈 없음"으로 쓴다 |
| 비용(PoC 실제, 운영 예상)과 가격 기준 | 비용 섹션을 빼거나, 계산에 필요한 값만 묻는다 |
| 구성도 | aws-diagrams 플러그인의 aws-diagram 스킬로 그린다. 구성 정보가 없으면 그림 없이 표로 쓴다 |

보고서의 모든 숫자와 판정은 데이터에서 계산한다. 목표 대비 비율, 필수 기준 충족 수, 비용 합계는 Python으로 계산해 표와 본문에 옮긴다. 손으로 옮기면 표 1, 기준별 결과, 종합 평가 표가 서로 어긋나기 쉽다. 없는 값은 만들지 않는다.

## 2. 뼈대 (references/structure.md)

머리말과 리드, 굵은 결론 문단(전체 판정), 표 1 성공 기준별 판정 요약 → **1. PoC 개요** → **2. 성공 기준** → 3. 구성과 방법 → 기준별 결과 → 이슈와 조치 → 비용 → **마지막: 종합 평가와 다음 단계**. 의사결정자는 첫 쪽에서 판정을, 실무자는 기준과 방법을 먼저 확인한다. 사용자가 이 순서를 골랐다.

## 3. 판정 (references/verdict-rules.md)

기준마다 충족 / 부분 충족 / 미충족 / 측정하지 않음 중 하나를 정하고, 필수 기준의 결과로 전체 판정(진행 / 조건부 진행 / 보류)을 정한다. 미충족, 부분 충족, 측정하지 않음은 모두 이슈 표나 다음 단계 표와 이어져야 한다. 판정 단어를 바꿔 쓰거나(PASS, 성공), 결과를 본 뒤 목표를 고치지 않는다.

## 4. 차트 ($R/scripts/chart_style.py)

차트는 PNG로 만들어 원고 옆 `charts/`에 둔다. 판정 계산과 차트를 한 스크립트에 두면 숫자가 한 곳에서 나온다(예제 `make_charts.py`).

```python
import sys; sys.path.insert(0, "<R>/scripts")   # <R>: 위 R 변수의 실제 경로(echo "$R"로 확인)
from chart_style import setup, criteria, grouped_hbar, lines, fmt, MUTED, INK
setup()
criteria("charts/chart-criteria.png", [("C1 요약 품질", 1.075, "충족"), ("C5 피크 처리량", 0.70, "미충족"),
                                       ("C3 개인정보 마스킹", None, "충족", "누락 0건")])
```

`uv run --no-project --with matplotlib python make_charts.py`로 실행한다. 구성도는 aws-diagram 스킬로 SVG를 만든 뒤 `$R/scripts/svg2png.py`로 PNG로 바꾼다(Word는 SVG를 넣지 못한다). 만든 PNG는 Read로 열어 범례, 라벨 겹침, 잘림을 확인한다.

## 5. 원고 ($R/markdown-spec.md, $R/style-rules.md)

원고는 작업 폴더에 `<name>.md`로 쓴다(사용자가 정하지 않으면 프로젝트의 `report/`). 예제 `assets/example/example.md`를 열어 뼈대를 그대로 따라 쓰면 빠르다. 핵심 문법:

- 그림: `![캡션](charts/x.png "width=15")` 단독 문단 → 아래에 `그림 N. 캡션`
- 표: GFM 표, 빈 줄, `표: 캡션` → 아래에 `표 N. 캡션`. 이어서 `주: …`는 작은 회색 설명(한 줄이면 가운데, 길면 왼쪽 정렬)
- 판정 열의 머리글은 정확히 `판정`으로 쓴다. 검사 스크립트가 이 열의 단어를 확인한다
- 표 머리글의 단위는 괄호로 끝에 쓴다(`PoC 실제 비용 (USD)`). 열 폭에 넘치면 변환기가 괄호를 둘째 줄로 내리고 머리글을 가운데 정렬한다
- 박스: `> **함축형 제목**` + 본문/목록. 권고 박스 제목은 "권고"
- `<!-- pagebreak -->`: 기준별 결과 앞, 종합 평가 앞

문장은 style-rules.md를 따른다. 사용자가 교정한 표현("고객 권고" → "권고", 박스 제목은 함축형, 보고서 밖 화면·링크 언급 금지)은 처음부터 쓰지 않는다. 고객이 읽는 문서이므로 고객사를 3인칭으로 낮추거나 평가하는 말을 쓰지 않는다.

## 6. 빌드

```bash
node "$R/scripts/report.mjs" report/<name>.md --out-dir report/out
```

`report/out/<name>.docx`와 `report/out/<name>.html`이 생긴다. 변환기 경고(`warn:`)는 원고 문제이므로 원고를 고쳐 0으로 만든다.

## 7. 검사

```bash
python3 "$R/scripts/check_report.py" report/out/<name>.docx report/out/<name>.html --profile poc
```

- `ERROR`: 스타일 계약 위반(A4·여백, 글꼴, 캡션 위치와 번호, 강조 막대, 두 줄 머리글 정렬, 캡션 주석 정렬, 두 파일의 그림·표 수 불일치). 고친 뒤 다시 빌드한다.
- `WARN`: 섹션 순서(개요 → 성공 기준 → … → 종합 평가와 다음 단계), 판정 열의 단어, 결론 문단의 전체 판정, 교정했던 표현, 문장형 박스 제목. 하나씩 보고 고치거나, 의도한 것이면 그대로 둔다.

## 8. 눈으로 확인

```bash
uv run --no-project --with playwright python "$R/scripts/preview.py" report/out/<name>.docx report/out/<name>.html --out-dir report/out/preview
```

출력된 PNG를 Read로 열어 본다. 첫 쪽에 전체 판정과 표 1이 함께 보이는지, 판정 단어가 표마다 같은지 확인한다. docx 미리보기는 쪽 나눔, 쪽 번호 필드, 한글 단어 단위 줄바꿈을 재현하지 않는다. LibreOffice(`soffice`)가 있으면 PDF로 바꿔 실제 쪽 나눔도 확인한다.

## 9. 전달

마지막 응답에 두 파일의 절대 경로, 전체 판정 한 줄, 사용자에게 확인받아야 할 것(가정한 필수/선택 구분, 묻지 못한 값)을 적는다. 그리고 다음을 한두 줄로 알린다.

- Word 본문 글꼴 나눔스퀘어OTF는 문서에 포함할 수 없어 받는 사람 PC에 없으면 다른 글꼴로 보인다. D2Coding(코드)은 포함돼 있다.
- HTML은 글꼴과 그림을 포함한 단일 파일이라 그대로 메일로 보내거나 열 수 있다.

## 교정을 받으면

1. 원고 `.md`를 고치고 두 파일을 다시 빌드한다. Word나 HTML을 직접 고치지 않는다.
2. 사용자가 Word 파일을 직접 고쳐 보냈으면 다시 빌드하기 전에 생성한 파일과 비교해 바뀐 점을 원고나 규칙으로 옮긴다. 그냥 다시 빌드하면 사용자의 수정이 사라진다.
3. 판정이 바뀌면 표 1, 기준별 소제목, 종합 평가 표, 결론 문단을 함께 고친다(한 스크립트에서 다시 계산하면 어긋나지 않는다).
4. 새 표현 교정은 `$R/style-rules.md`와 `$R/scripts/style_terms.json`에 추가한다. PoC에만 해당하면 `"profiles": ["poc"]`를 붙인다.
