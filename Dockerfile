FROM python:3.9-slim

ENV NODE_VERSION=16.13.0

RUN apt-get update && apt-get install -y ca-certificates curl uuid-runtime git && rm -rf /var/lib/apt/lists/*
RUN curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /bin/yq && chmod +x /bin/yq
RUN pip install -no-cache-dir piperider


ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN node --version
RUN npm --version

WORKDIR /usr/src/github-action/
COPY . .
RUN npm install

WORKDIR /usr/src/github/
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
