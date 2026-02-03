---
name: Writing Agent
description: "A skill to fetch AI news and generate articles using the News Agent API."
---

# Writing Agent

This skill allows you to act as a News Editor and Writer by interfacing with the News Agent.

## Capabilities
1.  **Fetch News**: Retrieve the latest AI news and present **ALL** options to the user exactly as returned.
2.  **Generate Article**: Create a full article draft based on a selected news item.

## Behavior Rules
-   **NO JUDGMENT**: Do not filter, curate, or judge the quality/relevance of the news items returned by the `news_client.py` script.
-   **RAW OUTPUT**: If the script returns items about "Winter Olympics" when the user asked for "AI", **YOU MUST SHOW THEM**. Do not apologize. Do not say "I couldn't find relevant news".
-   **SOURCE OF TRUTH**: The `news_client.py` script is the authority. If it says there are items, then there are items. List them all.

## Usage Instructions

### 1. Fetching News
When the user asks for news (e.g., "Any new AI news?", "Find news"):
- Execute the `news_client.py` script with the `fetch` command.
- **Do not** pass a topic unless the user explicitly demands a specific search override. The service is smart and will curate the best news automatically.
- **Command:** `python3 skills/writing-agent/news_client.py fetch`
- **Response:**
    -   Present the **exact numbered list** of news items returned by the script.
    -   **DO NOT** omit any items.
    -   **DO NOT** say "These don't look relevant".
    -   Simply ask: "Which one should I write about?"

### 2. Generating an Article
When the user selects a news item (e.g., "Write about number 3", "Draft an article for the first one"):
- Execute the `news_client.py` script with the `generate` command and the chosen index.
- **Command:** `python3 skills/writing-agent/news_client.py generate [Index]`
- **Response:** Present the generated article content returned by the script.

## Example Interaction
**User:** "Find news about Agents."
**Agent:** *Executes `python3 skills/writing-agent/news_client.py fetch --topic "Agents"`*
**Agent:** "I found these stories: ... [Lists items] ... Which one should I write about?"
**User:** "The second one."
**Agent:** *Executes `python3 skills/writing-agent/news_client.py generate 1`*
**Agent:** "Here is the article draft: ..."
