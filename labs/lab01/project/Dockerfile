FROM julia:1.11.9-bookworm

ARG TARGETARCH
ARG QUARTO_VERSION=1.10.18

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates curl fonts-dejavu-core git make python3 python3-pip \
    && python3 -m pip install --break-system-packages --no-cache-dir \
       jupyterlab==4.4.7 nbconvert==7.16.6 \
    && case "${TARGETARCH}" in amd64|arm64) true ;; *) exit 1 ;; esac \
    && curl -fsSL \
       "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-${TARGETARCH}.tar.gz" \
       -o /tmp/quarto.tar.gz \
    && mkdir -p /opt/quarto \
    && tar -xzf /tmp/quarto.tar.gz -C /opt/quarto --strip-components=1 \
    && ln -s /opt/quarto/bin/quarto /usr/local/bin/quarto \
    && rm -f /tmp/quarto.tar.gz \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash dakuokkonen

ENV JULIA_DEPOT_PATH=/workspace/labs/lab01/project/.julia
ENV JUPYTER_DATA_DIR=/workspace/labs/lab01/project/.jupyter
ENV GKSwstype=100

USER dakuokkonen
WORKDIR /workspace/labs/lab01/project

CMD ["bash"]
