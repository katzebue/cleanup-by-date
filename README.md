![CI](https://github.com/katzebue/cleanup-by-date/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

# cleanup-by-date 🧹

A bash utility to clean up files based on the date in their filenames.

## 🔍 Description

`cleanup-by-date` is a shell utility to delete files based on dates in filenames.
It supports custom regex, time-based conditions (like 7d, 3h), dry-run, logging and is cron-friendly.

## 🔧 Features
- Local time support
- Regex-matched dates in filenames
- Time-range deletion (e.g. 7d, 3h, 2w)
- Dry-run and log mode

## 🏁 Example Filenames
- `backup-2025-05-20_1300.sql.gz`
- `site-dump-2024-12-11_0000.tar.gz`

## 🛠 Installation

```bash
git clone https://github.com/katzebue/cleanup-by-date.git
cd cleanup-by-date
sudo install -m 755 bin/cleanup-by-date /usr/local/bin/cleanup-by-date
```

## 🧪 Run Tests

```bash
make test
```

## 📦 Example Usage

```bash
cleanup-by-date /path/to/files '' 7d --log /var/log/cleanup.log
```
