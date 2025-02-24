{{/*
Recursively process a component and its dependants.
*/}}
{{- define "crossplane-components.process.component" -}}
{{- /* Parameters */}}
{{- $ctx := .ctx }}
{{- $componentType := .componentType }}
{{- $apiVersion := .apiVersion }}
{{- $instance := .instance }}
{{- $instanceName := .instanceName }}
{{- $parentRefs := .parentRefs }}
{{- $namePrefix := .namePrefix }}

{{- /* Global variables */}}
{{- $global := $ctx.Values.global }}
{{- $useSimplifiedNames := $global.useSimplifiedNames | default false }}

{{- /* Get component configuration */}}
{{- $componentConfig := get $ctx.Values.components $componentType | default dict }}
{{- $defaultRefKey := ternary (printf "%sId" ($componentType | lower)) (printf "%sIdRef" ($componentType | lower)) $useSimplifiedNames }}
{{- $refKey := $componentConfig.refKey | default $defaultRefKey }}

{{- /* Build resource name */}}
{{- $fullNameBase := (concat $namePrefix (list $instanceName) | join "-") }}
{{- $resourceSuffix := (printf "-%s" ($componentType | lower)) }}
{{- $fullName := printf "%s%s" $fullNameBase $resourceSuffix }}

{{- /* Determine providerConfig */}}
{{- $providerConfig := $global.providerConfig }}

{{- /* Generate the current resource */}}
---
apiVersion: {{ $apiVersion }}
kind: {{ $componentType }}
metadata:
  name: {{ $fullName }}
spec:
  {{- if $providerConfig }}
  providerConfigRef:
    name: {{ $providerConfig }}
  {{- end }}
  forProvider:
    {{- toYaml ($instance.forProvider | default dict) | nindent 4 }}
    {{- /* Add references from parent components */}}
    {{- range $parentRef := $parentRefs }}
    {{- if $useSimplifiedNames }}
    {{ $parentRef.refKey }}: {{ $parentRef.instanceName }}
    {{- else }}
    {{ $parentRef.refKey }}:
      name: {{ $parentRef.fullName }}
    {{- end }}
    {{- end }}
{{- /* Process dependants recursively */}}
{{- if $instance.dependants }}
  {{- range $dependantComponentType, $dependant := $instance.dependants }}
    {{- $dependantApiVersion := $dependant.apiVersion | default $apiVersion }}
    {{- $currentParentRef := dict "kind" $componentType "refKey" $refKey "fullName" $fullName "instanceName" $instanceName }}
    {{- $newParentRefs := append $parentRefs $currentParentRef }}
    {{- $sortedDependantInstances := keys $dependant.list | sortAlpha }}
    {{- range $dependantInstanceName := $sortedDependantInstances }}
      {{- $dependantInstance := get $dependant.list $dependantInstanceName }}
      {{- $newNamePrefix := append $namePrefix $instanceName }}
      {{- include "crossplane-components.process.component" (dict "ctx" $ctx "componentType" $dependantComponentType "apiVersion" $dependantApiVersion "instance" $dependantInstance "instanceName" $dependantInstanceName "parentRefs" $newParentRefs "namePrefix" $newNamePrefix) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}