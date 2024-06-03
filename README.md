# scalable-eks

EKS Deployment that supports Scaling

## Local Environment 

### Setup Terraform and Terragrunt

1. Install terraform (v1.8.4 as of this writing)
2. Install terragrunt (v0.58.10 as of this writing)

Modify terragrunt/main/account.hcl so that aws_profile reflects the name of the aws profile in your ~/.aws/config 

(yosefrow-main by default)

### Setup AWS Profile

Modify ~/.aws/config

Example config:
```toml
[profile yosefrow-main]
region=eu-west-1
output=json
aws_access_key_id=AKIAMYACCESSKEYID
aws_secret_access_key=verysecretaccesskey
```

## Terraform & Terragrunt

Terragrunt is used to keep our Terraform DRY

1. We use the following hierarchical structure

```
`-- terragrunt
    |-- account_name
    |   |-- account.hcl
    |   `-- region_name
    |       |-- region.hcl
    |       `-- service_name
    |           |-- service.hcl
    |           `-- component
    |               `-- terragrunt.hcl
```

State at: https://eu-west-1.console.aws.amazon.com/s3/buckets/yosefrow-main-terraform-state?region=eu-west-1

Lock at: https://eu-west-1.console.aws.amazon.com/dynamodbv2/home?region=eu-west-1#table?name=main-terraform-state-lock

### root.hcl

The main configuration including the configuration that is included in all modules and is used to generate the remote state and provider and backend files 

### Other files

account.hcl, region.hcl, and service.hcl are used to manage variables includes for the Account, Region, and Service respectively.

### Basic Commands

*Non-interactive*
- Attach the `--terragrunt-non-interactive` to use  `run-all` commands without confirmation **Use with Caution!**

*Plan*
- ` terragrunt run-all plan --terragrunt-non-interactive`

*Apply*
- ` terragrunt run-all apply --terragrunt-non-interactive`

### Troubleshooting

Removing `.terragrunt-cache` and `.terraform.lock.hcl` can solve many problems that occur with TF and TG e.g. `find': find . -regex '.*\.\(terragrunt-cache\|terraform\.lock\.hcl\)' -exec rm -rf {} \;`

If you face a locking issue and you are sure nothing else is using the lock you can remove the lock with `terragrunt force-unlock lockid`

## VPC & Subnets

The VPC contains 3 private networks and 3 public networks spread across 3 AZs. Though we deploy our resources to private networks, the public networks are needed in order to enable NAT

**Note**: The VPC is considered part of the service in this scenario so its located under the service folder. 

Though in many cases vpcs are not service related and can be shared by many services. In cases like that vpc config might be located in a more general folder like region folder or system folder.

Deployed to: https://eu-west-1.console.aws.amazon.com/vpcconsole/home?region=eu-west-1#vpcs:tag:Name=scalable-eks-vpc

## EKS Cluster

The EKS Cluster is deployed contains 2 nodes distributed to 3 private networks in 3 AZs of the VPC we created. 

Although we allow public access to the API, in a production environment we would remove this access and only allow access securely such as through a VPN.

min_size, max_size, and desired_size are all the same (2) because we haven't provisioned a cluster auto-scaler

**Note**: Changing desired_size after provisioning will not influence the number of nodes, but you can raise the min_size as a workaround

Deployed to: https://eu-west-1.console.aws.amazon.com/eks/home?region=eu-west-1#/clusters/scalable-eks-cluster