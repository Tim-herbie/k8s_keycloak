###############################
### Variables Section Begin ###
###############################

# PostgreSQL OPERATOR Variables
PostgreSQL_OPERATOR_NAMESPACE := postgres
PostgreSQL_OPERATOR_VERSION := 1.10.1
POSTGRES_OPERATOR_CHECK = $(shell kubectl get pods -A -l app.kubernetes.io/name=postgres-operator)

# Keycloak Variables
KEYCLOAK_NAMESPACE := keycloak
KEYCLOAK_VERSION := 18.7.1
KEYCLOAK_REPLICA := 2
KEYCLOAK_URL := https://keycloak.example.com


###########################
### Deployment Section ####
###########################

all: prep install-postgresql-operator database-install wait_for_postgresql install-keycloak echo

prep:
# PostgreSQL Operator
	kubectl create namespace $(PostgreSQL_OPERATOR_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	helm repo add postgres-operator-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator

# Keycloak
	kubectl create namespace $(KEYCLOAK_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	helm repo add bitnami https://charts.bitnami.com/bitnami
	
install-postgresql-operator:
ifneq ($(strip $(POSTGRES_OPERATOR_CHECK)),)
	$(info Postgres Operator is already installed. Nothing to do here.)
else
	helm upgrade --install postgres-operator \
	--set configKubernetes.enable_pod_antiaffinity=true \
	--set configKubernetes.enable_readiness_probe=true \
	--namespace $(PostgreSQL_OPERATOR_NAMESPACE) \
	--version=$(PostgreSQL_OPERATOR_VERSION) \
	postgres-operator-charts/postgres-operator
endif

database-install:
	kubectl -n $(KEYCLOAK_NAMESPACE) apply -f postgres-db.yaml

wait_for_postgresql:
	@while true; do \
        status=$$(kubectl get postgresql -o json | jq -r '.items[0].status.PostgresClusterStatus'); \
        if [ "$$status" = "Running" ]; then \
            echo "PostgreSQL cluster is now Running."; \
            break; \
        else \
            echo "PostgreSQL cluster is still not ready. Waiting..."; \
            sleep 10; \
        fi; \
    done

install-keycloak:
	helm upgrade --install keycloak \
	--namespace $(KEYCLOAK_NAMESPACE) \
	--values keycloak-values.yaml \
	--version $(KEYCLOAK_VERSION) \
	--set replicaCount=$(KEYCLOAK_REPLICA) \
	--set extraEnvVars[0].name=KC_HOSTNAME_URL \
    --set extraEnvVars[0].value=$(KEYCLOAK_URL) \
    --set extraEnvVars[1].name=KC_HOSTNAME_ADMIN_URL \
    --set extraEnvVars[1].value=$(KEYCLOAK_URL) \
	--set externalDatabase.host=keycloak-postgres-db.$(KEYCLOAK_NAMESPACE).svc.cluster.local \
	bitnami/keycloak

echo:
	echo "Admin User: user"
	echo "Password can be grabed with this command: k -n $(KEYCLOAK_NAMESPACE) get secret keycloak -o jsonpath='{.data.admin-password}' | base64 -d"

delete:
	helm -n $(KEYCLOAK_NAMESPACE) uninstall keycloak
	kubectl -n $(KEYCLOAK_NAMESPACE) delete -f postgres-db.yaml
	kubectl delete namespace $(KEYCLOAK_NAMESPACE)
	helm -n $(PostgreSQL_OPERATOR_NAMESPACE) uninstall postgres-operator
	kubectl delete namespace $(PostgreSQL_OPERATOR_NAMESPACE)