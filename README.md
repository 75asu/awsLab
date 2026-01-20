## Project 1 — Terraform AWS Bootstrap + “Hello Infra” Workload

### Workload

**Deploy a tiny “hello” container** (your own or public) behind a simple endpoint.

Fastest path: use a public container image (e.g., nginx) just to validate VPC + routing + SGs.

### Infra you build

* IAM baseline roles (admin break-glass, CI role)
* Terraform remote state: S3 + DynamoDB lock
* Minimal VPC (public/private subnets + NAT + routes)
* Standard tags + outputs

### Validation checklist (demo-able)

* Terraform state is remote + locking works (two applies don’t corrupt state)
* You can reach the endpoint (even if it’s just nginx “welcome” page)
* All resources are tagged consistently

### Interview angle

“I started with **state + IAM + network** so everything after is safe and repeatable.”

---

## Project 2 — Production-ish VPC + Security + “Network Proof” Workload

### Workload

Keep the same simple container, but prove the **security boundaries**:

* public ALB
* private compute
* isolated DB subnet (even if DB not created yet)

### Infra you build (upgrade)

* 2–3 AZ VPC
* public subnets (ALB), private (compute), isolated (data)
* SG vs NACL usage
* VPC endpoints for S3/ECR to reduce NAT usage

### Validation checklist

* Tasks/services in private subnet still pull images (via NAT or endpoints)
* DB subnet has **no route to internet**
* Only ALB is internet-facing
* Security group rules are tight (no “open everything”)

### Interview angle

“Here’s how I prevent exfiltration and reduce NAT cost with endpoints.”

---

## Project 3 — ECS Fargate + ALB + Real App (you can show a URL)

### Workload (pick ONE)

Option A (AWS official learning repo — perfect for interview):

* **aws-samples/amazon-ecs-for-beginners-catsdogs** ([GitHub][1])

Option B (more “web app” shaped):

* **aws-samples/drupal-on-ecs-fargate** ([GitHub][2])

### Infra you build

* ECR (if building your own image)
* ECS cluster + Fargate service
* ALB with path routing
* Autoscaling policy

### Validation checklist

* You have a public ALB URL and the app responds
* Rolling deploy works (update image tag → service updates)
* Autoscaling triggers under load (even CPU-based is fine)

### Interview angle

“I can deploy real services to AWS using Terraform, with safe rollouts + scaling.”

---

## Project 4 — Observability + Real Signals (logs/metrics/alerts)

### Workload

Use the same ECS service from Project 3.

### Infra you build

* CloudWatch log group + retention policy
* Alarms: 5xx rate, target response time, CPU high, memory high
* (Optional) Container Insights / dashboards

### Validation checklist

* You can show:

  * structured logs in CloudWatch
  * a dashboard with latency + errors
  * at least one alarm that you intentionally trigger (load test → alarm fires)

### Interview angle

“I don’t just ‘deploy’—I make it observable and operable.”

---

## Project 5 — RDS Postgres + Redis + A Real API that uses both

This one is **extremely aligned** with their requirement (Redis + Postgres). 

### Workload (pick ONE)

* **mbaneshi/FastAPI-SQLModel-PostgreSQL-and-Redis** ([GitHub][3])
  or
* **Forture128/fastapi-redis-demo** (more Redis patterns) ([GitHub][4])
  or
* **benavlabs/FastAPI-boilerplate** ([GitHub][5])

### Infra you build

* RDS Postgres (private subnet, Multi-AZ if you can afford)
* ElastiCache Redis (private subnet)
* ECS service connects to both (via security groups)
* Secrets: use SSM Parameter Store or Secrets Manager (either is fine)

### Validation checklist

* API endpoint that:

  * reads/writes Postgres
  * caches a hot read in Redis
* You can show cache hit/miss effect (latency drops on second request)
* Backups enabled, SGs locked (no public DB)

### Interview angle

“This mirrors real backend infra: DB + cache + secure connectivity.”

---

## Project 6 — Event-Driven Pipeline (most similar to on-chain listeners)

### Workload (best match)

* **aws-samples/amazon-kinesis-data-processor-aws-fargate** ([GitHub][6])
  (Producer + consumer on Fargate for Kinesis streams)

If you want SQS instead: you can swap Kinesis with SQS, but Kinesis maps better to “streaming listeners”.

### Infra you build

* Kinesis stream (or SQS)
* Producer service (writes events)
* Consumer service (processes events)
* DLQ (or dead-letter pattern)
* Metrics: lag/backlog, error count

### Validation checklist

* You can generate events and watch them processed end-to-end
* You can force failures and see retries / DLQ behavior
* You can answer: “how do you ensure idempotency?”

### Interview angle

“This is exactly how I’d structure Solana listeners/indexers as a reliable pipeline.”

---

## Project 7 — Terraform CI/CD + Guardrails (now with real deployments)

### Workload

Use *your* infra repo (Terraform) + the app deployments above.

### CI pipeline you build

* PR: fmt + validate + plan (post plan to PR)
* main: manual approval → apply
* environment separation (workspaces or separate states)
* Guardrail:

  * simplest: deny “0.0.0.0/0 to DB”
  * better: OPA/Conftest or tflint + checkov (optional)

### Validation checklist

* You can show a PR that changes infra and produces a plan
* Apply is controlled (approval / protected branches)
* “Bad change” gets blocked by guardrail

### Interview angle

“I run infra changes like software changes: reviewable, auditable, reversible.”

---

## Project 8 — Game Day (prove reliability, not just “it works”)

### Workload

Use the ECS app + the DB/cache app.

### Tests

* Load test ALB (k6/hey)
* Kill tasks and confirm health checks recover
* DB failover (if Multi-AZ) or simulate connection drops
* Show autoscaling + alerting

### Output artifact (super useful in interviews)

A one-pager called: **“Production Readiness Notes”**

* SLOs you picked (e.g., 99.9% API availability)
* key alarms
* key runbooks (“High 5xx”, “DB connections exhausted”)
* cost levers (NAT, log retention, instance sizing)
