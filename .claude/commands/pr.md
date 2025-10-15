---
description: Pull Request를 생성합니다
---

현재 브랜치로 Pull Request를 생성해줘.

## 작업 순서

1. CONTRIBUTING.md 파일을 읽고 PR 작성 규칙 확인
2. git status로 현재 상태 확인
3. git log main..HEAD로 커밋 목록 확인
4. .github/PULL_REQUEST_TEMPLATE.md 템플릿을 기반으로 PR 내용 작성
5. 작성한 PR 내용을 나에게 먼저 보여주고 승인받기
6. `gh pr create`로 PR 생성

## 주의사항

- Assignee는 나(PR 작성자)로 설정
- ⚠️ "Generated with Claude Code" 같은 자동 생성 문구 절대 포함 금지