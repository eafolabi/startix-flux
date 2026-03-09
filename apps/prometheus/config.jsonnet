local tolerations = {
  tolerations: [
    {
      key: 'node-role.kubernetes.io/control-plane',
      operator: 'Exists',
    },
  ],
};

local podAntiAffinity = {
  affinity: {
    podAntiAffinity: {
      preferredDuringSchedulingIgnoredDuringExecution: [
        {
          weight: 10,
          podAffinityTerm: {
            labelSelector: {
              matchExpressions: [
                {
                  key: 'app.kubernetes.io/name',
                  operator: 'In',
                  values: [
                    'prometheus-adapter',
                  ],
                },
              ],
            },
            topologyKey: 'kubernetes.io/hostname',
          },
        },
      ],
    },
  },
};

local ingressLabel = { labels+: { 'b2.genesiscloud.dev/expose-to-ingress': 'true' } };

local filter = {
  kubernetesControlPlane+: {
    prometheusRule+: {
      spec+: {
        groups: std.map(
          function(group)
            if group.name == 'kubernetes-resources' then
              group {
                rules: std.filter(
                  function(rule)
                    rule.alert != 'CPUThrottlingHigh',
                  group.rules
                ),
              }
            else if group.name == 'kubernetes-system-kubelet' then
              group {
                rules: std.filter(
                  function(rule) (
                       rule.alert == 'KubeletClientCertificateExpiration'
                    || rule.alert == 'KubeletServerCertificateExpiration'
                    || rule.alert == 'KubeletClientCertificateRenewalErrors'
                    || rule.alert == 'KubeletServerCertificateRenewalErrors'
                  ),
                  group.rules
                ),
              }
            else if group.name == 'kubernetes-system' then
              group {
                rules: std.filter(
                  function(rule) (
                       rule.alert != 'KubeVersionMismatch'
                  ),
                  group.rules
                ),
              }
            else
              group,
          super.groups
        ),
      },
    },
  },
};

