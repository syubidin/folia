package middleware

import (
	"context"
	"net/http"
	"sync"
	"time"

	"golang.org/x/time/rate"
)

type visitor struct {
	lim  *rate.Limiter
	seen time.Time
}

type RateLimiter struct {
	mu    sync.Mutex
	v     map[string]*visitor
	r     rate.Limit
	burst int
}

func NewRateLimiter(ctx context.Context, perMinute, burst int) *RateLimiter {
	rl := &RateLimiter{v: map[string]*visitor{}, r: rate.Limit(float64(perMinute) / 60), burst: burst}
	go rl.cleanup(ctx)
	return rl
}

func (rl *RateLimiter) limiter(key string) *rate.Limiter {
	rl.mu.Lock()
	defer rl.mu.Unlock()
	v, ok := rl.v[key]
	if !ok {
		v = &visitor{lim: rate.NewLimiter(rl.r, rl.burst)}
		rl.v[key] = v
	}
	v.seen = time.Now()
	return v.lim
}

func (rl *RateLimiter) cleanup(ctx context.Context) {
	t := time.NewTicker(time.Minute)
	defer t.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-t.C:
			rl.mu.Lock()
			for k, v := range rl.v {
				if time.Since(v.seen) > 5*time.Minute {
					delete(rl.v, k)
				}
			}
			rl.mu.Unlock()
		}
	}
}

func (rl *RateLimiter) Limit(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		key, ok := UserID(r.Context())
		if !ok {
			key = r.RemoteAddr
		}
		if !rl.limiter(key).Allow() {
			w.Header().Set("Retry-After", "10")
			http.Error(w, "too many requests", http.StatusTooManyRequests)
			return
		}
		next.ServeHTTP(w, r)
	})
}
