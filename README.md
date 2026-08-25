# AWS Production Reliability Lab

A production-like AWS platform: ALB to ECS Fargate to RDS PostgreSQL across two
Availability Zones, with least-privilege IAM and network boundaries, CloudWatch
observability, deliberate failure drills, incident runbooks, and infrastructure
as code (CloudFormation first, then Terraform).

**Status:** M1 network foundation complete and verified. M2 application platform
in progress. Nothing below is claimed without captured command output in
`evidence/`.

## The 60-second answers

**What problem does this environment simulate?**
A three-tier service where the database must never be reachable from the
internet, the application must never run with more privilege than it uses, and
every failure mode is triggered on purpose and measured rather than described.

**What is the architecture and why is each layer placed there?**
One VPC, `10.20.0.0/16`, two Availability Zones, six subnets in three tiers.
Public subnets hold the load balancer. Private application subnets hold the
Fargate tasks, which have no public address. Isolated database subnets hold no
route to the internet by any path. Traffic flows one direction only:
`internet -443-> ALB -8080-> ECS -5432-> RDS`.

**How do I deploy and destroy it?**
Infrastructure as code lands in M5. Until then the environment is built through
documented commands and destroyed at the end of every session. Teardown is the
primary cost control; the budget alert is the second line of defence.

**Which failure drills ran and what changed in the metrics?**
M1 route failure drill: the default route was removed at 14:25:26Z and restored
at 14:26:17Z against a two-second probe. Fifty seconds of observed
unavailability across ten failed requests. Further drills land in M2 and M3.

**Which risks were deliberately left out of scope?**
Kubernetes, multiple microservices, multi-region failover and service mesh. One
service proven end to end comes first. Host-level operating system
administration is absent by design, because Fargate abstracts it.

## What is built and verified

### M1 — network foundation

- VPC `10.20.0.0/16`, DNS hostnames and DNS support enabled
- Six `/24` subnets across two Availability Zones, auto-assign public IP
  disabled on every one of them, including the public tier
- Internet gateway attached; four route tables, one per behaviour. The database
  table holds the local route alone and never leaves the VPC
- Security group chain: ALB accepts 443 from the internet, the application tier
  accepts 8080 from the ALB group, the database tier accepts 5432 from the
  application group. The inner two reference security groups, not address ranges

Verified in both directions, evidence in `evidence/m1-network/`:

- **Permitted path.** An instance in the private application subnet, with no
  public address, appeared to an external endpoint as the NAT gateway address.
  Route, translation and return path proven in a single measurement.
- **Denied path.** An identical instance in the isolated database subnet, same
  image, type and instance profile, never registered with Systems Manager. The
  subnet was the only variable.
- **Route failure drill.** Documented above.

### M2 — application platform, in progress

- Java API with a health endpoint and a deliberately slow endpoint that returns
  both the delay it was asked for and the delay it actually observed, so
  application latency can be separated from infrastructure latency
- Multi-stage container build. The jar is compiled inside the build, so the
  image cannot ship a stale artifact from the machine that built it. The runtime
  stage starts from a JRE base and carries no compiler, no build tool and no
  source. Runs as an unprivileged account, uid 10001, verified in both
  directions
- Image published to ECR with immutable tags, scan-on-push and encryption at
  rest. 124 MB. Scan completed with no findings, which covers operating system
  packages and not the application's own dependencies
- ECS cluster and task definition registered with **separate task execution and
  task roles**. The execution role pulls the image and writes logs. The task
  role is the application's own identity and is deliberately empty until the
  application calls an AWS API in M3
- PrivateLink and gateway endpoints so tasks reach the registry without any
  route to the internet

Still open in M2: the running service, the load balancer, rolling deploy and
rollback, and the task-kill and unhealthy-target drills.

## Evidence discipline

An audit of an earlier revision found overclaims. These rules exist because of
that, and are enforced in `docs/operating-rules.md`:

- An inference is never written as if it were verified
- A resource existing is not proof it is configured correctly. Read the
  authoritative field, not an adjacent signal
- Validation runs both directions. A milestone is not done until its failure
  case has been tested
- No metric enters any document without a recorded measurement

## Cost control

Every billable resource is destroyed at the end of the session that needed it.
Anything left running carries a recorded reason. Per-resource list prices and
the destroy policy live in `docs/cost-controls.md`.

Cumulative spend to date is in the low cents.

## Certification mapping

Target: AWS Certified CloudOps Engineer Associate (SOA-C03). Containers and IaC
tooling entered scope with C03 and were absent from C02, which is why M2, M5 and
M6 exist. Domain mapping and current coverage are in `PLAN.md`.

## Repository layout

app/ Java API and Dockerfile
infra/cloudformation/ native AWS stacks
infra/terraform/ modules, state and environments
sql/ seed, slow query, diagnostics
load-test/ k6 and pgbench scripts
runbooks/ incident playbooks
postmortems/ failure-drill reports
docs/ architecture, threat model, cost controls, ADRs
evidence/ captured command output per milestone
scripts/ reusable evidence capture

