# Kubernetes Helm Charts를 관리하는 Repository 입니다

## 본 Repository는 helm charts 중 일반적으로 사용하기 위한 template을 관리합니다.

- 본 Repository의 Helm Chart를 수정할 경우, 반드시 test-values.yaml에 해당 내용을 갱신해 주세요.

- 본 Base Helm Chart를 이용하여 새로운 애플리케이션 차트를 만들 경우, `-chart`를 suffix로 붙여주세요.


- 이 후 해당 차트의 동작은 다음 명령어로 확인할 수 있습니다.

  - deployment-chart를 수정한 경우

    ```shell
    $ helm template deployment-chart/ -f deployment-chart/test-values.yaml
    ---
    # Source: deployment-chart/templates/deployment.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: pigeon
      namespace: default
      labels:
        helm.sh/chart: deployment-chart-0.0.1
        app.kubernetes.io/version: 0.0.1-eks
        app.kubernetes.io/managed-by: Helm
        my-label: custom-label
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            helm.sh/chart: deployment-chart-0.0.1
            app.kubernetes.io/version: 0.0.1-eks
            app.kubernetes.io/managed-by: Helm
        spec:
          containers:
            - name: pigeon-1
              image: "first-reg/first-rep:1.0.0"
              imagePullPolicy: Never
    ```

### How to Use

#### Common

```yaml
apiVersion: v2
name: my-service-name
description: A Helm chart for my-service-name
type: application
version: 0.1.0
dependencies:
  - name: base-chart-name # deployment-chart, service-chart, ...
    alias: my-service-name
    version: latest-version-of-service-chart
    repository: oci://608767950018.dkr.ecr.ap-northeast-2.amazonaws.com
    condition: my-service-name.enabled
```

- `apiVersion`은 사용할 helm chart의 버전을 정의합니다.
- `name`은 본 차트로 배포되는 helm chart의 이름을 정의합니다.
- `description`은 본 차트를 설명합니다.
- `type`는 아래를 확인하세요. 우리는 application을 이용해 차트를 배포합니다.
  ```
  # A chart can be either an 'application' or a 'library' chart.
  #
  # Application charts are a collection of templates that can be packaged into versioned archives
  # to be deployed.
  #
  # Library charts provide useful utilities or functions for the chart developer. They're included as
  # a dependency of application charts to inject those utilities and functions into the rendering
  # pipeline. Library charts do not define any templates and therefore cannot be deployed.
  ```
- `dependencies.name`은 사용할 helm template을 정의합니다.
  - `deployment-chart`, `service-chart`
- `dependencies.alias`는 template을 통해 배포하고자 하는 차트의 이름을 정의합니다.
- `dependencies.repository`은 사용할 template의 ECR 주소를 정의합니다. 배포 스테이지에 따라 다른 값을 갖습니다.
- `dependencies.version`은 사용할 template의 버전을 정의합니다.
- `dependencies.condition`은 본 차트를 사용할 지 정의합니다.
  - 해당 값은 default values 혹은 stage.values에 정의될 수 있습니다.
