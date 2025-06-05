# Waybar Lyrics
![image](https://github.com/user-attachments/assets/dd7c0fe0-ede8-4c3f-8057-20e08675edec)

An extremely simple waybar lyric displayer

## How does it work?

It fetches the lyrics using the API at https://lrclib.net/ for the currently plaiying song (according to playerctl) and, if they are found, displays them at the correct time using the timestamps available.

## How do I use it?

- Download the lyrics.sh script, place it somewhere safe, and `chmod +x lyrics.sh` it
- Add something along the lines of the following as a waybar module:
```json
"custom/lyrics": {
    "exec": "stdbuf -oL /path/to/lyrics.sh",
    "format": "{}"
},
```
- Add the module to your waybar's config
- You now have lyrics!
- You can go into the lyrics.sh to adjust the maximum characters it will show if it appears too long on your waybar

## What does it depend on?

It relies on playerctl to fetch the current track being played, jq to parse the json response, and an internet connection to fetch the lyrics.

## It isn't working!

Feel free to make an issue - I can try to provide assistance or improve the script to work more generally!
