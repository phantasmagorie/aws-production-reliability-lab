#!/usr/bin/env bash
# Capture read-only AWS evidence for a milestone.
# Usage: ./scripts/capture-evidence.sh <milestone-id>
set -euo pipefail

MILESTONE="${1:-}"
PROFILE="lab"
[ -z "$MILESTONE" ] && { echo "usage: $0 <milestone-id>   e.g. m0-preflight"; exit 1; }

if ! aws sts get-caller-identity --profile "$PROFILE" >/dev/null 2>&1; then
  echo "SSO session expired. Run: aws sso login --profile $PROFILE"; exit 1
fi

OUT="evidence/$MILESTONE"
mkdir -p "$OUT"
MASK='s/[0-9]{12}/XXXXXXXXXXXX/g; s/d-[0-9a-f]{10}/d-XXXXXXXXXX/g'
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

q() { aws --profile "$PROFILE" "$@" 2>&1 || echo "ERROR: query failed"; }

echo "Capturing evidence for $MILESTONE ..."

{
  echo "# Identity"; echo "Captured: $TS"; echo
  echo "## Caller identity"
  q sts get-caller-identity
  echo
  echo "## Negative control: same call without --profile (must fail)"
  { aws sts get-caller-identity 2>&1 | tail -1; } || true
} | sed -E "$MASK" > "$OUT/01-identity.txt"

{
  echo "# Account security"; echo "Captured: $TS"; echo
  echo "Root MFA:                       $(st x "$(q iam get-account-summary --query 'SummaryMap.AccountMFAEnabled')" 1)"
  echo "Root access keys present:       $(q iam get-account-summary --query 'SummaryMap.AccountAccessKeysPresent')"
  echo "IAM users:                      $(q iam get-account-summary --query 'SummaryMap.Users')"
  echo "IAM roles:                      $(q iam get-account-summary --query 'SummaryMap.Roles')"
  echo
  echo "## Identity Center"
  q sso-admin list-instances --query 'Instances[].{Arn:InstanceArn,Status:Status}'
  echo
  echo "## Customer managed KMS keys (expected: none)"
  q kms list-keys --query 'Keys'
} | sed -E "$MASK" > "$OUT/02-account-security.txt"

ACCT=$(aws sts get-caller-identity --profile "$PROFILE" --query Account --output text)
{
  echo "# Cost controls"; echo "Captured: $TS"; echo
  echo "## Budgets (amount intentionally not recorded)"
  q budgets describe-budgets --account-id "$ACCT" \
    --query 'Budgets[].{Name:BudgetName,Period:TimeUnit,Type:BudgetType}'
  echo
  echo "## Alert thresholds"
  q budgets describe-notifications-for-budget --account-id "$ACCT" \
    --budget-name lab-monthly-ceiling \
    --query 'Notifications[].{Type:NotificationType,Op:ComparisonOperator,Threshold:Threshold}'
} | sed -E "$MASK" > "$OUT/03-cost-controls.txt"

NAT=$(q ec2 describe-nat-gateways --query 'length(NatGateways[?State!=`deleted`])')
ALB=$(q elbv2 describe-load-balancers --query 'length(LoadBalancers)')
RDS=$(q rds describe-db-instances --query 'length(DBInstances)')
EIP=$(q ec2 describe-addresses --query 'length(Addresses)')
ECS=$(q ecs list-clusters --query 'length(clusterArns)')
ECR=$(q ecr describe-repositories --query 'length(repositories)')
VPC=$(q ec2 describe-vpcs --query 'length(Vpcs[?IsDefault==`false`])')

{
  echo "# Billable resource inventory"; echo "Captured: $TS"; echo
  echo "nat_gateways: $NAT"
  echo "load_balancers: $ALB"
  echo "rds_instances: $RDS"
  echo "elastic_ips: $EIP"
  echo "ecs_clusters: $ECS"
  echo "ecr_repositories: $ECR"
  echo "non_default_vpcs: $VPC"
} | sed -E "$MASK" > "$OUT/04-resource-inventory.txt"

MFA=$(q iam get-account-summary --query 'SummaryMap.AccountMFAEnabled')
KEYS=$(q iam get-account-summary --query 'SummaryMap.AccountAccessKeysPresent')
KMS=$(q kms list-keys --query 'length(Keys)')

st() { [ "$2" = "$3" ] && echo "PASS" || echo "FAIL"; }

{
  printf "# %s summary\n\n" "$MILESTONE"
  printf "%-26s %-10s %-10s %s\n" "CHECK" "EXPECTED" "ACTUAL" "STATUS"
  printf "%-26s %-10s %-10s %s\n" "--------------------------" "--------" "--------" "------"
  printf "%-26s %-10s %-10s %s\n" "root MFA"              "-" "-"  "$(st x "$MFA" 1)"
  printf "%-26s %-10s %-10s %s\n" "root access keys"      "0" "$KEYS" "$(st x "$KEYS" 0)"
  printf "%-26s %-10s %-10s %s\n" "customer managed KMS"  "0" "$KMS"  "$(st x "$KMS" 0)"
  printf "%-26s %-10s %-10s %s\n" "nat gateways"          "0" "$NAT"  "$(st x "$NAT" 0)"
  printf "%-26s %-10s %-10s %s\n" "load balancers"        "0" "$ALB"  "$(st x "$ALB" 0)"
  printf "%-26s %-10s %-10s %s\n" "rds instances"         "0" "$RDS"  "$(st x "$RDS" 0)"
  printf "%-26s %-10s %-10s %s\n" "elastic ips"           "0" "$EIP"  "$(st x "$EIP" 0)"
  printf "%-26s %-10s %-10s %s\n" "ecs clusters"          "0" "$ECS"  "$(st x "$ECS" 0)"
  printf "\nGenerated %s\n" "$TS"
} > "$OUT/00-summary.txt"

echo "Done. Files written:"
ls -1 "$OUT"/*.txt
