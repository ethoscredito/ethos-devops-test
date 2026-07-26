# Camino B — Kubernetes (EKS) · **plus voluntario**

El camino principal de esta entrega es el **A (ECS Fargate + ALB)**, que está
desplegado y funcionando. Este directorio es el plus del enunciado
("despliega también el camino que no elegiste"): manifiestos listos para
aplicar, con el mismo contrato (`/health`, `/ready`, ALB HTTP:80) y la misma
convención de nombres y tags.

## Estado

Manifiestos completos y validados con `kubectl --dry-run=client`. **No están
aplicados**: requieren un cluster EKS previo con el AWS Load Balancer
Controller instalado. Se dejan como IaC versionada, no como afirmación de que
hay algo corriendo.

## Qué contiene

| Archivo | Rol |
|---|---|
| `base/namespace.yaml` | Namespace `ethos-cand-lucio-o-dev` |
| `base/deployment.yaml` | 2 réplicas, probes `/health` (liveness) y `/ready` (readiness), rootfs read-only, non-root, spread por AZ |
| `base/service.yaml` | `ClusterIP` — la exposición pública la hace el Ingress |
| `base/ingress.yaml` | `ingressClassName: alb`, `internet-facing`, `target-type: ip`, HTTP:80, health check a `/health`, tags `ethos:*` |
| `base/kustomization.yaml` | Punto de entrada; el pipeline sustituye el tag de imagen |

## Requisitos previos

1. **Cluster EKS.** Crearlo con los roles ya provistos por el stack de la
   prueba, respetando nombre y permissions boundary:

   ```bash
   aws iam create-role \
     --role-name ethos-cand-lucio-o-dev-eks-cluster \
     --assume-role-policy-document file://trust-eks.json \
     --permissions-boundary arn:aws:iam::816583873447:policy/EthosDevOpsCandidateBoundary \
     --tags Key=ethos:candidate,Value=lucio-o-dev Key=ethos:project,Value=devops-test

   aws iam attach-role-policy \
     --role-name ethos-cand-lucio-o-dev-eks-cluster \
     --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
   ```

   > `eks:ListClusters` está denegado a propósito. El nombre del cluster
   > (`ethos-cand-lucio-o-dev-eks-cluster`) se guarda y se usa siempre por
   > `describe` / `update-kubeconfig`; no se intenta inventariar la cuenta.

2. **AWS Load Balancer Controller** en el cluster (es quien crea el ALB a
   partir del Ingress).

3. **Puerto del contenedor.** `containerPort` y el `targetPort` del Service
   deben coincidir con el `EXPOSE` de `app-ethos-mock/Dockerfile`
   (mismo valor que `container_port` en el camino A).

## Aplicar

```bash
aws eks update-kubeconfig \
  --name ethos-cand-lucio-o-dev-eks-cluster \
  --region us-east-1 --profile ethos-cand

# Validación sin tocar el cluster
kubectl apply -k infra/eks/base --dry-run=client

# Despliegue
kubectl apply -k infra/eks/base
kubectl -n ethos-cand-lucio-o-dev rollout status deploy/app-ethos-mock --timeout=5m

# URL pública del ALB creado por el Ingress
kubectl -n ethos-cand-lucio-o-dev get ingress app-ethos-mock \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Validación final, idéntica a la del camino A:

```bash
DNS=$(kubectl -n ethos-cand-lucio-o-dev get ingress app-ethos-mock \
        -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
bash ci/smoke-test.sh "http://$DNS"
```

## CI/CD

`.github/workflows/deploy-eks.yml` cubre este camino. Es `workflow_dispatch`
manual a propósito: el push a `candidato/lucio-o-dev` despliega el camino A
(el principal) y no debe fallar por un cluster EKS que puede no existir.
