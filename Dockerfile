FROM haskell:9.8.4

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libsqlite3-dev \
    pkg-config \
 && rm -rf /var/lib/apt/lists/*

COPY backend/dietaapp.cabal /app/

RUN cabal update && cabal build --only-dependencies

COPY backend/ /app/
COPY frontend/ /app/frontend/

RUN cabal install exe:dietaapp --install-method=copy --installdir=/usr/local/bin

ENV DB_PATH=/data/banco.db
ENV FRONTEND_DIR=/app/frontend

EXPOSE 3000

CMD ["dietaapp"]
