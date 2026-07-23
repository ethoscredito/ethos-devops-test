# EthosPay — Prueba técnica DevOps

**Repo:** https://github.com/ethoscredito/ethos-devops-test.git

Publica la app mock (`app-ethos-mock/`) en AWS por **HTTP** detrás de un **Application Load Balancer** (URL tipo `http://….elb.amazonaws.com`), eligiendo **uno** de estos caminos:

| Camino | Qué implica (orientativo) |
|--------|---------------------------|
| **ECS** | Imagen en ECR, servicio ECS (p. ej. Fargate) + ALB HTTP |
| **Kubernetes** | Cluster (p. ej. EKS), manifiestos/Helm + exposición vía ALB HTTP |

**No** se exige dominio custom ni HTTPS. El criterio de éxito es el DNS del ALB + `/health` y `/ready`.

**Obligatorio además:** trabajar en una rama desde `main` con tu id
(`candidato/<tu-id>`, ej. `candidato/christianmisel3`) y un pipeline de **CI/CD con GitHub Actions**
en esa rama (build → push al registry → despliegue). No entregues desde `main`.

**Plus (voluntario, suma puntos):**

- Desplegar por **ambos** caminos (ECS **y** Kubernetes), cada uno con su ALB/URL documentada.
- Automatizaciones extra (IaC, observabilidad, rollback, HTTPS como plus, etc.). Prioriza calidad y justificación.

Primero levanta la app en local (`app-ethos-mock/`, `docker compose up --build`) y lee la guía en **http://localhost:8081**.

**Uso de IA:** permitido consultar métodos y documentación; no usar agentes que resuelvan la prueba por ti.

**Entrega:** responde en el **mismo hilo de correo** con tu rama `candidato/<tu-id>`, URL HTTP del ALB, enlace al workflow de Actions exitoso, y un breve resumen (camino, arquitectura, IAM/secretos). Si hiciste plus, indícalo.

Los accesos AWS e invitación al repo se envían por correo. El IAM exige tags
`ethos:candidate=<tu-id>` y `ethos:project=devops-test`; sin ellos no podrás crear/operar.
No listarás clusters ECS/EKS ajenos. Detalle (roles por CLI, etc.) en la guía local.
