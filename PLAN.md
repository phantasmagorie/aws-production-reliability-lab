# PLAN

Living tracker for the AWS Production Reliability Lab.

Last updated: 2026-08-11

Legend: `[ ]` todo | `[~]` in progress | `[x]` done | `[!]` blocked

## Where we are

Milestone **M0 - Preflight and guardrails**, effectively complete but not yet
signed off. Two items remain open, one of them blocking.

**No billable AWS resource exists.** Verified 2026-08-11T09:44:10Z across seven
resource classes - NAT gateways, load balancers, RDS instances, Elastic IPs, ECS
clusters, ECR repositories and non-default VPCs all report zero
(`evidence/m0-preflight/04-resource-inventory.txt`). The account holds identity,
budget and tagging configuration only, none of which bills.

The M0 baseline runs eight automated checks against the account, captured in
`evidence/m0-preflight/00-summary.txt`. Findings are carried as explicit accepted risks
with an owner and a target date rather than quietly deferred. Findings specific to this
account are tracked privately.

What comes next, in order:

1. Close the identity hardening item tracked privately. It exposed a measurement gap
   worth stating: the baseline's second-factor row reads the root flag only, and the
   administrative identity is an Identity Center directory user, so that row turning
   green would not by itself prove the administrative identity is covered.
2. Create the public GitHub remote and push. The repository is local-only today.
3. Sign off M0, then start M1 and provision the first NAT Gateway, which is the
   first resource in this project that bills by the hour.

## Milestone overview

Hours are estimates for a single operator, not measurements.

| Milestone | Status | Est. hours | Bills while running |
|---|---|---|---|
| M0 - Preflight and guardrails | `[~]` | 6 | nothing |
| M1 - Network foundation | `[ ]` | 8-10 | NAT Gateway, Elastic IP |
| M2 - Application platform | `[ ]` | 14-18 | + ALB, Fargate tasks, ECR storage |
| M3 - Database layer | `[ ]` | 12-16 | + RDS instance, RDS storage, secrets |
| M4 - Observability and incident ops | `[ ]` | 12-16 | + alarms, dashboards, log storage |
| M5 - Infrastructure as code | `[ ]` | 16-20 | same stack, plus remote state bucket and lock table |
| M6 - Reusability proof | `[ ]` | 8-10 | + second workload's tasks and target group |

RDS storage is the one line item that keeps billing after the instance is
stopped. Per-resource list prices and the destroy policy live in
`docs/cost-controls.md`; teardown is the primary cost control, and the budget
alert is only the second line of defence.

## M0 - Preflight and guardrails

**Dependency:** none, this is the entry point.
**Exam domain:** primarily Domain 4 (Security and Compliance), with the evidence
tooling feeding Domain 1.
**Gate:** M1 does not start until 0.1a, 0.1b and 0.2 below are closed, because the
first NAT Gateway is also the first hourly charge. Note that 0.1b cannot currently
be verified at all - see 0.18 - so "all checks pass" is not yet the same as "the
account is protected".

