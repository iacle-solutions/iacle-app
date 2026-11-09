#!/bin/bash
set -euo pipefail
: "${CLOUDFLARE_EMAIL:?CLOUDFLARE_EMAIL is required}"
: "${CLOUDFLARE_API_KEY:?CLOUDFLARE_API_KEY is required}"
: "${CLOUDFLARE_ZONE_ID:?CLOUDFLARE_ZONE_ID is required}"
: "${CLOUDFLARE_TUNNEL_ID:?CLOUDFLARE_TUNNEL_ID is required}"
: "${ARGOCD_RECORD_ID:?ARGOCD_RECORD_ID is required}"
: "${GRAFANA_RECORD_ID:?GRAFANA_RECORD_ID is required}"
TUNNEL_CNAME="${CLOUDFLARE_TUNNEL_ID}.cfargotunnel.com"
EMAIL="$CLOUDFLARE_EMAIL"
API_KEY="$CLOUDFLARE_API_KEY"
ZONE_ID="$CLOUDFLARE_ZONE_ID"

echo "Deleting broken records..."
curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$ARGOCD_RECORD_ID" \
     -H "X-Auth-Email: $EMAIL" \
     -H "X-Auth-Key: $API_KEY"
echo -e "\n"

curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$GRAFANA_RECORD_ID" \
     -H "X-Auth-Email: $EMAIL" \
     -H "X-Auth-Key: $API_KEY"
echo -e "\n"

echo "Re-creating ArgoCD CNAME..."
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
     -H "X-Auth-Email: $EMAIL" \
     -H "X-Auth-Key: $API_KEY" \
     -H "Content-Type: application/json" \
     --data "{\"type\":\"CNAME\",\"name\":\"argocd\",\"content\":\"$TUNNEL_CNAME\",\"proxied\":true}"
echo -e "\n"

echo "Re-creating Grafana CNAME..."
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
     -H "X-Auth-Email: $EMAIL" \
     -H "X-Auth-Key: $API_KEY" \
     -H "Content-Type: application/json" \
     --data "{\"type\":\"CNAME\",\"name\":\"grafana\",\"content\":\"$TUNNEL_CNAME\",\"proxied\":true}"
echo -e "\n"
