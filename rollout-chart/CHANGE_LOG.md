# Change Log

## 0.0.2

- fix: fail with a clear message instead of a nil pointer error when `lifecycle.<hook>` has no handler
  - `lifecycle.preStop` without `exec` used to render `nil pointer evaluating interface {}.command`
  - `exec` without `command`, an unsupported handler (`httpGet`, `tcpSocket`) and a misspelled hook name are now rejected at render time
- refactor: render `lifecycle` through a shared template helper
- feat: support the `sleep` lifecycle handler (`lifecycle.<hook>.sleep.seconds`)
  - runs in the kubelet, so the image needs no shell and no `sleep` binary (works on distroless/scratch)
  - requires Kubernetes 1.30+, or 1.29 with the `PodLifecycleSleepAction` feature gate
  - `seconds: 0` is rejected; it needs the separate `PodLifecycleSleepActionAllowZero` gate
  - `exec` and `sleep` cannot be set on the same hook

## 0.0.1

- feat: support initContainers
