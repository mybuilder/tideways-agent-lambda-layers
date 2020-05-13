# Tideways Agent Lambda Layers

This repo provides the Tideways agent for profiling PHP on Lambda. The `build.sh` script compiles a ZIP file for various versions of PHP and uses the AWS CLI to publish each one as a Lambda layer.

The following `php.ini` entries should be used to enable/configure the agent:

```
extension=/opt/tideways.so
tideways.api_key=${TIDEWAYS_APIKEY}
tideways.service=${TIDEWAYS_SERVICE}
tideways.connection=${TIDEWAYS_CONNECTION}
```

See [the guide on configuring PHP](https://bref.sh/docs/environment/php.html) in the Bref documentation for info on how to customise the `php.ini` file.
