# 概要

Opentelemetryを使ってLaravelの可観測性を上げるサンプルプロジェクトです。
azdを使ってインフラ構築、デプロイ(今後)を行います。

## 構成

![アーキテクチャ](./docs/images/architecture.png)

App Serviceのカスタムコンテナを複数、もしくはサイドカーでOpenTelemetry Collectorを立ち上げ、そこからAzure Monitorにデータを送信します。

送られたデータはApplication Insightsに格納され、可観測性を上げることができます。

## 前提条件

- Dockerがインストールされていること。
(Docker Desktopを推奨します。)

- azdがインストールされていること。
  - azd auth loginを実行してログインしてください。

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

grpc

```php
composer require grpc/grpc@1.57.0
composer require open-telemetry/transport-grpc
```

もしgrpcがインストールされていない場合環境変数を`OTEL_EXPORTER_OTLP_PROTOCOLを"grpc"から"http/json"`に変更する必要があります。

下記画像はdocker-composeを使った環境変数の例です。
![docker-compose](./docs/images/docker-compose.png)

### 設定とApplication Insightsアウトプットについて

[設定と詳細](./docs/detailed.md)をご覧ください。

## インフラの構築

```bash
azd provision
```

このコマンドでインフラが構築されます。

## ローカルでの実行

.env.exampleをコピーして.envを作成します。

```bash
cp .env.example .env
```

.env内の
`APPLICATIONINSIGHTS_CONNECTION_STRING`の値を作成したApplicationInsightsの接続文字列に変えます。

```.env
APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=xxxxx..."
```

```bash
docker compose up -d --build --force-recreate
```

こちらでコンテナが立ち上がります。
またmakeコマンドが使えれば下記のコマンドでコンテナを立ち上げることができます。

```bash
make up
```

リソースを消す場合は下記のコマンドを実行してください。

```bash
docker compose down
```

makeコマンドが使えれば下記のコマンドでコンテナを消すことができます。

```bash
make down
```

## 参照

[How To Use OpenTelemetry in Laravel 11](https://www.gmhafiz.com/blog/laravel-with-opentelemetry/)

[Laravel 11 with OpenTelemetry ソースコード例](https://codeberg.org/gmhafiz/observability/src/branch/master/laravel)