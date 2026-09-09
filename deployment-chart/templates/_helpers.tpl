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
Check if both minAvailable and maxUnavailable are set in a container's pdb.
Takes the root context so it can be included from validations.yaml like the
other validators, instead of relying on pdb.yaml passing each `.pdb` in.
*/}}
{{- define "validate.pdbAvailability" -}}
{{- range $i, $c := .Values.containers }}
  {{- if and $c.pdb $c.pdb.enabled }}
    {{- if and (not (empty $c.pdb.minAvailable)) (not (empty $c.pdb.maxUnavailable)) -}}
      {{- fail (printf "Error: containers[%d](%s).pdb has both minAvailable and maxUnavailable set. Please set only one." $i $c.name) -}}
    {{- end }}
  {{- end }}
{{- end }}
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

{{/*
Reject `hostUsers: false` together with `hostNetwork: true`.
The API server forbids a pod from joining the host network namespace while it
runs in its own user namespace.
*/}}
{{- define "validate.hostUsers" -}}
{{- if hasKey .Values "hostUsers" }}
  {{- if not (kindIs "bool" .Values.hostUsers) }}
    {{- fail (printf "Error: hostUsers must be a boolean, but got '%v'." .Values.hostUsers) -}}
  {{- end }}
  {{- if and (not .Values.hostUsers) .Values.hostNetwork }}
    {{- fail "Error: hostUsers=false cannot be combined with hostNetwork=true. A pod cannot join the host network namespace while running in its own user namespace." -}}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Check every securityContext is a map, and reject an effective (pod merged with
container) securityContext that sets `runAsNonRoot: true` together with
`runAsUser: 0`. The API server accepts that combination, but the kubelet fails
the container at start with CreateContainerConfigError.
*/}}
{{- define "validate.securityContext" -}}
{{- $pod := default dict .Values.securityContext -}}
{{- if not (kindIs "map" $pod) }}
  {{- fail (printf "Error: securityContext must be a map, but got '%v'." $pod) -}}
{{- end }}
{{- $groups := dict "initContainers" (default list .Values.initContainers) "containers" (default list .Values.containers) -}}
{{- range $path, $containers := $groups }}
  {{- range $i, $c := $containers }}
    {{- $name := default (printf "%d" $i) $c.name }}
    {{- $ctx := default dict $c.securityContext }}
    {{- if not (kindIs "map" $ctx) }}
      {{- fail (printf "Error: %s[%s].securityContext must be a map, but got '%v'." $path $name $ctx) -}}
    {{- end }}
    {{- $nonRoot := $pod.runAsNonRoot }}
    {{- if hasKey $ctx "runAsNonRoot" }}{{- $nonRoot = $ctx.runAsNonRoot }}{{- end }}
    {{- $user := $pod.runAsUser }}
    {{- if hasKey $ctx "runAsUser" }}{{- $user = $ctx.runAsUser }}{{- end }}
    {{- if and $nonRoot (not (kindIs "invalid" $user)) (not (kindIs "bool" $user)) }}
      {{- if eq (int $user) 0 }}
        {{- fail (printf "Error: %s[%s] resolves to runAsNonRoot=true with runAsUser=0. The container would fail to start." $path $name) -}}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Validate a seccompProfile block.
Input: dict "path" <values path> "seccompProfile" <seccompProfile map>
*/}}
{{- define "annuums-deployment.validateSeccompProfile" -}}
{{- $path := .path -}}
{{- $profile := .seccompProfile -}}
{{- if not (kindIs "map" $profile) -}}
  {{- fail (printf "Error: %s.seccompProfile must be a map, but got '%v'." $path $profile) -}}
{{- end -}}
{{- range $key, $_ := $profile -}}
  {{- if not (has $key (list "type" "localhostProfile")) -}}
    {{- fail (printf "Error: %s.seccompProfile.%s is not supported. Please use one of type, localhostProfile." $path $key) -}}
  {{- end -}}
{{- end -}}
{{- if not (has $profile.type (list "RuntimeDefault" "Unconfined" "Localhost")) -}}
  {{- fail (printf "Error: %s.seccompProfile.type is required and must be one of RuntimeDefault, Unconfined, Localhost." $path) -}}
{{- end -}}
{{- if eq $profile.type "Localhost" -}}
  {{- if not $profile.localhostProfile -}}
    {{- fail (printf "Error: %s.seccompProfile.localhostProfile is required when type is 'Localhost'." $path) -}}
  {{- end -}}
{{- else if hasKey $profile "localhostProfile" -}}
  {{- fail (printf "Error: %s.seccompProfile.localhostProfile is only allowed when type is 'Localhost'." $path) -}}
{{- end -}}
{{- end -}}

