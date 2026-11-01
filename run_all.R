source("R/packages.R")
source("R/fetch_next_50.R")
source("R/append_old_new.R")

# Preserve the Spotify client setup.
c = oauth_client(
  id = Sys.getenv("SPOTIFY_CLIENT_ID", "cc525d9f178345069373a54b2696e58a"),
  token_url = "https://accounts.spotify.com/api/token",
  name = "my-spotify-dashboard"
)

dir.create("data", showWarnings = FALSE, recursive = TRUE)
dir.create("dist", showWarnings = FALSE, recursive = TRUE)

# The continuously updated DIST file is the only historical input.
history_path = "dist/collecting-dmj-spotify-hist.csv"
if (!file.exists(history_path)) {
  stop("Missing dist/collecting-dmj-spotify-hist.csv. Put your existing history there before running.")
}
# Explicit types prevent an all-NA logical column being inferred incorrectly.
history_types = cols(
  track_duration_ms = col_double(), track_explicit = col_logical(),
  track_id = col_character(), track_name = col_character(),
  track_artists_name = col_character(),
  played_at = col_datetime(), finished_at = col_datetime(),
  gap_seconds = col_double(), listened_in_full = col_logical()
)
o = read_csv(history_path, col_types = history_types)
if (nrow(problems(o)) > 0) stop("History contains CSV parsing errors; no history written.")

# Fetch exactly once; the function also writes data/new-batch.csv.
new_batch = fetch_next_50(client = c)
n = new_batch

# Stabilise floating-point timestamp parsing at Spotify's millisecond precision.
# distinct(played_at, .keep_all = TRUE) remains unchanged in the append function.
normalise_timestamp = function(x) {
  as.POSIXct(round(as.numeric(x) * 1000) / 1000,
             origin = "1970-01-01", tz = "UTC")
}
o$played_at = normalise_timestamp(o$played_at)
n$played_at = normalise_timestamp(n$played_at)

updated = append_old_new(old = o, new = n)
# Re-read before replacing history, so a failed write never truncates the old CSV.
pending_path = "dist/collecting-dmj-spotify-hist.pending.csv"
write_csv(updated, pending_path)
check = read_csv(pending_path, col_types = history_types)
stopifnot(nrow(check) == nrow(updated), nrow(problems(check)) == 0)
if (!file.rename(pending_path, history_path)) stop("Could not replace historical CSV.")
message("Saved ", nrow(updated), " rows to ", history_path)
if (nrow(n) > 0) message("Latest fetched play (UTC): ", format(max(n$played_at), tz = "UTC", usetz = TRUE))
