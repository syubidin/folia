package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

const (
	testIssuer = "https://x.supabase.co/auth/v1"
	testSecret = "test-secret-test-secret-test-secret"
)

func newTestAuth() *Authenticator {
	return &Authenticator{parser: newParser(testIssuer), hmacSecret: []byte(testSecret)}
}

func signToken(t *testing.T, aud string, exp time.Time) string {
	t.Helper()
	tok := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub": "user-123", "iss": testIssuer, "aud": aud, "exp": exp.Unix(),
	})
	s, err := tok.SignedString([]byte(testSecret))
	if err != nil {
		t.Fatal(err)
	}
	return s
}

func TestRequire(t *testing.T) {
	tests := []struct {
		name   string
		header string
		want   int
	}{
		{"no header", "", http.StatusUnauthorized},
		{"garbage token", "Bearer abc", http.StatusUnauthorized},
		{"wrong audience", "Bearer " + signToken(t, "other", time.Now().Add(time.Hour)), http.StatusUnauthorized},
		{"expired", "Bearer " + signToken(t, "authenticated", time.Now().Add(-time.Hour)), http.StatusUnauthorized},
		{"valid", "Bearer " + signToken(t, "authenticated", time.Now().Add(time.Hour)), http.StatusOK},
	}
	h := newTestAuth().Require(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if id, ok := UserID(r.Context()); !ok || id != "user-123" {
			t.Errorf("user id not in context")
		}
	}))
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, "/", nil)
			if tc.header != "" {
				req.Header.Set("Authorization", tc.header)
			}
			rec := httptest.NewRecorder()
			h.ServeHTTP(rec, req)
			if rec.Code != tc.want {
				t.Fatalf("got %d, want %d", rec.Code, tc.want)
			}
		})
	}
}
