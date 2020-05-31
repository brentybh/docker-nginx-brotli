#!/usr/bin/env sh

set -eux

_link="/etc/nginx"
_base="/usr/src/docker-nginx"
_defaults="$_base/defaults"
_upstream="$_base/conf"

# Ensure upstream exists
mkdir -p "$_upstream"

if [ ! -e "$_link" ]; then
  # First start: ""
  # Subsequent updates: "/usr/src/docker-nginx/v0012345678"
  _current=""
elif [ -L "$_link" ]; then
  _current="$(readlink -f "$_link")"
else
  echo "Invalid link $_link" >&2
  exit 1
fi

# First start: "/usr/src/docker-nginx/v0012345678"
# Subsequent updates: "/usr/src/docker-nginx/v1123456789"
_target="$_base/v$(date +%s%N)"

# Ensure target is empty
rm -rf "$_target"
mkdir "$_target"

# Apply defaults
cp -R "$_defaults/." "$_target"

# Pull from upstream (defaults will be overwritten)
cp -R "$_upstream/." "$_target"

# Set link to target
ln -sfn "$_target" "$_link"

if nginx -t; then
  # Test OK
  if [ -n "$_current" ]; then
    # Delete old target only if it's not a first start
    rm -rf "$_current"
  fi
else
  # Test failed
  rm -rf "$_target"
  if [ -z "$_current" ]; then
    rm -rf "$_link"
    exit 1
  fi
  # Rollback only if it's not a first start
  ln -sfn "$_current" "$_link"
fi
