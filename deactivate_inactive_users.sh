#!/usr/bin/env bash
# Purpose : Lock accounts inactive for N days and optionally archive homes
# Author  : Learn Academy
# Usage   : sudo deactivate_inactive_users.sh DAYS
# Example : sudo deactivate_inactive_users.sh 90
set -euo pipefail
IFS=$'\n\t'

DAYS="${1:-90}"
ARCHIVE_DIR="/var/archive/homes"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root" >&2
  exit 2
fi

mkdir -p "$ARCHIVE_DIR"
echo "Scanning for users with last login older than $DAYS days..."

# uses lastlog -t to find inactive accounts; fallback parsing last
inactive_users=$(lastlog -b "$DAYS" | awk 'NR>1 && $1!="**Never**" {print $1}')

# also include accounts that show **Never** and were created long time ago? be cautious.
for u in $inactive_users; do
  # ignore system accounts (UID < 1000 typical on many distros)
  uid=$(id -u "$u")
  if [ "$uid" -ge 1000 ]; then
    echo "Locking $u (UID $uid)"
    usermod -L "$u"
    mkdir -p "$ARCHIVE_DIR"
    if [ -d "/home/$u" ]; then
      mv "/home/$u" "$ARCHIVE_DIR/$u.$(date +%F)"
      chown -R root:root "$ARCHIVE_DIR/$u.$(date +%F)"
      echo "  -> moved /home/$u to archive"
    fi
  fi
done

echo "Completed inactive user processing."
