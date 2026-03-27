# Change Log

## 0.1.0
- fix: remove `namespace` field from GatewayClass (cluster-scoped resource)
- fix: `allowedRoutes` in Gateway listener was hardcoded to `from: Selector` — now configurable
- fix: `hostnames` in HTTPRoute/GRPCRoute now optional (rendered only when set)
- fix: `httpRoutes` and `grpcRoutes` changed from single object to list to support multiple routes per release
- feat: add `parametersRef` and `description` fields to GatewayClass
- feat: add `addresses` and `infrastructure` fields to Gateway (GA in v1.2)
- feat: add `TLSRoute` template (promoted to Standard in Gateway API v1.5)
- feat: add `ReferenceGrant` template (for cross-namespace access)
- feat: add `LoadBalancerConfiguration` template (AWS LBC custom CRD)
- feat: add `TargetGroupConfiguration` template (AWS LBC custom CRD)
- refactor: `namespace` in values.yaml → `namespaceOverride` (aligns with _helpers.tpl)

## 0.0.6
- fix: fix missing `tls` field in template

## 0.0.5
- fix: add missing `hostname` filed in listeners

## 0.0.4
- fix: fix typo in template of Gateway object
  - class name to gateway.className

## 0.0.3
- feat: add GRPCRoute Object
- fix: fix template of HttpRoute Object
  - HttpRoute -> HTTPRoute
- fix: allowedRoutes in Gateway Object
  - namespace -> namespaces
  - add selector property
- fix: fix test-values.yaml

## 0.0.2
- fix: fix template of Gateway object
  - fix name of Gateway object

## 0.0.1
- gateway-chart: has been created
