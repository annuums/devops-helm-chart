{{/*
Expand the name of the chart.
*/}}
{{- define "annuums-deployment.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "annuums-deployment.fullname" -}}
{{- required "A valid .Values.fullnameOverride required!" .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts
*/}}
{{- define "annuums-deployment.namespace" -}}
  {{- if .Values.namespaceOverride }}
    {{- .Values.namespaceOverride -}}
  {{- else }}
    {{- .Release.Namespace -}}
  {{- end }}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "annuums-deployment.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default appVersion.
*/}}
{{- define "annuums-deployment.appVersion" -}}
{{- printf "%s-%s" .Chart.Version .Values.appVersionSuffix | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "annuums-deployment.labels" -}}
{{- if .Values.serviceSelector }}
{{- toYaml $.Values.serviceSelector }}
{{- else }}
annuums.devops/name: {{ include "annuums-deployment.fullname" . }}-selector
{{- end }}
helm.sh/chart: {{ include "annuums-deployment.chart" . }}
app.kubernetes.io/version: {{ include "annuums-deployment.appVersion" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Check if both minAvailable and maxUnavailable are set.
*/}}
{{- define "validate.pdbAvailability" -}}
  {{- if and (not (empty .minAvailable)) (not (empty .maxUnavailable)) -}}
    {{- fail "Error: Both minAvailable and maxUnavailable are set in PodDisruptionBudget. Please set only one." -}}
  {{- end -}}
{{- end -}}

{{/*
Check if hostNetwork is set to true and hostPort is defined in any container.
*/}}
{{- define "validate.hostNetworkAndHostPort" -}}
  {{- if .Values.hostNetwork }}
  {{- range $i, $c := .Values.containers }}
    {{- range $j, $p := $c.ports }}
      {{- if $p.hostPort }}
        {{- fail (printf "Error: hostNetwork=true and containers[%d].ports[%d].hostPort=%v. This configuration is not allowed." $i $j $p.hostPort) -}}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Check if rollingUpdate maxSurge and maxUnavailable both 0
*/}}
{{- define "validate.rollingUpdateStrategy" -}}
{{- if .Values.strategy.rollingUpdate }}
  {{- if and (.Values.strategy.rollingUpdate.maxSurge | toString | eq "0") (.Values.strategy.rollingUpdate.maxUnavailable | toString | eq "0") }}
    {{- fail (printf "Error: .strategy.rollingUpdate.maxSurge .Values.strategy.rollingUpdate.maxUnavailable cannot be zero at the same time.") }}
  {{- end }}
{{- end -}}
{{- end -}}

{{/*
Check if hpa and keda is defined together
*/}}
{{- define "validate.autoscaling" -}}
{{- $hasAutoscaling := and (hasKey .Values "autoscaling") (kindIs "map" .Values.autoscaling) -}}
{{- $hasHpa := and $hasAutoscaling (hasKey .Values.autoscaling "hpa") (gt (len .Values.autoscaling.hpa) 0) -}}
{{- $hasKeda := and $hasAutoscaling (hasKey .Values.autoscaling "keda") (gt (len .Values.autoscaling.keda) 0) -}}
{{- if and $hasHpa $hasKeda -}}
  {{- fail "Error: .autoscaling.hpa and .autoscaling.keda cannot be defined together" -}}
{{- end -}}
{{- end -}}
