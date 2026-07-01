# Docker MySQL Shell

[![Build Test](https://github.com/snickerjp/docker-mysql-shell/actions/workflows/docker-build-test.yml/badge.svg)](https://github.com/snickerjp/docker-mysql-shell/actions/workflows/docker-build-test.yml)
[![Build and Push](https://github.com/snickerjp/docker-mysql-shell/actions/workflows/docker-push.yml/badge.svg)](https://github.com/snickerjp/docker-mysql-shell/actions/workflows/docker-push.yml)

A minimal Docker image for MySQL Shell, based on Debian 13 (slim).

## Available Tags

- `snickerjp/docker-mysql-shell:9.7.1` — Full version (pinned)
- `snickerjp/docker-mysql-shell:9.7` — Minor version (rolling update)
- `snickerjp/docker-mysql-shell:latest` — Latest version

### Deprecated Tags

The following tags are deprecated and will no longer be updated:

- `8.4`, `LTS` — Former LTS Series
- `9.6`, `Innovation` — Former Innovation Series

## Quick Start

```bash
# Run in interactive mode
docker run -it --rm snickerjp/docker-mysql-shell:latest

# Connect to MySQL Server (Classic Protocol)
docker run -it --rm snickerjp/docker-mysql-shell:latest \
  --uri mysql://user:pass@host:3306/schema

# Connect to MySQL Server (X Protocol)
docker run -it --rm snickerjp/docker-mysql-shell:latest \
  --uri mysqlx://user:pass@host:33060/schema
```

## Usage Examples

### Connect in SQL mode

```bash
docker run -it --rm snickerjp/docker-mysql-shell:latest \
  --sql --uri mysql://root@host:3306
```

### Start in JavaScript mode

```bash
docker run -it --rm snickerjp/docker-mysql-shell:latest --js
```

### Start in Python mode

```bash
docker run -it --rm snickerjp/docker-mysql-shell:latest --py
```

### Execute a SQL file

```bash
docker run -i --rm \
  -v ./queries:/queries \
  snickerjp/docker-mysql-shell:latest \
  --sql --uri mysql://root@host:3306 -f /queries/setup.sql
```

### Check InnoDB Cluster status

```bash
docker run -it --rm snickerjp/docker-mysql-shell:latest \
  --uri mysql://admin@host:3306 \
  -- cluster status
```

### Docker Compose

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

The ENTRYPOINT of this image is `mysqlsh`. Arguments passed to `docker run` are forwarded directly as `mysqlsh` options.

| Option | Description |
|--------|-------------|
| `--uri=<value>` | Connect using URI format (`mysql://user:pass@host:port/schema`) |
| `--sql` | Start in SQL mode |
| `--js` | Start in JavaScript mode |
| `--py` | Start in Python mode |
| `-f, --file=<file>` | Execute a script file |
| `-e, --execute=<cmd>` | Execute a command and exit |
| `--json[=pretty]` | Output in JSON format |
| `--quiet-start[={1\|2}]` | Suppress startup information |
| `--cluster` | Ensure connection to an InnoDB Cluster member |
| `--` | API Command Line (e.g. `-- util check-for-server-upgrade`) |

For all options, run `docker run --rm snickerjp/docker-mysql-shell:latest --help`.

## Environment Variables

This image does not define custom environment variables. The following are standard variables recognized by `mysqlsh`:

| Variable | Description | Default |
|----------|-------------|---------|
| `MYSQL_PWD` | MySQL password (deprecated, use `--password`) | None |
| `MYSQL_TCP_PORT` | Default TCP port | `3306` |
| `MYSQL_HOST` | Default host | None |
| `MYSQL_UNIX_PORT` | Unix socket path | None |

### Examples

```bash
# Disable color output
docker run -it --rm -e MYSQLSH_TERM_COLOR_MODE=nocolor \
  snickerjp/docker-mysql-shell:latest --uri mysql://root@host:3306

# Mount config directory
docker run -it --rm \
  -v ./mysqlsh-config:/home/mysqlshelluser/.mysqlsh \
  snickerjp/docker-mysql-shell:latest
```

## Volumes

| Path | Purpose |
|------|---------|
| `/home/mysqlshelluser/.mysqlsh` | MySQL Shell configuration and history |
| Any mount point | For SQL scripts or SSL certificates |

## Ports

This image does not EXPOSE any ports. MySQL Shell is a client tool and does not listen as a server.

## Building

```bash
cd docker
docker build -t snickerjp/docker-mysql-shell:9.7 .
```

## How It Works

### Automatic Version Updates

Every Friday, the [check-new-release](.github/workflows/check-new-release.yml) workflow runs and automatically creates a PR when a new MySQL Shell version is available.

### Docker Image Push

When a PR is merged, the [docker-push](.github/workflows/docker-push.yml) workflow pushes the image to Docker Hub with multiple tags.

### Dockerfile

- [`docker/Dockerfile`](docker/Dockerfile) — Single Dockerfile for version management

## Architecture

- **Base image:** Debian 13 slim
- **Platform:** linux/amd64
- **Non-root user:** `mysqlshelluser`
- **ENTRYPOINT:** `mysqlsh`
- **Default CMD:** `--version`
