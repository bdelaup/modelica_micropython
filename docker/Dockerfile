FROM openmodelica/openmodelica:v1.24.4-minimal

RUN echo 'installPackage(Modelica, "4.1.0", exactMatch=false); getErrorString();' > /tmp/i.mos \
    && omc /tmp/i.mos > /tmp/i.log \
    && cat /tmp/i.log \
    && grep -qx true /tmp/i.log \
    && rm /tmp/i.mos /tmp/i.log

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG PBS_URL=https://github.com/astral-sh/python-build-standalone/releases/download/20261110/cpython-3.12.16%2B20261110-x86_64-unknown-linux-gnu-install_only_stripped.tar.gz
ARG PBS_SHA256=6a9e62dad033790aef722dbd370e0ce76ce17b73627ba3ae679f537049350b39
RUN curl -fsSL "$PBS_URL" -o /tmp/python.tar.gz \
    && echo "$PBS_SHA256  /tmp/python.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/python.tar.gz -C /opt \
    && rm /tmp/python.tar.gz \
    && /opt/python/bin/python3 -c 'import ssl; assert ssl.OPENSSL_VERSION'

ENV PATH="/opt/python/bin:${PATH}"

WORKDIR /w
