# Change Log

## 0.14.1
- feat: remove service and targetgroup binding from deployment chart

## 0.14.0
- feat: support custom selector for service

## 0.13.1
- fix: pdb template yaml error
- fix: service template indent error

## 0.13.0
- feat: support service app protocol

## 0.12.0
- feat: support pdb for pods

## 0.11.0
- feat: support aws target group binding

## 0.10.1
- fix: fix image pull secret when value is not present

## 0.10.0
- feat: add image pull secret

## 0.9.0
- Add labels for `annuums.orb/version: {{ chart-name }}-{{ chart-version }}`
  - It will helps gaining observability

## 0.8.0
- Add LifeCycle Hook
- Fix Annotation

## 0.7.9
- Fix service account annotation template
- Fix duplicates; Add `exist` property
- Fix Git Actions

## 0.7.8
- Fix annotations

## 0.7.7
- Fix tolerations value; Add quote

## 0.7.6
- Remove deprecated `serviceAccount`. Use `serviceAccountName` instead

## 0.7.5
- Fix maxReplicas in hpa

## 0.7.4
- Fix typo in hpa.yaml

## 0.7.3
- Fix namespace in hpa.yaml of Deployment Chart
- Update test-values.yaml; Include autoscaling
- Add default values for hpa.yaml

## 0.7.2
- Add default value `IfNotPresent` to `image.imagePullPolicy`
- Fix empty `env:` when `environment.envFrom` exist
  - 기존에 `envrionment.envFrom`만 있을 때, manifest에 `env:` 이렇게 빈 값이 추가됐는데, 이 버그를 고침

## 0.7.1
- Remove annotation from service when it is empty
- Add default value `false` to `env.valueFrom.secretKeyRef.optional`

## 0.7.0

- Add tcpSocket for readinessProbe and livenessProbe
- Deliver to Production

## 0.6.1

- Fix bugs;
  - Fix restartPolicy to Always
  - Fix livenessProbe and readinessProbe

## 0.6.0

- Add restart policy

## 0.5.0

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

## 0.4.1

- Fix container port

## 0.4.0

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

## 0.3.0

- Add annotations and labels in pod level

## 0.2.0

- Add Persistent Volume Claim to Volume Property

## 0.1.0

- Add command and args

## 0.0.8

- Fix service account

## 0.0.7

- Fix deployment-chart:
  - Fix typo in `service-account.yaml`: Service의 name 오류를 고칩니다.
  - Remove tcpGet in readinessProbe and livenessProbe
  - Fix nodeAffinity.matchExpressions to array
  - Fix `service.yaml`: Port에 이름을 설정합니다.

## 0.0.6

- Fix deployment-chart: Fix `app.kubernetes.io/version` label to have chart version

## 0.0.5

- Fix deployment-chart: Remove appVersion property

## 0.0.4

- Fix deployment-chart: remove sa from default value

## 0.0.3

- Fix deployment-chart: add selector

## 0.0.2

- deployment-chart
  - deployment template
    - Add containers
    - Add ports
    - Add resources
    - Add affinity and nodeSelector
    - Add toleration
    - Add volumes
    - Add service account
    - Add readiness and liveness probes
  - Add service account template
  - Add service template
- Fix git actions ci/cd

## 0.0.1

- deployment-chart: has been created
