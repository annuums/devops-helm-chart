{{/*
Expand the name of the chart.
*/}}
{{- define "annuums-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "annuums-service.fullname" -}}
{{- required "A valid .Values.fullnameOverride required!" .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts
*/}}
{{- define "annuums-service.namespace" -}}
  {{- if .Values.namespaceOverride }}
    {{- .Values.namespaceOverride -}}
  {{- else }}
    {{- .Release.Namespace -}}
  {{- end }}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "annuums-service.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default appVersion.
*/}}
{{- define "annuums-service.appVersion" -}}
{{- printf "%s-%s" .Chart.Version .Values.appVersionSuffix | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "annuums-service.labels" -}}
{{- if .Values.selector }}
{{- toYaml $.Values.selector }}
{{- else }}
annuums.devops/name: {{ include "annuums-service.fullname" . }}-selector
{{- end }}
helm.sh/chart: {{ include "annuums-service.chart" . }}
app.kubernetes.io/version: {{ include "annuums-service.appVersion" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}


{{/*
Test externalTrafficPolicy for LoadBalancer, NodePort Type Only
*/}}
{{- define "annuums-service.checkExternalTrafficPolicyPassed" -}}
{{/* hasKey externalTrafficPolicy and it is not null */}}
    {{- if and (hasKey .Values "externalTrafficPolicy") (not (eq .Values.externalTrafficPolicy nil)) -}}
        {{- if not (or (eq .Values.type "NodePort") (eq .Values.type "LoadBalancer")) -}}
            {{- fail "externalTrafficPolicy can only be set when type is for external s.t. LoadBalancer or NodePort" -}}
        {{- end }}
    {{- end }}
{{- end }}

{{/*
Test clusterIP for ClusterIP Type Only
*/}}
{{- define "annuums-service.checkClusterIPPassed" -}}
{{- if eq .Values.type "ClusterIP" -}}
  {{- if hasKey .Values "clusterIP" -}}
    {{- /* valid value */ -}}
  {{- else -}}
    {{- fail "When type is ClusterIP, clusterIP must be set to a valid IP or 'None' for headless services" -}}
  {{- end -}}
{{- end -}}
{{- end }}
