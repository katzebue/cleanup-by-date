![CI](https://github.com/katzebue/cleanup-by-date/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

# cleanup-by-date 🧹

A bash utility to clean up files based on the date in their filenames.

## 🔍 Description

`cleanup-by-date` is a CLI tool for deleting old files by extracting dates from filenames using regex.
Supports dry-run, custom date patterns, logging, and cron jobs. Works with `date` or `gdate`.

## 🔧 Features

- 📅 Local date parsing (YYYY-MM-DD[_HHMM])
- 🔍 Regex with optional capturing group for date
- 🕒 Flexible time period (e.g. `7d`, `3h`, `2w`, `1y`)
- 🧪 Dry-run mode
- 📓 Optional logging

## 🏁 Example Filenames
- `backup-2025-05-20_1300.sql.gz`
- `site-dump-2024-12-11_0000.tar.gz`
- `log-2023-09-01.txt`

## 🛠 Installation

### Installation from source

```bash
git clone https://github.com/katzebue/cleanup-by-date.git
cd cleanup-by-date
sudo make install
```

### Quick installation for system

```bash
curl -L https://raw.githubusercontent.com/katzebue/cleanup-by-date/main/src/cleanup-by-date -o /usr/local/bin/cleanup-by-date
chmod +x /usr/local/bin/cleanup-by-date
```
### Quick installation for user

```bash
mkdir -p ~/bin
curl -L https://raw.githubusercontent.com/katzebue/cleanup-by-date/main/src/cleanup-by-date -o ~/bin/cleanup-by-date
chmod +x ~/bin/cleanup-by-date
```

## 🧪 Run Tests

```bash
make test
```

## ✅ Usage

```bash
cleanup-by-date <path> <period> [options]
```

Arguments
-	<path>: directory to scan
-	<period>: how old files should be (e.g. 7d, 3h, 1w, 1y)

Options
-	--regex <regex>: custom regex with optional capturing group (default: ([0-9]{4}-[0-9]{2}-[0-9]{2}(_[0-9]{4})?))
-	--log <file>: write actions to log file
-	--dry-run: simulate deletions
-	--now <date>: override current date (format: YYYY-MM-DD HH:MM:SS)

### 🗑️ Example Usage

```bash
cleanup-by-date /var/backups 30d --regex 'dump-.*([0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{4})\.sql' --log cleanup.log --dry-run
```
