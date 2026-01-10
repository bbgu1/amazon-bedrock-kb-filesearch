# Lambda Layer Module
# Provides shared dependencies for Lambda functions

# ============================================================================
# Build Lambda Layer Package
# ============================================================================

# Create a temporary directory for building the layer
resource "null_resource" "build_layer" {
  triggers = {
    requirements_hash = filemd5("${path.module}/../../../lambda/shared/layer/python/requirements.txt")
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "Building Lambda layer..."
      
      # Use absolute path for build directory
      BUILD_DIR="$(pwd)/.terraform/tmp/lambda-layer-build"
      OUTPUT_ZIP="$(pwd)/.terraform/tmp/lambda-layer.zip"
      
      rm -rf "$BUILD_DIR"
      mkdir -p "$BUILD_DIR/python"
      
      # Copy requirements file
      cp "${path.module}/../../../lambda/shared/layer/python/requirements.txt" "$BUILD_DIR/"
      
      # Install dependencies using python3 and pip3
      python3 -m pip install -r "$BUILD_DIR/requirements.txt" -t "$BUILD_DIR/python/" --upgrade
      
      # Create ZIP file
      cd "$BUILD_DIR"
      zip -r "$OUTPUT_ZIP" python/
      
      echo "Lambda layer built successfully at $OUTPUT_ZIP"
    EOT

    working_dir = path.module
  }
}

# Archive the layer (depends on build)
data "archive_file" "layer_package" {
  type        = "zip"
  source_dir  = "${path.module}/.terraform/tmp/lambda-layer-build"
  output_path = "${path.module}/.terraform/tmp/lambda-layer.zip"

  depends_on = [null_resource.build_layer]
}

# ============================================================================
# Lambda Layer
# ============================================================================

resource "aws_lambda_layer_version" "shared" {
  filename            = data.archive_file.layer_package.output_path
  layer_name          = "${var.name_prefix}-shared-dependencies"
  compatible_runtimes = ["python3.12", "python3.11", "python3.10"]
  source_code_hash    = data.archive_file.layer_package.output_base64sha256

  description = "Shared dependencies for Lambda functions (boto3, botocore)"

  depends_on = [null_resource.build_layer]
}
