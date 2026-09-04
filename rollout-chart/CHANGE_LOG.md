# Change Log

## 0.0.2

- fix: fail with a clear message instead of a nil pointer error when `lifecycle.<hook>` has no handler
  - `lifecycle.preStop` without `exec` used to render `nil pointer evaluating interface {}.command`
  - `exec` without `command`, an unsupported handler (`httpGet`, `tcpSocket`) and a misspelled hook name are now rejected at render time
- refactor: render `lifecycle` through a shared template helper

## 0.0.1

- feat: support initContainers
