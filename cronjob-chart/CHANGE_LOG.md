# Change Log

## 0.8.0

- **BREAKING**: in the flat `resources` format, a key other than `cpu`/`memory` now fails at render time instead of being silently dropped; mixing the flat format with `requests`/`limits` fails too
  - values that only use `resources.cpu` / `resources.memory` render the same as before and need no change
- feat: support Kubernetes-style `resources` (`requests` / `limits`) on `cronjob.containers[]` and `initContainers[]`
  - `requests` and `limits` are set independently and only what is set is rendered, so a container can set requests without limits, or give `limits` higher values than `requests`
  - any resource name Kubernetes accepts is supported: `cpu`, `memory`, `ephemeral-storage`, `hugepages-<size>`, and fully qualified extended resources such as `nvidia.com/gpu`
  - a resource set in `limits` but not in `requests` gets a request equal to the limit (Kubernetes default behavior)
  - an unknown resource name (e.g. a misspelled `ephemeral-storage`), a non-map `requests`/`limits` and a value that is not a quantity fail at render time
  ```yaml
  resources:
    requests:
      cpu: 250m
      memory: 256Mi
      ephemeral-storage: 1Gi
    limits:
      memory: 512Mi
      ephemeral-storage: 2Gi
  ```
- the flat format (`resources.cpu`, `resources.memory`, applied to both requests and limits) still works and renders the same as before
- unchanged: with no `resources`, the chart default (`250m` CPU / `128Mi` memory for both requests and limits) is used

## 0.7.13

- fix: render custom `labels` on the job pod template
  - the pod template read `.labels` at the root context, which is always empty, so `labels` only reached the CronJob and ServiceAccount; it now reaches the pod as well
- fix: render a numeric image tag correctly
  - `image.tag: 1` rendered as `image: "repo:%!s(int64=1)"`; the tag is now formatted with `%v`
  - YAML still parses an unquoted tag as a number, so `tag: 1.10` becomes `1.1`. Quote tags that have a trailing zero
- fix: skip the `# <cronjob.name>-<index>` comment on containers when `cronjob.name` is unset
  - it rendered as `# %!s(<nil>)-0`
- chore: remove a stray `*/}}` in `_helpers.tpl`

## 0.7.12

- feat: support `securityContext`
  - Pod-level (`cronjob.securityContext`): `runAsNonRoot`, `runAsUser`, `runAsGroup`, `fsGroup`, `fsGroupChangePolicy`, `supplementalGroups`, `seccompProfile`
  - Container-level (`cronjob.containers[].securityContext`, `initContainers[].securityContext`): `runAsNonRoot`, `runAsUser`, `runAsGroup`, `capabilities`, `allowPrivilegeEscalation`, `seccompProfile`, `readOnlyRootFilesystem`
  - an unsupported key is rejected at render time with a clear error message
  - `capabilities` and `seccompProfile` are validated too, not just passed through: unknown sub-keys, a non-list `add`/`drop`, an invalid `seccompProfile.type`, and a `localhostProfile` that does not match the type all fail at render time
  - `securityContext` that is not a map fails with a chart error instead of a raw template error
- feat: support `hostUsers` (Pod spec, `cronjob.hostUsers`)
  - not rendered unless explicitly set, so existing releases keep the Kubernetes default (host user namespace, `hostUsers: true`)
  - `hostUsers` that is not a boolean fails at render time
- fix: reject `cronjob.hostUsers: false` together with `cronjob.hostNetwork: true`
  - the API server forbids this combination (`spec.hostNetwork: Forbidden: when 'hostUsers' is false`), so the chart now fails at render time instead of at apply time
- fix: reject an effective `runAsNonRoot: true` with `runAsUser: 0`
  - the pod-level and container-level `securityContext` are merged the way the kubelet merges them, so a pod-level `runAsNonRoot: true` combined with a container-level `runAsUser: 0` is caught
  - the API server accepts this combination and the container then fails to start with `CreateContainerConfigError`, so the chart fails at render time instead

## 0.7.11

- feat: support `lifecycle` on job containers
  - `exec` and `sleep` handlers, `postStart` and `preStop` hooks
  - `sleep` runs in the kubelet, so the image needs no shell and no `sleep` binary (works on distroless/scratch); requires Kubernetes 1.30+, or 1.29 with the `PodLifecycleSleepAction` feature gate
  - note: `preStop` does not run when a job container exits on its own. It fires only when the kubelet terminates the pod (eviction, node drain, `activeDeadlineSeconds`, deletion)
  - an unsupported handler (`httpGet`, `tcpSocket`), a missing handler, `exec` without `command`, `sleep` without `seconds` and a misspelled hook name are rejected at render time
