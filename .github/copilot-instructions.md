<!-- Copilot / AI agent instructions for contributors working in this repository -->
# Repo-specific AI assistant guidance

This file contains concise, action-oriented notes to help an AI coding agent be productive in this repository.

1) Big-picture architecture
- **Microservices:** three services: `product-service` (FastAPI, port 8001), `inventory-service` (Go, port 8002) and `api-gateway` (Go, port 8000). See `product-service/main.py`, `inventory-service/main.go`, `api-gateway/main.go`.
- **Data stores:** PostgreSQL for persistent data; Redis for caching. DB schema and seed data in `init.sql`.
- **Deployment:** local orchestration via `docker-compose.yml`. Cloud infra via Terraform in `infra/` (creates VPC, RDS, ECR repos, ECS cluster, ALB). See `infra/main.tf` and `infra/envs/*.tfvars`.
- **Service discovery:** When deployed to ECS, services are referenced by service names (Terraform sets `PRODUCT_SERVICE_URL = "http://product-service:8001"`). In `docker-compose.yml` service names differ (`product_service`); be careful when mapping local vs cloud env values.

2) How to run and debug locally (most-common flows)
- Bring up all dependencies quickly: `docker-compose up --build` from the repo root. This starts Postgres, Redis, and the three services. Files: `docker-compose.yml`, `init.sql`.
- Run a single service locally:
  - Product service: `cd product-service && pip install -r requirements.txt && uvicorn main:app --reload --port 8001`
  - Inventory service: `cd inventory-service && go run main.go` (or `go build && ./inventory-service`).
  - API gateway: `cd api-gateway && go run main.go` (or build binary via `go build`).
- Useful endpoints: health checks at `/health` on each service (8000, 8001, 8002). The API gateway exposes proxied APIs under `/api/*` and a special aggregator `/api/products-full` (supports `?force_refresh=true`).

3) Build, container, and deploy notes
- Dockerfiles are multi-stage and create non-root `appuser` users. See `api-gateway/Dockerfile`, `inventory-service/Dockerfile`, `product-service/Dockerfile`.
- Local image build & test: `docker build -t product-service:local ./product-service` then run with env vars as in `docker-compose.yml`.
- Terraform workflow (in `infra/`):
  - `cd infra`
  - `terraform init`
  - `terraform apply -var-file=envs/dev.tfvars`
- Terraform creates ECR repositories for `api-gateway`, `product-service`, `inventory-service` — push images to the created ECR repos after authenticating (`aws ecr get-login-password ... | docker login ...`) and tag images to the repository URL (shown in Terraform outputs).

4) Project-specific conventions & patterns
- **Caching keys & invalidation patterns:**
  - Product service uses keys like `product:{id}` and `products:all` (and `products:all:{category}`).
  - Inventory service uses keys like `inventory:{id}`, `inventory:all`, `inventory:product:{product_id}`.
  - API gateway caches aggregated responses with keys like `gateway:product_full:{id}` and `gateway:products_full:all`.
  - When mutating resources, services actively invalidate caches. See `product-service` (after create/update/delete) and `inventory-service.invalidateInventoryCaches` which also removes related gateway/product cache keys.
- **Force-refresh:** The gateway supports `?force_refresh=true` on `/api/products-full` to bypass cache — useful for testing.
- **DB connection strings:** Local `docker-compose.yml` uses plain local connection strings (no ssl). Terraform sets RDS connection strings with `sslmode=require` — be explicit when testing locally vs cloud.
- **Healthchecks:** Dockerfiles embed `HEALTHCHECK` commands mirroring `/health` endpoints. Use them for container readiness checks.

5) Key files to reference for patterns and examples
- `api-gateway/main.go` — routing, proxy logic, Redis caching, embedding frontend (`static/index.html`).
- `product-service/main.py` — FastAPI endpoints, asyncpg usage, Redis caching, Pydantic models.
- `inventory-service/main.go` — PostgreSQL usage, cache invalidation helpers, example SQL queries.
- `init.sql` — DB schema and seed data used by `docker-compose`.
- `docker-compose.yml` — canonical local dev startup and environment variable examples.
- `infra/` — Terraform modules and environment `.tfvars`; study `infra/main.tf` for deployment wiring (ECR, ECS, RDS, ALB).

6) Things to watch out for (gotchas discovered in the codebase)
- Service name mismatch: local compose uses `product_service`, but Terraform/ECS expects `product-service`. When switching contexts, verify `PRODUCT_SERVICE_URL` and `INVENTORY_SERVICE_URL` values.
- Secrets are currently embedded in Terraform resources (RDS username/password in `infra/main.tf`). Treat as discoverable configuration; do not assume secret management is implemented.
- Caching means tests can get stale results — use `?force_refresh=true` on the gateway or invalidate cache keys when writing integration tests.

7) What to do when adding or modifying services
- Preserve cache key conventions when changing data shapes. If you change a product representation, update both product-service cache keys and gateway aggregation code (`api-gateway/getProductWithInventory`, `getAllProductsWithInventory`).
- When adding a new service make sure to:
  - Add an ECR repo name in `infra/main.tf` `aws_ecr_repository.repos` set.
  - Wire the service into the ECS `services` module with proper `env_vars`, `subnets`, and `security_groups`.

8) Quick examples (copyable)
- Start full stack locally:
  ```bash
  docker-compose up --build
  ```
- Start product service locally (fast iteration):
  ```bash
  cd product-service
  pip install -r requirements.txt
  uvicorn main:app --reload --port 8001
  ```
- Apply Terraform (dev):
  ```bash
  cd infra
  terraform init
  terraform apply -var-file=envs/dev.tfvars
  ```

9) If you need more context
- Ask for pointers to specific terraform module files (e.g., `modules/ecs-service`) if you want examples of how task definitions and container definitions are modeled.
- If you want an E2E runbook (CI/CD, build->push->deploy), say so and I will produce step-by-step commands to build/tag/push images and update ECS services.

---
If anything above is unclear or you want additional examples (CI snippets, more Terraform push commands, or sample integration tests), tell me which section to expand. 