{{/*
Validate a capabilities block.
Input: dict "path" <values path> "capabilities" <capabilities map>
*/}}
{{- define "annuums-deployment.validateCapabilities" -}}
{{- $path := .path -}}
{{- $capabilities := .capabilities -}}
{{- if not (kindIs "map" $capabilities) -}}
  {{- fail (printf "Error: %s.capabilities must be a map, but got '%v'." $path $capabilities) -}}
{{- end -}}
{{- range $key, $value := $capabilities -}}
  {{- if not (has $key (list "add" "drop")) -}}
    {{- fail (printf "Error: %s.capabilities.%s is not supported. Please use one of add, drop." $path $key) -}}
  {{- end -}}
  {{- if not (kindIs "slice" $value) -}}
    {{- fail (printf "Error: %s.capabilities.%s must be a list, but got '%v'." $path $key $value) -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Render the pod-level securityContext block.
Only `runAsNonRoot`, `runAsUser`, `runAsGroup`, `fsGroup`, `fsGroupChangePolicy`,
`supplementalGroups` and `seccompProfile` are supported.
Input: securityContext map
*/}}
{{- define "annuums-deployment.podSecurityContext" -}}
{{- $ctx := . -}}
{{- $allowed := list "runAsNonRoot" "runAsUser" "runAsGroup" "fsGroup" "fsGroupChangePolicy" "supplementalGroups" "seccompProfile" -}}
{{- range $key, $_ := $ctx -}}
  {{- if not (has $key $allowed) -}}
    {{- fail (printf "Error: securityContext.%s is not supported. Please use one of %s." $key (join ", " $allowed)) -}}
  {{- end -}}
{{- end -}}
{{- if hasKey $ctx "fsGroupChangePolicy" -}}
  {{- if not (has $ctx.fsGroupChangePolicy (list "Always" "OnRootMismatch")) -}}
    {{- fail (printf "Error: securityContext.fsGroupChangePolicy must be one of Always, OnRootMismatch, but got '%v'." $ctx.fsGroupChangePolicy) -}}
  {{- end -}}
{{- end -}}
{{- if hasKey $ctx "supplementalGroups" -}}
  {{- if not (kindIs "slice" $ctx.supplementalGroups) -}}
    {{- fail (printf "Error: securityContext.supplementalGroups must be a list, but got '%v'." $ctx.supplementalGroups) -}}
  {{- end -}}
{{- end -}}
{{- if hasKey $ctx "seccompProfile" -}}
  {{- include "annuums-deployment.validateSeccompProfile" (dict "path" "securityContext" "seccompProfile" $ctx.seccompProfile) -}}
{{- end -}}
securityContext:
  {{- if hasKey $ctx "runAsNonRoot" }}
  runAsNonRoot: {{ $ctx.runAsNonRoot }}
  {{- end }}
  {{- if hasKey $ctx "runAsUser" }}
  runAsUser: {{ $ctx.runAsUser }}
  {{- end }}
  {{- if hasKey $ctx "runAsGroup" }}
  runAsGroup: {{ $ctx.runAsGroup }}
  {{- end }}
  {{- if hasKey $ctx "fsGroup" }}
  fsGroup: {{ $ctx.fsGroup }}
  {{- end }}
  {{- if hasKey $ctx "fsGroupChangePolicy" }}
  fsGroupChangePolicy: {{ $ctx.fsGroupChangePolicy | quote }}
  {{- end }}
  {{- if hasKey $ctx "supplementalGroups" }}
  supplementalGroups:
    {{- toYaml $ctx.supplementalGroups | nindent 4 }}
  {{- end }}
  {{- if hasKey $ctx "seccompProfile" }}
  seccompProfile:
    {{- toYaml $ctx.seccompProfile | nindent 4 }}
  {{- end }}
{{- end -}}

{{/*
Render a container-level securityContext block.
Supports `runAsNonRoot`, `runAsUser`, `runAsGroup`, `capabilities`,
`allowPrivilegeEscalation`, `seccompProfile` and `readOnlyRootFilesystem`.
Input: dict "name" <container name> "securityContext" <securityContext map>
*/}}
{{- define "annuums-deployment.containerSecurityContext" -}}
{{- $name := .name -}}
{{- $ctx := .securityContext -}}
{{- $allowed := list "runAsNonRoot" "runAsUser" "runAsGroup" "capabilities" "allowPrivilegeEscalation" "seccompProfile" "readOnlyRootFilesystem" -}}
{{- range $key, $_ := $ctx -}}
  {{- if not (has $key $allowed) -}}
    {{- fail (printf "Error: %s.securityContext.%s is not supported. Please use one of %s." $name $key (join ", " $allowed)) -}}
  {{- end -}}
{{- end -}}
{{- if hasKey $ctx "capabilities" -}}
  {{- include "annuums-deployment.validateCapabilities" (dict "path" (printf "%s.securityContext" $name) "capabilities" $ctx.capabilities) -}}
{{- end -}}
{{- if hasKey $ctx "seccompProfile" -}}
  {{- include "annuums-deployment.validateSeccompProfile" (dict "path" (printf "%s.securityContext" $name) "seccompProfile" $ctx.seccompProfile) -}}
{{- end -}}
securityContext:
  {{- if hasKey $ctx "runAsNonRoot" }}
  runAsNonRoot: {{ $ctx.runAsNonRoot }}
  {{- end }}
  {{- if hasKey $ctx "runAsUser" }}
  runAsUser: {{ $ctx.runAsUser }}
  {{- end }}
  {{- if hasKey $ctx "runAsGroup" }}
  runAsGroup: {{ $ctx.runAsGroup }}
  {{- end }}
  {{- if hasKey $ctx "allowPrivilegeEscalation" }}
  allowPrivilegeEscalation: {{ $ctx.allowPrivilegeEscalation }}
  {{- end }}
  {{- if hasKey $ctx "readOnlyRootFilesystem" }}
  readOnlyRootFilesystem: {{ $ctx.readOnlyRootFilesystem }}
  {{- end }}
  {{- if hasKey $ctx "capabilities" }}
  capabilities:
    {{- toYaml $ctx.capabilities | nindent 4 }}
  {{- end }}
  {{- if hasKey $ctx "seccompProfile" }}
  seccompProfile:
    {{- toYaml $ctx.seccompProfile | nindent 4 }}
  {{- end }}
{{- end -}}
