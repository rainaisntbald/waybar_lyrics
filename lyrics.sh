cache_dir="/tmp/lyrics_cache"
mkdir -p "$cache_dir"

max_length=65

debug=0
if [[ "$1" == "--debug" ]]; then
    debug=1
fi

truncate_text() {
    local text="$1"
    if (( ${#text} > max_length )); then
        echo "${text:0:max_length}…"
    else
        echo "$text"
    fi
}

last_cache_key=""
last_lyrics=""
last_position_sec=0
last_duration_sec=0

while true; do
    status=$(playerctl status 2>/dev/null)
    if [[ "$status" != "Playing" ]]; then
        if [[ "$status" == "Paused" ]]; then
            echo "⏸️ Paused"
        else
            echo "⏸️ Not playing"
        fi
        sleep 1
        continue
    fi

    artist=$(playerctl metadata artist 2>/dev/null)
    title=$(playerctl metadata title 2>/dev/null)
    duration=$(playerctl metadata mpris:length 2>/dev/null || echo 0)
    duration_sec=$(awk "BEGIN {print int($duration / 1000000)}")

    if [[ -z "$artist" || -z "$title" ]]; then
        echo "⏸️ Not playing"
        sleep 1
        continue
    fi

    cache_key=$(printf "%s_%s" "$artist" "$title" \
                  | tr ' ' '_' \
                  | tr -dc 'A-Za-z0-9_')
    cache_file="${cache_dir}/${cache_key}.json"

    if [[ "$cache_key" != "$last_cache_key" ]]; then
        last_cache_key="$cache_key"
        last_position_sec=0
        last_duration_sec="$duration_sec"

        if (( debug )); then
            echo "—▶ New song detected: '$artist' — '$title'"
            echo "    cache_key = '$cache_key'"
        fi

        if [[ -f "$cache_file" ]]; then
            cache_hit=1
            if (( debug )); then
                echo "    [cache hit] reading from $cache_file"
            fi
        else
            cache_hit=0
            if (( debug )); then
                echo "    [cache miss] fetching from API…"
            fi

            artist_encoded=$(printf "%s" "$artist" | jq -sRr @uri)
            title_encoded=$(printf "%s" "$title" | jq -sRr @uri)

            api_url="https://lrclib.net/api/get?artist_name=${artist_encoded}&track_name=${title_encoded}&duration=${duration_sec}"
            if (( debug )); then
                echo "    Requesting:"
                echo "      $api_url"
            fi

            response=$(curl -s "$api_url")
            echo "$response" > "$cache_file"
        fi

        raw_lyrics=$(jq -r '.syncedLyrics // ""' < "$cache_file" 2>/dev/null)
        if [[ -z "$raw_lyrics" ]]; then
            last_lyrics=""
            if (( debug )); then
                echo "    [warning] no syncedLyrics in JSON, fallback to empty"
            fi
        else
            last_lyrics="$raw_lyrics"
            if (( debug )); then
                line_count=$(grep -c '^' <<< "$last_lyrics")
                echo "    Loaded $(printf "%d" "$line_count") lyric lines"
            fi
        fi
    fi

    if (( debug )); then
        if (( cache_hit )); then
            echo "    (cache hit for '$cache_key')"
        else
            echo "    (cache miss for '$cache_key')"
        fi
        sleep 1
        continue
    fi

    position_sec=$(playerctl position 2>/dev/null)
    if [[ -z "$position_sec" ]]; then
        position_sec=0
    fi

    delta=$(awk "BEGIN {print $position_sec - $last_position_sec}")
    if (( $(awk "BEGIN {print ($delta < -0.1)}") )); then
        last_position_sec="$position_sec"
    fi

    last_position_sec="$position_sec"

    if [[ -n "$last_lyrics" ]]; then
        current_line=""
        while IFS= read -r line; do
            if [[ "$line" =~ \[([0-9]+):([0-9]+\.[0-9]+)\] ]]; then
                min="${BASH_REMATCH[1]}"
                sec="${BASH_REMATCH[2]}"
                time_float=$(awk "BEGIN {print $min*60 + $sec}")
                if (( $(awk "BEGIN {print ($position_sec >= $time_float)}") )); then
                    text_only=$(sed -E 's/\[[0-9:.]+\]//g' <<< "$line")
                    current_line="$text_only"
                fi
            fi
        done <<< "$last_lyrics"

        if [[ -n "$current_line" ]]; then
            echo "🎶 $(truncate_text "$current_line")"
        else
            echo "🎶 $(truncate_text "$title - $artist")"
        fi
    else
        echo "🎵 $(truncate_text "$title - $artist")"
    fi

    sleep 0.2
done

