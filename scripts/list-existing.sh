#!/usr/bin/env bash
# Lists existing DNS records and the redirect ruleset of a zone, so you can
# copy IDs into dns_record_imports / redirect_ruleset_import_id.
# Usage: CLOUDFLARE_API_TOKEN=... ./scripts/list-existing.sh <zone_id>
# Requires: curl, jq
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: CLOUDFLARE_API_TOKEN=... $0 <zone_id>"
  exit 1
fi

API="https://api.cloudflare.com/client/v4/zones/$1"
AUTH="Authorization: Bearer $CLOUDFLARE_API_TOKEN"

echo "== DNS records (id, type, name, content, proxied) =="
curl -fsS "$API/dns_records?per_page=1000" -H "$AUTH" \
  | jq -r '.result[] | [.id, .type, .name, .content, (.proxied | tostring)] | @tsv'

echo
echo "== Redirect ruleset (http_request_dynamic_redirect) =="
curl -sS "$API/rulesets/phases/http_request_dynamic_redirect/entrypoint" -H "$AUTH" \
  | jq '{ruleset_id: .result.id, rules: [.result.rules[]? | {description, expression, action_parameters}]}'
