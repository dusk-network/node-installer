FROM ubuntu:24.04

RUN apt-get update && apt-get install -y curl openssl iproute2 && rm -rf /var/lib/apt/lists/*

WORKDIR /root

COPY . .

ARG BUILDING_DOCKER_IMAGE=true
ARG NETWORK
ARG FEATURE

RUN chmod +x node-installer.sh && ./node-installer.sh
RUN chmod +x bin/start-in-docker.sh

CMD ["./bin/start-in-docker.sh"]
