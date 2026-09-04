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

{{/*
Render a single lifecycle handler.
Only `exec` and `sleep` are supported; `httpGet` and `tcpSocket` are not.
Input: dict "name" <container name> "hook" <postStart|preStop> "handler" <handler map>
*/}}
{{- define "annuums-deployment.lifecycleHandler" -}}
{{- $name := .name -}}
{{- $hook := .hook -}}
{{- $handler := default dict .handler -}}
{{- if and (hasKey $handler "exec") (hasKey $handler "sleep") -}}
  {{- fail (printf "Error: %s.lifecycle.%s has both 'exec' and 'sleep' set. Please set only one." $name $hook) -}}
{{- end -}}
{{- if hasKey $handler "exec" -}}
{{- $exec := default dict $handler.exec -}}
{{- if not $exec.command -}}
  {{- fail (printf "Error: %s.lifecycle.%s.exec.command is required." $name $hook) -}}
{{- end -}}
exec:
  command:
    {{- toYaml $exec.command | nindent 4 }}
{{- else if hasKey $handler "sleep" -}}
{{- $sleep := default dict $handler.sleep -}}
{{- if not $sleep.seconds -}}
  {{- fail (printf "Error: %s.lifecycle.%s.sleep.seconds is required and must be greater than 0." $name $hook) -}}
{{- end -}}
sleep:
  seconds: {{ int $sleep.seconds }}
{{- else -}}
  {{- fail (printf "Error: %s.lifecycle.%s must set one of 'exec' or 'sleep'." $name $hook) -}}
{{- end -}}
{{- end -}}

{{/*
Render the lifecycle block of a container.
Input: dict "name" <container name> "lifecycle" <lifecycle map>
*/}}
{{- define "annuums-deployment.lifecycle" -}}
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
    {{- include "annuums-deployment.lifecycleHandler" (dict "name" $name "hook" "postStart" "handler" $lifecycle.postStart) | nindent 4 }}
  {{- end }}
  {{- if hasKey $lifecycle "preStop" }}
  preStop:
    {{- include "annuums-deployment.lifecycleHandler" (dict "name" $name "hook" "preStop" "handler" $lifecycle.preStop) | nindent 4 }}
  {{- end }}
{{- end -}}
