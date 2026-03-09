Based on https://github.com/prometheus-operator/kube-prometheus.

To update the content of `upstream`, run `update.sh`.

`config.jsonnet` is based on the upstream `example.jsonnet` with the following changes:
- Removed the namespace resource, is managed by us
- Moved non-`setup/` components to `main/` to avoid double-management by Flux
- Added tolerations
- Added ingress label
- Added anonymous access
