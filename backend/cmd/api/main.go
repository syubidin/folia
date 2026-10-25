package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/go-chi/chi/v5"
	chimw "github.com/go-chi/chi/v5/middleware"

	"github.com/syubidin/folia/backend/internal/config"
	"github.com/syubidin/folia/backend/internal/handler"
	"github.com/syubidin/folia/backend/internal/middleware"
)

func main() {
	log := slog.New(slog.NewJSONHandler(os.Stdout, nil))

	cfg, err := config.Load()
	if err != nil {
		log.Error("config", "err", err)
		os.Exit(1)
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	auth, err := middleware.NewAuthenticator(cfg.SupabaseURL, cfg.JWTSecret)
	if err != nil {
		log.Error("auth", "err", err)
		os.Exit(1)
	}
	limiter := middleware.NewRateLimiter(ctx, 60, 20)

	r := chi.NewRouter()
	r.Use(chimw.RequestID, chimw.RealIP)
	r.Use(middleware.Recoverer(log), middleware.SecurityHeaders)
	r.Use(middleware.BodyLimit(6 << 20))
	r.Use(chimw.Timeout(30 * time.Second))

	r.Get("/healthz", func(w http.ResponseWriter, _ *http.Request) { _, _ = w.Write([]byte("ok")) })

	r.Route("/v1", func(r chi.Router) {
		r.Use(auth.Require, limiter.Limit)
		r.Get("/me", handler.Me)
	})

	srv := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           r,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      35 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	go func() {
		log.Info("server starting", "port", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Error("server", "err", err)
			os.Exit(1)
		}
	}()

	<-ctx.Done()
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	_ = srv.Shutdown(shutdownCtx)
	log.Info("server stopped")
}