| # | Task | Status | Acceptance criteria |
|---|---|---|---|
| 0.1a | Root identity second factor | `[~]` | Tracked privately; acceptance criteria and target date held outside this repository |
| 0.1b | Administrative identity second factor | `[~]` | Tracked privately. The measurement gap is the publishable finding: `AccountMFAEnabled` is an IAM root flag, and the administrative identity is an Identity Center directory user rather than an IAM user (`IAM users: 0`), so it can never appear in `get-account-summary`. Needs 0.18 first |
| 0.2 | Create the public GitHub remote and push | `[ ]` | `git remote -v` resolves; history pushed; no secret or personal figure present in any reachable commit |
| 0.3 | M0 acceptance review | `[~]` | This PLAN.md and `docs/skills-demonstrated.md` exist and every claim traces to a file; 0.1 and 0.2 closed |
| 0.4 | Scaffold repository, guardrails and initial state | `[x]` | Directory skeleton, secret-denying `.gitignore`, README, `PROJECT_STATE.md` committed (`fadcb0d`) |
| 0.5 | Confirm account baseline: root holds no access keys | `[x]` | `AccountAccessKeysPresent` = 0, recorded in `evidence/m0-preflight/02-account-security.txt` |
| 0.6 | IAM Identity Center instance created and active | `[x]` | Instance reports `ACTIVE` in `evidence/m0-preflight/02-account-security.txt`. The organization-instance type and the us-east-1 primary Region are recorded in prose only (`PROJECT_STATE.md`, `docs/adr/0001-aws-region.md`) and are not proven by any captured output - see 0.17 |
| 0.7 | Federated admin identity via permission set, 8h session | `[x]` | Caller identity resolves to an `assumed-role` ARN, not an IAM user; 0 IAM users on the account |
| 0.8 | CLI profile `lab` over SSO, no static credentials on disk | `[x]` | `evidence/m0-preflight/01-identity.txt` shows the assumed-role ARN |
| 0.9 | Remove the `[default]` profile so unqualified commands fail closed | `[x]` | Negative control recorded: the same call without `--profile` returns `NoCredentials` |
| 0.10 | Monthly cost budget with three alert thresholds | `[x]` | API confirms 50% actual, 80% actual, 100% forecasted (`evidence/m0-preflight/03-cost-controls.txt`) |
| 0.11 | ADR-0001 records the region decision | `[x]` | Alternatives, trade-offs and the irreversible element documented (`docs/adr/0001-aws-region.md`) |
| 0.12 | Tagging convention and destroy policy | `[x]` | Four mandatory tags defined, `managed-by` identifies console-created resources (`docs/cost-controls.md`) |
| 0.13 | Keep personal financial figures out of committed content | `[x]` | Redacted in `e4dd52c` while the repository was still local-only; no monetary ceiling in any reachable commit |
| 0.14 | Reusable, masked evidence capture script | `[x]` | `scripts/capture-evidence.sh` writes five files per milestone, masks 12-digit account IDs and directory IDs, emits a PASS/FAIL table |
| 0.15 | Zero-billable-resource baseline before provisioning | `[x]` | Seven resource classes all report zero (`evidence/m0-preflight/04-resource-inventory.txt`) |
| 0.16 | Confirm zero customer managed KMS keys | `[x]` | `kms list-keys` returns `[]` (`evidence/m0-preflight/02-account-security.txt`), so no per-key monthly charge exists. This is a key-inventory fact and its cost consequence; it is not on its own proof of the Identity Center replication configuration |
| 0.17 | Close the Identity Center evidence gap | `[ ]` | Widen the `sso-admin list-instances` projection to include `OwnerAccountId` and `IdentityStoreId`, and capture the primary Region explicitly, so 0.6's instance type and Region stop being prose-only. The instance ARN carries no Region, so it cannot supply this |
| 0.18 | Give the administrative identity a defined second-factor check | `[ ]` | Baseline queries Identity Center MFA state, so 0.1b has a proof condition instead of none. Until then an all-pass summary would not cover that identity |

## M1 - Network foundation

**Dependency:** M0 signed off.
**Exam domain:** Domain 5 (Networking and Content Delivery).

| # | Task | Status | Acceptance criteria |
|---|---|---|---|
| 1.1 | CIDR plan and port matrix, written before any resource | `[ ]` | Every subnet range and every allowed source/destination/port pair documented and non-overlapping |
| 1.2 | VPC `10.20.0.0/16` with six subnets across two AZs | `[ ]` | Two public, two private-app, two isolated-db subnets, symmetric across both AZs |
| 1.3 | Internet Gateway and route tables | `[ ]` | Public subnets route `0.0.0.0/0` to the IGW; isolated-db subnets have no route to the internet by any path |
| 1.4 | Security group chain | `[ ]` | ALB SG -> app SG -> db SG, each rule sourced from the previous group's ID, never from a CIDR |
| 1.5 | NAT Gateway - first billable resource | `[ ]` | Private-app subnets reach the internet outbound; creation timestamp recorded so cost is attributable |
| 1.6 | Positive and negative reachability tests | `[ ]` | Permitted path succeeds **and** forbidden path fails, both captured as evidence. A test suite with no negative case does not pass |
| 1.7 | Route failure drill | `[ ]` | Remove or break the NAT route, observe and record the failure signature, restore, document detection method |
| 1.8 | Evidence capture and teardown | `[ ]` | `./scripts/capture-evidence.sh m1-network` committed; post-teardown inventory returns to all zeros |

## M2 - Application platform

**Dependency:** M1 network exists.
**Exam domain:** Domain 3 (Deployment, Provisioning, and Automation), with the
drills feeding Domain 2.

