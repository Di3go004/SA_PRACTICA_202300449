// internal/streaming/handler.go
package streaming

import (
	"net/http"
	"github.com/gin-gonic/gin"
)

type Handler struct{ service *Service }

func NewHandler(service *Service) *Handler { return &Handler{service: service} }

func RegisterRoutes(r *gin.Engine, service *Service) {
	h := NewHandler(service)
	v1 := r.Group("/api/videos")
	{
		v1.POST("/session/start", h.StartSession)
		v1.POST("/session/event", h.RecordEvent)
	}
}

// POST /api/videos/session/start
func (h *Handler) StartSession(c *gin.Context) {
	var dto StartSessionDTO
	if err := c.ShouldBindJSON(&dto); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	sessionID, checkpoint, err := h.service.StartSession(c.Request.Context(), dto)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al iniciar sesión"})
		return
	}

	startPosition := 0
	if checkpoint != nil {
		startPosition = checkpoint.PositionSeconds
	}

	c.JSON(http.StatusOK, gin.H{
		"session_id":     sessionID,
		"start_position": startPosition,
		"checkpoint":     checkpoint,
	})
}

// POST /api/videos/session/event
func (h *Handler) RecordEvent(c *gin.Context) {
	var dto EventDTO
	if err := c.ShouldBindJSON(&dto); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.service.RecordEvent(c.Request.Context(), dto); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al registrar evento"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"ok": true})
}
