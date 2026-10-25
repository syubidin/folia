package config

import (
	"fmt"
	"os"
)

type Config struct {
	Port        string
	DatabaseURL string
	JWTSecret   string
	Env         string
}

func Load() (Config, error) {
	c := Config{
		Port:        getenv("PORT", "8080"),
		DatabaseURL: os.Getenv("DATABASE_URL"),
		JWTSecret:   os.Getenv("SUPABASE_JWT_SECRET"),
		Env:         getenv("APP_ENV", "development"),
	}
	if c.Env == "production" && (c.DatabaseURL == "" || c.JWTSecret == "") {
		return c, fmt.Errorf("DATABASE_URL and SUPABASE_JWT_SECRET are required in production")
	}
	return c, nil
}

func getenv(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}
