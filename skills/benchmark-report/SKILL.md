---
name: benchmark-report
description: 벤치마크, 성능 비교, 부하 시험, 인스턴스·설정 비교 결과를 고객과 동료에게 공유할 보고서로 만든다. 하나의 Markdown 원고에서 MS Word(.docx)와 단일 HTML 파일을 같은 스타일(나눔스퀘어OTF 본문, D2Coding 코드, 번호 붙은 섹션, 아래쪽 그림·표 캡션, 왼쪽 막대 없는 회색 박스, Graviton 주황·Intel 파랑 차트)로 함께 만들고 검사한다. "벤치마크 보고서", "성능 비교 결과 정리", "측정 결과를 Word로", "워드랑 HTML로", "docx 보고서", "인스턴스 비교 보고서", "Graviton vs Intel", "부하 테스트 결과 문서", "고객 공유용 결과 보고서" 같은 요청에 사용하고, 측정 데이터(CSV, JSON, 로그, 표)만 주면서 "보고서로 정리해줘"라고 할 때도 사용한다. 성공 기준을 놓고 충족 여부를 판정하는 PoC 결과 보고서는 poc-report를, 이미 있는 .docx를 고치거나 변경 추적이 필요하면 docx 스킬을, 블로그 원고는 aws-blog-skills를 쓴다.
---

# Benchmark Report: Markdown → Word + HTML

측정 결과를 **Word(.docx)와 HTML 두 파일**로 만든다. 둘은 같은 Markdown 원고에서 함께 빌드되므로 문장, 숫자, 그림·표 번호가 항상 같다. 스타일은 Graviton과 Intel 인스턴스의 Spring Boot 벤치마크 보고서에서 사용자가 하나씩 교정해 확정한 것이다.

빌드 엔진과 공통 규칙은 이 플러그인의 `shared/` 폴더에 있고 poc-report 스킬과 함께 쓴다. 아래 명령의 `$R`은 그 폴더다.

```bash
R="${CLAUDE_SKILL_DIR}/../../shared"
```

| 파일 | 언제 읽나 |
|---|---|
| `references/structure.md` | 원고 뼈대를 잡을 때. 섹션 순서, 섹션 하나의 모양, 차트 고르기, 결론 쓰는 법 |
| `$R/markdown-spec.md` | 원고를 쓸 때. 머리말, 그림·표 캡션, 표 머리글, 박스, 코드, 페이지 나눔 문법 |
| `$R/style-rules.md` | 문장을 쓰고 고칠 때. 사용자가 교정한 표현, 표기, 권고 박스 |
| `assets/example/` | 완성된 예: `example.md`, 차트 스크립트 `make_charts.py`, 데이터 `data.json` |

## 0. 준비

```bash
bash "$R/scripts/setup.sh"
```

npm 패키지(docx, marked, docx-preview), 글꼴(나눔스퀘어OTF, D2Coding, npm `@kfonts/*` OFL-1.1), uv를 확인하고 없는 것만 설치한다. 이미 설치돼 있으면 바로 끝나므로 빌드 전에 매번 실행해도 된다. 플러그인을 새 버전으로 업데이트하면 npm 패키지는 다시 설치된다. 글꼴이 없으면 차트의 한글이 깨지고 HTML에 글꼴을 넣을 수 없다.

## 1. 재료 확인

측정 데이터, 측정 조건(인스턴스, 리전, 도구, 부하 단계, 회차), 가격 기준을 모은다. 보고서의 모든 숫자는 데이터에서 계산한다. 비율, 변화율, 기하평균은 Python으로 계산해 표와 본문에 옮긴다. 손으로 옮기면 표와 본문 숫자가 어긋나기 쉽다.

없는 값은 만들지 않는다. 결론에 필요한 값(예: 가격 기준)이 빠졌으면 사용자에게 묻고, 나머지는 "측정하지 않았습니다"로 쓴다.

## 2. 뼈대 (references/structure.md)

머리말과 리드, 굵은 결론 문단, 표 1 핵심 결과 → **1. 측정 환경과 방법** → 결과 섹션들 → **마지막: 종합 평가와 권고**. 독자는 조건을 먼저 확인해야 숫자를 믿고, 결정은 끝에서 찾는다. 사용자가 실제로 이 순서를 지정했다.

## 3. 차트 ($R/scripts/chart_style.py)

차트는 PNG로 만들어 원고 옆 `charts/`에 둔다. Word와 HTML이 같은 PNG를 쓴다.

```python
import sys; sys.path.insert(0, "<R>/scripts")   # <R>: 위 R 변수의 실제 경로(echo "$R"로 확인)
from chart_style import setup, hbar, grouped_hbar, dumbbell, lines, verdict, fmt
setup()
hbar("charts/chart-score.png", [("c8i.2xlarge", 92976, "Intel", 8), ("c8g.2xlarge", 74721, "Graviton", 8)], fmt=fmt.int)
```

`uv run --no-project --with matplotlib python make_charts.py`로 실행한다. 아키텍처 구성도는 aws-diagrams 플러그인의 aws-diagram 스킬로 SVG를 만든 뒤 `$R/scripts/svg2png.py`로 PNG로 바꾼다(Word는 SVG만으로는 그림을 넣지 못한다). 만든 PNG는 Read로 열어 범례, 라벨 겹침, 잘림을 확인한다.

## 4. 원고 ($R/markdown-spec.md, $R/style-rules.md)

