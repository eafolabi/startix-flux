snapshot-presigned-key.yaml: pwgen 250 1 | base64 -w0
northbound-api.yaml: pwgen 42 1 -s | tee /tmp/nb-api-passwd-plaintext-delete-me-soon | openssl passwd -apr1 -stdin | sed 's/^/gws:/g' | base64
prometheus.yaml->prom-basic-auth: pwgen 32 1 -s | tee /tmp/prom-basic-auth-plaintext-delete-me-soon | openssl passwd -apr1 -stdin | base64
prometheus.yaml->alertmanager-slack-api-url: Add the new channel in slack, go to the slack API web page, select App b2-clusters-notification and under web hooks add a new one. Then copy the generated URL and base64 encode it.
