#!/usr/bin/env bats

# Tests for kube-auth-proxy error scenarios.
# Verifies that the proxy returns 500 when TokenReview fails due to
# RBAC misconfiguration or an unreachable endpoint.

ECHO_URL="${ECHO_URL:-http://echo-server}"
MANIFEST_DIR="${BATS_TEST_DIRNAME}/manifests"

setup_file() {
    load 'test_helper'
    wait_for_service "${ECHO_URL}/healthz"
}

setup() {
    load 'test_helper'
}

teardown() {
    # Restore ClusterRoleBinding (idempotent)
    kubectl apply -f "${MANIFEST_DIR}/kube-auth-proxy.yaml"
    # Remove TOKEN_REVIEW_URL if set (ignore error if not present)
    kubectl set env -n "$NAMESPACE" deployment/echo-server -c kube-auth-proxy "TOKEN_REVIEW_URL-" 2>/dev/null || true
    wait_for_rollout
    wait_for_service "${ECHO_URL}/healthz"
}

teardown_file() {
    load 'test_helper'
    kubectl apply -f "${MANIFEST_DIR}/kube-auth-proxy.yaml"
    kubectl set env -n "$NAMESPACE" deployment/echo-server -c kube-auth-proxy "TOKEN_REVIEW_URL-" 2>/dev/null || true
    wait_for_rollout
    wait_for_service "${ECHO_URL}/healthz"
}

@test "returns 500 when RBAC is misconfigured" {
    kubectl delete clusterrolebinding token-reviewer
    # Restart pods to clear cached TokenReview results from prior tests
    kubectl rollout restart deployment/echo-server -n "$NAMESPACE"
    wait_for_rollout
    wait_for_service "${ECHO_URL}/healthz"

    local token
    token=$(get_token)

    local http_code
    http_code=$(kexec curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
        -H "Authorization: Bearer ${token}" \
        "${ECHO_URL}/")
    echo "# http_code=$http_code"
    [[ "$http_code" == "500" ]]
}

@test "returns 500 when token review endpoint is unreachable" {
    patch_proxy_env TOKEN_REVIEW_URL "https://does-not-exist.kube-auth-proxy.svc:6443"
    wait_for_service "${ECHO_URL}/healthz"

    local token
    token=$(get_token)

    local http_code
    http_code=$(kexec curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
        -H "Authorization: Bearer ${token}" \
        "${ECHO_URL}/")
    echo "# http_code=$http_code"
    [[ "$http_code" == "500" ]]
}