| # | Task | Status | Acceptance criteria |
|---|---|---|---|
| 2.1 | Java/Spring Boot API | `[ ]` | Health endpoint, CRUD resource, one deliberately slow endpoint, structured logs with a correlation field |
| 2.2 | Docker image | `[ ]` | Builds reproducibly, runs as a non-root user, health endpoint responds in a local container |
| 2.3 | ECR repository and push | `[ ]` | Image pushed with an immutable tag; image scanning result recorded |
| 2.4 | ECS Fargate service | `[ ]` | Tasks run in private-app subnets with no public IP, desired count met |
| 2.5 | ALB with health checks | `[ ]` | Target group healthy; a task failing its health check is replaced without operator action |
| 2.6 | Separate task execution role and task role | `[ ]` | Execution role pulls the image and writes logs; task role carries only application permissions. Distinction explained, not just configured |
| 2.7 | CloudWatch log group | `[ ]` | Application logs queryable by correlation field in Logs Insights |
| 2.8 | Rolling deploy and rollback | `[ ]` | Deploy a new revision with no dropped requests; roll back to the previous task definition and record both durations |
| 2.9 | Task-kill drill | `[ ]` | Stop a running task; record detection time, replacement time, and whether any request failed |
| 2.10 | Unhealthy-target drill | `[ ]` | Force a target unhealthy; record deregistration behaviour and client-visible impact |
| 2.11 | Evidence capture and teardown | `[ ]` | `m2-platform` evidence committed; inventory returns to zeros |

## M3 - Database layer

**Dependency:** M2 platform runs.
**Exam domain:** Domain 2 (Reliability and Business Continuity).

| # | Task | Status | Acceptance criteria |
|---|---|---|---|
| 3.1 | RDS PostgreSQL in isolated subnets | `[ ]` | Not publicly accessible; reachable only from the app security group |
| 3.2 | Credentials in Secrets Manager | `[ ]` | No password in task definition, environment variable, repository or shell history; task role reads the secret at runtime |
| 3.3 | Encryption at rest and SSL in transit | `[ ]` | Storage encrypted; server rejects a non-SSL connection attempt, and that rejection is captured |
| 3.4 | Parameter group tuning | `[ ]` | Custom parameter group attached; each changed parameter has a written reason |
| 3.5 | Enable `pg_stat_statements` | `[ ]` | Extension active; top queries by total time captured before and after tuning |
| 3.6 | Backup and restore | `[ ]` | Point-in-time restore to a new instance succeeds; measured restore duration recorded, not estimated |
| 3.7 | Failover behaviour | `[ ]` | Reboot with failover; record application-visible downtime and connection-pool recovery |
| 3.8 | Connection pool tuning | `[ ]` | Pool sized against `max_connections` with headroom; before/after measurements under load |
| 3.9 | Drill: slow query | `[ ]` | Slow endpoint reproduces the symptom; diagnosed from `pg_stat_statements`, not from the source code |
| 3.10 | Drill: lock contention | `[ ]` | Blocking session identified via `pg_locks`/`pg_stat_activity`; resolution documented |
| 3.11 | Drill: connection saturation | `[ ]` | Exhaust the pool; record the client-visible error and the metric that revealed it first |
| 3.12 | Drill: autovacuum and bloat | `[ ]` | Generate bloat, observe autovacuum, record table growth and reclaim |
| 3.13 | Evidence capture and teardown | `[ ]` | `m3-database` evidence committed; final snapshot decision recorded, since storage bills after stop |

## M4 - Observability and incident ops

**Dependency:** M3 database runs, so drills have a full stack to break.
**Exam domain:** Domain 1 (Monitoring, Logging, Analysis, Remediation,
Performance Optimization).

| # | Task | Status | Acceptance criteria |
|---|---|---|---|
| 4.1 | Dashboards per layer | `[ ]` | ALB, ECS and RDS on one view; a reader can locate the failing layer without opening the console elsewhere |
| 4.2 | Actionable alarms only | `[ ]` | Every alarm names the runbook it triggers. An alarm with no action is deleted, not tolerated |
| 4.3 | Metric filters from logs | `[ ]` | Error-rate metric derived from structured logs; alarm fires on the filter |
| 4.4 | Logs Insights query library | `[ ]` | Saved queries for latency outliers, error bursts and a single request's path across layers |
| 4.5 | Load test | `[ ]` | Baseline and saturation runs; recorded p50, p95, p99 and error rate at each level |
| 4.6 | Detection and recovery timestamps | `[ ]` | Every drill records fault-injected, first-signal, alarm-fired and recovered times. Time-to-detect is computed, not guessed |
| 4.7 | Severity model | `[ ]` | Sev1-Sev3 defined by user-visible impact, with response expectation per level |
| 4.8 | Runbooks | `[ ]` | One runbook per alarm in `runbooks/`, each with symptom, checks, remedy, escalation, verification |
| 4.9 | Blameless postmortem | `[ ]` | One drill written up in `postmortems/`: timeline, impact, contributing factors, no individual blamed |
| 4.10 | Corrective actions | `[ ]` | Each postmortem action either implemented and linked, or explicitly declined with a reason |

