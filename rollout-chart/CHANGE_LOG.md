# Change Log

## 0.0.3

- feat: support `securityContext`
  - Pod-level (`.Values.securityContext`): `runAsNonRoot`, `runAsUser`, `runAsGroup`, `fsGroup`, `fsGroupChangePolicy`, `supplementalGroups`, `seccompProfile`
  - Container-level (`containers[].securityContext`, `initContainers[].securityContext`): `runAsNonRoot`, `runAsUser`, `runAsGroup`, `capabilities`, `allowPrivilegeEscalation`, `seccompProfile`, `readOnlyRootFilesystem`
  - an unsupported key is rejected at render time with a clear error message
  - `capabilities` and `seccompProfile` are validated too, not just passed through: unknown sub-keys, a non-list `add`/`drop`, an invalid `seccompProfile.type`, and a `localhostProfile` that does not match the type all fail at render time
  - `securityContext` that is not a map fails with a chart error instead of a raw template error
- feat: support `hostUsers` (Pod spec)
  - not rendered unless explicitly set, so existing releases keep the Kubernetes default (host user namespace, `hostUsers: true`)
  - `hostUsers` that is not a boolean fails at render time
- fix: reject `hostUsers: false` together with `hostNetwork: true`
  - the API server forbids this combination (`spec.hostNetwork: Forbidden: when 'hostUsers' is false`), so the chart now fails at render time instead of at apply time
- fix: reject an effective `runAsNonRoot: true` with `runAsUser: 0`
  - the pod-level and container-level `securityContext` are merged the way the kubelet merges them, so a pod-level `runAsNonRoot: true` combined with a container-level `runAsUser: 0` is caught
  - the API server accepts this combination and the container then fails to start with `CreateContainerConfigError`, so the chart fails at render time instead

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
- feat: support `lifecycle` on init containers
  - Kubernetes only allows it on sidecar init containers, so `initContainers[].restartPolicy: Always` is required
- feat: support `initContainers[].restartPolicy`
  - `Always` is the only value Kubernetes accepts for init containers; anything else is rejected at render time

## 0.0.1

- feat: support initContainers
