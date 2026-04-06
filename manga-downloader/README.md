# Manga Downloader

Docker setup using [mangadex-downloader](https://github.com/mansuf/mangadex-downloader) to download manga from MangaDex in CBZ format for Kavita.

## Quick Start

```bash
cd manga-downloader
docker-compose run --rm -v /home/jimoney/library/manga:/downloads mangadex-downloader "https://mangadex.org/manga/one-piece" --save-as cbz --language en
```

## How it Works

1. Downloads manga from MangaDex
2. Saves as CBZ files (Kavita-compatible)
3. Files go to `/home/jimoney/library/manga/`
4. Kavita scans `/books/manga` to find them

## Options

| Flag | Description |
|------|-------------|
| `--save-as cbz` | Save as CBZ (required for Kavita) |
| `--language en` | Language: en, ja, ko, zh, etc. |
| `--start-chapter N` | Start from chapter N |
| `--end-chapter N` | End at chapter N |
| `--group GROUP_ID` | Filter by scanlation group |

## Examples

```bash
# Download One Piece (English)
docker-compose run --rm -v /home/jimoney/library/manga:/downloads mangadex-downloader "https://mangadex.org/manga/one-piece" --save-as cbz --language en

# Download chapters 1000-1050
docker-compose run --rm -v /home/jimoney/library/manga:/downloads mangadex-downloader "https://mangadex.org/manga/one-piece" --save-as cbz --language en --start-chapter 1000 --end-chapter 1050

# Download specific group
docker-compose run --rm -v /home/jimoney/library/manga:/downloads mangadex-downloader "https://mangadex.org/manga/one-piece" --save-as cbz --language en --group GROUP_ID
```

## Kavita Integration

1. Open Kavita → Settings → Libraries
2. Add Library → Name: Manga
3. Path: `/books/manga`
4. Save and trigger a scan

The manga folder should contain subfolders for each series:

```
/home/jimoney/library/manga/
├── One Piece/
│   ├── Ch. 1.cbz
│   └── Ch. 2.cbz
└── Other Series/
    └── ...
```
