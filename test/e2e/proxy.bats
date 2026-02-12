#!/usr/bin/env bats

# Tests for kube-auth-proxy in auth subrequest mode with an external
# TokenReview URL (e.g. kube-federated-auth).
#
# Requires EXTERNAL_TOKEN_REVIEW_URL to be set, and a corresponding
# kube-auth-proxy deployment configured with --token-review-url.
# Skipped by default when running `make e2e`.

PROXY_URL="${PROXY_EXTERNAL_URL:-http://kube-auth-proxy-external:4180}"

setup_file() {
    load 'test_helper'
    if [[ -z "${EXTERNAL_TOKEN_REVIEW_URL:-}" ]]; then
        skip "EXTERNAL_TOKEN_REVIEW_URL not set; skipping external TokenReview tests"
    fi
    wait_for_service "${PROXY_URL}/healthz"
}

setup() {
    load 'test_helper'
    if [[ -z "${EXTERNAL_TOKEN_REVIEW_URL:-}" ]]; then
        skip "EXTERNAL_TOKEN_REVIEW_URL not set"
    fi
}

@test "external proxy healthz returns ok" {
    local result
    result=$(kexec curl -s "${PROXY_URL}/healthz")

    echo "# Response: $result"

    local status
    status=$(echo "$result" | jq -r '.status')
    [[ "$status" == "ok" ]]
}

@test "external proxy /auth returns 401 without token" {
    local http_code
    http_code=$(kexec curl -s -o /dev/null -w "%{http_code}" "${PROXY_URL}/auth")
    [[ "$http_code" == "401" ]]
}

@test "external proxy /auth returns 200 with valid token" {
    local token
    token=$(get_token)

    local http_code
    http_code=$(kexec curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer ${token}" \
        "${PROXY_URL}/auth")
    [[ "$http_code" == "200" ]]
}

@test "external proxy /auth sets identity headers on success" {
    local token
    token=$(get_token)

    local headers
    headers=$(kexec curl -s -D - -o /dev/null \
        -H "Authorization: Bearer ${token}" \
        "${PROXY_URL}/auth")

    echo "# Headers: $headers"

    echo "$headers" | grep -qi "X-Auth-Request-User:"
    echo "$headers" | grep -qi "X-Auth-Request-Extra-Cluster-Name:"
}

@test "external proxy /auth returns 401 with invalid token" {
    local http_code
    http_code=$(kexec curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer invalid.token.here" \
        "${PROXY_URL}/auth")
    [[ "$http_code" == "401" ]]
}
