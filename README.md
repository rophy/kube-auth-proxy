# kube-auth-proxy

Auth proxy for Kubernetes ServiceAccount tokens, similar to [oauth2-proxy](https://github.com/oauth2-proxy/oauth2-proxy). Validates Bearer tokens via the TokenReview API and sets identity headers.

## Modes

**Auth subrequest mode** (`GET /auth`) — for Nginx `auth_request`, Traefik ForwardAuth, or Istio ext_authz:

```
Request → Nginx → auth_request to kube-auth-proxy /auth
                   ↓
              200 + X-Auth-Request-User header  OR  401
```

**Reverse proxy mode** (`--upstream`) — sits in front of your service as a sidecar:

```
Request → kube-auth-proxy → upstream service
           ↓
      validates token, strips Authorization,
      adds X-Forwarded-User/Groups/Extra headers
```

## Configuration

| Flag | Env | Default | Description |
|------|-----|---------|-------------|
| `--token-review-url` | `TOKEN_REVIEW_URL` | (in-cluster API) | TokenReview endpoint URL |
| `--upstream` | `UPSTREAM` | | Upstream URL (enables reverse proxy mode) |
| `--port` | `PORT` | `4180` | Listen port |
| `--auth-prefix` | `AUTH_PREFIX` | `/auth` | Auth subrequest endpoint path |

## Headers

**Auth subrequest mode** (response headers):
- `X-Auth-Request-User` — authenticated username
- `X-Auth-Request-Groups` — comma-separated groups
- `X-Auth-Request-Extra-Cluster-Name` — source cluster name

**Reverse proxy mode** (forwarded to upstream):
- `X-Forwarded-User` — authenticated username
- `X-Forwarded-Groups` — comma-separated groups
- `X-Forwarded-Extra-Cluster-Name` — source cluster name

## Usage

### With kube-federated-auth

Point `--token-review-url` at your [kube-federated-auth](https://github.com/rophy/kube-federated-auth) instance to validate tokens from multiple clusters:

```bash
kube-auth-proxy --token-review-url=http://kube-federated-auth:8080
```

### Standalone (in-cluster)

When running inside a Kubernetes cluster without `--token-review-url`, kube-auth-proxy validates tokens directly against the cluster's own API server:

```bash
kube-auth-proxy
```

The ServiceAccount must have `system:auth-delegator` ClusterRoleBinding.

## Docker

```bash
docker pull rophy/kube-auth-proxy:latest
```

## License

MIT
