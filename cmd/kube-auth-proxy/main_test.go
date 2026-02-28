package main

import (
	"log/slog"
	"testing"
)

func TestParseLogLevel(t *testing.T) {
	tests := []struct {
		name      string
		input     string
		wantLevel slog.Level
		wantErr   bool
	}{
		{name: "empty defaults to INFO", input: "", wantLevel: slog.LevelInfo},
		{name: "debug lowercase", input: "debug", wantLevel: slog.LevelDebug},
		{name: "DEBUG uppercase", input: "DEBUG", wantLevel: slog.LevelDebug},
		{name: "info", input: "info", wantLevel: slog.LevelInfo},
		{name: "INFO", input: "INFO", wantLevel: slog.LevelInfo},
		{name: "warn", input: "warn", wantLevel: slog.LevelWarn},
		{name: "WARN", input: "WARN", wantLevel: slog.LevelWarn},
		{name: "error", input: "error", wantLevel: slog.LevelError},
		{name: "ERROR", input: "ERROR", wantLevel: slog.LevelError},
		{name: "mixed case", input: "WaRn", wantLevel: slog.LevelWarn},
		{name: "invalid value", input: "TRACE", wantErr: true},
		{name: "nonsense", input: "abc123", wantErr: true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			level, err := parseLogLevel(tt.input)
			if tt.wantErr {
				if err == nil {
					t.Fatalf("parseLogLevel(%q) expected error, got nil", tt.input)
				}
				return
			}
			if err != nil {
				t.Fatalf("parseLogLevel(%q) unexpected error: %v", tt.input, err)
			}
			if got := level.Level(); got != tt.wantLevel {
				t.Errorf("parseLogLevel(%q) = %v, want %v", tt.input, got, tt.wantLevel)
			}
		})
	}
}
