# Change Log

## 0.0.5

- fix: `volumes[].emptyDir` was skipped when it had no `sizeLimit`
  - the template tested `{{- if .emptyDir }}`, and an empty map is falsy in Go templates, so `emptyDir: {}` rendered a volume with no source at all and the API server rejected the manifest with `must specify a volume type`
  - the source is now detected by presence, so `emptyDir: {}` renders as `emptyDir: {}`. This unblocks `readOnlyRootFilesystem: true`, which almost always needs a bare `/tmp` emptyDir
- feat: support `volumes[].emptyDir.medium` (`""` or `Memory`)
  - `sizeLimit` and `medium` are both optional and independent; an unsupported key or an invalid `medium` fails at render time
- feat: reject a volume that declares no source, or more than one
  - a volume with no source used to render as a bare `- name: <name>` and fail at apply time
- feat: support `defaultContainerSecurityContext`
  - a container-level `securityContext` applied to every entry in `containers` and `initContainers`, set once at the top level of values
  - Helm replaces lists instead of merging them, so a default for `containers[].securityContext` cannot live in `containers[]`; without this key the same block has to be repeated in every container of every env values file
  - a container's own `securityContext` overrides the default per top-level key, so a container that sets `capabilities` replaces the default `capabilities` whole
  - accepts the same keys as `containers[].securityContext` and is validated the same way, even when no container is defined
  - `validate.securityContext` resolves it as part of the effective securityContext, so a default `runAsNonRoot: true` combined with a container `runAsUser: 0` is still caught

## 0.0.4

- fix: add the missing `validate.pdbAvailability` validator (it was never carried over from deployment-chart, so a container setting both `pdb.minAvailable` and `pdb.maxUnavailable` rendered two overlapping PodDisruptionBudgets instead of failing)
- fix: `containers[].pdb` treated `0` as unset, so `maxUnavailable: 0` (block all voluntary evictions) and `minAvailable: 0` silently rendered no PodDisruptionBudget. Both fields are now detected by presence instead of truthiness, so `0` renders; an explicitly empty value (`maxUnavailable:`) still counts as unset

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
