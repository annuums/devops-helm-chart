{{/*
Expand the name of the chart.
*/}}
{{- define "annuums-job.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "annuums-job.fullname" -}}
{{- required "A valid .Values.fullnameOverride required!" .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Allow the release namespace to be overridden for multi-namespace jobs in combined charts
*/}}
{{- define "annuums-job.namespace" -}}
  {{- if .Values.namespaceOverride }}
    {{- .Values.namespaceOverride -}}
  {{- else }}
    {{- .Release.Namespace -}}
  {{- end }}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "annuums-job.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default appVersion.
*/}}
{{- define "annuums-job.appVersion" -}}
{{- printf "%s-%s" .Chart.Version .Values.appVersionSuffix | trimSuffix "-" -}}
{{- end -}}

{{/*
Containers in job must have unique names.
This helper checks if there are multiple containers defined with the same name.
*/}}
{{- define "job.checkUniqueContainerNames" -}}
{{- with .Values.job.containers }}
  {{- $seen := dict -}}
  {{- $dupes := list -}}
  {{- range . }}
    {{- $name := required "job.containers[].name is required" .name -}}
    {{- if hasKey $seen $name -}}
      {{- $dupes = mustAppend $dupes $name -}}
    {{- else -}}
      {{- $_ := set $seen $name true -}}
    {{- end -}}
  {{- end -}}
  {{- if gt (len $dupes) 0 -}}
    {{- fail (printf "Duplicate container names in .Values.job.containers: %s" (join ", " $dupes)) -}}
  {{- end -}}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "annuums-job.labels" -}}
