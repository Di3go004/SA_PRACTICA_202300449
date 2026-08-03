// internal/grpc/server/server.go
package server

import (
	"context"
	"strconv"

	"reproduction-service/internal/checkpoints"
	"reproduction-service/internal/ratings"
	pb "reproduction-service/proto"

	"google.golang.org/grpc"
)

// ReproduccionServer implementa la interfaz generada por protoc
type ReproduccionServer struct {
	pb.UnimplementedReproduccionServiceServer
	checkpointSvc *checkpoints.Service
	ratingSvc     *ratings.Service
}

// NewReproduccionServer crea e inicializa el servidor gRPC
func NewReproduccionServer(
	checkpointSvc *checkpoints.Service,
	ratingSvc *ratings.Service,
) *ReproduccionServer {
	return &ReproduccionServer{
		checkpointSvc: checkpointSvc,
		ratingSvc:     ratingSvc,
	}
}

// Register registra el servidor en el grpc.Server
func Register(grpcServer *grpc.Server, checkpointSvc *checkpoints.Service, ratingSvc *ratings.Service) {
	srv := NewReproduccionServer(checkpointSvc, ratingSvc)
	pb.RegisterReproduccionServiceServer(grpcServer, srv)
}

// GetCheckpoint devuelve el checkpoint de un usuario para un video
func (s *ReproduccionServer) GetCheckpoint(
	ctx context.Context,
	req *pb.CheckpointRequest,
) (*pb.CheckpointResponse, error) {
	// Los IDs vienen como string desde el proto
	userID, _ := strconv.Atoi(req.GetUserId())
	videoID, _ := strconv.Atoi(req.GetVideoId())

	cp, err := s.checkpointSvc.GetCheckpoint(ctx, userID, videoID)
	if err != nil {
		return nil, err
	}

	if cp == nil {
		return &pb.CheckpointResponse{
			UserId:          req.GetUserId(),
			VideoId:         req.GetVideoId(),
			PositionSeconds: 0,
			ProgressPercent: 0,
			Completed:       false,
		}, nil
	}

	return &pb.CheckpointResponse{
		UserId:          req.GetUserId(),
		VideoId:         req.GetVideoId(),
		PositionSeconds: int32(cp.PositionSeconds),
		ProgressPercent: float32(cp.ProgressPercent),
		Completed:       cp.Completed,
	}, nil
}

// GetVideoStats devuelve estadísticas de un video para Analítica
func (s *ReproduccionServer) GetVideoStats(
	ctx context.Context,
	req *pb.VideoStatsRequest,
) (*pb.VideoStatsResponse, error) {
	videoID, _ := strconv.Atoi(req.GetVideoId())

	stats, err := s.ratingSvc.GetVideoStats(ctx, videoID)
	if err != nil {
		return nil, err
	}

	return &pb.VideoStatsResponse{
		VideoId:               req.GetVideoId(),
		TotalViews:            int32(stats.TotalRatings),
		AverageProgress:       float32(stats.AverageStars),
		RecommendationPercent: float32(stats.RecommendationPercent),
	}, nil
}

// GetUserProgress devuelve el progreso de un usuario en un curso
func (s *ReproduccionServer) GetUserProgress(
	ctx context.Context,
	req *pb.UserProgressRequest,
) (*pb.UserProgressResponse, error) {
	return &pb.UserProgressResponse{
		UserId:          req.GetUserId(),
		CourseId:        req.GetCourseId(),
		OverallProgress: 0,
		Videos:          []*pb.VideoProgress{},
	}, nil
}