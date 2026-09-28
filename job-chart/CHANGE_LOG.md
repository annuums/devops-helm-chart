# Change Log

## 0.0.0

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