annuums.devops/name: {{ include "annuums-job.fullname" . }}-selector
helm.sh/chart: {{ include "annuums-job.chart" . }}
app.kubernetes.io/version: {{ include "annuums-job.appVersion" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Render a single lifecycle handler.
Only `exec` and `sleep` are supported; `httpGet` and `tcpSocket` are not.
Input: dict "name" <container name> "hook" <postStart|preStop> "handler" <handler map>
*/}}
{{- define "annuums-job.lifecycleHandler" -}}
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
{{- define "annuums-job.lifecycle" -}}
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
    {{- include "annuums-job.lifecycleHandler" (dict "name" $name "hook" "postStart" "handler" $lifecycle.postStart) | nindent 4 }}
  {{- end }}
  {{- if hasKey $lifecycle "preStop" }}
  preStop:
    {{- include "annuums-job.lifecycleHandler" (dict "name" $name "hook" "preStop" "handler" $lifecycle.preStop) | nindent 4 }}
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
{{- if hasKey .Values.job "hostUsers" }}
  {{- if not (kindIs "bool" .Values.job.hostUsers) }}
    {{- fail (printf "Error: job.hostUsers must be a boolean, but got '%v'." .Values.job.hostUsers) -}}
  {{- end }}
  {{- if and (not .Values.job.hostUsers) .Values.job.hostNetwork }}
    {{- fail "Error: job.hostUsers=false cannot be combined with job.hostNetwork=true. A pod cannot join the host network namespace while running in its own user namespace." -}}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Check every securityContext is a map, and reject an effective (pod merged with
`defaultContainerSecurityContext` merged with container) securityContext that
sets `runAsNonRoot: true` together with `runAsUser: 0`. The API server accepts
that combination, but the kubelet fails the container at start with
CreateContainerConfigError.
*/}}
{{- define "validate.securityContext" -}}
{{- $pod := default dict .Values.job.securityContext -}}
{{- if not (kindIs "map" $pod) }}
  {{- fail (printf "Error: job.securityContext must be a map, but got '%v'." $pod) -}}
{{- end }}
{{- $default := default dict .Values.defaultContainerSecurityContext -}}
{{- if not (kindIs "map" $default) }}
  {{- fail (printf "Error: defaultContainerSecurityContext must be a map, but got '%v'." $default) -}}
{{- end }}
{{- if $default }}
  {{- /* Render it once so an unsupported key is rejected even with no containers defined. */}}
  {{- $_ := include "annuums-job.containerSecurityContext" (dict "path" "defaultContainerSecurityContext" "securityContext" $default) }}
{{- end }}
{{- $groups := dict "initContainers" (default list .Values.initContainers) "job.containers" (default list .Values.job.containers) -}}
{{- range $path, $containers := $groups }}
  {{- range $i, $c := $containers }}
    {{- $name := default (printf "%d" $i) $c.name }}
    {{- $ctx := default dict $c.securityContext }}
    {{- if not (kindIs "map" $ctx) }}
      {{- fail (printf "Error: %s[%s].securityContext must be a map, but got '%v'." $path $name $ctx) -}}
    {{- end }}
    {{- $nonRoot := $pod.runAsNonRoot }}
    {{- if hasKey $default "runAsNonRoot" }}{{- $nonRoot = $default.runAsNonRoot }}{{- end }}
    {{- if hasKey $ctx "runAsNonRoot" }}{{- $nonRoot = $ctx.runAsNonRoot }}{{- end }}
    {{- $user := $pod.runAsUser }}
    {{- if hasKey $default "runAsUser" }}{{- $user = $default.runAsUser }}{{- end }}
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
{{- define "annuums-job.validateSeccompProfile" -}}
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
{{- define "annuums-job.validateCapabilities" -}}
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
{{- define "annuums-job.podSecurityContext" -}}
{{- $ctx := . -}}
{{- $allowed := list "runAsNonRoot" "runAsUser" "runAsGroup" "fsGroup" "fsGroupChangePolicy" "supplementalGroups" "seccompProfile" -}}
{{- range $key, $_ := $ctx -}}
  {{- if not (has $key $allowed) -}}
    {{- fail (printf "Error: job.securityContext.%s is not supported. Please use one of %s." $key (join ", " $allowed)) -}}
  {{- end -}}
{{- end -}}
{{- if hasKey $ctx "fsGroupChangePolicy" -}}
  {{- if not (has $ctx.fsGroupChangePolicy (list "Always" "OnRootMismatch")) -}}
    {{- fail (printf "Error: job.securityContext.fsGroupChangePolicy must be one of Always, OnRootMismatch, but got '%v'." $ctx.fsGroupChangePolicy) -}}
  {{- end -}}
{{- end -}}
{{- if hasKey $ctx "supplementalGroups" -}}
  {{- if not (kindIs "slice" $ctx.supplementalGroups) -}}
    {{- fail (printf "Error: job.securityContext.supplementalGroups must be a list, but got '%v'." $ctx.supplementalGroups) -}}
  {{- end -}}
{{- end -}}
{{- if hasKey $ctx "seccompProfile" -}}
  {{- include "annuums-job.validateSeccompProfile" (dict "path" "job.securityContext" "seccompProfile" $ctx.seccompProfile) -}}
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
`path` overrides the values path used in error messages; it defaults to
`<name>.securityContext`.
Input: dict "name" <container name> "securityContext" <securityContext map> ["path" <values path>]
*/}}
{{- define "annuums-job.containerSecurityContext" -}}
{{- $ctx := .securityContext -}}
{{- $path := default (printf "%s.securityContext" .name) .path -}}
{{- $allowed := list "runAsNonRoot" "runAsUser" "runAsGroup" "capabilities" "allowPrivilegeEscalation" "seccompProfile" "readOnlyRootFilesystem" -}}
{{- range $key, $_ := $ctx -}}
  {{- if not (has $key $allowed) -}}
    {{- fail (printf "Error: %s.%s is not supported. Please use one of %s." $path $key (join ", " $allowed)) -}}
  {{- end -}}
{{- end -}}
{{- if hasKey $ctx "capabilities" -}}
  {{- include "annuums-job.validateCapabilities" (dict "path" $path "capabilities" $ctx.capabilities) -}}
{{- end -}}
{{- if hasKey $ctx "seccompProfile" -}}
  {{- include "annuums-job.validateSeccompProfile" (dict "path" $path "seccompProfile" $ctx.seccompProfile) -}}
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

