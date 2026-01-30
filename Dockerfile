FROM node:22-bookworm

# Install Bun (required for build scripts)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app

ARG CLAWDBOT_DOCKER_APT_PACKAGES=""
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    $CLAWDBOT_DOCKER_APT_PACKAGES \
    python3 \
    python3-pip \
    python3-venv \
    poppler-utils \
    qpdf \
    tesseract-ocr \
    tesseract-ocr-eng \
    tesseract-ocr-por \
    ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*;

# Setup Python Virtual Environment
# We use a venv to avoid PEP 668 issues on Debian Bookworm
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install Python dependencies
# We install these as root but they will be accessible to all users via the global read permissions
# and the PATH modification above.
RUN pip install --no-cache-dir \
    pdfminer.six \
    PyPDF2 \
    python-docx \
    pillow \
    pytesseract \
    requests \
    beautifulsoup4

# Ownership adjustment for runtime pip installs
# This allows the 'node' user to install additional packages at runtime if needed
RUN chown -R node:node $VIRTUAL_ENV

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts

RUN pnpm install --frozen-lockfile

COPY . .
RUN CLAWDBOT_A2UI_SKIP_MISSING=1 pnpm build
# Force pnpm for UI build (Bun may fail on ARM/Synology architectures)
ENV CLAWDBOT_PREFER_PNPM=1
RUN pnpm ui:install
RUN pnpm ui:build

ENV NODE_ENV=production

# Create global CLI symlink
RUN ln -s /app/moltbot.mjs /usr/local/bin/moltbot

# Ensure state directories exist and are owned by node
RUN mkdir -p /var/lib/moltbot /home/node/clawd && \
    chown -R node:node /var/lib/moltbot /home/node/clawd && \
    chmod 700 /var/lib/moltbot

# Security hardening: Run as non-root user
# The node:22-bookworm image includes a 'node' user (uid 1000)
# This reduces the attack surface by preventing container escape via root privileges
USER node

CMD ["node", "dist/index.js"]
