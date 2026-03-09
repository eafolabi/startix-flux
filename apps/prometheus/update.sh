#!/usr/bin/env bash

set -eExo pipefail

# Install dependencies
go install github.com/google/go-jsonnet/cmd/jsonnet@latest
go install github.com/brancz/gojsontoyaml@latest
go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest

# Enter build folder
outdir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
tempdir=$(mktemp -d)
pushd "$tempdir"

# Pull repo
~/go/bin/jb init
~/go/bin/jb install github.com/prometheus-operator/kube-prometheus@release-0.14

# Setup output folders
rm -rf manifests
mkdir -p manifests/setup
mkdir -p manifests/main

# Generate YAML
cp "$outdir/config.jsonnet" config.jsonnet
~/go/bin/jsonnet -J vendor -m manifests config.jsonnet | xargs -I{} sh -c 'cat {} | ~/go/bin/gojsontoyaml > {}.yaml' -- {}

# Remove unused files
find manifests -type f ! -name '*.yaml' -delete
find manifests -type f -name '*.yaml' -exec sed '/# yamllint disable/b; 1s/^/# yamllint disable\n/' -i '{}' ';'

# Copy to output
rm -r "$outdir/upstream/"{setup,main}
cp -r manifests/{setup,main} "$outdir/upstream/"

# Clean up
popd
rm -r "$tempdir"
