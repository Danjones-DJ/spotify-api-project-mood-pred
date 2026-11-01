append_old_new = function(old = o, new = n) {
  
  output = bind_rows(new, old) %>%
    arrange(track_id, played_at) %>%
    group_by(track_id) %>%
    mutate(
      duplicate = coalesce(
        as.numeric(difftime(
          played_at, lag(played_at), units = "secs"
        )) <= 1,
        FALSE
      )
    ) %>%
    filter(!duplicate) %>%
    ungroup() %>%
    select(-duplicate) %>%
    arrange(played_at) %>%
    mutate(
      finished_at = played_at + track_duration_ms / 1000,
      gap_seconds = as.numeric(
        difftime(lead(played_at), finished_at, units = "secs")
      ),
      listened_in_full = abs(gap_seconds) <= 3
    ) %>%
    arrange(desc(played_at))
  
  return(output)
}