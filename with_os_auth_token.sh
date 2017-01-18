#!/bin/sh

# In addition to `curl`, `jq` is needed for JSON querying

HTTP_RESPONSE=$(curl -s \
  -H "Content-Type: application/json" \
  -d "
{
    \"auth\": {
        \"tenantName\": \"$OS_TENANT_NAME\",
        \"passwordCredentials\": {
            \"username\": \"$OS_USERNAME\",
            \"password\": \"$OS_PASSWORD\"
        }
    }
}" \
$OS_AUTH_URL/tokens)

EXIT_CODE=$?
if [[ "$EXIT_CODE" == "0" ]]; then
  export OS_TOKEN=$(echo "$HTTP_RESPONSE" | jq -r .access.token.id)
  exec "$@"
else
  exit $EXIT_CODE
fi
