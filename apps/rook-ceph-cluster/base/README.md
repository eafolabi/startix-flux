# toolbox.yaml

downloaded from: https://raw.githubusercontent.com/rook/rook/master/deploy/examples/toolbox.yaml, COMMIT: 04c9f989548994c82291e1e5f3c4bfa4cb9b6a8a
Appended a toleration:
      - effect: NoSchedule
        key: node-role.kubernetes.io/control-plane
        operator: Exists
and modified to include yaml --- on top.

Note: We don't use the rook-ceph-cluster helm chart which allows to include the toolbox deployment, so just copied the example for now