# Waybar Lyrics
An extremely simple waybar lyric displayer

## How does it work?

It fetches the lyrics using the API at https://lrclib.net/ and, if they are found, displays them at the correct time using the timestamps available.

## How do I use it?

- Install the lyrics.sh script and place it somewhere safe.
- Add something along the lines of the following as a waybar module:
```json
"custom/lyrics": {
    "exec": "stdbuf -oL ./lyrics.sh",
    "format": "{}"
},
```
- Add the module to your waybar's config
- You now have lyrics!

## What does it depend on?

It relies on playerctl to fetch the current track being played, and an internet connection to fetch the lyrics.

## It isn't working!

Feel free to make an issue - I can try to provide assistance or improve the script to work more generally!
