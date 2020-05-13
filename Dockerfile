ARG PHP_VERSION

FROM bref/build-php-$PHP_VERSION AS ext

ARG TIDEWAYS_VERSION

RUN version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/tideways-php.tar.gz -D - -L -s "https://s3-eu-west-1.amazonaws.com/tideways/extension/${TIDEWAYS_VERSION}/tideways-php-${TIDEWAYS_VERSION}-x86_64.tar.gz" \
    && mkdir -p /tmp/tideways-php \
    && tar zxpf /tmp/tideways-php.tar.gz -C /tmp/tideways-php \
    && cp "/tmp/tideways-php/tideways-${TIDEWAYS_VERSION}/tideways-php-$version-zts.so" /tmp/tideways.so \
    && rm -rf /tmp/tideways-php /tmp/tideways-php.tar.gz

FROM lambci/lambda:provided

COPY --from=ext /tmp/tideways.so /opt/tideways.so
