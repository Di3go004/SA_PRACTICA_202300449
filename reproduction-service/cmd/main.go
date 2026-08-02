package main

import (
    "fmt"
    "log"
    "os"
)

func main() {
    port := os.Getenv("HTTP_PORT")
    if port == "" {
        port = "3001"
    }
    fmt.Printf("Reproduction service running on port %s\n", port)
    log.Println("gRPC server starting on port 50051...")
    // TODO: inicializar Gin y servidor gRPC
    select {}
}
