{{/*
Expand the name of the chart.
*/}}
{{- define "annuums-gateway.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "annuums-gateway.fullname" -}}
{{- required "A valid .Values.fullnameOverride required!" .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Allow the release namespace to be overridden for multi-namespace gateways in combined charts
*/}}
{{- define "annuums-gateway.namespace" -}}
  {{- if .Values.namespaceOverride }}
    {{- .Values.namespaceOverride -}}
  {{- else }}
    {{- .Release.Namespace -}}
  {{- end }}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "annuums-gateway.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default appVersion.
*/}}
{{- define "annuums-gateway.appVersion" -}}
{{- printf "%s-%s" .Chart.Version .Values.appVersionSuffix | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "annuums-gateway.labels" -}}
annuums.devops/name: {{ include "annuums-gateway.fullname" . }}-selector
helm.sh/chart: {{ include "annuums-gateway.chart" . }}
app.kubernetes.io/version: {{ include "annuums-gateway.appVersion" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