- feat: support `lifecycle` on init containers
  - Kubernetes only allows it on sidecar init containers, so `initContainers[].restartPolicy: Always` is required
- feat: support `initContainers[].restartPolicy`
  - `Always` is the only value Kubernetes accepts for init containers; anything else is rejected at render time

## 0.7.10
- feat: support `timeZone`, `concurrencyPolicy`, `startingDeadlineSeconds`
  - Example:
    ```yaml
    cronjob:
      timeZone: "Asia/Seoul"
      concurrencyPolicy: Forbid # Allow | Forbid | Replace
      startingDeadlineSeconds: 60
    ```

## 0.7.9

- feat: support initContainers

## 0.7.8
- fix: cronjob chart service account template referencing wrong chart

## 0.7.7
- fix: add missing labels to service account

## 0.7.6
- fix: prevent empty annotations from being rendered in templates

## 0.7.5
- fix: set common annotations for pod and cronjob object

## 0.7.4
- fix: remove duplicates in pod's labels and annotations
  - remove annotations in pod level
- feat: add hostNetwork options

## 0.7.3
- feat: add cronjob.checkUniqueContainerNames helperNames
  - If you have multiple containers in a pod, you need to set unique names for each container.
  - This property will help you to set unique names for each container.

## 0.7.2
- fix: remove image pull secrets when it is nil

## 0.7.1
- fix: fix affinity syntax as native kubernetes syntax

## 0.7.0
- feat: support persistent volume claim
  - Add `persistentVolumeClaim` property to `cronjob.spec.template.spec`
  - Example:
    ```yaml
    persistentVolumeClaim:
      name: my-pvc
      mountPath: /data
    ```

## 0.6.1
- chore: trigger for docker public hub

## 0.6.0
- feat: add image pull secret

## 0.5.0
- Add labels for `annuums.orb/version: {{ chart-name }}-{{ chart-version }}`
  - It will helps gaining observability

## 0.4.4
- Fix service account annotation template
- Fix duplicates; Add `exist` property
- Fix Git Actions
- Build

## 0.4.3
- Fix labels for loki

## 0.4.2
- Fix tolerations value; Add quote

## 0.4.1
- Add default value `IfNotPresent` to `image.imagePullPolicy`
- Fix empty `env:` when `environment.envFrom` exist
  - 기존에 `envrionment.envFrom`만 있을 때, manifest에 `env:` 이렇게 빈 값이 추가됐는데, 이 버그를 고침

## 0.4.0
- Add `backoffLimit` property default to 0
```yaml
cronjob:
  name: pigeon-cron-job
  schedule: "* * * * *"
  backoffLimit: 0 # Added
```
## 0.3.0

- Add envFrom property

```yaml
environment:
  envFrom:
    - type: configmap
      configMapRefName: special-config-name
    - type: configmap
      configMapRefName: another-config-name
    - type: secret
      secretRefName: secret-name
    - type: secret
      secretRefName: another-secret-name
```

- Deliver to Production

## 0.2.0

- Add environment variable property

  - `env`: 직접적으로 env를 할당
  - `configmap`: configmap으로 부터 env를 할당

    - 예시

    ```yaml
    environment:
      configmap:
        - name: env-name
          ref:
            name: configmap-name
            key: configmap-key
    ```

    - 예시 결과

    ```yaml
    env:
      - name: env-from-cm
        valueFrom:
          configMapKeyRef:
            name: configmap-name
            key: configmap-key
    ```

  - `secret`: secret으로 부터 env를 할당

    - 예시

    ```yaml
    environment:
      secret:
        - name: env-name
          ref:
            name: secret-name
            key: secret-key
            optional: false
    ```

    - 예시 결과

    ```yaml
    env:
      - name: env-name
        valueFrom:
          secretKeyRef:
            name: secret-name
            key: secret-key
            optional: false
    ```

## 0.1.0

- Add annotations and labels in pod level

## 0.0.2

- Fix service account

## 0.0.1

- Add cronjob-chart: Add chart for `CronJob` Object
