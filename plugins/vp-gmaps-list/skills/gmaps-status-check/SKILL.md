---
name: gmaps-status-check
description: >-
  Check business status of places in a Google Maps saved list to find permanently
  closed or temporarily closed places. Use when asked to "check which places are
  closed", "find permanently closed places", "find removed or invalid items",
  "find 永久歇業", "find 暫停營業", "identify invalid landmarks",
  "check business status", or "clean up my saved list".
---

# Google Maps Business Status Checker

Check business status of places in a Google Maps saved list to identify permanently closed (永久歇業) or temporarily closed (暫停營業) places.

## Prerequisites

Two approaches available. **Always ask the user which to use** — do not auto-detect or auto-fallback.

| Approach | Speed | Cost | Reliability |
|----------|-------|------|-------------|
| **gcloud + Places API** (recommended) | ~2 min / 220 places | ~$0.032/query (~$7 for 220, covered by $200/mo free credit) | High — structured `businessStatus` field |
| **Playwright** (free fallback) | ~11 min / 220 places | Free | Medium — DOM parsing may miss some |

### Option A: Google Places API via gcloud (Recommended)

- `gcloud` CLI installed and authenticated
- GCP project with billing enabled
- Places API (New) enabled: `gcloud services enable places.googleapis.com`

### Option B: Playwright (Free)

- Node.js with `playwright` package: `npm install playwright && npx playwright install chromium`
- Slower, less reliable for large batches

## When to Use

- User wants to find closed/defunct places in a Google Maps list
- User asks about 營業狀態 or business status
- User wants to clean up a saved list by identifying invalid landmarks
- User shares a Google Maps list URL and asks about "失效的地標"

## Workflow

### Step 1: Confirm approach and Google account

**Always ask the user:**

1. Which approach: gcloud (recommended, faster, more reliable) or Playwright (free)?
2. If gcloud: which Google account to use?

Do NOT auto-detect, auto-fallback, or assume which account. Wait for the user's explicit choice. If the user has documented a preferred Google account in their CLAUDE.md or memory files, suggest it but still confirm.

### Step 2: Extract places

Use the `gmaps-list` skill to extract all places from the list URL. Save the extracted data for processing.

Format a file at `/tmp/all_places.txt` with one place per line:

```
1|Place Name search query
2|Another Place search query
```

Include address/area info in the search query for better matching (e.g., `試茶 台南中西區南寧街`).

### Step 3A: Check via Places API (gcloud)

Verify prerequisites:

```bash
gcloud auth list  # Confirm correct account is active
gcloud config get project  # Confirm project
gcloud services list --enabled --filter="name:places.googleapis.com"  # Confirm API enabled
```

Generate OAuth token and run the check script:

```js
import { readFileSync, writeFileSync } from 'fs';

const TOKEN = process.env.GCLOUD_TOKEN;
const PROJECT = process.env.GCLOUD_PROJECT;

const places = readFileSync('/tmp/all_places.txt', 'utf8')
  .trim().split('\n')
  .map(line => {
    const sep = line.indexOf('|');
    if (sep === -1) return null;
    return { idx: line.substring(0, sep).trim(), query: line.substring(sep + 1).trim() };
  })
  .filter(Boolean);

const results = [];
const total = places.length;
let retries = 0;

for (let i = 0; i < total; i++) {
  const { idx, query } = places[i];
  try {
    const resp = await fetch('https://places.googleapis.com/v1/places:searchText', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${TOKEN}`,
        'X-Goog-User-Project': PROJECT,
        'Content-Type': 'application/json',
        'X-Goog-FieldMask': 'places.displayName,places.businessStatus,places.id',
      },
      body: JSON.stringify({ textQuery: query, languageCode: 'zh-TW' }), // change languageCode as needed — only affects displayName, not businessStatus
    });

    if (!resp.ok) {
      const errBody = await resp.text().catch(() => '');
      console.log(`[${i+1}/${total}] #${idx} HTTP ${resp.status}: ${errBody.substring(0, 120)}`);
      if (resp.status === 429 && retries++ < 3) { await new Promise(r => setTimeout(r, 5000)); i--; continue; }
      if (resp.status === 429) { console.log(`[${i+1}/${total}] #${idx} SKIPPED (retry limit): ${query}`); continue; }
      if (i === 0) { console.log('First request failed — check billing, API enablement, and token.'); break; }
      continue;
    }
    retries = 0;

    const data = await resp.json();
    const place = data.places?.[0];

    if (!place) {
      console.log(`[${i+1}/${total}] #${idx} NOT_FOUND: ${query}`);
    } else if (place.businessStatus && place.businessStatus !== 'OPERATIONAL') {
      const name = place.displayName?.text || query;
      results.push({ idx, query, name, status: place.businessStatus, placeId: place.id });
      console.log(`[${i+1}/${total}] #${idx} ${place.businessStatus}: ${name}`);
    } else {
      if ((i+1) % 20 === 0) console.log(`[${i+1}/${total}] progress...`);
    }
  } catch (e) {
    console.log(`[${i+1}/${total}] #${idx} ERROR: ${e.message.substring(0, 80)}`);
  }
  if (i < total - 1) await new Promise(r => setTimeout(r, 200)); // rate limit buffer
}

