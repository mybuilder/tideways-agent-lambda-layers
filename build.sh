#!/usr/bin/env bash

set -e

command -v aws >/dev/null || {
  echo 'ERROR: aws command is missing' >&2
  exit 1
}

PHP_VERSIONS=(72 73 74)
TIDEWAYS_VERSION=5.1.18
LAYERS_DIR=$(pwd)/layers

mkdir -p "${LAYERS_DIR}"

for PHP_VERSION in "${PHP_VERSIONS[@]}"; do
  echo ""
  echo "### Building Tideways ${TIDEWAYS_VERSION} for PHP ${PHP_VERSION}"
  echo ""

  IMAGE="tideways-${TIDEWAYS_VERSION}-php-${PHP_VERSION}"
  ZIP_PATH="${LAYERS_DIR}/${IMAGE}.zip"

  docker build -t "${IMAGE}" \
    --build-arg PHP_VERSION="${PHP_VERSION}" \
    --build-arg TIDEWAYS_VERSION="${TIDEWAYS_VERSION}" .

  BUILD_DIR=$(pwd)/build/"${IMAGE}"
  rm -rf "${BUILD_DIR}" && mkdir -p "${BUILD_DIR}"
  docker run --entrypoint tar "${IMAGE}" -ch -C /opt . | tar -x -C "${BUILD_DIR}"
  cd "${BUILD_DIR}" && zip -X "${ZIP_PATH}" ./* && cd - >/dev/null

  echo ""
  echo "### Publishing Tideways ${TIDEWAYS_VERSION} for PHP ${PHP_VERSION}"
  echo ""

  LAYER_VERSION=$(
    aws lambda publish-layer-version \
      --region eu-west-1 \
      --layer-name "tideways-php-${PHP_VERSION}" \
      --description "${IMAGE}" \
      --zip-file "fileb://${ZIP_PATH}" \
      --compatible-runtimes provided \
      --license-info MIT \
      --output text \
      --query Version
  )

  aws lambda add-layer-version-permission \
    --region eu-west-1 \
    --layer-name "tideways-php-${PHP_VERSION}" \
    --version-number "${LAYER_VERSION}" \
    --action lambda:GetLayerVersion \
    --statement-id public \
    --principal "*"
done
