# towelie

Infrastructure boilerplate for VPN gateway nodes.

## Layout

```
images/
  ingress-node/     Containerfile for the client-facing ingress gateway
  egress-node/      Containerfile for the internet-facing egress gateway
apps/
  terraform/
    applications/
      org/          Org-level Terraform (accounts, base infra)
```

## Images

- **ingress-node** — terminates client connections, forwards to egress
- **egress-node** — NATs tunneled traffic out to the internet

Build with any OCI-compatible tool (Docker, Podman, `buildah`).

## Terraform

`apps/terraform/applications/org` provisions the shared org-level resources
that node deployments depend on. Run `terraform init` inside that directory
before planning or applying.

## Status

Early scaffold — images and Terraform are stubs pending implementation.
