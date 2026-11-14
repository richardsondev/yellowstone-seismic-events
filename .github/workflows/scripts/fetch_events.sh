#!/usr/bin/env bash
# Fetch the event hash and the event map, and accept them only when both are
# good and agree with each other.
#
# The API reports its own failures inside an HTTP 200 response, for example
#   {"status":500,"data":{"hashString":"","events":null},
#    "message":"Failed to query event table database"}
# so the HTTP status alone cannot be trusted. Each attempt checks the "status"
# field of both bodies and compares the two hashes, and a bad attempt is
# retried after a pause.
#
# Outcome, written to $GITHUB_OUTPUT as skip=true|false:
#   skip=false  eventmap.json holds verified data; carry on and commit.
#   skip=true   the API was still reporting an error after every attempt.
#               eventmap.json is left untouched, a warning is raised and the run
#               ends green: there is nothing to scrape until the API recovers.
# Anything else (network failure, invalid JSON, hashes that never agree) exits 1.
set -euo pipefail

BASE_URL="${EVENTDATA_URL:-https://webproducts.quake-utah.org/Catalog/ComCat/EventData}"
ATTEMPTS="${FETCH_ATTEMPTS:-3}"
RETRY_DELAY="${FETCH_RETRY_DELAY:-20}"
HASH_FILE="${HASH_FILE:-/tmp/eventmaphash.json}"
MAP_FILE="${MAP_FILE:-eventmap.json}"
MAP_TMP="$(mktemp)"
trap 'rm -f "$MAP_TMP"' EXIT

fetch() {
  # The API emits a trailing comma before the closing bracket of the event list.
  curl --max-time 15 --retry 1 --retry-delay 3 -sf "${BASE_URL}?application=$1" \
    | tr '\n' ' ' | sed 's/, ]/] /g' | jq . >"$2" && test -s "$2"
}

set_output() {
  if [ -n "${GITHUB_OUTPUT:-}" ]; then echo "$1" >>"$GITHUB_OUTPUT"; fi
  echo "$1"
}

reason=''
upstream_error=false
for attempt in $(seq 1 "$ATTEMPTS"); do
  if [ "$attempt" -gt 1 ]; then
    echo "Attempt $((attempt - 1)) failed: ${reason}. Retrying in ${RETRY_DELAY}s."
    sleep "$RETRY_DELAY"
  fi
  upstream_error=false

  if ! fetch eventmaphash "$HASH_FILE" || ! fetch eventmap "$MAP_TMP"; then
    reason='request failed or returned invalid JSON'
    continue
  fi

  hash_status=$(jq -r '.status // empty' "$HASH_FILE")
  map_status=$(jq -r '.status // empty' "$MAP_TMP")
  if [ "$hash_status" != "200" ] || [ "$map_status" != "200" ]; then
    upstream_error=true
    reason="API reported an error (hash status ${hash_status:-none}: $(jq -r '.message // "no message"' "$HASH_FILE"); event map status ${map_status:-none}: $(jq -r '.message // "no message"' "$MAP_TMP"))"
    continue
  fi

  hash_expected=$(jq -r '.data | if type == "string" then . else empty end' "$HASH_FILE")
  hash_actual=$(jq -r '.data.hashString // empty' "$MAP_TMP")
  if [ -z "$hash_expected" ] || [ -z "$hash_actual" ]; then
    upstream_error=true
    reason='API returned status 200 without a hash'
    continue
  fi
  if [ "$hash_expected" != "$hash_actual" ]; then
    reason="hash mismatch: expected $hash_expected, got $hash_actual"
    continue
  fi

  mv "$MAP_TMP" "$MAP_FILE"
  echo "Fetched event map with hash $hash_actual on attempt $attempt."
  set_output 'skip=false'
  exit 0
done

if [ "$upstream_error" = true ]; then
  echo "::warning::Skipping this run: ${reason} after ${ATTEMPTS} attempts."
  set_output 'skip=true'
  exit 0
fi

echo "::error::Giving up after ${ATTEMPTS} attempts: ${reason}." >&2
exit 1