{{/*
Merge `defaultContainerSecurityContext` with a container's own `securityContext`
and render the result. The merge is per top-level key and the container wins, so
a container that sets `capabilities` replaces the default `capabilities` whole
instead of merging into it.
Returns an empty string when neither side sets anything.
Input: dict "name" <container name> "default" <defaultContainerSecurityContext map> "securityContext" <securityContext map>
*/}}
{{- define "annuums-job.effectiveContainerSecurityContext" -}}
{{- $name := .name -}}
{{- $effective := dict -}}
{{- range $key, $value := (default dict .default) -}}
  {{- $_ := set $effective $key $value -}}
{{- end -}}
{{- range $key, $value := (default dict .securityContext) -}}
  {{- $_ := set $effective $key $value -}}
{{- end -}}
{{- if $effective -}}
{{- include "annuums-job.containerSecurityContext" (dict "name" $name "securityContext" $effective) -}}
{{- end -}}
{{- end -}}

{{/*
Render the emptyDir source of a volume.
Presence-based, not truthiness-based: `emptyDir: {}` is a complete and valid
source, so it must render as `emptyDir: {}` rather than be skipped and leave the
volume without a source.
Input: dict "name" <volume name> "emptyDir" <emptyDir map>
*/}}
{{- define "annuums-job.emptyDirVolume" -}}
{{- $name := .name -}}
{{- $emptyDir := default dict .emptyDir -}}
{{- if not (kindIs "map" $emptyDir) -}}
  {{- fail (printf "Error: volumes[%s].emptyDir must be a map, but got '%v'." $name $emptyDir) -}}
{{- end -}}
{{- range $key, $_ := $emptyDir -}}
  {{- if not (has $key (list "medium" "sizeLimit")) -}}
    {{- fail (printf "Error: volumes[%s].emptyDir.%s is not supported. Please use one of medium, sizeLimit." $name $key) -}}
  {{- end -}}
{{- end -}}
{{- $hasMedium := and (hasKey $emptyDir "medium") (not (kindIs "invalid" $emptyDir.medium)) -}}
{{- $hasSizeLimit := and (hasKey $emptyDir "sizeLimit") (not (kindIs "invalid" $emptyDir.sizeLimit)) -}}
{{- if $hasMedium -}}
  {{- if not (has $emptyDir.medium (list "" "Memory")) -}}
    {{- fail (printf "Error: volumes[%s].emptyDir.medium must be one of \"\", Memory, but got '%v'." $name $emptyDir.medium) -}}
  {{- end -}}
{{- end -}}
{{- if not (or $hasMedium $hasSizeLimit) -}}
emptyDir: {}
{{- else -}}
emptyDir:
  {{- if $hasMedium }}
  medium: {{ $emptyDir.medium | quote }}
  {{- end }}
  {{- if $hasSizeLimit }}
  sizeLimit: {{ $emptyDir.sizeLimit }}
  {{- end }}
{{- end -}}
{{- end -}}

