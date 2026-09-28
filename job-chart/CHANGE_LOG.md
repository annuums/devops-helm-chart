# Change Log

## 0.1.0

- **BREAKING**: in the flat `resources` format, a key other than `cpu`/`memory` now fails at render time instead of being silently dropped; mixing the flat format with `requests`/`limits` fails too
  - values that only use `resources.cpu` / `resources.memory` render the same as before and need no change
- feat: support Kubernetes-style `resources` (`requests` / `limits`) on `job.containers[]` and `initContainers[]`
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

## 0.0.1

- Add job-chart: Add chart for `Job` Object
  - Based on `cronjob-chart` 0.7.12; the values layout is the same, except `cronjob:` is `job:` and the CronJob-only fields (`schedule`, `timeZone`, `concurrencyPolicy`, `startingDeadlineSeconds`, `successfulJobsHistoryLimit`, `failedJobsHistoryLimit`) are gone
  - Job spec: `backoffLimit` (default `0`), `activeDeadlineSeconds` (default `600`), `ttlSecondsAfterFinished`, `completions`, `parallelism`, `completionMode`, `suspend`
    - `ttlSecondsAfterFinished`, `completions`, `parallelism`, `completionMode` and `suspend` are not rendered unless set, so the Kubernetes defaults apply
    - `restartPolicy` accepts only `Never` (default) or `OnFailure`, the two values the API server allows for a Job pod
    - a non-integer or negative counter, `activeDeadlineSeconds: 0`, an unknown `completionMode`, `completionMode: Indexed` without `completions`, a non-boolean `suspend` and an empty `job.containers` are rejected at render time
    ```yaml
    job:
      backoffLimit: 2
      activeDeadlineSeconds: 600
      ttlSecondsAfterFinished: 3600
      completions: 3
      parallelism: 2
      completionMode: Indexed # NonIndexed | Indexed
      restartPolicy: OnFailure # Never | OnFailure
    ```
  - `annotations` is set on the Job object only, `podAnnotations` on the pod
    - a Job's pod template is immutable, so to re-run the Job on every release, run it as a Helm hook via `annotations` (`helm.sh/hook`, `helm.sh/hook-delete-policy`) without the hook annotations leaking onto the pod
  - `labels` is set on the pod too (in `cronjob-chart` the pod-level custom labels were never rendered)
  - `defaultContainerSecurityContext`, `emptyDir: {}` rendering and volume source validation, the same as `deployment-chart`
  - `initContainers`, `lifecycle`, `securityContext`, `hostUsers`, `hostNetwork`, `environment`, `volumes`, `imagePullSecrets`, `nodeSelector`, `affinity`, `tolerations`, `serviceAccount` work the same as in `cronjob-chart`
