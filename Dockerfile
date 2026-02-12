FROM golang:1.24-alpine AS builder

ARG VERSION=dev

WORKDIR /app

COPY go.mod ./

COPY . .
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 go build -ldflags "-X main.Version=${VERSION}" -o /kube-auth-proxy ./cmd/kube-auth-proxy

FROM gcr.io/distroless/static

COPY --from=builder /kube-auth-proxy /usr/local/bin/kube-auth-proxy

EXPOSE 4180

ENTRYPOINT ["/usr/local/bin/kube-auth-proxy"]
