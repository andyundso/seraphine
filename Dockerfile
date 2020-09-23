# Build backend executable
FROM crystallang/crystal:0.35.1 as crystal-builder
WORKDIR /app
ADD . /app
RUN shards install
RUN crystal build src/seraphine.cr

# Build frontend
FROM node:14 as node-builder
WORKDIR /app

ADD frontend .
RUN yarn install
RUN yarn run build

# Build main application
FROM debian:buster as app
WORKDIR /app

RUN apt-get update && \
  apt install -y libyaml-0-2 \
  libssl-dev \
  libevent-dev && \
  rm -rf /var/lib/apt/lists/*

COPY --from=crystal-builder /app/seraphine .
COPY --from=node-builder /app/public .

CMD ["/app/seraphine"]
