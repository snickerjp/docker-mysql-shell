FROM debian:12-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG MYSQL_SHELL_VERSION=9.6.0

# Create a user for the container
RUN useradd -ms /bin/bash mysqlshelluser

RUN apt-get update && apt-get install -y \
    wget=1.21.* \
    && rm -rf /var/lib/apt/lists/* \
    && wget https://dev.mysql.com/get/Downloads/MySQL-Shell/mysql-shell_${MYSQL_SHELL_VERSION}-1debian12_amd64.deb \
    && apt-get update \
    && apt-get install -y ./mysql-shell_${MYSQL_SHELL_VERSION}-1debian12_amd64.deb \
    && rm -f mysql-shell_${MYSQL_SHELL_VERSION}-1debian12_amd64.deb \
    && apt-get remove -y wget \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Switch to the non-root user
USER mysqlshelluser

# Add a healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 CMD mysqlsh --version || exit 1

ENTRYPOINT ["mysqlsh"]
CMD ["--version"]