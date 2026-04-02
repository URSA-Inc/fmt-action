#!/usr/bin/env bash
# FMT equivalence check — thin client that calls the fmt-api via Zuplo.
set -euo pipefail

API_URL="${FMT_API_URL:-https://api.fmt.ursasecure.com}"
LANGUAGE="${FMT_LANGUAGE:-python}"
TIMEOUT_SECS="${FMT_TIMEOUT:-30}"

echo "::group::FMT Equivalence Check"
echo "Submitting check to ${API_URL}..."

# Encode function sources as JSON strings
FUNC_A_JSON=$(python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))" <<< "${FMT_FUNCTION_A}")
FUNC_B_JSON=$(python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))" <<< "${FMT_FUNCTION_B}")

PAYLOAD=$(printf '{"function_a":%s,"function_b":%s,"language":"%s","timeout":%s}' \
  "$FUNC_A_JSON" "$FUNC_B_JSON" "$LANGUAGE" "$TIMEOUT_SECS")

RESPONSE=$(curl -sf \
  -X POST "${API_URL}/v1/checks" \
  -H "Authorization: Bearer ${FMT_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

JOB_ID=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['job_id'])" "$RESPONSE")
echo "job_id=${JOB_ID}" >> "$GITHUB_OUTPUT"
echo "Job ID: ${JOB_ID}"

# Poll for result (max 120 attempts × 5s = 10 minutes)
MAX=120
N=0
while [ $N -lt $MAX ]; do
  sleep 5
  RESULT=$(curl -sf \
    -H "Authorization: Bearer ${FMT_API_KEY}" \
    "${API_URL}/v1/checks/${JOB_ID}")

  STATUS=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['status'])" "$RESULT")
  echo "Status: ${STATUS} (attempt $((N+1))/${MAX})"

  if [ "$STATUS" = "complete" ] || [ "$STATUS" = "failed" ]; then
    EQUIVALENT=$(python3 -c "
import json, sys
d = json.loads(sys.argv[1])
v = d.get('equivalent')
print('true' if v is True else 'false' if v is False else 'unknown')
" "$RESULT")

    echo "equivalent=${EQUIVALENT}" >> "$GITHUB_OUTPUT"
    echo "status=${STATUS}" >> "$GITHUB_OUTPUT"
    echo "Result: equivalent=${EQUIVALENT}"
    echo "::endgroup::"

    if [ "$STATUS" = "failed" ]; then
      echo "::error::FMT equivalence check failed."
      exit 1
    fi
    exit 0
  fi
  N=$((N+1))
done

echo "::error::Timed out waiting for FMT result after $((MAX * 5))s."
echo "::endgroup::"
exit 1
