fetch_next_50 = function(client = c) {

  # Making the request
  spotify_request = request("https://api.spotify.com/v1/me/player/recently-played") |>
    req_url_query(limit = 50) # Limit is 50 on Spotify Developer

  refresh_token = Sys.getenv("SPOTIFY_REFRESH_TOKEN")
  if (nzchar(refresh_token)) {
    spotify_request = spotify_request |>
      req_oauth_refresh(
        client = client,
        refresh_token = refresh_token,
        token_params = list(client_id = client$id)
      )
  } else {
    if (identical(Sys.getenv("GITHUB_ACTIONS"), "true")) {
      stop("Missing GitHub Actions secret: SPOTIFY_REFRESH_TOKEN")
    }
    spotify_request = spotify_request |>
      req_oauth_auth_code(
      client = client, # Above
      auth_url = "https://accounts.spotify.com/authorize",
      scope = "user-read-recently-played",
      redirect_uri = "http://127.0.0.1:1410",
      cache_disk = TRUE
    )
  }
  
  # Format data
  response_items = spotify_request |>
    req_perform() |>
    resp_body_json() |>
    purrr::pluck("items")

  if (length(response_items) == 0L) {
    batch = tibble(
      track_duration_ms = double(), track_explicit = logical(),
      track_id = character(), track_name = character(),
      track_artists_name = character(),
      played_at = as.POSIXct(character(), tz = "UTC"),
      finished_at = as.POSIXct(character(), tz = "UTC"),
      gap_seconds = double(), listened_in_full = logical()
    )
    write_csv(batch, "data/new-batch.csv")
    message("Spotify returned no recent plays.")
    return(batch)
  }

  items = response_items |>
    tibble::tibble(item = _) |>
    tidyr::unnest_wider(item) |>
    tidyr::unnest_wider(track, names_sep = "_") |>
    tidyr::unnest_longer(track_artists) |>
    tidyr::unnest_wider(track_artists, names_sep = "_")
  
  # Format new batch
  batch = items %>%
    select(track_duration_ms, track_explicit, track_id, track_name, track_artists_name, played_at) %>%
    mutate(
      played_at = as.POSIXct(played_at, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC"),
      finished_at = played_at + track_duration_ms / 1000
    ) %>%
    arrange(played_at) %>%
    mutate(
      gap_seconds = as.numeric(difftime(lead(played_at), finished_at, units = "secs")),
      listened_in_full = abs(gap_seconds) <= 3
    )
  
  message("Created new batch: ", max(batch$played_at))
  write_csv(batch, paste0("data/new-batch.csv"))
  return(batch)
}






