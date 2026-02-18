# 1. Base Image - Official Perl 5.38 (Debian-based)
FROM perl:5.38

ARG GITHUB_TOKEN
ENV DEBIAN_FRONTEND=noninteractive

# 2. Add PostgreSQL Official Repository & Install Dependencies
RUN apt-get update && apt-get install -y curl ca-certificates gnupg lsb-release && \
    curl -fSsL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y \
    supervisor \
    postgresql-14 \
    postgresql-server-dev-14 \
    git build-essential pkg-config \
    libdb-dev libicu-dev libpq-dev libssl-dev libxml2-dev \
    libgnutls28-dev gnupg \
    nodejs npm sudo \
    && rm -rf /var/lib/apt/lists/*

# 3. Build MusicBrainz Postgres Extensions (Rest remains the same)
WORKDIR /src
RUN git clone --depth 1 https://github.com/metabrainz/postgresql-musicbrainz-collate.git && \
    cd postgresql-musicbrainz-collate && \
    make PG_CONFIG=/usr/lib/postgresql/14/bin/pg_config with_llvm=no install

RUN git clone --depth 1 https://github.com/metabrainz/postgresql-musicbrainz-unaccent.git && \
    cd postgresql-musicbrainz-unaccent && \
    make PG_CONFIG=/usr/lib/postgresql/14/bin/pg_config with_llvm=no install

# 4. Clone and Setup Your Forked Repositories
WORKDIR /app
RUN git clone https://x-access-token:${GITHUB_TOKEN}@github.com/snorkle256/musicbrainz-server.git && \
    cd musicbrainz-server && \
    cpanm --installdeps .

RUN git clone https://x-access-token:${GITHUB_TOKEN}@github.com/snorkle256/LM-Bridge.git && \
    cd LM-Bridge && \
    npm install

# 5. Environment & Scripts
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-script.sh /usr/local/bin/start-script.sh
RUN chmod +x /usr/local/bin/start-script.sh

EXPOSE 5000 5001 5432
CMD ["/usr/local/bin/start-script.sh"]
