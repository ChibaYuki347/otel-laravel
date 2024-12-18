# 概要

Opentelemetryを使ってLaravelの可観測性を上げるサンプルプロジェクトです。
azdを使ってインフラ構築、デプロイ(今後)を行います。

## 依存パッケージ

```php
composer require open-telemetry/sdk
composer require open-telemetry/exporter-otlp
composer require guzzlehttp/guzzle
composer require php-http/guzzle7-adapter
composer require open-telemetry/opentelemetry-auto-laravel

# for distributed tracing 
composer require open-telemetry/opentelemetry-auto-psr15
composer require open-telemetry/opentelemetry-auto-psr18
composer require open-telemetry/opentelemetry-auto-guzzle
```

### Optional

オプションとして、Laravelがロギングに使用しているパッケージであるmonologに計装を作成することで、各トレースにログを添付することができます。この方法を使う利点は、OpenTelemetry SDKに、トレースへのログの自動相関をさせることです。

```php
composer require \
  monolog/monolog \
  open-telemetry/opentelemetry-logger-monolog
```

## 参照

[How To Use OpenTelemetry in Laravel 11](https://www.gmhafiz.com/blog/laravel-with-opentelemetry/)

[Laravel 11 with OpenTelemetry ソースコード例](https://codeberg.org/gmhafiz/observability/src/branch/master/laravel)