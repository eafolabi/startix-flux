This job pulls the public DNS record list from Netbox so the public DNS operator (part of the Customer Instance Operator package) can manage them.

It's not part of the C-I-O itself since it lives in the `infra` namespace so that we don't need a third copy of the `netbox-key` secret.