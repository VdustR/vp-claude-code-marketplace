---
name: gmaps-list
description: >-
  Extract all places from a Google Maps saved list URL.
  Use when users share a Google Maps list link (maps.app.goo.gl/... or google.com/maps/...) and want to extract all places from it.
---

# Google Maps List Extractor

Extract all places from a shared Google Maps saved list in a single API call, bypassing the UI's limited scroll-based rendering.

## Prerequisites

This skill uses [agent-browser](https://github.com/anthropics/claude-code/tree/main/.claude/skills/agent-browser) to open the list URL and execute JavaScript within the page context. Install the agent-browser skill before using this skill:

```
/install-skill agent-browser
```

## When to Use

- User shares a Google Maps list URL (`maps.app.goo.gl/...` or `google.com/maps/.../@/data=...`)
- User wants to extract, export, or analyze places from a saved list
- User asks how many items are in a Google Maps list

## Workflow

### Phase 1: Open the list URL

Open the Google Maps list URL in agent-browser. Wait for the page to load (the `networkidle` wait may time out because Google Maps keeps active connections — this is expected; a fixed 5-second wait after navigation is sufficient).

### Phase 2: Discover the API endpoint

Run this JavaScript via agent-browser to find the internal API URL from the page's performance entries:

```js
performance.getEntriesByType("resource")
  .find(e => e.name.includes("entitylist/getlist"))
  ?.name
```

The URL looks like:

```
/maps/preview/entitylist/getlist?authuser=0&hl=zh-TW&gl=tw&pb=!1m4!1s<LIST_ID>!2e1!3m1!1e1!2e2!3e2!4i500...
```

Key parameters:
- `!1s<LIST_ID>` — the list identifier (e.g., `164bI_79K-Xzimzr32UrF7H5udaA`)
- `!4i500` — max items to return (Google defaults to 500, which covers most lists)

### Phase 3: Fetch and parse the full list

Execute this JavaScript **inside the browser context** (the API requires the page's session cookies — direct `curl` calls will return 400):

```js
(async () => {
  const entry = performance.getEntriesByType("resource")
    .find(e => e.name.includes("entitylist/getlist"));
  const resp = await fetch(entry.name);
  const text = await resp.text();
  // Remove XSSI protection prefix ")]}'\n"
  const jsonStr = text.substring(text.indexOf('\n') + 1);
  const data = JSON.parse(jsonStr);

  const listName = data[0][4];
  const items = data[0][8];

  const results = items.map((item, idx) => {
    const loc = item[1];
    return JSON.stringify({
      i: idx + 1,
      name: item[2] || "",
      address: loc?.[4] ?? "",
      lat: loc?.[5]?.[1] ?? "",
      lng: loc?.[5]?.[2] ?? "",
      note: item[3] ?? "",
      gid: loc?.[7] ?? ""
    });
  });

  return "LIST:" + listName + "\nCOUNT:" + items.length + "\n" + results.join("\n");
})()
```

### Phase 4: Present results

Parse the output and present it to the user. Common output formats:
- **Summary table** — name, address, note (default)
- **JSON** — full structured data if user wants to process further
- **CSV** — if user wants to import into a spreadsheet

## Response Structure

| Index | Field | Description |
|-------|-------|-------------|
| `data[0][4]` | List name | e.g., "V Picks" |
| `data[0][8]` | Items array | All places in the list |
| `item[1]` | Location info | Nested array with address, coords, place ID |
| `item[1][4]` | Address | Full address string |
| `item[1][5][1]` | Latitude | Float |
| `item[1][5][2]` | Longitude | Float |
| `item[1][7]` | Google Place ID | `/g/...` format |
| `item[2]` | Place name | Display name on Google Maps |
| `item[3]` | User note | Personal note added by list owner (may be empty) |

## Notes

- The response has a `)]}'\n` XSSI protection prefix — always strip it before parsing
- The `fetch()` MUST run inside the browser page context; the API requires Google Maps session cookies
- Older items in long lists may have empty address/coordinates fields (only name preserved)
- The `!4i500` parameter controls max items; increase if a list has 500+ items
- Close the browser session after extraction to avoid leaked processes
