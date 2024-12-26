apiVersion: v1
kind: Pod
metadata:
  name: {{ include "config-validator.fullname" . | quote }}
  namespace: {{ .Release.Namespace }}
  labels:
    app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
    app.kubernetes.io/instance: {{ .Release.Name | quote }}
    app.kubernetes.io/version: {{ .Chart.AppVersion }}
    helm.sh/chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
    {{- range $key, $val := .Values.configValidator.extraLabels }}
    {{ $key }}: {{ $val | quote }}
    {{- end }}
  annotations:
    "helm.sh/hook": pre-install,pre-upgrade
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
    {{- range $key, $val := .Values.configValidator.extraAnnotations }}
    {{ $key }}: {{ $val | quote }}
    {{- end}}
spec:
  {{- if .Values.configValidator.serviceAccount.name }}
  serviceAccountName: {{ .Values.configValidator.serviceAccount.name }}
  {{- end }}
  restartPolicy: Never
  containers:
    - name: alloy
      image: "{{ .Values.global.image.registry | default (index .Values $enabledAlloy).image.registry }}/{{ (index .Values $enabledAlloy).image.repository }}{{ include "alloy.imageId" (index .Subcharts $enabledAlloy) }}"
      command:
      - bash
      - -c
      - |
        echo Validating Grafana Alloy config file
        if ! alloy fmt /etc/alloy/config.alloy > /dev/null; then
          exit 1
        fi
        output=$(alloy run --stability.level {{ (index .Values $enabledAlloy).alloy.stabilityLevel | default "generally-available" }} "/etc/alloy/config.alloy" 2>&1)
        if ! echo "${output}" | grep "KUBERNETES_SERVICE_HOST and KUBERNETES_SERVICE_PORT must be defined" >/dev/null; then
          echo "${output}"
          exit 1
        fi
        echo "Grafana Alloy config file is valid"
{{- if .Values.logs.cluster_events.enabled }}
        echo Validating Grafana Alloy for Events config file
        if ! alloy fmt /etc/alloy/events.alloy > /dev/null; then
          exit 1
        fi
        output=$(alloy run --stability.level {{ (index .Values "alloy-events").alloy.stabilityLevel | default "generally-available" }} "/etc/alloy/events.alloy" 2>&1)
        if ! echo "${output}" | grep "KUBERNETES_SERVICE_HOST and KUBERNETES_SERVICE_PORT must be defined" >/dev/null; then
          echo "${output}"
          exit 1
        fi
        echo "Grafana Alloy for Events config file is valid"
{{- end }}
{{- if .Values.logs.pod_logs.enabled }}
        echo Validating Grafana Alloy for Logs config file
        if ! alloy fmt /etc/alloy/logs.alloy > /dev/null; then
          exit 1
        fi
        output=$(alloy run --stability.level {{ (index .Values "alloy-logs").alloy.stabilityLevel | default "generally-available" }} "/etc/alloy/logs.alloy" 2>&1)
        if ! echo "${output}" | grep "KUBERNETES_SERVICE_HOST and KUBERNETES_SERVICE_PORT must be defined" >/dev/null; then
          echo "${output}"
          exit 1
        fi
        echo "Grafana Alloy for Logs config file is valid"
{{- end }}
{{- if .Values.profiles.enabled }}
        echo Validating Grafana Alloy for Profiles config file
        if ! alloy fmt /etc/alloy/profiles.alloy > /dev/null; then
          exit 1
        fi
        output=$(alloy run --stability.level {{ (index .Values "alloy-profiles").alloy.stabilityLevel | default "generally-available" }} "/etc/alloy/profiles.alloy" 2>&1)
        if ! echo "${output}" | grep "KUBERNETES_SERVICE_HOST and KUBERNETES_SERVICE_PORT must be defined" >/dev/null; then
          echo "${output}"
          exit 1
        fi
        echo "Grafana Alloy for Profiles config file is valid"
{{- end }}
      env:
        - name: KUBERNETES_SERVICE_HOST
          value: ""
        - name: KUBERNETES_SERVICE_PORT
          value: ""
        - name: CLUSTER_NAME  # Add the cluster name environment variable
          value: "{{ .Values.cluster.name | quote }}"  # Reference the cluster name from values.yaml
      volumeMounts:
        - name: config
          mountPath: /etc/alloy
  volumes:
    - name: config
      configMap:
        name: {{ include "config-validator.fullname" . | quote }}
