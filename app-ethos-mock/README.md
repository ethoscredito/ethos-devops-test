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