writeFileSync('/tmp/closed_places.json', JSON.stringify(results, null, 2));
console.log(`\n=== DONE === Found ${results.length} non-operational places`);
results.forEach(r => console.log(`#${r.idx} | ${r.name} | ${r.status}`));
```

Save the script to `/tmp/check_places_api.mjs` and execute:

```bash
GCLOUD_TOKEN=$(gcloud auth print-access-token) GCLOUD_PROJECT=<project-id> node /tmp/check_places_api.mjs
```

### Step 3B: Check via Playwright (free)

Save the script to `/tmp/check_playwright.mjs` and run with `node /tmp/check_playwright.mjs`.

```js
import { chromium } from 'playwright';
import { readFileSync, writeFileSync } from 'fs';

const places = readFileSync('/tmp/all_places.txt', 'utf8')
  .trim().split('\n')
  .map(line => {
    const sep = line.indexOf('|');
    if (sep === -1) return null;
    return { idx: line.substring(0, sep).trim(), query: line.substring(sep + 1).trim() };
  })
  .filter(Boolean);

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();

await page.goto('https://www.google.com/maps', { waitUntil: 'networkidle' })
  .catch(() => { console.error('Failed to load Google Maps'); process.exit(1); });
await page.waitForSelector('input[name="q"]', { timeout: 10000 });

const results = [];
const total = places.length;

for (let i = 0; i < total; i++) {
  const { idx, query } = places[i];
  try {
    const input = page.locator('input[name="q"]');
    await input.fill(query);
    await input.press('Enter');
    await page.waitForTimeout(3000);

    const status = await page.evaluate(() => {
      const CLOSED = ['永久歇業', 'Permanently closed']; // add locale strings as needed
      const TEMP = ['暫停營業', 'Temporarily closed'];
      const main = document.querySelector('[role="main"]');
      const text = main ? main.textContent : '';
      const h1 = document.querySelector('h1');
      return {
        name: h1 ? h1.textContent : '',
        closed: CLOSED.some(s => text.includes(s)),
        tempClosed: TEMP.some(s => text.includes(s)),
      };
    });

    if (status.closed) {
      results.push({ idx, query, name: status.name, status: 'CLOSED_PERMANENTLY' });
      console.log(`[${i+1}/${total}] #${idx} CLOSED: ${status.name}`);
    } else if (status.tempClosed) {
      results.push({ idx, query, name: status.name, status: 'CLOSED_TEMPORARILY' });
      console.log(`[${i+1}/${total}] #${idx} TEMP: ${status.name}`);
    } else {
      if ((i+1) % 20 === 0) console.log(`[${i+1}/${total}] progress...`);
    }
  } catch (e) {
    console.log(`[${i+1}/${total}] #${idx} ERROR: ${e.message.substring(0, 80)}`);
  }
}

await browser.close();

writeFileSync('/tmp/closed_places.json', JSON.stringify(results, null, 2));
console.log(`\n=== DONE === Found ${results.length} closed places`);
results.forEach(r => console.log(`#${r.idx} | ${r.name} | ${r.status}`));
```

### Step 4: Present results

Cross-reference the closed places with the original `gmaps-list` extraction data to get the `gid` for link generation. Generate a markdown file with clickable Google Maps links, grouped by status:

- **CLOSED_PERMANENTLY** (永久歇業) — permanently closed
- **CLOSED_TEMPORARILY** (暫停營業) — temporarily closed

For places with a `gid` (from the gmaps-list extraction, `/g/...` format):

```
https://www.google.com/maps/place/data=!3m1!4b1!4m2!3m1!1s{gid}
```

For places without a gid:

```
https://www.google.com/maps/search/{encoded_name_and_area}
```

Note: The Places API `place.id` field (`ChIJ...` format) differs from the gmaps-list `gid` (`/g/...` format). Use the gmaps-list gid for direct links.

## Notes

- Places API `businessStatus` values: `OPERATIONAL`, `CLOSED_PERMANENTLY`, `CLOSED_TEMPORARILY`
- The two approaches may produce slightly different results due to search matching differences — recommend cross-referencing (union) for completeness
- OAuth tokens from `gcloud auth print-access-token` expire after 1 hour
- Places API cost assumes Basic SKU field mask (`displayName`, `businessStatus`, `id`) — adding fields like `formattedAddress` increases cost tier
- After checking, suggest disabling the API if not needed: `gcloud services disable places.googleapis.com`
- Playwright approach checks both Chinese (`永久歇業` / `暫停營業`) and English (`Permanently closed` / `Temporarily closed`) DOM text — other locales may need additional strings
- Only the first search result is checked (`places[0]`) — ambiguous queries may match a different place. Include address/area in the search query to improve accuracy
- agent-browser is not recommended for batch status checks — the daemon becomes unreliable at 200+ sequential cycles; use Playwright directly instead
- Playwright: Google Maps may show a cookie consent banner in fresh profiles — dismiss it before the main loop if encountered
- Playwright: ambiguous queries may show a results list instead of a single place — `h1` will be empty and DOM text may contain status from other places in the list (potential false positive)
- Playwright: if Google serves a CAPTCHA in headless mode, re-run with `headless: false` to solve it manually
