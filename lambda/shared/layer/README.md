# Shared Lambda Layer

This directory contains common dependencies shared across Lambda functions.

## Structure

```
lambda/shared/layer/
├── python/
│   └── requirements.txt    # Python dependencies
└── README.md
```

## Dependencies

- **boto3**: AWS SDK for Python
- **botocore**: Low-level AWS service access

## Building the Layer

The layer is automatically packaged by Terraform during deployment. The build process:

1. Creates a temporary directory
2. Installs dependencies from `requirements.txt` into `python/` directory
3. Packages the directory as a ZIP file
4. Uploads to AWS Lambda as a layer

## Usage

Lambda functions reference this layer in their Terraform configuration:

```hcl
resource "aws_lambda_function" "example" {
  # ... other configuration ...
  
  layers = [var.shared_layer_arn]
}
```

## Local Development

To install dependencies locally for testing:

```bash
cd lambda/shared/layer
pip install -r python/requirements.txt -t python/
```

## Notes

- The `python/` directory structure is required by AWS Lambda layers
- Dependencies are installed at the layer level, not in individual Lambda functions
- This reduces deployment package size and enables dependency reuse
