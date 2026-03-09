# Directories and what is called by what

`apps/` is where we create applications/workloads.
`clusters/` is where we keep configuration for specific clusters (e.g. a test cluster might only start one or two workloads)

## cluster directory

When adding flux to a cluster we tell it where to look for its configuration:

```
flux bootstrap git --url ssh://git@gitolite.default.k.okvm.de/flux --branch main --path clusters/empty --private-key-file flux-key
```
Note, if you are deploying a management cluster, add `--components-extra image-reflector-controller,image-automation-controller` to the command above. 

See the `--path`?

This tells flux to pull in any `.yaml`-file in that path.

The files in `clusters/*/flux-system` are handled by flux itself, we will not touch those.
All other files are things we want to be in the cluster.

For better encapsulation and possibility of re-use by other clusters, we do not put applications directly into the cluster-config, but we tell it to load the config from some git-repo:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo-app
  namespace: flux-system
spec:
  interval: 1m0s
  sourceRef:
    kind: GitRepository
    name: flux-system
  path: ./apps/podinfo/base
  prune: true
  wait: true
  timeout: 5m0s
```

This re-uses the default repo `flux-system` but specifies a different directory (`apps/podinfo/base`) in this case.
The document `kustomization.podinfo-app` is created and causes flux to look again at the repository and load more config from there; we could also reference another `GitRepository` here.

## apps directory 

We use `apps/*/base` for the default config of the application; if we ever want to start the application a second time (with a different config), we can create a `apps/*/other-config` and reference `../base` from there (or we use the `Kustomization` to patch certain things in `base`).

In this config directories (`base` or `other-config`) flux expects to find a document describing a "kustomization" -- this is *not* the same as `kustomize.toolkit.fluxcd.io/Kustomization` but a `kustomize.config.k8s.io/Kustomization`. This second kind of kustomization is never written to the cluster but configures the kustomization tool of kubectl. See https://kustomize.io

Long story short: That `kustomization.yaml` references other yaml files, merges and patches them and dumps the result into the cluster.

Use `kustomize build apps/podinfo/base` to show what kustomize thinks of your files. This will print the resulting yaml, *not* apply it to the cluster.

# Secrets

To encrypt secret, you need to have `sops` and `age` installed.
You could do that by running `nix-shell -p sops age`.

Create the secret as normal yaml file.
Before commiting, run `sops --encrypt -i my-secret.yaml` and commit the resulting file.

If you need to decrypt a file, add the age-key(s) from bitwarden to your `~/.config/sops/age/keys.txt`.
