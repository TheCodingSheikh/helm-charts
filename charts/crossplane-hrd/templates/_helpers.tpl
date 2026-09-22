{{- /*
crossplane-hrd.merge deep-merges .src into .dst, mutating .dst.
Maps are merged recursively, any other value (string, number, bool, list)
replaces the destination value, and a null value removes the key.
*/ -}}
{{- define "crossplane-hrd.merge" -}}
{{- $dst := .dst -}}
{{- range $key, $value := .src -}}
  {{- if kindIs "invalid" $value -}}
    {{- $_ := unset $dst $key -}}
  {{- else if kindIs "map" $value -}}
    {{- if not (kindIs "map" (get $dst $key)) -}}
      {{- $_ := set $dst $key (dict) -}}
    {{- end -}}
    {{- include "crossplane-hrd.merge" (dict "dst" (get $dst $key) "src" $value) -}}
  {{- else -}}
    {{- $_ := set $dst $key (deepCopy $value) -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- /*
crossplane-hrd.applySettings applies the inheritable settings declared in .src
(global values or a single resource) on top of .dst, mutating .dst:
providerConfigRef, namespace, labels, annotations and spec.
*/ -}}
{{- define "crossplane-hrd.applySettings" -}}
{{- $dst := .dst -}}
{{- $src := .src -}}
{{- $at := printf "%s." .path -}}
{{- $own := pick $src "providerConfigRef" "namespace" "labels" "annotations" "spec" -}}
{{- if and (hasKey $own "namespace") (not (or (kindIs "string" $own.namespace) (kindIs "invalid" $own.namespace))) -}}
  {{- fail (printf "%snamespace must be a string" $at) -}}
{{- end -}}
{{- if and (hasKey $own "providerConfigRef") (not (or (kindIs "map" $own.providerConfigRef) (kindIs "invalid" $own.providerConfigRef))) -}}
  {{- fail (printf "%sproviderConfigRef must be a map, e.g. {name: aws-prod}" $at) -}}
{{- end -}}
{{- range $key := list "labels" "annotations" "spec" -}}
  {{- if and (hasKey $own $key) (not (or (kindIs "map" (get $own $key)) (kindIs "invalid" (get $own $key)))) -}}
    {{- fail (printf "%s%s must be a map" $at $key) -}}
  {{- end -}}
{{- end -}}
{{- if kindIs "map" $own.spec -}}
  {{- if hasKey $own.spec "forProvider" -}}
    {{- fail (printf "%sspec.forProvider is not supported, use forProvider on the resource instead" $at) -}}
  {{- end -}}
  {{- if hasKey $own.spec "providerConfigRef" -}}
    {{- fail (printf "%sspec.providerConfigRef is not supported, use %sproviderConfigRef instead" $at $at) -}}
  {{- end -}}
{{- end -}}
{{- include "crossplane-hrd.merge" (dict "dst" $dst "src" $own) -}}
{{- end -}}

{{- /*
crossplane-hrd.stringMap renders a labels/annotations map with every value
converted to a string, as Kubernetes requires.
*/ -}}
{{- define "crossplane-hrd.stringMap" -}}
{{- $out := dict -}}
{{- range $key, $value := . -}}
  {{- $_ := set $out $key (toString $value) -}}
{{- end -}}
{{- toYaml $out -}}
{{- end -}}
