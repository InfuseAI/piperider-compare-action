FROM python:3.9-slim

RUN apt-get update && apt-get install -y ca-certificates curl uuid-runtime git && rm -rf /var/lib/apt/lists/*
RUN curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /bin/yq && chmod +x /bin/yq
RUN pip install --no-cache-dir piperider

WORKDIR /usr/src/github/
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
