{{/*
Expand the name of the chart.
*/}}
{{- define "annuums-tgb.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "annuums-tgb.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "annuums-tgb.fullname" -}}
{{- required "A valid .Values.fullnameOverride required!" .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Allow the release namespace to be overridden for multi-namespace tgb in combined charts
*/}}
{{- define "annuums-tgb.namespace" -}}
  {{- if .Values.namespaceOverride }}
    {{- .Values.namespaceOverride -}}
  {{- else }}
    {{- .Release.Namespace -}}
  {{- end }}
{{- end -}}

{{/*
Create a default appVersion.
*/}}
{{- define "annuums-tgb.appVersion" -}}
{{- printf "%s-%s" .Chart.Version .Values.appVersionSuffix | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "annuums-tgb.labels" -}}
helm.sh/chart: {{ include "annuums-tgb.chart" . }}
app.kubernetes.io/version: {{ include "annuums-tgb.appVersion" . }}
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
