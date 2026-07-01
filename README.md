# Docker MySQL Shell

[![Build Test](https://github.com/snickerjp/docker-mysql-shell/actions/workflows/docker-build-test.yml/badge.svg)](https://github.com/snickerjp/docker-mysql-shell/actions/workflows/docker-build-test.yml)
[![Build and Push](https://github.com/snickerjp/docker-mysql-shell/actions/workflows/docker-push.yml/badge.svg)](https://github.com/snickerjp/docker-mysql-shell/actions/workflows/docker-push.yml)

MySQL Shell の Docker イメージです。Debian 13 (slim) ベースで最小限のイメージサイズを実現しています。

## Available Tags

- `snickerjp/docker-mysql-shell:9.7.1` — フルバージョン（固定）
- `snickerjp/docker-mysql-shell:9.7` — マイナーバージョン（ローリング更新）
- `snickerjp/docker-mysql-shell:latest` — 最新バージョン

### Deprecated Tags

以下のタグは廃止されました。今後更新されません:

- `8.4`, `LTS` — 旧 LTS Series
- `9.6`, `Innovation` — 旧 Innovation Series

## Quick Start

```bash
# インタラクティブモードで起動
docker run -it --rm snickerjp/docker-mysql-shell:latest

# MySQL Server に接続（クラシックプロトコル）
docker run -it --rm snickerjp/docker-mysql-shell:latest \
  --uri mysql://user:pass@host:3306/schema

# MySQL Server に接続（X Protocol）
docker run -it --rm snickerjp/docker-mysql-shell:latest \
  --uri mysqlx://user:pass@host:33060/schema
```

## Usage Examples

### SQL モードで接続

```bash
docker run -it --rm snickerjp/docker-mysql-shell:latest \
  --sql --uri mysql://root@host:3306
```

### JavaScript モードで起動

```bash
docker run -it --rm snickerjp/docker-mysql-shell:latest --js
```

### Python モードで起動

```bash
docker run -it --rm snickerjp/docker-mysql-shell:latest --py
```

### SQL ファイルを実行

```bash
docker run -i --rm \
  -v ./queries:/queries \
  snickerjp/docker-mysql-shell:latest \
  --sql --uri mysql://root@host:3306 -f /queries/setup.sql
```

### InnoDB Cluster の状態確認

```bash
docker run -it --rm snickerjp/docker-mysql-shell:latest \
  --uri mysql://admin@host:3306 \
  -- cluster status
```

### Docker Compose での利用

```yaml
services:
  mysql:
    image: mysql:9.7
    environment:
      MYSQL_ROOT_PASSWORD: example

  mysqlsh:
    image: snickerjp/docker-mysql-shell:latest
    stdin_open: true
    tty: true
    command: ["--uri", "mysql://root:example@mysql:3306", "--sql"]
    depends_on:
      - mysql
```

## Command-Line Options

このイメージの ENTRYPOINT は `mysqlsh` です。`docker run` の引数がそのまま `mysqlsh` のオプションとして渡されます。

| オプション | 説明 |
|-----------|------|
| `--uri=<value>` | URI 形式で接続先を指定 (`mysql://user:pass@host:port/schema`) |
| `--sql` | SQL モードで起動 |
| `--js` | JavaScript モードで起動 |
| `--py` | Python モードで起動 |
| `-f, --file=<file>` | スクリプトファイルを実行 |
| `-e, --execute=<cmd>` | コマンドを実行して終了 |
| `--json[=pretty]` | JSON 形式で出力 |
| `--quiet-start[={1\|2}]` | 起動時の情報出力を抑制 |
| `--cluster` | InnoDB Cluster メンバーへの接続を保証 |
| `--` | API Command Line（例: `-- util check-for-server-upgrade`） |

全オプションは `docker run --rm snickerjp/docker-mysql-shell:latest --help` で確認できます。

## Environment Variables

このイメージ自体はカスタム環境変数を定義していません。`mysqlsh` が参照する代表的な環境変数:

| 環境変数 | 説明 | デフォルト |
|---------|------|-----------|
| `MYSQL_PWD` | MySQL パスワード（非推奨、`--password` を使用） | なし |
| `MYSQL_TCP_PORT` | デフォルトの TCP ポート | `3306` |
| `MYSQL_HOST` | デフォルトのホスト | なし |
| `MYSQL_UNIX_PORT` | Unix ソケットのパス | なし |

### 使用例

```bash
# 色出力を無効化
docker run -it --rm -e MYSQLSH_TERM_COLOR_MODE=nocolor \
  snickerjp/docker-mysql-shell:latest --uri mysql://root@host:3306

# 設定ディレクトリをマウント
docker run -it --rm \
  -v ./mysqlsh-config:/home/mysqlshelluser/.mysqlsh \
  snickerjp/docker-mysql-shell:latest
```

## Volumes

| パス | 用途 |
|------|------|
| `/home/mysqlshelluser/.mysqlsh` | MySQL Shell 設定・履歴ディレクトリ |
| 任意のマウントポイント | SQL スクリプトやSSL証明書の配置用 |

## Ports

このイメージはポートを EXPOSE していません。MySQL Shell はクライアントツールであり、サーバーとして Listen しません。

## Building

```bash
cd docker
docker build -t snickerjp/docker-mysql-shell:9.7 .
```

## How It Works

### 自動バージョン更新

毎週金曜日に [check-new-release](.github/workflows/check-new-release.yml) ワークフローが実行され、
MySQL Shell の新しいバージョンが利用可能になると自動で PR が作成されます。

### Docker Image Push

PR がマージされると [docker-push](.github/workflows/docker-push.yml) ワークフローが発火し、
複数のタグで Docker Hub にイメージが push されます。

### Dockerfile

- [`docker/Dockerfile`](docker/Dockerfile) — 単一の Dockerfile でバージョン管理

## Architecture

- **Base image:** Debian 13 slim
- **Platform:** linux/amd64
- **Non-root user:** `mysqlshelluser` で実行
- **ENTRYPOINT:** `mysqlsh`
- **Default CMD:** `--version`
