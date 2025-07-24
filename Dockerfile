FROM python:3.10-alpine AS builder

WORKDIR /app
RUN apk add --no-cache \
    gcc \
    musl-dev \
    libffi-dev \
    openssl-dev \
    bash \
    curl \
    make \
    build-base \
    libgcc \
    libstdc++ \
    binutils \
    tar \
    ca-certificates && \
    rm -rf /var/cache/apk/*

RUN curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

RUN curl -LO https://github.com/k8sgpt-ai/k8sgpt/releases/download/v0.4.17/k8sgpt_amd64.deb && \
    ar x k8sgpt_amd64.deb && \
    tar -xzf data.tar.gz -C /usr/local/bin/ && \
    mv /usr/local/bin/usr/bin/k8sgpt /usr/local/bin/k8sgpt && \
    rm -f k8sgpt_amd64.deb data.tar.gz control.tar.gz debian-binary && \
    rm -rf /usr/local/bin/usr # Clean up the extra /usr directory created by tar

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend.py .
COPY azureopenai.sh .

FROM python:3.10-alpine
WORKDIR /app
RUN apk add --no-cache libffi openssl bash libgcc libstdc++ ca-certificates && \
    rm -rf /var/cache/apk/*

COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=builder /usr/local/bin/uvicorn /usr/local/bin/uvicorn
COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=builder /usr/local/bin/k8sgpt /usr/local/bin/k8sgpt
COPY --from=builder /app/backend.py .
COPY --from=builder /app/azureopenai.sh .

RUN chmod +x azureopenai.sh && chmod +x /usr/local/bin/k8sgpt && chmod +x /usr/local/bin/kubectl
ENV PYTHONPATH=/app
CMD ["./azureopenai.sh"]
