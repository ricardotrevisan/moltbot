# Moltbot User Guide

This guide covers how to set up, run, and configure Moltbot with the GPU-accelerated **Voice Agent** skill.

## 1. Quick Start

### A. Prerequisites
- Docker & Docker Compose
- NVIDIA Container Toolkit (for GPU support)
- OpenAI API Key
- AWS Keys (for Polly TTS)

### B. Setup
1.  **Clone the repository**:
    ```bash
    git clone https://github.com/ricardotrevisan/moltbot.git
    cd moltbot
    git checkout feature/voice-agent-skill
    ```

2.  **Configure Environment**:
    Copy the example and add your keys.
    ```bash
    cp .env.example .env
    nano .env
    ```
    *   **Required**: `OPENAI_API_KEY`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`

3.  **Launch**:
    Start the entire stack (Gateway + Voice Backend).
    ```bash
    docker compose up -d
    ```

## 2. Onboarding

Once the containers are running, you need to initialize the bot and pair your WhatsApp.

1.  **Run the Onboard Wizard**:
    ```bash
    docker exec -it moltbot moltbot onboard
    ```
2.  Follow the prompts:
    *   **Name your bot**: (e.g., "Jarvis")
    *   **Pair WhatsApp**: Select "WhatsApp", then "Link". Scan the QR code with your phone.

## 3. The Voice Agent Skill

Your bot is equipped with the `voice-agent` skill, which uses a local GPU backend for high-quality Speech-to-Text (Whisper) and Text-to-Speech (Polly).

### Health Check
To verify the voice system is working:
```bash
# Run the skill's health check inside the container
docker exec -it moltbot python3 /app/skills/voice-agent/scripts/client.py health
```
*Expected Output*: `✅ Voice Agent API is UP`

### How It Works
*   **Transcribe**: Converts your audio notes to text so the agent can read them.
*   **Synthesize**: Converts the agent's reply to an audio file.

## 4. Activating "Voice Mode"

By default, the agent might reply with text. To enforce a natural voice conversation flow (Voice-in → Voice-out), you need to give it a **Directive**.

### The Directive
Send this message to your bot (via WhatsApp or the terminal):

> "I want to establish a permanent rule for our interaction.
> 
> **Rule: Voice Mode**
> When I send you a **voice message** (audio), you must:
> 1.  Transcribe it using the `voice-agent` skill.
> 2.  Reply **ONLY** with an audio file (using `voice-agent` synthesize).
> 3.  **DO NOT** send any text explanation like 'Here is the audio'. Just send the file.
> 
> When I send text, reply with text.
> 
> Please update your **SOUL** to remember this preference forever."

### Verification
1.  Send a voice note saying "Hello, are you there?".
2.  The bot should reply **only** with a voice note.

---

## Troubleshooting

**"Could not connect to Voice Agent API"**
*   Ensure the `voice-backend` container is running: `docker ps`
*   Check if `VOICE_AGENT_API_URL` is set to `http://voice-backend:8000` inside the container:
    ```bash
    docker exec moltbot env | grep VOICE
    ```

**Permissions Errors**
*   If you see permissions errors restart with a clean slate (don't worry, WhatsApp stays paired):
    ```bash
    docker compose down
    docker compose up -d
    ```