## M5 - Infrastructure as code

**Dependency:** M1-M4 built by hand first, so the code encodes understood
decisions rather than guesses.
**Exam domain:** Domain 3 (Deployment, Provisioning, and Automation).

**Hard rule:** CloudFormation and Terraform never manage the same live resource
at the same time. Migrating a resource between them means a full teardown, or a
deliberate import with the other tool's control removed first.

| # | Task | Status | Acceptance criteria |
|---|---|---|---|
| 5.1 | CloudFormation stack for the network layer | `[ ]` | `10.20.0.0/16` VPC and subnets reproduced from template; deployed with a change set reviewed before execution |
| 5.2 | Deliberate rollback exercise | `[ ]` | Push a failing update; observe automatic rollback; record the resource states during it |
| 5.3 | Terraform modules | `[ ]` | `network`, `platform`, `database` modules composable independently |
| 5.4 | Remote state, encrypted, with locking | `[ ]` | State in S3 with encryption enabled; concurrent apply is refused by the lock |
| 5.5 | Typed variables and validation | `[ ]` | Every variable typed with description; invalid CIDR rejected at plan time, not at apply time |
| 5.6 | CI checks | `[ ]` | `fmt`, `validate`, `plan` and a security scan run in `.github/workflows/`; a bad plan fails the build |
| 5.7 | Drift detection | `[ ]` | Change a resource by hand, detect the drift by tooling, then reconcile |
| 5.8 | Import exercise | `[ ]` | Bring one console-created resource under Terraform; plan shows no diff afterwards |

## M6 - Reusability proof

**Dependency:** M5 modules exist.
**Exam domain:** Domain 3, with the shared-versus-per-workload boundary feeding
Domain 2.

| # | Task | Status | Acceptance criteria |
|---|---|---|---|
| 6.1 | Deploy a second workload from the same modules | `[ ]` | Second service runs behind the same ALB or its own, with no module source edited - inputs only |
| 6.2 | Document what changes per application | `[ ]` | Table separating per-workload inputs from shared infrastructure |
| 6.3 | Identify the shared-failure boundary | `[ ]` | State plainly which shared components take both workloads down together |
| 6.4 | Extensions chosen by ADR | `[ ]` | Any further service (CDN, queue, cache, EKS) gets an ADR with alternatives first. Nothing is added because it is expected on a resume |

## Certification mapping

Target: **AWS Certified CloudOps Engineer - Associate (SOA-C03)**, formerly AWS
Certified SysOps Administrator - Associate (SOA-C02).

Containers (ECS, EKS, ECR) and IaC tooling (CDK, Terraform, Git) entered scope
with SOA-C03 and were absent from SOA-C02. M2, M5 and M6 exist largely because of
that change, and older SOA-C02 study material does not cover them.

| Domain | Weight | Milestones | What proves it |
|---|---|---|---|
| 1 - Monitoring, Logging, Analysis, Remediation, Performance Optimization | 22% | M4, with inputs from M2 and M3 | Dashboards, log-derived metric filters, measured p50/p95/p99, computed time-to-detect |
| 2 - Reliability and Business Continuity | 22% | M3, M6, drills in M1 and M2 | Measured restore and failover, task-kill and unhealthy-target recovery, stated shared-failure boundary |
| 3 - Deployment, Provisioning, and Automation | 22% | M2, M5, M6 | Rolling deploy and rollback, change sets, Terraform modules with locked remote state, drift and import |
| 4 - Security and Compliance | 16% | M0, M3, threaded through M1 and M2 | Federated short-lived credentials, fail-closed CLI, split execution/task roles, secrets never in source, encryption in transit and at rest |
| 5 - Networking and Content Delivery | 18% | M1 | CIDR and port matrix, three-tier subnet isolation, security group chaining, negative reachability tests |

Weights sum to 100%. Domain 4 is the only one with committed evidence today; the
remaining four are planned and currently unproven, which is exactly what
`docs/skills-demonstrated.md` records.

