package main

import (
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"strings"

	"github.com/rophy/kube-auth-proxy/internal/proxy"
)

var Version = "dev"

func main() {
	initLogging()

	cfg := proxy.ParseFlags()
	if err := cfg.Validate(); err != nil {
		slog.Error("configuration error", "err", err)
		os.Exit(1)
	}

	tokenReview := "in-cluster"
	if cfg.TokenReviewURL != "" {
		tokenReview = cfg.TokenReviewURL
	}
	slog.Info("starting", "version", Version)
	slog.Info("config", "upstream", cfg.Upstream, "port", cfg.Port, "token_review", tokenReview)

	reviewer, err := cfg.NewTokenReviewer()
	if err != nil {
		slog.Error("failed to create token reviewer", "err", err)
		os.Exit(1)
	}

	handler, err := proxy.NewServer(cfg, proxy.NewCachedTokenReviewer(reviewer), Version)
	if err != nil {
		slog.Error("failed to create server", "err", err)
		os.Exit(1)
	}

	addr := fmt.Sprintf(":%d", cfg.Port)
	slog.Info("listening", "addr", addr)
	if err := http.ListenAndServe(addr, handler); err != nil {
		slog.Error("server failed", "err", err)
		os.Exit(1)
	}
}

func initLogging() {
	level, err := parseLogLevel(os.Getenv("LOG_LEVEL"))
	if err != nil {
		slog.Error("invalid LOG_LEVEL", "value", os.Getenv("LOG_LEVEL"), "err", err)
		os.Exit(1)
	}
	handler := slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{
		Level: level,
	})
	slog.SetDefault(slog.New(handler))
}

func parseLogLevel(s string) (slog.Leveler, error) {
	var level slog.LevelVar
	if s != "" {
		if err := level.UnmarshalText([]byte(strings.ToUpper(s))); err != nil {
			return nil, err
		}
	}
	return &level, nil
}
