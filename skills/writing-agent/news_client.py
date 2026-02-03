import argparse
import json
import os
import sys
import requests

# Default configuration
# The agent will run inside the docker network usually, or localhost if host. 
# 'news-agent:8008' key implies docker network.
BASE_URL = os.getenv("NEWS_AGENT_URL", "http://news-agent:8008")
CACHE_FILE = "/tmp/news_agent_cache.json"

def fetch_news(days_back=1, topic=None):
    """Fetch news from the API and save to cache."""
    url = f"{BASE_URL}/news/fetch"
    
    # Construct payload based on API requirement
    payload = {
        "days_back": days_back,
        "include_sources": True,
        "include_chatgpt": False
    }
    
    if topic:
        payload["user_comment"] = f"Topic: {topic}"

    try:
        response = requests.post(url, json=payload, timeout=60)
        response.raise_for_status()
        news_items = response.json()
        
        # Save to cache
        with open(CACHE_FILE, "w") as f:
            json.dump(news_items, f)
            
        print(f"Successfully fetched {len(news_items)} news items.")
        print("-" * 40)
        for i, item in enumerate(news_items):
            print(f"Index: {i}")
            print(f"Title: {item.get('title', 'No Title')}")
            print(f"Source: {item.get('source', 'Unknown')}")
            print(f"Link: {item.get('link', '#')}")
            print("-" * 40)
            
    except Exception as e:
        print(f"Error fetching news: {e}")
        sys.exit(1)

def generate_article(index, provider="openai"):
    """Generate an article from a cached news item."""
    if not os.path.exists(CACHE_FILE):
        print("Error: No news cache found. Please run 'fetch' first.")
        sys.exit(1)
        
    try:
        with open(CACHE_FILE, "r") as f:
            news_items = json.load(f)
            
        if index < 0 or index >= len(news_items):
            print(f"Error: Invalid index {index}. Available: 0-{len(news_items)-1}")
            sys.exit(1)
            
        selected_item = news_items[index]
        
        url = f"{BASE_URL}/posts/generate"
        
        # Enforcing gpt-5-mini as requested
        payload = {
            "news_items": [selected_item],
            "prompt_file": "defaultProfile.txt", 
            "provider": provider,
            "openai_model": "gpt-5-mini",
            "temperature": 1.0 
        }
        
        print(f"Generating article for: {selected_item.get('title')} (Model: gpt-5-mini)...")
        response = requests.post(url, json=payload, timeout=180)
        response.raise_for_status()
        result = response.json()
        
        print("\n" + "="*20 + " GENERATED ARTICLE " + "="*20 + "\n")
        print(result.get("content", "No content returned."))
        print("\n" + "="*20 + " END OF ARTICLE " + "="*20 + "\n")
        
    except Exception as e:
        print(f"Error generating article: {e}")
        # Try to print response text if available for debugging
        if 'response' in locals() and hasattr(response, 'text'):
             print(f"Server response: {response.text}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="News Agent Client")
    subparsers = parser.add_subparsers(dest="command", required=True)
    
    # Fetch command
    fetch = subparsers.add_parser("fetch", help="Fetch news items")
    fetch.add_argument("--days", type=int, default=1, help="Days back to search")
    fetch.add_argument("--topic", type=str, help="Topic to filter/search for")
    
    # Generate command
    gen = subparsers.add_parser("generate", help="Generate article from fetched news")
    gen.add_argument("index", type=int, help="Index of the news item to use")
    gen.add_argument("--provider", type=str, default="openai", help="LLM Provider (default: openai)")
    
    args = parser.parse_args()
    
    if args.command == "fetch":
        fetch_news(args.days, args.topic)
    elif args.command == "generate":
        generate_article(args.index, args.provider)

if __name__ == "__main__":
    main()
