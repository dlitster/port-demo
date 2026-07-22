{{- define "development-environment.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "development-environment.policyLabels" -}}
platform.example.com/owner: {{ .Values.owner | quote }}
platform.example.com/service: {{ .Values.service | quote }}
platform.example.com/profile: {{ .Values.profile | quote }}
{{- end }}

{{- define "development-environment.policyAnnotations" -}}
platform.example.com/expires-at: {{ .Values.expiration | quote }}
{{- $portRunId := .Values.portRunId | default "" | trim }}
{{- with $portRunId }}
platform.example.com/port-run-id: {{ . | quote }}
{{- end }}
{{- end }}

{{- define "development-environment.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
platform.example.com/owner: {{ .Values.owner | quote }}
platform.example.com/service: {{ .Values.service | quote }}
{{- end }}

{{- define "development-environment.workloadLabels" -}}
{{- include "development-environment.selectorLabels" . }}
platform.example.com/profile: {{ .Values.profile | quote }}
{{- end }}

{{- define "development-environment.policyProfile" -}}
{{- if eq .Values.profile "small" }}
namespaceQuota:
  hard:
    cpu: 500m
    memory: 512Mi
workload:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 100m
    memory: 128Mi
{{- else if eq .Values.profile "medium" }}
namespaceQuota:
  hard:
    cpu: "1"
    memory: 1Gi
workload:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi
{{- else if eq .Values.profile "large" }}
namespaceQuota:
  hard:
    cpu: "2"
    memory: 2Gi
workload:
  requests:
    cpu: 250m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
{{- end }}
{{- end }}
