FROM haskell:9.8.4

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libsqlite3-dev \
    pkg-config \
 && rm -rf /var/lib/apt/lists/*

COPY . .

WORKDIR /app/src/06-scotty-sqlite

RUN cabal update && \
    cabal build && \
    cp "$(cabal list-bin demo-scotty-sqlite)" /usr/local/bin/demo-scotty-sqlite

CMD ["demo-scotty-sqlite"]