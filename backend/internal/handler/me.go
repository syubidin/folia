package handler

import (
	"encoding/json"
	"net/http"

	"github.com/syubidin/folia/backend/internal/middleware"
)

func Me(w http.ResponseWriter, r *http.Request) {
	id, ok := middleware.UserID(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]string{"user_id": id})
}
