# PROJECT_STATE

Updated: 2026-08-11
Milestone: M0 - Preflight and guardrails

## Done
- Existing AWS account; root user has no access keys
- IAM Identity Center: organization instance, primary region us-east-1,
  Single-Region configuration (verified: 0 customer managed KMS keys)
- Federated user with AdministratorAccess permission set, 8h session
- CLI profile "lab" via SSO. No static credentials on disk.
- [default] profile removed from ~/.aws/config, so any command without
  --profile fails loudly instead of silently using root (validated)
- Monthly cost budget configured in AWS Budgets with alerts at
  50% actual, 80% actual, 100% forecasted
- ADR-0001 records the us-east-1 decision; docs/cost-controls.md records
  the tagging convention and destroy policy

## Accepted risk
- Identity hardening for the root and administrative identities is tracked privately,
  outside this repository, together with its verification procedure and target date.

## Next actions
- Reusable evidence capture script under scripts/
- M0 acceptance review
- Phase 1: network foundation

## Cost
No billable resources exist.

## M1 network foundation, complete 2026-08-19

Built and verified, all resources free and still present:

- VPC 10.20.0.0/16, DNS hostnames and DNS support both enabled
- Six /24 subnets across us-east-1a and us-east-1b, auto-assign public IP disabled on
  every one of them, including the public tier
- Internet gateway attached
- Four route tables, one per behaviour: public reaches the internet through the gateway,
  the two application tables take a NAT route only while a test window is open, and the
  database table holds the local route alone and never leaves the VPC
- Security group chain alb 443 from the internet, app 8080 from the alb group, db 5432
  from the app group. The inner two reference groups rather than address ranges
- IAM role lab-ec2-ssm with AmazonSSMManagedInstanceCore, plus its instance profile

Verified, with evidence in evidence/m1-network/:

- Positive path: an instance in lab-app-a with no public address appeared to an external
  endpoint as the NAT gateway public address. Route, translation and return path proven
  in a single measurement
- Negative path: an identical instance in lab-db-a, same image, type and instance
  profile, never registered with Systems Manager. The subnet was the only variable
- Route failure drill: default route removed at 14:25:26Z and restored at 14:26:17Z
  against a 2 second probe. Fifty seconds of observed unavailability across ten failed
  requests

Deliberately absent: no NAT gateway, no Elastic IP and no instances persist between
sessions. Recreating them is part of opening a test window.

Next: M2 application platform. Java API, ECR, ECS Fargate behind an ALB, separate task
execution and task roles.

## M1 network foundation, complete 2026-08-19

Built and verified, all resources free and still present:

- VPC 10.20.0.0/16, DNS hostnames and DNS support both enabled
- Six /24 subnets across us-east-1a and us-east-1b, auto-assign public IP disabled on
  every one of them, including the public tier
- Internet gateway attached
- Four route tables, one per behaviour: public reaches the internet through the gateway,
  the two application tables take a NAT route only while a test window is open, and the
  database table holds the local route alone and never leaves the VPC
- Security group chain alb 443 from the internet, app 8080 from the alb group, db 5432
  from the app group. The inner two reference groups rather than address ranges
- IAM role lab-ec2-ssm with AmazonSSMManagedInstanceCore, plus its instance profile

Verified, with evidence in evidence/m1-network/:

- Positive path: an instance in lab-app-a with no public address appeared to an external
  endpoint as the NAT gateway public address. Route, translation and return path proven
  in a single measurement
- Negative path: an identical instance in lab-db-a, same image, type and instance
  profile, never registered with Systems Manager. The subnet was the only variable
- Route failure drill: default route removed at 14:25:26Z and restored at 14:26:17Z
  against a 2 second probe. Fifty seconds of observed unavailability across ten failed
  requests

Deliberately absent: no NAT gateway, no Elastic IP and no instances persist between
sessions. Recreating them is part of opening a test window.

Next: M2 application platform. Java API, ECR, ECS Fargate behind an ALB, separate task
execution and task roles.
