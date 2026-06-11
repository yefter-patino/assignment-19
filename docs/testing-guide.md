# Assignment 19 - Testing Guide

Run everything from the **repo root** so the relative paths (`cloudformation/...`)
work. Make sure your AWS CLI is configured for account `866934333672` and region
`us-east-1`.

## 1. Validate the templates
```bash
./scripts/validate.sh
```
Expected: `All templates are valid.`

## 2. Deploy dev (nested stacks deploy in order)
```bash
./scripts/deploy.sh dev
```
What to check (success criteria: *nested stacks deploy in correct order* and
*outputs passed correctly between stacks*):

- In the CloudFormation console you see 4 stacks:
  `yefter-main-infrastructure-dev` plus 3 nested stacks for network, security,
  and compute.
- They reach `CREATE_COMPLETE` in this order: network -> security -> compute.
- The parent stack's **Outputs** tab shows `VpcId`, `SecurityGroupId`,
  and `Instance1Id`.
- Only **one** EC2 instance exists, type **t2.micro**, named
  `yefter-dev-instance-1`.

> Screenshot ideas: the 4 stacks list, the parent Outputs tab, the single
> t2.micro instance. Save them in `screenshots/`.

## 3. Test an update by changing the instance type
```bash
./scripts/update.sh prod
```
What to check (success criteria: *stack updates without replacing everything*):

- The update completes as `UPDATE_COMPLETE`.
- The instance type is now **t3.medium** and there are **two** instances
  (`yefter-prod-instance-1` and `yefter-prod-instance-2`).
- The **VPC, subnets, IGW, and security group keep the same IDs** - they were
  not recreated. Only the compute layer changed.

> Tip: note the VpcId before and after the update to prove it did not change.

## 4. Test a deliberate failure and verify rollback
```bash
./scripts/test-rollback.sh prod
```
What happens (success criteria: *rollback works on failure*):

- The script uploads a broken compute template (invalid instance type) and runs
  an update.
- The update fails on purpose.
- CloudFormation rolls back automatically.
- The script prints the final status, which should be
  **`UPDATE_ROLLBACK_COMPLETE`**.
- Your good infrastructure is still intact.

> Screenshot ideas: the failed stack event showing the invalid instance type,
> and the final `UPDATE_ROLLBACK_COMPLETE` status.

## 5. Clean up (so you do not get charged)
```bash
./scripts/cleanup.sh prod
```
Deletes the parent stack (and all nested stacks) and removes the S3 bucket.

## Success criteria checklist

| Criteria                                  | Step | How you prove it                                 |
|-------------------------------------------|------|--------------------------------------------------|
| Nested stacks deploy in correct order     | 2    | 4 stacks reach CREATE_COMPLETE: network->sec->compute |
| Outputs passed correctly between stacks   | 2    | Security uses VpcId; compute uses subnets + SG   |
| Stack updates without replacing everything| 3    | Instance type changes; VPC/subnet/SG IDs unchanged |
| Rollback works on failure                 | 4    | Status ends as UPDATE_ROLLBACK_COMPLETE          |
