# Assignment 19 - Architecture

## The big idea: nested stacks

Instead of one giant CloudFormation template, this project splits the
infrastructure into **one parent stack** and **three nested (child) stacks**.
Each child stack owns one job:

```
                  main-infrastructure.yaml   (PARENT)
                            |
        ----------------------------------------------
        |                   |                        |
  network-stack.yaml   security-stack.yaml    compute-stack.yaml
  (VPC, subnets, IGW)  (security group, NACL) (EC2 instances)
```

## How the stacks deploy in order

CloudFormation works out the order automatically from the data each stack needs:

1. **NetworkStack** runs first. It has no dependencies.
2. **SecurityStack** needs `VpcId` from the network stack, so it waits for it.
3. **ComputeStack** needs the subnet IDs (network) and the security group ID
   (security), so it waits for both.

We get this ordering by using `!GetAtt <ChildStack>.Outputs.<Name>` in the
parent. Referencing another stack's output creates an automatic dependency, so
we do **not** need to write `DependsOn` by hand.

## How outputs become inputs

| Produced by        | Output            | Used by         | As parameter      |
|--------------------|-------------------|-----------------|-------------------|
| network-stack      | `VpcId`           | security-stack  | `VpcId`           |
| network-stack      | `VpcCidr`         | security-stack  | `VpcCidr`         |
| network-stack      | `PublicSubnet1Id` | compute-stack   | `Subnet1Id`       |
| network-stack      | `PublicSubnet2Id` | compute-stack   | `Subnet2Id`       |
| security-stack     | `SecurityGroupId` | compute-stack   | `SecurityGroupId` |

## Dev vs prod (parameters + conditions)

One parameter, `EnvironmentName`, drives the differences. The compute stack
defines a condition:

```yaml
Conditions:
  IsProd: !Equals [!Ref EnvironmentName, prod]
```

| Setting        | dev               | prod                       |
|----------------|-------------------|----------------------------|
| Instance type  | `t2.micro`        | `t3.medium`                |
| Instance count | 1 (`Instance1`)   | 2 (`Instance1` + `Instance2`) |

`Instance2` only exists in prod because it has `Condition: IsProd`.

## No hardcoding

- CIDR blocks, environment, and the S3 template URL are all **parameters**.
- The AMI is looked up from **SSM** (`/aws/service/ami-amazon-linux-latest/...`)
  so we never paste an AMI ID that would go stale.
- Availability Zones are picked with `!Select [0, !GetAZs '']` instead of being
  typed in.

## Naming

Every resource is named/tagged with the `yefter-` prefix and an `Owner: yefter`
tag, for example `yefter-dev-vpc`, `yefter-prod-instance-2`.