local kp =
  (import 'kube-prometheus/main.libsonnet') +
  filter +
  {
    # Override namespace from "monitoring"
    values+:: {
      common+: {
        namespace: 'prometheus',
      },
      grafana+: {
        config+: {
          sections+: {
            'auth.anonymous': { enabled: 'true', org_role: 'Admin', hide_version: 'false' }
          }
        },
        datasources: [
          {
            name: 'Prometheus',
            type: 'prometheus',
            access: 'proxy',
            url: 'http://prometheus-k8s.prometheus.svc:9090',
            version: 1,
            editable: false,
            uid: 'P1809F7CD0C75ACF3',
          },
          {
            name: 'Loki',
            type: 'loki',
            access: 'proxy',
            url: 'http://loki-read.monitoring.svc:3100',
            jsonData: {timeout: 60, maxLines: 1000},
            version: 1,
            editable: false,
            uid: 'P8E80F9AEF21F6940',
          },
        ]
      },
      prometheus+:: {
        namespaces: ["default", "kube-system", "prometheus", "northbound-api", "harbor", "flux-system", "monitoring", "customer-operators", "node-operator", "ingress", "infra", "rook-ceph", "external-prometheus", "kamaji-system"],
      },
      alertmanager+: {
        config+: {
          receivers+: [
            {
              name: 'slack-notifications',
              slack_configs: [
                {
                  channel: '#b2_alerts_${environment}',
                  api_url_file: '/etc/alertmanager/secrets/alertmanager-slack-api-url/backend-v2-notifications.txt',
                  title_link: 'https://alertmanager.${environment}.b2.${base_domain}/#/alerts?receiver=slack-notifications',
                  send_resolved: true,
                  title: ':${environment_flag_emoji}:${environment}: {{ .Status | toUpper }} - {{ if eq .Status "firing" }}{{ .Alerts.Firing | len }}{{ end }} {{ .CommonLabels.severity }}(s) in namespace {{ .GroupLabels.namespace }}',
                  text: '{{ range .Alerts }}• <https://alertmanager.${environment}.b2.${base_domain}/#/alerts?filter=%7B{{ $first := true }}{{ range $key, $value := .Labels }}{{ if $first }}{{ $first = false }}{{ else }},{{end}}{{ $key }}%3D"{{ $value }}"{{ end }}%7D|{{ .Labels.alertname }}>{{ if .GeneratorURL }} (<{{ .GeneratorURL }}|:chart_with_upwards_trend:>){{ end }}: {{ .Annotations.description }} <https://alertmanager.${environment}.b2.${base_domain}/#/silences/new?filter=%7B{{ $first := true }}{{ range $key, $value := .Labels }}{{ if $first }}{{ $first = false }}{{ else }},{{end}}{{ $key }}%3D"{{ $value }}"{{ end }}%7D|Silence this alarm.>\n{{ end }}'
                }
              ]
            },
            {
              name: 'slack-resource-cleanup-notifications',
              slack_configs: [
                {
                  channel: '#gws-b2-cleanup-notifications',
                  api_url_file: '/etc/alertmanager/secrets/alertmanager-slack-api-url/gws-b2-cleanup-notifications.txt',
                  title_link: 'https://alertmanager.${environment}.b2.${base_domain}/#/alerts?receiver=slack-resource-cleanup-notifications',
                  send_resolved: true,
                  title: ':${environment_flag_emoji}:${environment}: {{ .Status | toUpper }} - {{ .CommonLabels.severity }} in namespace {{ .GroupLabels.namespace }}',
                  text: '{{ range .Alerts }}<https://alertmanager.${environment}.b2.${base_domain}/#/alerts?filter=%7B{{ $first := true }}{{ range $key, $value := .Labels }}{{ if $first }}{{ $first = false }}{{ else }},{{end}}{{ $key }}%3D"{{ $value }}"{{ end }}%7D|{{ .Labels.alertname }}>{{ if .GeneratorURL }} (<{{ .GeneratorURL }}|:chart_with_upwards_trend:>){{ end }}: {{ .Annotations.description }} <https://alertmanager.${environment}.b2.${base_domain}/#/silences/new?filter=%7B{{ $first := true }}{{ range $key, $value := .Labels }}{{ if $first }}{{ $first = false }}{{ else }},{{end}}{{ $key }}%3D"{{ $value }}"{{ end }}%7D|Silence this alarm.>\n{{ end }}'
                }
              ]
            },
            {
              name: 'slack-rook-ceph-notifications',
              slack_configs: [
                {
                  channel: '#rook-ceph-alerts',
                  api_url_file: '/etc/alertmanager/secrets/alertmanager-slack-api-url/rook-ceph-alerts.txt',
                  title_link: 'https://alertmanager.${environment}.b2.${base_domain}/#/alerts?receiver=slack-rook-ceph-notifications',
                  send_resolved: true,
                  title: ':${environment_flag_emoji}:${environment}: {{ .Status | toUpper }} - {{ .CommonLabels.severity }} in namespace {{ .GroupLabels.namespace }}',
                  text: '{{ range .Alerts }}<https://alertmanager.${environment}.b2.${base_domain}/#/alerts?filter=%7B{{ $first := true }}{{ range $key, $value := .Labels }}{{ if $first }}{{ $first = false }}{{ else }},{{end}}{{ $key }}%3D"{{ $value }}"{{ end }}%7D|{{ .Labels.alertname }}>{{ if .GeneratorURL }} (<{{ .GeneratorURL }}|:chart_with_upwards_trend:>){{ end }}: {{ .Annotations.description }} <https://alertmanager.${environment}.b2.${base_domain}/#/silences/new?filter=%7B{{ $first := true }}{{ range $key, $value := .Labels }}{{ if $first }}{{ $first = false }}{{ else }},{{end}}{{ $key }}%3D"{{ $value }}"{{ end }}%7D|Silence this alarm.>\n{{ end }}'
                }
              ]
            }
          ],
          route+: {
            receiver: 'slack-notifications', # root receiver
            routes: [
              { receiver: 'Watchdog', matchers: ['alertname = Watchdog'] },
              { receiver: 'null', matchers: ['alertname = InfoInhibitor'] },
              {
                receiver: 'slack-resource-cleanup-notifications',
                matchers: [
                  'channel = resource-cleanup-notifications'
                ],
                group_by: ["..."],
                repeat_interval: "12h"
              },
              {
                receiver: 'slack-rook-ceph-notifications',
                matchers: [
                  'namespace = external-prometheus',
                  'channel = rook-ceph-notifications'
                ],
                group_by: ["type"],
                repeat_interval: "24h"
              }
            ]
          }
        }
      }
    },

    # Add tolerations and ingress label to CRD instances
    prometheus+:: {
      prometheus+: {
        spec+: tolerations + {
          replicas: '${prometheus_replicas}',
          externalUrl: "https://prometheus.${environment}.b2.${base_domain}/",
          podMetadata+: ingressLabel,
          retention: '${prometheus_retention}',
          storage: {
            volumeClaimTemplate: {
              apiVersion: 'v1',
              kind: 'PersistentVolumeClaim',
              spec: {
                accessModes: ['ReadWriteOnce'],
                resources: { requests: { storage: '${prometheus_size}' } },
                storageClassName: '${prometheus_class}',
              },
            }
          }
        }
      },
      networkPolicy+: { spec+: { ingress+: [ {
        from: [ { podSelector: { matchLabels: { 'app.kubernetes.io/name': 'prometheus-adapter' } } } ],
        ports: [ { port: 9090, protocol: 'TCP' } ]
      } ] } }
    },
    alertmanager+:: {
      alertmanager+: {
        spec+: tolerations + {
          podMetadata+: ingressLabel,
          secrets+: ['alertmanager-slack-api-url']
        }
      },
      networkPolicy+: { spec+: { ingress+: [ {
        from: [ { namespaceSelector:{}, podSelector: { matchLabels: { 'b2.genesiscloud.dev/allow-to-alertmanager': 'true' } } } ],
        ports: [ { port: 9093, protocol: 'TCP' } ]
      } ] } }
    },

    # Add tolerations to deployments
    prometheusOperator+:: { deployment+: { spec+: { template+: { spec+: tolerations + {
      containers: [
        (
          if c.name == 'prometheus-operator' then
            c + {
              resources+: {
                limits+: {
                  memory: '500Mi',
                },
              },
            }
          else
            c
        ) for c in super.containers
      ]
    } } } } },
    blackboxExporter+:: { deployment+: { spec+: { template+: { spec+: tolerations } } } },
    grafana+:: { deployment+: { spec+: { template+: {
      metadata+: ingressLabel,
      spec+: tolerations + {
        containers: [
        (
          if c.name == 'grafana' then
            c + {
              readinessProbe+: {
                initialDelaySeconds: 30,
              },
              livenessProbe+: {
                httpGet+: {
                  path: '/api/health',
                  port: 'http',
                },
                initialDelaySeconds: 120,
                },
               resources+: {
                limits+: {
                  memory: '500Mi',
                  cpu: '400m',
                },
              },
            }
          else
            c
        ) for c in super.containers
      ]
    } } } } },
    kubeStateMetrics+:: { deployment+: { spec+: { template+: { spec+: tolerations } } } },
    prometheusAdapter+:: { deployment+: { spec+: { template+: { spec+: tolerations + podAntiAffinity } } } },
  };

