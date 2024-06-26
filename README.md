# scalable-eks

EKS Deployment that supports Scaling based on SQS Changes

## Main Flows

1. Publish or Delete SQS Messages -> KEDA detects change -> Updates Nginx ScaledObject -> Updates Nginx HPA -> Updates Nginx Deployment 

## Components

```
|-- charts
|   `-- scalable-nginx
|-- scripts
|   |-- helm-package-and-push.sh
|   `-- load-kubeconfig.sh
`-- terragrunt
    |-- kubeconfig
    |-- main
    |   `-- eu-west-1
    |       `-- scalable-eks
    |           |-- eks
    |           |-- keda
    |           |   |-- helm
    |           |   |-- iam-policy
    |           |   `-- iam-role
    |           |-- scalable-nginx
    |           |   `-- helm
    |           |-- sqs
    |           `-- vpc
```

## Local Environment 

### Setup Terraform and Terragrunt

1. Install terraform (v1.8.4 as of this writing)
2. Install terragrunt (v0.58.10 as of this writing)

#### Custom Settings

Option 1. Modify `terragrunt/{account}/account.hcl` so that aws_profile reflects the name of the aws profile in your `~/.aws/config`

Option 2. (Temporary) Set env vars by copying `.env` -> `.env.example` 
**Requires running `set -a; source .env; set +a` in each new terminal session**

(yosefrow-main by default)

### Setup Kubectl

When you deploy EKS it will automatically setup a kubeconfig file for you at `${REPO_ROOT_DIR}/terragrunt/kubeconfig` which will also be used by the helm provider 

You can run the following command to setup kubectl for your current shell `/source ./load-kubeconfig.sh ${YOUR_AWS_PROFILE}`

**Note**: you will need to setup KUBECONFIG every time you open a new shell.

**Tip**: If you run into API errors, make sure you are running a compatible version of awscli (which generates the config) and kubectl (which uses the config). EKS is provisioned with v1.30.

### Setup AWS Profile

Modify `~/.aws/config`

Example config:
```
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
                    |-- component.hcl
    |               `-- terragrunt.hcl
```

State at: https://eu-west-1.console.aws.amazon.com/s3/buckets/yosefrow-main-terraform-state?region=eu-west-1

Lock at: https://eu-west-1.console.aws.amazon.com/dynamodbv2/home?region=eu-west-1#table?name=main-terraform-state-lock

### root.hcl

The main configuration including the configuration that is included in all modules and is used to generate the remote state and provider and backend files 

### Other files

account.hcl, region.hcl, service.hcl, and component.hcl are used to manage variables includes for the Account, Region, Service, and Component respectively.

### Basic Commands

*Non-interactive*
- Attach the `--terragrunt-non-interactive` to use  `run-all` commands without confirmation **Use with Caution!**

*Plan*
- `terragrunt run-all --terragrunt-non-interactive plan`

*Apply*
- `terragrunt run-all --terragrunt-non-interactive apply`

*Destroy*
- `terragrunt run-all --terragrunt-non-interactive destroy`

### Troubleshooting

Removing `.terragrunt-cache` and `.terraform.lock.hcl` can solve many problems that occur with TF and TG e.g. find: `find . -regex '.*\.\(terragrunt-cache\|terraform\.lock\.hcl\)' -exec rm -rf {} \;`

If you face a locking issue and you are sure nothing else is using the lock you can remove the lock with `terragrunt force-unlock ${LOCKID}`

### Caching

We did not configure caching for plugins, but it can save time and disk space to do so.

## VPC & Subnets

The VPC contains 3 private networks and 3 public networks spread across 3 AZs. Though we deploy our resources to private networks, the public networks are needed in order to enable NAT

**Note**: The VPC is considered part of the service in this scenario so its located under the service folder. 

Though in many cases vpcs are not service related and can be shared by many services. In cases like that vpc config might be located in a more general folder like region folder or system folder.

Deployed to: https://eu-west-1.console.aws.amazon.com/vpcconsole/home?region=eu-west-1#vpcs:tag:Name=scalable-eks-vpc

## EKS Cluster

The EKS Cluster is deployed contains 2 nodes distributed to 3 private networks in 3 AZs of the VPC we created. 


min_size, max_size, and desired_size are all the same (2) because we haven't provisioned a cluster auto-scaler

**Note**: Changing desired_size after provisioning will not influence the number of nodes, but you can raise the min_size as a workaround

Deployed to: https://eu-west-1.console.aws.amazon.com/eks/home?region=eu-west-1#/clusters/scalable-eks-cluster

### Security

Although we allow public access to the API, in a production environment we would remove this access and only allow access securely such as through a VPN.

## KEDA Autoscaler

KEDA Autoscaler is used to horizontally scale applications based on specific metrics. In our project, we focus on SQS metrics

It is deployed via the `keda/helm` modules and the aws irsa role and policy is deployed via the `keda/iam-role` and `keda/iam-policy` modules

KEDA controller is configured to be able to access SQS using the role and policy mentioned above.

## AWS SQS

An AWS SQS queue is used to demonstrate load based autoscaling. You can manipulate SQS in the following ways

### Set environment

```bash
AWS_ACCOUNT_ID=203513363151
SQS_QUEUE_URL=https://sqs.eu-west-1.amazonaws.com/${AWS_ACCOUNT_ID}/scalable-eks.fifo
SQS_GROUP_ID=123456789
TEST_MESSAGE="Testing KEDA"
```

### Fill the queue with messages

```bash
for i in {1..10}; do
    aws sqs send-message --queue-url ${SQS_QUEUE_URL} \
        --message-body "$TEST_MESSAGE $(date +%s)" \
        --message-group-id ${SQS_GROUP_ID} \
        --message-deduplication-id $i;
done
```

### Remove next 5 messages

 ```bash
# Get the next message
aws sqs receive-message --queue-url ${SQS_QUEUE_URL}

# Delete the next 5 messagse by their receipt handles
for i in {1..5}; do
    RECEIPT_HANDLE=$(aws sqs receive-message --queue-url ${SQS_QUEUE_URL} | jq -r '.[][].ReceiptHandle')
    aws sqs delete-message --queue-url ${SQS_QUEUE_URL} --receipt-handle "${RECEIPT_HANDLE}"
done
```

### Purge the queue to reset

```bash
aws sqs purge-queue --queue-url ${SQS_QUEUE_URL}
```
## Scalable Nginx (SQS)

An instance of nginx which is designed to be scalable through the use of KEDA ScaledObject resource which generates and manages and HPA

### Helm Chart

The `charts/scalable-nginx` is created by using helm dependency on the bitnami nginx chart and pushed to the docker oci registry.

It can be built with `/scripts/helm-package-and-push.sh`

### Deployment

The helm chart is deployed through terragrunt `./main/eu-west-1/scalable-eks/scalable-nginx/helm/`

### KEDA Configuration

The KEDA ScaledObject is configured to scale based on the number of messages in an SQS FIFO queue and uses the KEDA controller identity for access to SQS information.

## End-to-End Tests

1. `cd terragrunt; terragrunt run-all --terragrunt-non-interactive apply`
2. Wait for everything to finish applying (30-40 minutes on average)
3. Check Kubernetes cluster to confirm all is successfully applied
4. Generate messages for the queue using instructions above
5. Observe that scalable-nginx scales up to 10
6. Delete 5 messages from the queue using instructions above
7. Observe that after cooldown time (5 min) with no sqs activity, keda hpa scales down to min. (Targets = 500m/1)
8. Observe that after auto scaledown, hpa scales back up to 5 to match the number of messages in the queue
