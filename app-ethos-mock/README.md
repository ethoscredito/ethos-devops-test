# app-ethos-mock

Aplicación mock de la prueba DevOps (Nginx + Docker). La guía completa está en la interfaz web (`html/index.html`).

## Local

```bash
git clone https://github.com/ethoscredito/ethos-devops-test.git
cd ethos-devops-test/app-ethos-mock
docker compose up --build
```

Abre **http://localhost:8081** y sigue la guía (tags IAM, roles por CLI, ECS o Kubernetes + GitHub Actions).

Endpoints: `GET /health`, `GET /ready`.

# ME ENCONTRE CON DEMASIADOS ERRORES DE PERMISOS AL QUERER USAR EL MODULO DE VPC Y DE EKS PARA CONSTRUIR EL CAMINO B
# INTENTE EL CAMINO A PERO DE IGUAL MANERA MUCHOS ERRORES DE PERMISOS QUE NO ME PERMITIERON REALIZAR LA ACTIVIDAD