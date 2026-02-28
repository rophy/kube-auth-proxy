#!/bin/bash
# Common test helpers for kube-auth-proxy e2e tests.
# Tests run on the HOST and use kubectl exec to reach in-cluster services.

NAMESPACE="${NAMESPACE:-kube-auth-proxy}"
TEST_CLIENT="${TEST_CLIENT:-deployment/test-client}"
TOKEN_PATH="${TOKEN_PATH:-/var/run/secrets/kubernetes.io/serviceaccount/token}"

# Run a command in the test-client pod
kexec() {
    kubectl exec -n "$NAMESPACE" "$TEST_CLIENT" -- "$@"
}

# Read the projected ServiceAccount token from the test-client pod
get_token() {
    kexec cat "$TOKEN_PATH"
}

# Wait for a service to be ready (up to 30 seconds)
wait_for_service() {
    local url="$1"
    local attempts=0
    while [[ $attempts -lt 30 ]]; do
        if kexec curl -sf "$url" > /dev/null 2>&1; then
            return 0
        fi
        sleep 1
        attempts=$((attempts + 1))
    done
    echo "ERROR: service not ready at $url" >&2
    return 1
}

# Wait for a deployment rollout to complete
wait_for_rollout() {
    local deploy="${1:-echo-server}"
    kubectl rollout status "deployment/${deploy}" -n "$NAMESPACE" --timeout=60s
}

# Set an env var on the kube-auth-proxy container and wait for rollout
patch_proxy_env() {
    local key="$1" value="$2"
    kubectl set env -n "$NAMESPACE" deployment/echo-server -c kube-auth-proxy "${key}=${value}"
    wait_for_rollout
}

# Remove an env var from the kube-auth-proxy container and wait for rollout
unpatch_proxy_env() {
    local key="$1"
    kubectl set env -n "$NAMESPACE" deployment/echo-server -c kube-auth-proxy "${key}-"
    wait_for_rollout
}
