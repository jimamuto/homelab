#!/bin/bash

OUTPUT_DIR="/home/jimoney/library/manga"

echo "Manga Downloader for Kavita"
echo "============================"
echo ""
read -p "Enter MangaDex URL: " MANGA_URL

if [ -z "$MANGA_URL" ]; then
    echo "No URL provided. Exiting."
    exit 1
fi

echo ""
echo "Downloading to: $OUTPUT_DIR"
echo ""

docker-compose run --rm \
    -v "$OUTPUT_DIR:/downloads" \
    mangadex-downloader \
    "$MANGA_URL" \
    --save-as cbz

echo ""
echo "Done! Tell Kavita to scan /books/manga"
