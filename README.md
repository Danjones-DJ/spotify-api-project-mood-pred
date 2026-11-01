# Spotify hourly collection

Copy these files into your repository using the included paths. Keep your existing
`dist/collecting-dmj-spotify-hist.csv`: it is the historical input and updated output.
The new fetch is also saved to `data/new-batch.csv` on every run.

## One-time setup

1. In Spotify Developer settings, register `http://127.0.0.1:1410` as a redirect URI.
2. From your project root in local R, run `source("R/00-set-up.R")` and approve access.
3. In GitHub: repository Settings → Secrets and variables → Actions → New repository secret:
   - `SPOTIFY_CLIENT_ID`: `cc525d9f178345069373a54b2696e58a`
   - `SPOTIFY_REFRESH_TOKEN`: contents of the generated `spotify-refresh-token.txt`.
4. Delete the local token text file after adding the secret. Merge the supplied
   `.gitignore` entries into any existing `.gitignore`.
5. Commit these scripts, the workflow, and your existing dist CSV to the default branch.
6. Actions → Collect Spotify history → Run workflow to test immediately.

The workflow requests an hourly run at minute 17 (UTC). GitHub scheduling can be
delayed; it is not an exact 60-minute timer. Each successful run commits both CSVs.
The token setup script runs only on your computer, not in the scheduled job.
If Spotify revokes the token, repeat the one-time setup and replace the secret.

## Preserved behaviour

- Fetch latest 50 Spotify plays once per run; no pagination added.
- Same columns, artist expansion and new-batch CSV output.
- Your append function is copied unchanged: new rows first, chronological sort,
  `distinct(played_at, .keep_all = TRUE)`, recalculate gaps, ±3-second full-listen
  threshold, newest first.
- Multiple artist rows are still reduced to the first row by your timestamp
  deduplication rule. This intentionally preserves your rule.
- No new mood analysis, fields, or dashboards.

## Repairs

- Explicit `client = c`, `old = o`, and `new = n` inputs.
- Client initialisation only in the run/setup scripts; no hidden fetch on sourcing.
- Noninteractive refresh-token authentication on Actions; local interactive
  authentication remains available if no refresh-token environment variable is set.
- Explicit CSV column types and millisecond timestamp normalisation so overlaps
  remain equal after a CSV round trip; deduplication key stays `played_at`.
- Empty API batches do not destroy history; failed requests stop the run.
- A validated temporary CSV replaces the dist CSV after successful processing.

## Verification limits

The archive and YAML were checked locally. This environment has no R executable
or access to your Spotify login, so authenticated execution must be checked with
Run workflow. No claim is made that Spotify will immediately return every new play.
Keeping your latest-50 behaviour means more than 50 plays between runs may be missed.
