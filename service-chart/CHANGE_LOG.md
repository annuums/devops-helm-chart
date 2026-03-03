# Change Log

## 0.1.1
- fix: remove default values for service object
  - remove: `spec.clusterIP` for validation

## 0.1.0
- feat: add several config options for service object
  - add: `spec.clusterIP`
  - add: `spec.internalTrafficPolicy`
  - add: `spec.externalTrafficPolicy`
  - add: `spec.sessionAffinity`
  - add: `spec.Type`

## 0.0.3
- fix: remove default values

## 0.0.2
- fix: remove labels

## 0.0.1
- feat: separate service chart from deployment-chart
