# Run ONCE locally to obtain the GitHub Actions refresh token.
source("R/packages.R")
c = oauth_client(
  id = Sys.getenv("SPOTIFY_CLIENT_ID", "cc525d9f178345069373a54b2696e58a"),
  token_url = "https://accounts.spotify.com/api/token",
  name = "my-spotify-dashboard"
)
# Register http://127.0.0.1:1410 in your Spotify application's redirect URIs.
token = oauth_flow_auth_code(
  client = c,
  auth_url = "https://accounts.spotify.com/authorize",
  scope = "user-read-recently-played",
  redirect_uri = "http://127.0.0.1:1410",
  pkce = TRUE
)
stopifnot(is.character(token$refresh_token), nzchar(token$refresh_token))
# Contains a credential: paste its contents into the GitHub secret, then delete.
writeLines(token$refresh_token, "spotify-refresh-token.txt")
message("Refresh token saved to spotify-refresh-token.txt. Add it as the SPOTIFY_REFRESH_TOKEN Actions secret, then delete this local file.")
