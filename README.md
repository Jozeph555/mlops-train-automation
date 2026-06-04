# MLOps Train Automation

Automated ML training pipeline using AWS Step Functions, Lambda,
Terraform, and GitHub Actions.

## Architecture

```
GitHub Push (main branch)
↓
GitHub Actions (train.yml)
↓
aws stepfunctions start-execution
↓
AWS Step Functions (MLOpsPipeline)
↓
ValidateData          LogMetrics
(Lambda function)  →  (Lambda function)
↓
End
```

## Project Structure

```
mlops-train-automation/
├── .github/
│   └── workflows/
│       └── train.yml          # GitHub Actions workflow
├── terraform/
│   ├── main.tf                # IAM roles, Lambda, Step Function
│   ├── variables.tf           # Input variables
│   ├── outputs.tf             # Output ARNs
│   └── lambda/
│       ├── validate.py        # Validation Lambda function
│       ├── validate.zip       # Packaged Lambda archive
│       ├── log_metrics.py     # Logging Lambda function
│       └── log_metrics.zip    # Packaged Lambda archive
├── .gitignore
└── README.md
```

## Prerequisites

- AWS CLI configured with profile `terraform-admin`
- Terraform >= 1.0
- Python 3.x
- GitHub repository with AWS secrets configured

## How to Build Lambda Archives

Before deploying infrastructure, package Lambda functions into zip archives:

```bash
cd terraform/lambda

zip validate.zip validate.py
zip log_metrics.zip log_metrics.py
```

Verify archives were created:

```bash
ls -la *.zip
```

## How to Deploy Infrastructure via Terraform

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Review the plan

```bash
terraform plan
```

Expected resources to be created:
- IAM role for Lambda (`lambda_exec_role`)
- IAM role for Step Function (`stepfunction_exec_role`)
- Lambda function `validateData`
- Lambda function `logMetrics`
- Step Function state machine `MLOpsPipeline`

### 3. Apply the configuration

```bash
terraform apply
```

After successful apply, outputs will show:
state_machine_arn    = "arn:aws:states:eu-central-1:...:stateMachine:MLOpsPipeline"
validate_lambda_arn  = "arn:aws:lambda:eu-central-1:...:function:validateData"
log_metrics_lambda_arn = "arn:aws:lambda:eu-central-1:...:function:logMetrics"

### 4. Destroy infrastructure when done

⚠️ Always destroy resources after use to avoid unnecessary AWS costs:

```bash
terraform destroy
```

## How to Verify Step Function Manually via AWS Console

1. Open [AWS Console](https://console.aws.amazon.com) →
   **Step Functions** → **State machines**
2. Click **MLOpsPipeline**
3. Click **Start execution**
4. Enter input JSON:
```json
   {
     "source": "manual",
     "data": "test"
   }
```
5. Click **Start execution**
6. Watch the **Graph view** — both steps should turn green:
   - ✅ ValidateData
   - ✅ LogMetrics
7. Check **Execution status**: `Succeeded`

To verify Lambda logs:
- Go to **CloudWatch** → **Log Groups**
- `/aws/lambda/validateData` → should contain `✅ Validating input data...`
- `/aws/lambda/logMetrics` → should contain `📈 Logging metrics to MLflow...`

## How GitHub Actions Works

The workflow is defined in `.github/workflows/train.yml`.

### Trigger

The workflow runs automatically on every push to the `main` branch:

```yaml
on:
  push:
    branches:
      - main
```

### Steps

1. **Checkout code** — pulls the repository
2. **Configure AWS credentials** — authenticates with AWS using secrets
3. **Start Step Function execution** — calls `aws stepfunctions start-execution`

### Required GitHub Secrets

Go to **GitHub Repository** → **Settings** →
**Secrets and variables** → **Actions** → **New repository secret**

| Secret Name | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM user secret key |

The IAM user must have permissions to:
- `states:StartExecution` on the Step Function
- `lambda:InvokeFunction` on both Lambda functions

## Example JSON Passed via CI

When GitHub Actions triggers the Step Function, it passes this JSON:

```json
{
  "source": "github-actions",
  "commit": "b939073abc...",
  "branch": "main"
}
```

This allows the Step Function to know:
- Where the execution was triggered from
- Which commit caused the training run
- Which branch was used

## Verifying the Full Flow

After pushing to `main`:

1. Go to **GitHub** → **Actions** tab
   → Workflow `Train ML Model` should show ✅

2. Go to **AWS Console** → **Step Functions** → **MLOpsPipeline**
   → **Executions** tab should show a new `Succeeded` execution

3. Execution name follows the pattern:
   `train-{run_number}-{timestamp}`