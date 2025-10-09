{{/*
Expand the name of the chart.
*/}}
{{- define "annuums-cronjob.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "annuums-cronjob.fullname" -}}
{{- required "A valid .Values.fullnameOverride required!" .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Allow the release namespace to be overridden for multi-namespace cronjobs in combined charts
*/}}
{{- define "annuums-cronjob.namespace" -}}
  {{- if .Values.namespaceOverride }}
    {{- .Values.namespaceOverride -}}
  {{- else }}
    {{- .Release.Namespace -}}
  {{- end }}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "annuums-cronjob.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default appVersion.
*/}}
{{- define "annuums-cronjob.appVersion" -}}
{{- printf "%s-%s" .Chart.Version .Values.appVersionSuffix | trimSuffix "-" -}}
{{- end -}}

{{/*
Containers in cronjob must have unique names.
This helper checks if there are multiple containers defined with the same name.
*/}}
{{- define "cronjob.checkUniqueContainerNames" -}}
{{- with .Values.cronjob.containers }}
  {{- $seen := dict -}}
  {{- $dupes := list -}}
  {{- range . }}
    {{- $name := required "cronjob.containers[].name is required" .name -}}
    {{- if hasKey $seen $name -}}
      {{- $dupes = mustAppend $dupes $name -}}
    {{- else -}}
      {{- $_ := set $seen $name true -}}
    {{- end -}}
  {{- end -}}
  {{- if gt (len $dupes) 0 -}}
    {{- fail (printf "Duplicate container names in .Values.cronjob.containers: %s" (join ", " $dupes)) -}}
  {{- end -}}
{{- end }}
{{- end }}
*/}}

{{/*
Common labels
*/}}
{{- define "annuums-cronjob.labels" -}}
annuums.devops/name: {{ include "annuums-cronjob.fullname" . }}-selector
helm.sh/chart: {{ include "annuums-cronjob.chart" . }}
app.kubernetes.io/version: {{ include "annuums-cronjob.appVersion" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
