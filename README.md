# HA Keycloak Helm Deployment with external HA PostgresDB for Kubernetes

Deploying the High Availability (HA) [Keycloak](https://github.com/bitnami/charts/tree/main/bitnami/keycloak) Helm chart alongside an external High Availability PostgreSQL Database within Kubernetes ensures consistent availability for your identity and access management solution.

## Requirements

### System requirements for installation
- makefile
- kubectl
- helm
- git
- jq

### Already installed within your Kubernetes Cluster
- Ingresscontroller like Nginx or Traefik

## Installation

### Clone this repository
```
git clone <Github-Repo-URL>
```

### Deployment
Before you can deploy it, you have at least to adjust the variable **KEYCLOAK_URL** in the Makefile. 
> **High Availability : For optimal high availability, it's recommended to deploy a minimum of two replicas for Keycloak and three replicas for PostgreSQL. This redundancy ensures that even if one instance fails, the system can continue to operate without interruptions.** 

```
make all
```

## Documentation

### Installed applications
- PostgreSQL Operator
- PostgreSQL Database
- Keycloak

### Keycloak Access
If you installed the Ingresscontroller Traefik, you can use this snippet to make your application reachable from outside the kubernetes cluster:
```
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: keycloak
  namespace: keycloak
spec:
  entryPoints:
    - web
    - websecure
  routes:
    - match: Host(`keycloak.example.com`)
      kind: Rule
      services:
        - name: keycloak
          port: 80
  tls: {}
```

### Variables
The most variables are defined in the Makefile like versions, namespaces and your domain that you would like to use. 
Additional you can increae the instances of the PostgreSQL setup in the postgres-db.yaml file. 

### NodeAffinity
Please also ensure to use outcommented nodeAffinity option to spread your pods on different nodes. 
