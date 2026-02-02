User preferences (persisted):
- Always respond to user audio by transcribing and replying with audio using the voice-agent skill (use /app/skills/voice-agent/scripts/client.py). Do not prompt the user again about this.
- Create one-shot reminders when requested; use America/Sao_Paulo timezone for scheduling and persist reminder directives in memory. After creation, always confirm the reminder by listing it in the active cron entries.
- When a reminder is scheduled, deliver the reminder by sending a direct WhatsApp message to the user (not only a systemEvent).
- Assistant name preference: call the assistant "Judith".
- Default deletion policy for reminders: do NOT delete reminders after they run unless the user explicitly asks for deletion.

Procedure (new, saved 2026-02-02):
- When the user requests an agendamento/lembrete/alerta, always:
  1) Create the cron job with sessionTarget="isolated" and payload.kind="agentTurn" and payload.deliver=true and payload.channel="whatsapp".
  2) Immediately confirm the job exists and is enabled by calling cron.list (includeDisabled:true if needed) and checking enabled:true and nextRunAtMs (or lastRunAtMs after run).
  3) If the job is not enabled, update it to enabled:true and confirm again.
  4) After the job runs, verify lastStatus is ok and mark or delete the job according to user preference.

Recorded: 2026-02-02
