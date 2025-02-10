# Docker MySQL Shell Images

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/314c46648b7a4b85a25edfeef95edad5)](https://app.codacy.com/gh/snickerjp/docker-mysql-shell?utm_source=github.com&utm_medium=referral&utm_content=snickerjp/docker-mysql-shell&utm_campaign=Badge_Grade_Settings)

This repository contains Dockerfiles for MySQL Shell in two different series:
- Innovation Series (9.2.x) - Latest features [(Dockerfile)](docker/innovation/Dockerfile)
- LTS Series (8.4.x) - Long Term Support [(Dockerfile)](docker/lts/Dockerfile)

Both images are based on Debian 12 (slim) for minimal image size.

## Available Tags

### Innovation Series [(Dockerfile)](docker/innovation/Dockerfile)
- `snickerjp/docker-mysql-shell:9.2` - Innovation series with specific version
- `snickerjp/docker-mysql-shell:innovation` - Latest Innovation series build

### LTS Series [(Dockerfile)](docker/lts/Dockerfile)
- `snickerjp/docker-mysql-shell:8.4` - LTS series with specific version
- `snickerjp/docker-mysql-shell:lts` - Latest LTS series build
- `snickerjp/docker-mysql-shell:latest` - Same as LTS series

## Building the Images

### Innovation Series (9.2.x) [(Dockerfile)](docker/innovation/Dockerfile)
```bash
cd docker/innovation
docker build -t snickerjp/docker-mysql-shell:9.2 .
```

### LTS Series (8.4.x) [(Dockerfile)](docker/lts/Dockerfile)
```bash
cd docker/lts
docker build -t snickerjp/docker-mysql-shell:8.4 .
```

## Usage

Run MySQL Shell container:

```bash
# Innovation Series
docker run -it snickerjp/docker-mysql-shell:9.2
# or
docker run -it snickerjp/docker-mysql-shell:innovation

# LTS Series
docker run -it snickerjp/docker-mysql-shell:8.4
# or
docker run -it snickerjp/docker-mysql-shell:lts
# or
docker run -it snickerjp/docker-mysql-shell:latest
```

To connect to a MySQL Server:
```bash
# Innovation Series
docker run -it snickerjp/docker-mysql-shell:9.2 --uri mysql://user:pass@host:port/schema
# or using innovation tag
docker run -it snickerjp/docker-mysql-shell:innovation --uri mysql://user:pass@host:port/schema

# LTS Series
docker run -it snickerjp/docker-mysql-shell:8.4 --uri mysql://user:pass@host:port/schema
# or using lts tag
docker run -it snickerjp/docker-mysql-shell:lts --uri mysql://user:pass@host:port/schema
```

## Development Workflow

### Branch Strategy

- `feat-*`: Feature branches for new features and improvements
- `develop`: Integration branch for feature branches
- `main`: Release branch

### Pull Request Process

1. Create a new feature branch from `develop`:
```bash
git checkout develop
git pull origin develop
git checkout -b feat-your-feature-name
```

2. Make your changes and create a PR to `develop`
3. After PR is merged to `develop`, it will be included in the next release PR
4. Release PRs are automatically created from `develop` to `main` using git-pr-release

### Protected Branches

- `develop`: Requires PR review and successful status checks
- `main`: Protected release branch, only accepts PRs from `develop`
