# Lambda Layer Module

This Terraform module creates a Lambda layer containing shared dependencies for Lambda functions.

## Purpose

The Lambda layer provides common dependencies (boto3, botocore) that are shared across multiple Lambda functions, reducing deployment package sizes and enabling dependency reuse.

## Features

- Automatically builds Lambda layer from requirements.txt
- Installs Python dependencies using pip
- Creates versioned Lambda layer
- Compatible with Python 3.10, 3.11, and 3.12 runtimes

## Usage

```hcl
module "lambda_layer" {
  source = "./modules/lambda-layer"

  environment = "dev"
  name_prefix = "my-project"
}

# Use the layer in a Lambda function
resource "aws_lambda_function" "example" {
  # ... other configuration ...
  
  layers = [module.lambda_layer.layer_arn]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name_prefix | Prefix for resource names | string | - | yes |
| environment | Environment name (dev, staging, prod) | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| layer_arn | ARN of the Lambda layer |
| layer_version | Version of the Lambda layer |

## Dependencies

The layer includes the following Python packages:
- boto3 >= 1.34.0
- botocore >= 1.34.0

Dependencies are defined in `lambda/shared/layer/python/requirements.txt`.

## Build Process

The module uses a `null_resource` with a `local-exec` provisioner to:

1. Create a temporary build directory
2. Copy the requirements.txt file
3. Install dependencies using pip into the `python/` directory
4. Create a ZIP archive of the layer

The layer is rebuilt whenever the requirements.txt file changes (detected via MD5 hash).

## Layer Structure

```
lambda-layer.zip
└── python/
    ├── boto3/
    ├── botocore/
    └── ... (other dependencies)
```

## Notes

- The `python/` directory structure is required by AWS Lambda layers
- Dependencies are automatically available to Lambda functions that use this layer
- The layer is versioned - each change creates a new version
- Lambda functions reference the layer by ARN, which includes the version

## Requirements

- Terraform >= 1.0
- Python 3.x and pip installed on the machine running Terraform
- AWS provider configured

## Related Resources

- [AWS Lambda Layers Documentation](https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html)
- [Lambda Layer Python Structure](https://docs.aws.amazon.com/lambda/latest/dg/python-package.html#python-package-dependencies)
