#!/usr/bin/env bash
# Purpose  : Create a new Linux user, set password, deploy SSH public key
# Author   : Learn Academy
# Usage    : sudo create_user_with_ssh.sh <username> [path-to-pubkey]
# Example  : sudo create_user_with_ssh.sh emmanuel /tmp/emmanuel.pub
set -euo pipefail
IFS=$'\n\t'

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: must be root" >&2
  exit 2
fi

USERNAME="${1:-}"
PUBKEYPATH="${2:-}"

if [ -z "$USERNAME" ]; then
  echo "Usage: $0 <username> [path-to-pubkey]" >&2
  exit 1
fi

# check if user exists
if id "$USERNAME" &>/dev/null; then
  echo "User $USERNAME already exists." >&2
  exit 1
fi

# create user with home and bash shell
useradd -m -s /bin/bash "$USERNAME"

# set a randomized password (expire on first login)
RANDPASS=$(openssl rand -base64 12)
echo "${USERNAME}:${RANDPASS}" | chpasswd
chage -d 0 "$USERNAME"  # force password change on first login

# Setup SSH directory if pubkey provided
if [ -n "$PUBKEYPATH" ] && [ -f "$PUBKEYPATH" ]; then
  su - "$USERNAME" -c 'mkdir -p ~/.ssh && chmod 700 ~/.ssh'
  cat "$PUBKEYPATH" > "/home/$USERNAME/.ssh/authorized_keys"
  chmod 600 "/home/$USERNAME/.ssh/authorized_keys"
  chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.ssh"
  echo "SSH key installed for $USERNAME."
else
  echo "No pubkey supplied; user can still login with password."
fi

echo "Created user: $USERNAME"
echo "Temporary password: $RANDPASS"
exit 0
