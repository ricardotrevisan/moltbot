# Comprehensive Changes Summary

## 1. Atomized Architecture & Migration Fixes
**Docs**: [DOCKER_ENHANCEMENTS.md](file:///home/trevisan/repositories/moltbot/DOCKER_ENHANCEMENTS.md)
**File**: `docker-compose.yml`

*   **Isolated Volumes**: Replaced host bind mounts with Docker named volumes (`moltbot_data`, `moltbot_workspace`) to solve `EBUSY` migration loops and permission issues.
*   **Zero-Config**: Added `--allow-unconfigured` to the entrypoint for easier first-time setup.
*   **Migration Logic**: Patched `src/infra/state-migrations.ts` to skip rename operations if `EBUSY` occurs, preventing crash loops.

## 2. Dockerfile Capabilities & Permissions
**File**: [Dockerfile](file:///home/trevisan/repositories/moltbot/Dockerfile)

*   **Global NPM Fix**: Configured `NPM_CONFIG_PREFIX` to `/home/node/.npm-global`. Added this path to `PATH` and ensured directory ownership. This allows `npm install -g <skill>` to work as the `node` user without `EACCES` errors.
*   **Headless Browser**: Added `chromium`, `chromium-driver`, and shared libraries for agent browsing.
*   **Python/OCR**: Added `python3`, `pip`, `venv`, `tesseract-ocr`, `poppler-utils`, and pre-installed common Python libs (`pdfminer.six`, etc.) in `/opt/venv`.
*   **Runtime Ownership**: Explicitly creates and assigns `chown node:node` to all runtime directories (`.npm`, `.pnpm`, `.npm-global`, `/var/lib/moltbot`).

## 3. Cron Timezone Support
**Goal**: Ensure alerts trigger at local time (e.g. `UTC-3`) instead of container `UTC`.

*   **Configuration**: Added `timezone` option to `CronConfig`.
*   **Logic**: Updated scheduler to use the configured timezone (or `TZ` env var) for next-run calculations.
*   **Verification**: Tested via code analysis; user can set `TZ=America/Sao_Paulo`.

## 4. Voice Backend Integration
**File**: `docker-compose.yml`

*   **Service Added**: `voice-backend` service (image: `trevisanricardo/ai-voice-backend:latest`) included in the stack.
*   **GPU Support**: Configured for NVIDIA GPU passthrough (`deploy.resources.reservations.devices`).
*   **Environment**: Configured with `AWS_*` credentials for Polly TTS and `OPENAI_API_KEY`.
*   **Network**: Linked `moltbot-gateway` to `voice-backend` via internal network.

---

## Usage Guide
1.  **Rebuild**: `docker compose build` (to apply Dockerfile changes).
2.  **Configure**: Copy `.env.example` to `.env` and set keys + `TZ=America/Sao_Paulo`.
3.  **Start**: `docker compose up -d`
4.  **Interact**: `docker exec -it moltbot moltbot status`
