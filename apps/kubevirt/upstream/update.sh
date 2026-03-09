#!/usr/bin/env bash

set -o errexit
set -o nounset

VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases | grep tag_name | grep -v -- '-rc' | sort -r | head -1 | awk -F': ' '{print $2}' | sed 's/,//' | xargs)
{ echo '# yamllint disable-file'; curl -L https://github.com/kubevirt/kubevirt/releases/download/"${VERSION}"/kubevirt-operator.yaml; } > kubevirt-operator.yaml
{ echo '# yamllint disable-file'; curl -L https://github.com/kubevirt/kubevirt/releases/download/"${VERSION}"/kubevirt-cr.yaml; } > kubevirt-cr.yaml
