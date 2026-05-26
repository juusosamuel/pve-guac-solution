# pve-guac-solution
Implementation of Kubernetes based VDI system. 

This repository is designed around GitOps principles:

    Argo CD manages deployments via Application resources.
    Workloads are primarily deployed via Helm charts.
    Credentials are expected to be provided via Kubernetes Secrets (not committed to Git).

    Security note (important): Do not commit real credentials, private keys, or tokens into this repository. Use Kubernetes Secrets and/or external secret management.

Components

The current setup includes:

    authentik (SSO / identity provider)
    Apache Guacamole (remote desktop gateway)
    PostgreSQL (datastore for Guacamole + authentik)
    kube-prometheus-stack (monitoring)
    cert-manager (TLS issuers and certificate automation)
    Proxmox Virtual Environment (virtualization layer)

Deployments are defined as Argo CD Application manifests in argocd/.
Repository layout

    argocd/ – Argo CD Application manifests
        authentik.yaml
        guacamole.yaml
        postgresql.yaml
        kube-prometheus.yaml
    authentik/values.yaml – Helm values used by the authentik chart
    guacamole/values.yaml – Helm values used by the Guacamole chart
    postgresql/values.yaml – Helm values used by Bitnami PostgreSQL
    postgresql/initdb.sql – SQL schema/init used for Guacamole (mounted by PostgreSQL init scripts)
    cert-manager/manifest.yaml – cert-manager ClusterIssuer example

Prerequisites

    A Kubernetes cluster to deploy on
    Argo CD installed in the cluster
    An ingress controller installed (examples assume k3s default Traefik)
    cert-manager installed

How it works

    Argo CD reads the Application manifests under argocd/.
    Each application pulls:
        The Helm chart from its upstream chart repository, and
        Values from this Git repository via Argo CD multi-source support.
    PostgreSQL runs init scripts that create databases/users and optionally initialize the Guacamole schema.

Secrets and credentials

This repo expects credentials to be supplied via Kubernetes Secrets.
Required secrets (example)

You will need to create at least:

    app-db-passwords (in the target namespace)
        postgres-admin-password
        authentik-postgres-password
        guacamole-postgres-password
    authentik-secret
        authentik-secret-key

    Names/keys above are based on the Helm values currently in the repo. If you change chart values, ensure the secret keys match.

Example: create secrets (manual)

kubectl -n default create secret generic app-db-passwords \
  --from-literal=postgres-admin-password='REPLACE_ME' \
  --from-literal=authentik-postgres-password='REPLACE_ME' \
  --from-literal=guacamole-postgres-password='REPLACE_ME'

kubectl -n default create secret generic authentik-secret \
  --from-literal=authentik-secret-key='REPLACE_ME'

Deploying with Argo CD

    Apply the Argo CD Applications:

kubectl apply -n argocd -f argocd/postgresql.yaml
kubectl apply -n argocd -f argocd/authentik.yaml
kubectl apply -n argocd -f argocd/guacamole.yaml
kubectl apply -n argocd -f argocd/kube-prometheus.yaml

    Watch sync status:

argocd app list
argocd app get authentik

Ingress / DNS

The provided Helm values assume internal DNS such as:

    authentik.k3s.local
    guacamole.k3s.local

Update authentik/values.yaml and guacamole/values.yaml to match your DNS.
Notes / recommendations

    Avoid using container tags like latest in production. Pin versions.
    Treat postgresql/initdb.sql and init scripts as bootstrap logic; prefer creating initial admin users/passwords securely.

