// cmd/main.go
package main

import (
	"fmt"
	"log"
	"net"
	"net/http"
	"os"

	"reproduction-service/internal/checkpoints"
	grpcserver "reproduction-service/internal/grpc/server"
	"reproduction-service/internal/ratings"
	"reproduction-service/internal/streaming"
	"reproduction-service/internal/database"

	"github.com/gin-gonic/gin"
	"google.golang.org/grpc"
)

func main() {
	// Inicializar conexión a MongoDB
	db, err := database.NewMongoClient()
	if err != nil {
		log.Fatalf("Error conectando a MongoDB: %v", err)
	}
	defer db.Disconnect()
	fmt.Println("Conectado a MongoDB")

	// Inicializar repositorios
	checkpointRepo := checkpoints.NewRepository(db)
	ratingRepo     := ratings.NewRepository(db)
	streamingRepo  := streaming.NewRepository(db)

	// Inicializar servicios
	checkpointSvc := checkpoints.NewService(checkpointRepo)
	ratingSvc     := ratings.NewService(ratingRepo, checkpointRepo)
	streamingSvc  := streaming.NewService(streamingRepo, checkpointRepo)

	// ── Servidor gRPC ────────────────────────────────────────
	grpcPort := os.Getenv("GRPC_PORT")
	if grpcPort == "" {
		grpcPort = "50051"
	}

	go func() {
		lis, err := net.Listen("tcp", ":"+grpcPort)
		if err != nil {
			log.Fatalf("Error iniciando gRPC listener: %v", err)
		}
		grpcServer := grpc.NewServer()
		grpcserver.Register(grpcServer, checkpointSvc, ratingSvc)
		fmt.Printf("gRPC server corriendo en puerto %s\n", grpcPort)
		if err := grpcServer.Serve(lis); err != nil {
			log.Fatalf("Error en gRPC server: %v", err)
		}
	}()

	// ── Servidor HTTP (Gin) ──────────────────────────────────
	httpPort := os.Getenv("HTTP_PORT")
	if httpPort == "" {
		httpPort = "3001"
	}

	r := gin.Default()

	// Health check (RNF-017)
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok", "service": "reproduction"})
	})

	// Registrar rutas HTTP
	checkpoints.RegisterRoutes(r, checkpointSvc)
	ratings.RegisterRoutes(r, ratingSvc)
	streaming.RegisterRoutes(r, streamingSvc)

	fmt.Printf("HTTP server corriendo en puerto %s\n", httpPort)
	if err := r.Run(":" + httpPort); err != nil {
		log.Fatalf("Error iniciando HTTP server: %v", err)
	}
}