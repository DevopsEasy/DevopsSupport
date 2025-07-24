
FROM python:3.10-alpine AS builder

WORKDIR /app

RUN apk add --no-cache \
    build-base \
    libffi-dev \
    openssl-dev \
    curl \
    bash \
    ca-certificates \
    dpkg \
    tar


RUN curl -sLO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

RUN curl -LO https://github.com/k8sgpt-ai/k8sgpt/releases/download/v0.4.17/k8sgpt_amd64.deb && \
    ar x k8sgpt_amd64.deb && \
    tar -xzf data.tar.gz -C /tmp && \
    mv /tmp/usr/bin/k8sgpt /usr/local/bin/k8sgpt && \
    chmod +x /usr/local/bin/k8sgpt && \
    rm -rf k8sgpt_amd64.deb *.tar.gz /tmp/usr

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


COPY backend.py .
COPY azureopenai.sh .


FROM python:3.10-alpine

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app


RUN apk add --no-cache \
    libffi \
    openssl \
    bash \
    ca-certificates \
    && rm -rf /var/cache/apk/*

COPY --from=builder /install /usr/local
COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=builder /usr/local/bin/k8sgpt /usr/local/bin/k8sgpt

COPY --from=builder /app/backend.py .
COPY --from=builder /app/azureopenai.sh .

RUN chmod +x azureopenai.sh /usr/local/bin/k8sgpt /usr/local/bin/kubectl

CMD ["./azureopenai.sh"]
