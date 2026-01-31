FROM node:22-bookworm

# =========================
# Bun (build scripts)
# =========================
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app

# =========================
# APT packages
# =========================
ARG OPENCLAW_DOCKER_APT_PACKAGES=""
RUN if [ -n "$OPENCLAW_DOCKER_APT_PACKAGES" ]; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $OPENCLAW_DOCKER_APT_PACKAGES && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
    fi

# Install dependencies including Chromium and Python tools
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    $CLAWDBOT_DOCKER_APT_PACKAGES \
    # ---- Browser (Chromium) ----
    chromium \
    chromium-driver \
    fonts-liberation \
    libnss3 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpangocairo-1.0-0 \
    libgtk-3-0 \
    # ---- Existing deps ----
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
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# =========================
# Chromium env
# =========================
ENV CHROME_BIN=/usr/bin/chromium
ENV CHROMIUM_FLAGS="--headless=new \
  --no-sandbox \
  --disable-dev-shm-usage \
  --disable-gpu \
  --disable-software-rasterizer \
  --disable-extensions \
  --disable-background-networking \
  --disable-sync \
  --metrics-recording-only \
  --mute-audio"

# =========================
# Python venv (PEP 668 safe)
# =========================
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN pip install --no-cache-dir \
    pdfminer.six \
    PyPDF2 \
    python-docx \
    pillow \
    pytesseract \
    requests \
    beautifulsoup4

# Venv accessible to node
RUN chown -R node:node $VIRTUAL_ENV

# =========================
# Node deps (build-time)
# =========================
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts

RUN pnpm install --frozen-lockfile

# =========================
# Build
# =========================
COPY . .
RUN OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build
# Force pnpm for UI build (Bun may fail on ARM/Synology architectures)
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

ENV NODE_ENV=production

# =========================
# CLI
# =========================
RUN ln -s /app/openclaw.mjs /usr/local/bin/openclaw && ln -s /app/openclaw.mjs /usr/local/bin/moltbot

# =========================
# Runtime dirs + permissions
# =========================
# Added .npm-global for user-scoped npm installs
RUN mkdir -p \
    /var/lib/moltbot \
    /home/node/clawd \
    /home/node/.npm \
    /home/node/.pnpm \
    /home/node/.npm-global && \
    chown -R node:node \
    /app \
    /var/lib/moltbot \
    /home/node && \
    chmod 700 /var/lib/moltbot

# =========================
# npm / pnpm runtime config
# =========================
ENV NPM_CONFIG_CACHE=/home/node/.npm
ENV PNPM_HOME=/home/node/.pnpm
# Configure npm to use the user-writable global directory
ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
# Add both pnpm and npm global bin dirs to PATH
ENV PATH="/home/node/.pnpm:/home/node/.npm-global/bin:$PATH"

# =========================
# Security
# =========================
USER node

CMD ["node", "dist/index.js"]
