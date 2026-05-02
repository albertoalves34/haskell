FROM haskell:9.8.4

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libsqlite3-dev \
    pkg-config \
 && rm -rf /var/lib/apt/lists/*

COPY backend/dietaapp.cabal /app/

RUN cabal update && cabal build --only-dependencies

COPY backend/ /app/

RUN cabal build exe:dietaapp && \
    cp "$(cabal list-bin dietaapp)" /usr/local/bin/dietaapp

EXPOSE 3000

CMD ["dietaapp"]
