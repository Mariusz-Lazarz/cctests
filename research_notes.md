# Claude Code Token Cost: Bash vs jq

## Overview

A quick experiment comparing token usage and API cost when querying a JSON file using two approaches in Claude Code: plain bash (reading the file and filtering with shell tools) vs jq (a dedicated JSON processor).

## Test

The task was identical in both cases: open `airports.json` and list all airports located in the US along with their IATA codes.

## Results

| Metric | bash | jq |
|---|---|---|
| Model | claude-sonnet-4-6 | claude-sonnet-4-6 |
| Input tokens | 347 | 347 |
| Output tokens | 289 | 311 |
| Cache read | 7,375,000 | 6,237,500 |
| Cache write | 1,712,500 | 1,000,000 |
| Cost per query | $8.64 | $5.63 |
| Daily cost (10 queries) | $86.40 | $56.27 |
| Monthly cost | $2,591 | $1,688 |

## Conclusion

jq was approximately **30% cheaper**. The main difference came from cache writes — bash loaded more raw file content into the model's context, while jq pre-filtered the data before passing it along. Since cache write is the most expensive token type ($3.75 per 1M tokens), keeping context lean pays off.

At scale, this difference grows significantly. For large JSON files (MBs), bash may pull the entire file into context while jq extracts only the relevant fields — potentially reducing costs by an order of magnitude per query.

> **Rule of thumb:** pre-process data before it reaches the model. Less context = fewer tokens = lower cost.
