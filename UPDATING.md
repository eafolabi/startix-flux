# Updating to a new flux version the commercial environments

```shell
curl -s https://fluxcd.io/install.sh | sudo bash
{ echo "# yamllint disable-file"; flux install --toleration-keys node-role.kubernetes.io/control-plane  --export; }  > clusters/{no-krs-n01,de-muc-emc,dev,seedling}/flux-system/gotk-components.yaml
```

# Updating to a new flux version the management environment

```shell
curl -s https://fluxcd.io/install.sh | sudo bash
{ echo "# yamllint disable-file"; flux install --toleration-keys node-role.kubernetes.io/control-plane --components-extra image-reflector-controller,image-automation-controller --export; }  > clusters/management/flux-system/gotk-components.yaml
```
