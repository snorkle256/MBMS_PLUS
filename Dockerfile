FROM ubuntu:22.04

ARG GITHUB_TOKEN
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    supervisor \
    postgresql-14 \
    postgresql-server-dev-14 \
    git curl build-essential pkg-config \
    libdb-dev libicu-dev libpq-dev libssl-dev libxml2-dev \
    python3 nodejs npm cpanminus sudo \
    && rm -rf /var/lib/apt/lists/*

# Build Extensions with Corrected Paths
WORKDIR /src
RUN git clone https://github.com/metabrainz/musicbrainz-docker.git

# Collate
WORKDIR /src/musicbrainz-docker/postgres-extension/musicbrainz-collate
RUN make clean && make PG_CONFIG=/usr/lib/postgresql/14/bin/pg_config install

# Unaccent
WORKDIR /src/musicbrainz-docker/postgres-extension/musicbrainz-unaccent
RUN make clean && make PG_CONFIG=/usr/lib/postgresql/14/bin/pg_config install

# Main App Setup
WORKDIR /app
RUN git clone https://snorkle256:${GITHUB_TOKEN}@github.com/snorkle256/musicbrainz-server.git musicbrainz-server && \
    cd musicbrainz-server && cpanm --installdeps .

RUN git clone https://snorkle256:${GITHUB_TOKEN}@github.com/snorkle256/LM-Bridge.git lm-bridge && \
    cd lm-bridge && npm install

ENV MB_DB_HOST=127.0.0.1
ENV MB_DB_PORT=5432
ENV BRIDGE_PORT=5001

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-script.sh /usr/local/bin/start-script.sh
RUN chmod +x /usr/local/bin/start-script.sh

EXPOSE 5000 5001 5432
CMD ["/usr/local/bin/start-script.sh"]
