# kube-auth-proxy

Auth proxy for Kubernetes ServiceAccount tokens, similar to [oauth2-proxy](https://github.com/oauth2-proxy/oauth2-proxy). Validates Bearer tokens via the TokenReview API and sets identity headers.

## How it works

kube-auth-proxy sits in front of your service as a reverse proxy (typically as a sidecar):

```
Request → kube-auth-proxy → upstream service
           ↓
      validates token, strips Authorization,
      adds X-Forwarded-User/Groups/Extra headers
```

## Configuration

| Flag | Env | Default | Description |
|------|-----|---------|-------------|
| `--upstream` | `UPSTREAM` | (required) | Upstream URL to proxy to |
| `--token-review-url` | `TOKEN_REVIEW_URL` | (in-cluster API) | TokenReview endpoint URL |
| `--port` | `PORT` | `4180` | Listen port |

## Headers

Headers forwarded to upstream on successful authentication:
- `X-Forwarded-User` — authenticated username
- `X-Forwarded-Groups` — comma-separated groups
- `X-Forwarded-Extra-Cluster-Name` — source cluster name

The `Authorization` header is stripped before forwarding to upstream.

## Usage

### With kube-federated-auth

Point `--token-review-url` at your [kube-federated-auth](https://github.com/rophy/kube-federated-auth) instance to validate tokens from multiple clusters:

```bash
kube-auth-proxy --upstream=http://localhost:8080 --token-review-url=http://kube-federated-auth:8080
```

### Standalone (in-cluster)

When running inside a Kubernetes cluster without `--token-review-url`, kube-auth-proxy validates tokens directly against the cluster's own API server:

```bash
kube-auth-proxy --upstream=http://localhost:8080
```

The ServiceAccount must have `system:auth-delegator` ClusterRoleBinding.

## Docker

```bash
docker pull rophy/kube-auth-proxy:latest
```

## License

MIT