{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor' && name != 'prometheusRule'), std.objectFields(kp.prometheusOperator))
} +
{ 'main/prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ 'main/prometheus-operator-prometheusRule': kp.prometheusOperator.prometheusRule } +
{ 'main/kube-prometheus-prometheusRule': kp.kubePrometheus.prometheusRule } +
{ ['main/alertmanager-' + name]: kp.alertmanager[name] for name in std.filter((function(name) name != 'prometheusRule'), std.objectFields(kp.alertmanager)) } +
{ ['main/blackbox-exporter-' + name]: kp.blackboxExporter[name] for name in std.objectFields(kp.blackboxExporter) } +
{ ['main/grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) } +
{ ['main/kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{
  ['main/kubernetes-' + name]: kp.kubernetesControlPlane[name]
  for name in std.filter((function(name)  name != 'prometheusRule'), std.objectFields(kp.kubernetesControlPlane))
} +
{
  ['main/kubernetes-prometheusRule']: kp.kubernetesControlPlane['prometheusRule'] + {
	spec+: {
	  groups: std.filter(
		(
			function(group)
			   group.name != 'kubernetes-system-scheduler'
			&& group.name != 'kubernetes-system-controller-manager'
			&& group.name != 'kubernetes-apps'
		),
		super.groups
	  ),
	},
  }
} +

{ ['main/prometheus-' + name]: kp.prometheus[name]
  for name in std.filter((function(name)  name != 'prometheusRule'), std.objectFields(kp.prometheus))
} +
{
  ['main/prometheus-prometheusRule']: kp.prometheus['prometheusRule'] + {
   spec+: {
     groups:
       std.map(
         function(group)
            if group.name == 'prometheus' then
              group {
                rules: std.filter(
                  function(rule)
                    rule.alert != 'PrometheusDuplicateTimestamps',
                  group.rules
                ),
              }
            else
              group,
          super.groups
        ) ,
	},
  }
} +
{ ['main/prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) }
