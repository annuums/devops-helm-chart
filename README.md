# Kubernetes Helm Charts를 관리하는 Repository 입니다

## K8s의 Object에 대해 일관된 Helm charts를 관리합니다.

- 본 Repository의 Helm Chart를 수정할 경우, 반드시 test-values.yaml에 해당 내용을 갱신해 주세요.

- 기존에 없던 Kubernetes Object에 대한 Helm Chart를 만들 경우, `-chart`를 suffix로 붙여주세요.
  - 예시) Service Object 관련 차트를 만들 경우, `service-chart`가 됩니다.
  - 또한 반드시 `test-values.yaml`을 함께 제공해 주세요.
  
- 생성된 차트는 다음의 명령어를 통해 테스트 할 수 있습니다.
```shell
$ helm template <chart-name> -f <chart-name>/test-values.yaml > check.yaml
$ kubectl apply -f check.yaml --dry-run=server
```

### How to Use

- 먼저 Helm Chart를 만들어 주세요.
```shell
$ helm create <chart-name>
```

- 이후 `Chart.yaml`을 다음과 같이 수정합니다.
```yaml
apiVersion: v2
name: your-application-name
description: A Helm chart for your-application-name
type: application
version: 0.0.1 # your app version
dependencies:
  - name: base-chart-name # deployment-chart, cronjob-chart, config-chart ...
    alias: your-application-name
    version: version-of-the-base-chart # the annuums chart version
    repository: oci://registry-1.docker.io/annuums
    condition: your-application-name.enabled
```

- Helm 의존성을 갱신한 뒤, 차트를 `test-values.yaml`을 참고하여 적절히 수정, 사용합니다.
```shell
$ helm dep update
```
