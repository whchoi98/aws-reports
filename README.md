# aws-reports

[![Version](https://img.shields.io/badge/Version-1.0.0-green.svg)](CHANGELOG.md)
<a href="#english"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a>
<a href="#korean"><img src="https://img.shields.io/badge/lang-한국어-red.svg" alt="Korean"></a>

A Claude Code plugin that builds customer-facing technical reports as both an MS Word file and a standalone HTML file from one Markdown draft | Markdown 원고 하나에서 고객 공유용 기술 보고서를 MS Word와 단일 HTML로 함께 만드는 Claude Code 플러그인

---

<a id="english"></a>

# English

## Overview

`aws-reports` has two skills that share one build engine and one house style (NanumSquareOTF body, D2Coding code, numbered sections, figure and table captions below, gray boxes without an accent bar).

| Skill | Use it for |
|---|---|
| `benchmark-report` | Benchmarks, performance and instance comparisons, load tests. Order: test setup and method → results → cause → overall verdict and recommendations |
| `poc-report` | PoC and pilot results. Success criteria with a fixed verdict vocabulary (met / partly met / not met / not measured), an overall decision (proceed / proceed with conditions / hold), issues and next steps |

Both skills write one Markdown draft, build `<name>.docx` and `<name>.html` from it with `shared/scripts/report.mjs`, and check both files with `shared/scripts/check_report.py` (`--profile benchmark` or `--profile poc`).

## Layout

```
.claude-plugin/          plugin.json, marketplace.json (source ./)
shared/                  build engine and rules used by both skills
  markdown-spec.md       draft syntax (captions, notes, boxes, table headers, page breaks)
  style-rules.md         wording the user corrected, notation, the recommendation box
  scripts/               report.mjs, check_report.py, chart_style.py, fonts.py, preview.py, svg2png.py, setup.sh, style_terms.json
skills/benchmark-report/ SKILL.md, references/structure.md, assets/example/
skills/poc-report/       SKILL.md, references/structure.md, references/verdict-rules.md, assets/example/
tests/run-all.sh         builds both examples and runs positive and negative checks
```

Skills reach the shared folder through `${CLAUDE_SKILL_DIR}/../../shared`, so keep the two skills inside this plugin.

## Install (local marketplace)

```bash
claude plugin marketplace add /home/ec2-user/my-project/my-plugins/aws-reports
claude plugin install aws-reports@aws-reports
```

Then restart Claude Code or run `/reload-plugins`. The first build runs `shared/scripts/setup.sh`, which installs npm packages (docx, marked, docx-preview) into the plugin cache and fonts from npm `@kfonts/*` (OFL-1.1) into `~/.local/share/fonts`. Requirements: Node.js 18+, Python 3, uv.

## Update

Any change under `skills/` or `shared/` needs a version bump in `.claude-plugin/plugin.json`, a CHANGELOG entry, then `claude plugin marketplace update aws-reports` and `claude plugin update aws-reports@aws-reports`.

## Test

```bash
bash tests/run-all.sh
```

---

<a id="korean"></a>

# 한국어

## 개요

`aws-reports`에는 빌드 엔진 하나와 사내 스타일 하나(나눔스퀘어OTF 본문, D2Coding 코드, 번호 붙은 섹션, 아래쪽 그림·표 캡션, 강조 막대 없는 회색 박스)를 함께 쓰는 스킬 두 개가 있습니다.

| 스킬 | 쓰는 곳 |
|---|---|
| `benchmark-report` | 벤치마크, 성능·인스턴스 비교, 부하 시험. 순서: 측정 환경과 방법 → 결과 → 원인 → 종합 평가와 권고 |
| `poc-report` | PoC와 파일럿 결과. 성공 기준별 판정(충족 / 부분 충족 / 미충족 / 측정하지 않음), 전체 판정(진행 / 조건부 진행 / 보류), 이슈와 다음 단계 |

두 스킬 모두 Markdown 원고 하나를 쓰고, `shared/scripts/report.mjs`로 `<name>.docx`와 `<name>.html`을 함께 만든 뒤 `shared/scripts/check_report.py`(`--profile benchmark` 또는 `--profile poc`)로 두 파일을 검사합니다.

## 설치 (로컬 마켓플레이스)

```bash
claude plugin marketplace add /home/ec2-user/my-project/my-plugins/aws-reports
claude plugin install aws-reports@aws-reports
```

설치한 뒤 Claude Code를 다시 시작하거나 `/reload-plugins`를 실행합니다. 처음 빌드할 때 `shared/scripts/setup.sh`가 npm 패키지(docx, marked, docx-preview)를 플러그인 캐시에, 글꼴(npm `@kfonts/*`, OFL-1.1)을 `~/.local/share/fonts`에 설치합니다. 필요한 도구는 Node.js 18 이상, Python 3, uv입니다.

## 업데이트

`skills/`나 `shared/` 아래를 고치면 `.claude-plugin/plugin.json`의 버전을 올리고 CHANGELOG에 기록한 뒤 `claude plugin marketplace update aws-reports`, `claude plugin update aws-reports@aws-reports`를 실행합니다.

## 테스트

```bash
bash tests/run-all.sh
```