{{/*
Check that every volume declares exactly one source.
A volume with no source renders as a bare `- name: <name>`, which the API server
rejects with `must specify a volume type`.
*/}}
{{- define "validate.volumes" -}}
{{- $sources := list "hostPath" "emptyDir" "secretVolume" "configMapVolume" "persistentVolumeClaim" -}}
{{- range $i, $v := .Values.volumes -}}
  {{- if not (kindIs "map" $v) -}}
    {{- fail (printf "Error: volumes[%d] must be a map, but got '%v'." $i $v) -}}
  {{- end -}}
  {{- if not $v.name -}}
    {{- fail (printf "Error: volumes[%d].name is required." $i) -}}
  {{- end -}}
  {{- $found := list -}}
  {{- range $source := $sources -}}
    {{- /* Presence, not truthiness: `emptyDir: {}` is a complete source. */ -}}
    {{- if and (hasKey $v $source) (not (kindIs "invalid" (get $v $source))) -}}
      {{- $found = append $found $source -}}
    {{- end -}}
  {{- end -}}
  {{- if eq (len $found) 0 -}}
    {{- fail (printf "Error: volumes[%s] has no volume source. Please set one of %s." $v.name (join ", " $sources)) -}}
  {{- end -}}
  {{- if gt (len $found) 1 -}}
    {{- fail (printf "Error: volumes[%s] has more than one volume source (%s). Please set only one." $v.name (join ", " $found)) -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Check the Job spec fields.
- `restartPolicy` must be `Never` or `OnFailure`; the API server rejects `Always`
  for a Job pod.
- `completionMode` must be `NonIndexed` or `Indexed`, and `Indexed` needs
  `completions`.
- counters must be non-negative integers, and `completions`/`parallelism` must
  not be set to a value the API server would reject.
*/}}
{{- define "validate.job" -}}
{{- $job := required "job is required" .Values.job -}}
{{- if not (kindIs "map" $job) }}
  {{- fail (printf "Error: job must be a map, but got '%v'." $job) -}}
{{- end }}
{{- if not $job.containers }}
  {{- fail "Error: job.containers is required. Please set at least one container." -}}
{{- end }}
{{- $restartPolicy := default "Never" $job.restartPolicy }}
{{- if not (has $restartPolicy (list "Never" "OnFailure")) }}
  {{- fail (printf "Error: job.restartPolicy=%v. A Job pod only allows 'Never' or 'OnFailure'." $restartPolicy) -}}
{{- end }}
{{- range $key := list "backoffLimit" "activeDeadlineSeconds" "ttlSecondsAfterFinished" "completions" "parallelism" }}
  {{- if and (hasKey $job $key) (not (kindIs "invalid" (get $job $key))) }}
    {{- $value := get $job $key }}
    {{- if not (or (kindIs "int" $value) (kindIs "int64" $value) (kindIs "float64" $value)) }}
      {{- fail (printf "Error: job.%s must be an integer, but got '%v'." $key $value) -}}
    {{- end }}
    {{- if ne (float64 (int64 $value)) (float64 $value) }}
      {{- fail (printf "Error: job.%s must be an integer, but got '%v'." $key $value) -}}
    {{- end }}
    {{- if lt (int64 $value) 0 }}
      {{- fail (printf "Error: job.%s must be greater than or equal to 0, but got '%v'." $key $value) -}}
    {{- end }}
  {{- end }}
{{- end }}
{{- if and (hasKey $job "activeDeadlineSeconds") (not (kindIs "invalid" $job.activeDeadlineSeconds)) }}
  {{- if eq (int64 $job.activeDeadlineSeconds) 0 }}
    {{- fail "Error: job.activeDeadlineSeconds must be greater than 0." -}}
  {{- end }}
{{- end }}
{{- if hasKey $job "completionMode" }}
  {{- if not (has $job.completionMode (list "NonIndexed" "Indexed")) }}
    {{- fail (printf "Error: job.completionMode must be one of NonIndexed, Indexed, but got '%v'." $job.completionMode) -}}
  {{- end }}
  {{- if and (eq $job.completionMode "Indexed") (kindIs "invalid" $job.completions) }}
    {{- fail "Error: job.completions is required when job.completionMode is 'Indexed'." -}}
  {{- end }}
{{- end }}
{{- if hasKey $job "suspend" }}
  {{- if not (kindIs "bool" $job.suspend) }}
    {{- fail (printf "Error: job.suspend must be a boolean, but got '%v'." $job.suspend) -}}
  {{- end }}
{{- end }}
{{- end -}}
