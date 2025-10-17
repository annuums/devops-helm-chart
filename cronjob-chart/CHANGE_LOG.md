# Change Log

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
