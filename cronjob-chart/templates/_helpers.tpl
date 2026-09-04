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

{{/*
Render a single lifecycle handler.
Only `exec` and `sleep` are supported; `httpGet` and `tcpSocket` are not.
Input: dict "name" <container name> "hook" <postStart|preStop> "handler" <handler map>
*/}}
{{- define "annuums-cronjob.lifecycleHandler" -}}
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
{{- define "annuums-cronjob.lifecycle" -}}
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
    {{- include "annuums-cronjob.lifecycleHandler" (dict "name" $name "hook" "postStart" "handler" $lifecycle.postStart) | nindent 4 }}
  {{- end }}
  {{- if hasKey $lifecycle "preStop" }}
  preStop:
    {{- include "annuums-cronjob.lifecycleHandler" (dict "name" $name "hook" "preStop" "handler" $lifecycle.preStop) | nindent 4 }}
  {{- end }}
{{- end -}}

{{/*
Check init container restartPolicy, and that lifecycle is only set on sidecar init containers.
*/}}
{{- define "validate.initContainerLifecycle" -}}
{{- range $i, $c := .Values.initContainers }}
  {{- if and $c.restartPolicy (ne $c.restartPolicy "Always") }}
    {{- fail (printf "Error: initContainers[%d].restartPolicy=%v. Only 'Always' is allowed for init containers." $i $c.restartPolicy) -}}
  {{- end }}
  {{- if and $c.lifecycle (ne (default "" $c.restartPolicy) "Always") }}
    {{- fail (printf "Error: initContainers[%d].lifecycle is set but restartPolicy is not 'Always'. lifecycle is only allowed on sidecar init containers." $i) -}}
  {{- end }}
{{- end }}
{{- end -}}
