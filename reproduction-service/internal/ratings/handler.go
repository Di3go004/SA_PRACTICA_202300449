// internal/ratings/handler.go
package ratings

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

type Handler struct{ service *Service }

func NewHandler(service *Service) *Handler { return &Handler{service: service} }

func RegisterRoutes(r *gin.Engine, service *Service) {
	h := NewHandler(service)
	v1 := r.Group("/api/ratings")
	{
		v1.POST("", h.SaveRating)
		v1.GET("/:video_id/stats", h.GetVideoStats)
	}
}

// POST /api/ratings
func (h *Handler) SaveRating(c *gin.Context) {
	var dto SaveRatingDTO
	if err := c.ShouldBindJSON(&dto); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	stats, err := h.service.SaveRating(c.Request.Context(), dto)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, stats)
}

// GET /api/ratings/:video_id/stats
func (h *Handler) GetVideoStats(c *gin.Context) {
	videoID, _ := strconv.Atoi(c.Param("video_id"))
	stats, err := h.service.GetVideoStats(c.Request.Context(), videoID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al obtener estadísticas"})
		return
	}
	c.JSON(http.StatusOK, stats)
}
