#!/usr/bin/env bash

set -e

PHP_VERSIONS=(72) # 73 74)
TIDEWAYS_VERSION=5.1.14
AWS_REGION=eu-west-1
ROOT_DIR=$(pwd)
BUILD_DIR="${ROOT_DIR}/build"

for PHP_VERSION in "${PHP_VERSIONS[@]}"; do
  echo ""
  echo "### Building Tideways ${TIDEWAYS_VERSION} for PHP ${PHP_VERSION}"
  echo ""

  docker build \
    --build-arg PHP_VERSION="${PHP_VERSION}" \
    --build-arg TIDEWAYS_VERSION="${TIDEWAYS_VERSION}" \
    -t "tideways-${TIDEWAYS_VERSION}-php-${PHP_VERSION}" .

  mkdir -p "${BUILD_DIR}/tmp" && rm -fr "${BUILD_DIR:?}/tmp/*" && cd "${BUILD_DIR}/tmp"
  docker run --entrypoint tar "tideways-${TIDEWAYS_VERSION}-php-${PHP_VERSION}" -ch -C /opt . | tar -x
  zip --quiet -X --recurse-paths "${BUILD_DIR}/tideways-${TIDEWAYS_VERSION}-php-${PHP_VERSION}.zip" .
  cd "${ROOT}" && rm -fr "${BUILD_DIR}/tmp"

  echo ""
  echo "### Publishing Tideways ${TIDEWAYS_VERSION} for PHP ${PHP_VERSION}"
  echo ""

  LAYER_VERSION=$(
    aws lambda publish-layer-version \
      --region "${AWS_REGION}" \
      --layer-name "tideways-php-${PHP_VERSION}" \
      --description "tideways-${TIDEWAYS_VERSION}-php-${PHP_VERSION}" \
      --zip-file "fileb://build/tideways-${TIDEWAYS_VERSION}-php-${PHP_VERSION}.zip" \
      --compatible-runtimes provided \
      --license-info MIT \
      --output text \
      --query Version
  )

  aws lambda add-layer-version-permission \
    --region "${AWS_REGION}" \
    --layer-name "tideways-php-${PHP_VERSION}" \
    --version-number "${LAYER_VERSION}" \
    --action lambda:GetLayerVersion \
    --statement-id public \
    --principal "*"
done
