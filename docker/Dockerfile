FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV _UBUNTU_VERSION=22.04
ENV _MYSQL_SHELL_VERSION=8.1.1

RUN apt update \
    && apt install -y curl python3 \
    && curl -sL -o /tmp/mysql-shell.deb https://dev.mysql.com/get/Downloads/MySQL-Shell/mysql-shell_${_MYSQL_SHELL_VERSION}-1ubuntu${_UBUNTU_VERSION}_amd64.deb \
    && apt install -y /tmp/mysql-shell.deb \
    && rm -rf /tmp/*.deb \
    && rm -rf /var/lib/apt/lists/*
