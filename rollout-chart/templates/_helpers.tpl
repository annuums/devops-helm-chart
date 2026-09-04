{{/*
Expand the name of the chart.
*/}}
{{- define "annuums-rollout.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "annuums-rollout.fullname" -}}
{{- required "A valid .Values.fullnameOverride required!" .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts
*/}}
{{- define "annuums-rollout.namespace" -}}
  {{- if .Values.namespaceOverride }}
    {{- .Values.namespaceOverride -}}
  {{- else }}
    {{- .Release.Namespace -}}
  {{- end }}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "annuums-rollout.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default appVersion.
*/}}
{{- define "annuums-rollout.appVersion" -}}
{{- printf "%s-%s" .Chart.Version .Values.appVersionSuffix | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "annuums-rollout.labels" -}}
{{- if .Values.serviceSelector }}
{{- toYaml $.Values.serviceSelector }}
{{- else }}
annuums.devops/name: {{ include "annuums-rollout.fullname" . }}-selector
{{- end }}
helm.sh/chart: {{ include "annuums-rollout.chart" . }}
app.kubernetes.io/version: {{ include "annuums-rollout.appVersion" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
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

{{/*
Validate strategy type: must be canary or blueGreen
*/}}
{{- define "validate.rolloutStrategy" -}}
{{- $type := .Values.strategy.type -}}
{{- if not (or (eq $type "canary") (eq $type "blueGreen")) -}}
  {{- fail (printf "Error: .strategy.type must be 'canary' or 'blueGreen', got '%s'" $type) -}}
{{- end -}}
{{- end -}}

{{/*
Validate blueGreen requires activeService
*/}}
{{- define "validate.blueGreenActiveService" -}}
{{- if eq .Values.strategy.type "blueGreen" -}}
  {{- if not .Values.strategy.blueGreen.activeService -}}
    {{- fail "Error: .strategy.blueGreen.activeService is required when strategy.type is 'blueGreen'" -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Validate canary trafficRouting requires canaryService and stableService
*/}}
{{- define "validate.canaryTrafficRouting" -}}
{{- if eq .Values.strategy.type "canary" -}}
  {{- if .Values.strategy.canary.trafficRouting -}}
    {{- if not .Values.strategy.canary.canaryService -}}
      {{- fail "Error: .strategy.canary.canaryService is required when .strategy.canary.trafficRouting is set" -}}
    {{- end -}}
    {{- if not .Values.strategy.canary.stableService -}}
      {{- fail "Error: .strategy.canary.stableService is required when .strategy.canary.trafficRouting is set" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Render a single lifecycle handler.
Only `exec` is supported; `httpGet` and `tcpSocket` are not.
Input: dict "name" <container name> "hook" <postStart|preStop> "handler" <handler map>
*/}}
{{- define "annuums-rollout.lifecycleHandler" -}}
{{- $name := .name -}}
{{- $hook := .hook -}}
{{- $handler := default dict .handler -}}
{{- if hasKey $handler "exec" -}}
{{- $exec := default dict $handler.exec -}}
{{- if not $exec.command -}}
  {{- fail (printf "Error: %s.lifecycle.%s.exec.command is required." $name $hook) -}}
{{- end -}}
exec:
  command:
    {{- toYaml $exec.command | nindent 4 }}
{{- else -}}
  {{- fail (printf "Error: %s.lifecycle.%s must set 'exec'." $name $hook) -}}
{{- end -}}
{{- end -}}

{{/*
Render the lifecycle block of a container.
Input: dict "name" <container name> "lifecycle" <lifecycle map>
*/}}
{{- define "annuums-rollout.lifecycle" -}}
{{- $name := .name -}}
{{- $lifecycle := .lifecycle -}}
{{- range $hook, $_ := $lifecycle -}}
  {{- if not (has $hook (list "postStart" "preStop")) -}}
    {{- fail (printf "Error: %s.lifecycle.%s is not a supported hook. Please use 'postStart' or 'preStop'." $name $hook) -}}
  {{- end -}}
{{- end -}}
lifecycle:
  {{- if hasKey $lifecycle "postStart" }}
  postStart:
    {{- include "annuums-rollout.lifecycleHandler" (dict "name" $name "hook" "postStart" "handler" $lifecycle.postStart) | nindent 4 }}
  {{- end }}
  {{- if hasKey $lifecycle "preStop" }}
  preStop:
    {{- include "annuums-rollout.lifecycleHandler" (dict "name" $name "hook" "preStop" "handler" $lifecycle.preStop) | nindent 4 }}
  {{- end }}
{{- end -}}
