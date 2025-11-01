# Contributing Guidelines

## Branch

- default: `main`
- task: `feature/`, `fix/`, `refactor/` (ex: `feature/calendar-view`)

## Issue

- title format: `type: description` (ex: `feat: 캘린더 뷰 구현`)
  - type: English (feat, fix, refactor, docs, chore, etc)
  - description: Korean
- template: follow `.github/ISSUE_TEMPLATE/feature.md`
  - content: Korean
- assignee: self

## Commit

- format: `type: description (#issue_number)` (ex: `feat: 캘린더 뷰 구현 (#1)`)
  - type: English (feat, fix, refactor, docs, test, chore)
  - description: Korean
  - issue_number: related issue's number
- body(optional): brief explanation in Korean
  - what changed and why
  - keep concise but informative
- atomic commits: one logical change per commit, keep each commit buildable
- **forbidden**: "Generated with Claude Code" phrase, "Co-Authored-By" attribution

## PR

- title format: `type: description`
  - type: English
  - description: Korean
- content: follow `.github/PULL_REQUEST_TEMPLATE.md`
  - content: Korean
- size: recommend under 500 lines
- assignee: self
- close issue: `Closes #number`