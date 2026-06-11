# Assignment 19 - CloudFormation Nested Stacks

Modular AWS infrastructure built with **CloudFormation nested stacks**: one
parent stack that orchestrates three child stacks (network, security, compute),
with dev/prod parameters, conditions, and rollback testing.

- **IaC framework:** CloudFormation only (no Terraform/CDK mixed in)
- **Account / Region:** `866934333672` / `us-east-1`
- **Naming:** every resource uses the `yefter-` prefix and an `Owner: yefter` tag

## Repository structure

```
yefter-assignment-19-nested-stacks/
├── cloudformation/
│   ├── main-infrastructure.yaml   # PARENT stack (orchestrates the 3 below)
│   ├── network-stack.yaml         # VPC, subnets, IGW, route table
│   ├── security-stack.yaml        # security group + network ACL
│   └── compute-stack.yaml         # EC2 instances (dev/prod conditions)
├── scripts/
│   ├── validate.sh                # validate all templates
│   ├── deploy.sh                  # upload nested templates to S3 + create stack
│   ├── update.sh                  # update stack (e.g. change instance type)
│   ├── test-rollback.sh           # deliberate failure -> verify rollback
│   └── cleanup.sh                 # delete stack + bucket
├── docs/
│   ├── architecture.md            # how the nested stacks fit together
│   └── testing-guide.md           # step-by-step tests + success criteria
├── screenshots/                   # put your console screenshots here
├── .gitignore
└── README.md
```

## How it works

The parent reads each child stack's outputs with `!GetAtt`, which both passes
data between stacks **and** forces the deploy order:

```
network-stack  ->  security-stack  ->  compute-stack
(VpcId, subnets)    (SecurityGroupId)    (EC2 instances)
```

| Environment | Instance type | Instances |
|-------------|---------------|-----------|
| dev         | t2.micro      | 1         |
| prod        | t3.medium     | 2         |

Nested templates must live in S3, so `deploy.sh` creates a bucket
(`yefter-cfn-templates-<env>-<account>`), uploads the three child templates,
and passes the S3 base URL into the parent stack as the `TemplateBaseUrl`
parameter. Nothing is hardcoded inside the templates.

## Quick start

```bash
# from the repo root, with the AWS CLI configured for us-east-1
./scripts/validate.sh            # 1. check templates
./scripts/deploy.sh dev          # 2. deploy dev (1x t2.micro)
./scripts/update.sh prod         # 3. update to prod (2x t3.medium)
./scripts/test-rollback.sh prod  # 4. break on purpose -> rollback
./scripts/cleanup.sh prod        # 5. delete everything
```

See `docs/testing-guide.md` for what to check at each step.

## Success criteria

- [x] Nested stacks deploy in correct order
- [x] Outputs passed correctly between stacks
- [x] Stack updates without replacing everything
- [x] Rollback works on failure