원고는 작업 폴더에 `<name>.md`로 쓴다(사용자가 정하지 않으면 프로젝트의 `report/`). 핵심 문법:

- 그림: `![캡션](charts/x.png "width=15")` 단독 문단 → 아래에 `그림 N. 캡션`
- 표: GFM 표, 빈 줄, `표: 캡션` → 아래에 `표 N. 캡션`. 이어서 `주: …`는 작은 회색 설명(한 줄이면 가운데, 길면 왼쪽 정렬)
- 표 머리글: 단위는 괄호로 끝에 쓴다(`On-Demand (USD/시간)`). 열 폭에 넘치면 변환기가 괄호를 둘째 줄로 내리고 그 표의 머리글을 가운데 정렬한다. 직접 나누려면 `<br>`
- 박스: `> **함축형 제목**` + 본문/목록 → 회색 배경, 가는 테두리, 왼쪽 막대 없음
- 코드: 명령, 설정 키, 클래스, 경로는 `` `인라인 코드` `` → D2Coding
- `<!-- pagebreak -->`: 다음 섹션을 새 페이지에서 시작(첫 결과 섹션 앞, 종합 평가 앞)

문장은 style-rules.md를 따른다. 특히 사용자가 교정한 표현(쌍 → 페어, 잠금 → 락(lock), 박스 제목은 함축형, "고객 권고" → "권고", 보고서 밖 화면·링크 언급 금지)은 처음부터 쓰지 않는다.

## 5. 빌드

```bash
node "$R/scripts/report.mjs" report/<name>.md --out-dir report/out
```

`report/out/<name>.docx`와 `report/out/<name>.html`이 생긴다. 변환기 경고(`warn:`)는 캡션 누락, 문장형 박스 제목, 잘못 놓인 `표:` 같은 원고 문제이므로 원고를 고쳐 0으로 만든다.

- Word: A4, 여백 2 cm, 본문 나눔스퀘어OTF 10pt, 한글 단어 단위 줄바꿈, 머리글(제목), 바닥글(쪽 / 전체 쪽), D2Coding 영문 부분집합 포함
- HTML: 단일 파일(글꼴은 쓰인 글자만 잘라 woff2로, 그림은 data URI로 포함), 모바일 폭 대응, 다크 모드, 인쇄 시 A4와 쪽 번호

## 6. 검사

```bash
python3 "$R/scripts/check_report.py" report/out/<name>.docx report/out/<name>.html --profile benchmark
```

- `ERROR`: 스타일 계약 위반(A4·여백, 글꼴, 캡션 위치와 번호, 강조 막대, 두 줄 머리글 정렬, 캡션 주석 정렬, 두 파일의 그림·표 수 불일치). 고친 뒤 다시 빌드한다.
- `WARN`: 사용자가 교정했던 표현, 문장형 박스 제목, 섹션 순서. 하나씩 보고 고치거나, 의도한 것이면 그대로 둔다.

## 7. 눈으로 확인

```bash
uv run --no-project --with playwright python "$R/scripts/preview.py" report/out/<name>.docx report/out/<name>.html --out-dir report/out/preview
```

출력된 PNG를 Read로 열어 본다. 자동 검사가 통과해도 보지 않은 결과물은 전달하지 않는다. docx 미리보기(docx-preview)는 스타일, 표, 박스, 그림은 Word처럼 그리지만 내용 높이에 따른 쪽 나눔, 쪽 번호 필드, 한글 단어 단위 줄바꿈은 재현하지 않는다. LibreOffice(`soffice`)가 있으면 PDF로 바꿔 실제 쪽 나눔도 확인한다.

## 8. 전달

마지막 응답에 두 파일의 절대 경로를 적고, 다음을 한두 줄로 알린다.

- Word 본문 글꼴 나눔스퀘어OTF는 CFF 형식이라 문서에 포함할 수 없다. 받는 사람 PC에 없으면 다른 글꼴로 보인다. D2Coding(코드)은 문서에 포함돼 있다.
- HTML은 글꼴과 그림을 포함한 단일 파일이라 그대로 메일로 보내거나 열 수 있다.
- 확인하지 못한 것(예: Word에서 직접 연 화면)이 있으면 그대로 말한다.

사용자가 HTML을 링크로 공유하길 원하면 Artifact 도구 규칙(디자인 스킬 로드, 제목, 다크 모드)을 따라 게시한다. HTML은 이미 다크 모드 토큰과 모바일 폭을 갖추고 있다.

## 교정을 받으면

1. 원고 `.md`를 고치고 두 파일을 다시 빌드한다. Word나 HTML을 직접 고치지 않는다. 직접 고치면 두 파일이 어긋난다.
2. 사용자가 Word 파일을 직접 고쳐 보냈으면 다시 빌드하기 전에 생성한 파일과 비교한다(문구, 문단 정렬, 글자 크기, 열 폭, 머리글 줄 나눔). 바뀐 점을 원고나 규칙으로 옮긴 뒤 빌드한다. 그냥 다시 빌드하면 사용자의 수정이 사라진다. 원본은 `report/backup/`에 남겨 둔다.
3. 같은 표현을 원고 전체, 차트 라벨, 구성도 SVG에서 다시 찾는다.
4. 새 표현 교정은 `$R/style-rules.md` 표와 `$R/scripts/style_terms.json`에 추가해 다음 보고서에서도 검사되게 한다. 레이아웃 교정(정렬, 크기)은 `$R/scripts/report.mjs`의 `tableLayout`과 `check_report.py`에 함께 넣는다.