- **M8 — EKS comparison module (optional).** Runs the same reference workload on
  Amazon EKS and records the measured difference against ECS Fargate: control plane
  cost, cluster lifecycle time, IAM model (task roles against IRSA), ingress path and
  operational surface. The point is a defensible answer to "when is each one correct",
  not a second deployment. Requires M2 through M5 finished on ECS first, otherwise
  there is no baseline to compare against. Optional and unscoped.

- **M8 — modulo de comparacao com EKS (opcional).** Executa a mesma aplicacao de
  referencia no Amazon EKS e registra a diferenca medida contra o ECS Fargate: custo
  de control plane, tempo de ciclo de vida do cluster, modelo de IAM (task roles
  contra IRSA), caminho de ingress e superficie operacional. O objetivo e uma resposta
  defensavel para "quando cada um e a escolha certa", nao um segundo deploy. Exige M2
  ate M5 concluidos em ECS antes, caso contrario nao existe linha de base para
  comparar. Opcional e sem escopo definido.

## Candidate modules, not committed

- **M7 — incident triage assistant (Amazon Bedrock).** Reads CloudWatch alarms, ECS
  service events and PostgreSQL statistics, then drafts an incident timeline with
  hypotheses ranked by evidence and links the matching runbook. Read-only credentials,
  no remediation actions. Depends on M2 through M4 producing real telemetry first.
  Scope deliberately undefined: parked as an idea, not adopted as a plan.

- **M8 — EKS comparison module (optional).** Runs the same reference workload on
  Amazon EKS and records the measured difference against ECS Fargate: control plane
  cost, cluster lifecycle time, IAM model (task roles against IRSA), ingress path and
  operational surface. The point is a defensible answer to "when is each one correct",
  not a second deployment. Requires M2 through M5 finished on ECS first, otherwise
  there is no baseline to compare against. Optional and unscoped.

## Modulos candidatos, sem compromisso

- **M7 — assistente de triagem de incidentes (Amazon Bedrock).** Le alarmes do
  CloudWatch, eventos de servico do ECS e estatisticas do PostgreSQL, e rascunha uma
  timeline de incidente com hipoteses ordenadas por evidencia, ligando ao runbook
  correspondente. Credenciais somente leitura, sem acoes de remediacao. Depende de M2
  ate M4 produzirem telemetria real antes. Escopo deliberadamente indefinido:
  estacionado como ideia, nao adotado como plano.

- **M8 — modulo de comparacao com EKS (opcional).** Executa a mesma aplicacao de
  referencia no Amazon EKS e registra a diferenca medida contra o ECS Fargate: custo
  de control plane, tempo de ciclo de vida do cluster, modelo de IAM (task roles
  contra IRSA), caminho de ingress e superficie operacional. O objetivo e uma resposta
  defensavel para "quando cada um e a escolha certa", nao um segundo deploy. Exige M2
  ate M5 concluidos em ECS antes, caso contrario nao existe linha de base para
  comparar. Opcional e sem escopo definido.

- **M9 — EC2 host operations (optional, post-project).** Fargate abstracts the
  operating system, so nothing in M0 through M6 exercises host-level administration.
  This module closes that gap deliberately: one `t4g.micro` instance (~USD 0.008/h),
  access through SSM Session Manager rather than SSH or a public address, patching
  through Systems Manager Patch Manager, and log analysis on the host itself. Roughly
  six hours, cents of spend, and the instance is destroyed at the end of each window.
  The point is to be able to answer a host troubleshooting question with evidence
  instead of declaring the gap and stopping there. Runs after the main track, since it
  competes with nothing on the certification path.

- **M9 — operacao de host EC2 (opcional, pos-projeto).** O Fargate abstrai o sistema
  operacional, entao nada entre M0 e M6 exercita administracao no nivel do host. Este
  modulo fecha essa lacuna de forma deliberada: uma instancia `t4g.micro` (~USD
  0,008/h), acesso via SSM Session Manager em vez de SSH ou endereco publico, patching
  via Systems Manager Patch Manager, e analise de log no proprio host. Cerca de seis
  horas, centavos de gasto, e a instancia e destruida ao fim de cada janela. O objetivo
  e conseguir responder uma pergunta de troubleshooting de host com evidencia, em vez
  de apenas declarar a lacuna. Roda depois da trilha principal, ja que nao compete com
  nada no caminho da certificacao.
