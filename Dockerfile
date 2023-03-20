FROM python:3.9-slim

ENV NODE_VERSION=16.13.0

RUN apt-get update && apt-get install -y ca-certificates curl uuid-runtime git && rm -rf /var/lib/apt/lists/*
RUN pip install pip install 'piperider[duckdb]'

# TODO we should install packages by configuration
# RUN pip install pip install 'piperider[snowflake]' \
#     && pip install 'piperider[postgres]' \
#     && pip install 'piperider[bigquery]' \
#     && pip install 'piperider[redshift]' \
#     && pip install 'piperider[parquet]' \
#     && pip install 'piperider[csv]' \
#     && pip install 'piperider[duckdb]'

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

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
