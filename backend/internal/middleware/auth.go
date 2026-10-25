package middleware

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/MicahParks/keyfunc/v3"
	"github.com/golang-jwt/jwt/v5"
)

type ctxKey struct{}

func UserID(ctx context.Context) (string, bool) {
	id, ok := ctx.Value(ctxKey{}).(string)
	return id, ok && id != ""
}

type Authenticator struct {
	parser     *jwt.Parser
	jwks       keyfunc.Keyfunc
	hmacSecret []byte
}

func newParser(issuer string) *jwt.Parser {
	return jwt.NewParser(
		jwt.WithValidMethods([]string{"ES256", "RS256", "HS256"}),
		jwt.WithIssuer(issuer),
		jwt.WithAudience("authenticated"),
		jwt.WithExpirationRequired(),
		jwt.WithLeeway(5*time.Second),
	)
}

func NewAuthenticator(supabaseURL, hmacSecret string) (*Authenticator, error) {
	base := strings.TrimRight(supabaseURL, "/")
	a := &Authenticator{
		parser:     newParser(base + "/auth/v1"),
		hmacSecret: []byte(hmacSecret),
	}
	jwks, err := keyfunc.NewDefault([]string{base + "/auth/v1/.well-known/jwks.json"})
	switch {
	case err == nil:
		a.jwks = jwks
	case len(a.hmacSecret) == 0:
		return nil, fmt.Errorf("load jwks: %w", err)
	}
	return a, nil
}

func (a *Authenticator) keyFunc(t *jwt.Token) (any, error) {
	if t.Method.Alg() == "HS256" {
		if len(a.hmacSecret) == 0 {
			return nil, errors.New("hs256 not enabled")
		}
		return a.hmacSecret, nil
	}
	if a.jwks == nil {
		return nil, errors.New("jwks unavailable")
	}
	return a.jwks.Keyfunc(t)
}

func (a *Authenticator) Require(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		raw, ok := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer ")
		if !ok || raw == "" {
			slog.Error("JWT missing bearer token")
			unauthorized(w)
			return
		}
		tok, err := a.parser.Parse(raw, a.keyFunc)
		if err != nil || !tok.Valid {
			slog.Error("JWT validation failed", "err", err)
			unauthorized(w)
			return
		}
		sub, err := tok.Claims.GetSubject()
		if err != nil || sub == "" {
			slog.Error("JWT subject missing", "err", err)
			unauthorized(w)
			return
		}
		next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), ctxKey{}, sub)))
	})
}

func unauthorized(w http.ResponseWriter) {
	w.Header().Set("WWW-Authenticate", "Bearer")
	http.Error(w, "unauthorized", http.StatusUnauthorized)
}
