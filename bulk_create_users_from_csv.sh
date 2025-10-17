#!/usr/bin/env bash
# Purpose: Bulk-create users from CSV: username,full_name,groups,ssh_pubkey_path
# Author : Learn Academy
# Usage  : sudo bulk_create_users_from_csv.sh /path/to/users.csv
set -euo pipefail
IFS=$'\n\t'

CSV="${1:-}"
if [ -z "$CSV" ] || [ ! -f "$CSV" ]; then
  echo "Usage: $0 /path/to/users.csv" >&2
  exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "Must be root" >&2
  exit 2
fi

while IFS=, read -r username fullname groups pubkey; do
  # skip blank and comment lines
  [[ -z "$username" || "$username" == \#* ]] && continue

  echo "Processing $username ..."
  if id "$username" &>/dev/null; then
    echo "  -> user exists; skipping"
    continue
  fi

  # create user
  useradd -m -s /bin/bash -c "$fullname" "$username"

  # set random password and expire it
  pass=$(openssl rand -base64 12)
  echo "${username}:${pass}" | chpasswd
  chage -d 0 "$username"

  # add to groups if specified
  if [ -n "$groups" ]; then
    IFS=';' read -ra GARR <<< "$groups"
    for g in "${GARR[@]}"; do
      groupadd -f "$g"
      usermod -aG "$g" "$username"
    done
  fi

  # deploy ssh key if present
  if [ -n "$pubkey" ] && [ -f "$pubkey" ]; then
    mkdir -p "/home/$username/.ssh"
    cat "$pubkey" > "/home/$username/.ssh/authorized_keys"
    chown -R "$username:$username" "/home/$username/.ssh"
    chmod 700 "/home/$username/.ssh"
    chmod 600 "/home/$username/.ssh/authorized_keys"
  fi

  echo "  -> created $username with password: $pass"
done < "$CSV"
