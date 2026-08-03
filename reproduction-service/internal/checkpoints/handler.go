// internal/checkpoints/handler.go
// Principio S: solo maneja HTTP, delega al service
package checkpoints

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

func RegisterRoutes(r *gin.Engine, service *Service) {
	h := NewHandler(service)
	v1 := r.Group("/api/checkpoints")
	{
		v1.POST("", h.SaveCheckpoint)
		v1.GET("/:video_id", h.GetCheckpoint)
	}
}

// POST /api/checkpoints
func (h *Handler) SaveCheckpoint(c *gin.Context) {
	var dto SaveCheckpointDTO
	if err := c.ShouldBindJSON(&dto); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	cp, err := h.service.SaveCheckpoint(c.Request.Context(), dto)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al guardar checkpoint"})
		return
	}

	c.JSON(http.StatusOK, cp)
}

// GET /api/checkpoints/:video_id?user_id=X
func (h *Handler) GetCheckpoint(c *gin.Context) {
	videoID, err := strconv.Atoi(c.Param("video_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "video_id inválido"})
		return
	}

	userID, err := strconv.Atoi(c.Query("user_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id requerido"})
		return
	}

	cp, err := h.service.GetCheckpoint(c.Request.Context(), userID, videoID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al obtener checkpoint"})
		return
	}

	if cp == nil {
		c.JSON(http.StatusOK, gin.H{"position_seconds": 0, "progress_percent": 0, "completed": false})
		return
	}

	c.JSON(http.StatusOK, cp)
}
