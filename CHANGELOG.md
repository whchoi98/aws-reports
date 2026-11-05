# Changelog

All notable changes to this plugin are documented here. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versions: [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-11-05

### Added
- `benchmark-report` skill, moved from the user-level skill `~/.claude/skills/benchmark-report` (created 2026-11-03).
- `poc-report` skill: PoC result report with success criteria, fixed verdict words, overall decision, issues, cost and next steps; example PoC (fictional data) with `criteria` chart.
- `shared/`: build engine, draft syntax and wording rules used by both skills; `check_report.py --profile benchmark|poc`.
- `chart_style.criteria()`: success criteria against targets, colored by verdict.
- `tests/run-all.sh`: builds both examples, positive and negative checks.

### Changed
- Table headers that do not fit on one line put the trailing unit on a second line and center every header cell of that table; `<br>` splits a header by hand.
- Caption notes are centered when they fit on one line and left-aligned when they wrap.
- Wide tables use smaller text (8-9 columns 7.5/7 pt, 10+ columns 6.5 pt).
- Box title "고객 권고" is now "권고"; `style_terms.json` warns on the old title.

These four rules come from the user's hand edits of a generated Word report on 2026-11-04.

---

# 변경 이력

## [1.0.0] - 2026-11-05

### 추가
- `benchmark-report` 스킬: 사용자 스킬 `~/.claude/skills/benchmark-report`(2026-11-03)를 옮겼습니다.
- `poc-report` 스킬: 성공 기준, 고정된 판정 단어, 전체 판정, 이슈, 비용, 다음 단계를 담은 PoC 결과 보고서. 가상의 데이터로 만든 예제와 `criteria` 차트를 포함합니다.
- `shared/`: 두 스킬이 함께 쓰는 빌드 엔진, 원고 문법, 문체 규칙. `check_report.py --profile benchmark|poc`.
- `chart_style.criteria()`: 성공 기준별 목표 대비 결과를 판정 색으로 그립니다.
- `tests/run-all.sh`: 두 예제를 빌드하고 정상·부정 검사를 실행합니다.

### 변경
- 한 줄에 들어가지 않는 표 머리글은 끝의 단위를 둘째 줄로 내리고 그 표의 머리글을 모두 가운데 정렬합니다. `<br>`로 직접 나눌 수 있습니다.
- 캡션 주석은 한 줄이면 가운데, 두 줄 이상이면 왼쪽 정렬합니다.
- 열이 많은 표는 글자를 줄입니다(8~9열 7.5/7pt, 10열 이상 6.5pt).
- 박스 제목 "고객 권고"를 "권고"로 바꾸고, `style_terms.json`이 옛 제목을 경고합니다.

네 가지 규칙은 2026-11-04 사용자가 생성된 Word 보고서를 직접 고친 내용에서 가져왔습니다.
