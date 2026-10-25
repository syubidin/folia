package config

import (
	"errors"
	"os"
)

type Config struct {
	Port        string
	DatabaseURL string
	SupabaseURL string
	JWTSecret   string
	Env         string
}

func Load() (Config, error) {
	c := Config{
		Port:        getenv("PORT", "8080"),
		DatabaseURL: os.Getenv("DATABASE_URL"),
		SupabaseURL: os.Getenv("SUPABASE_URL"),
		JWTSecret:   os.Getenv("SUPABASE_JWT_SECRET"),
		Env:         getenv("APP_ENV", "development"),
	}
	if c.SupabaseURL == "" {
		return c, errors.New("SUPABASE_URL is required")
	}
	if c.Env == "production" && c.DatabaseURL == "" {
		return c, errors.New("DATABASE_URL is required in production")
	}
	return c, nil
}

func getenv(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}
