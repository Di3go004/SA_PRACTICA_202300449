#!/bin/bash

# ============================================================
# YoUSAC - Script de setup del proyecto
# Crea toda la estructura de carpetas y archivos base
# Ejecutar desde la raíz del repositorio SA_PRACTICA_CARNET
# ============================================================

echo "🚀 Creando estructura del proyecto YoUSAC..."

# ── AUTH-CATALOG SERVICE (TypeScript + NestJS) ───────────────
mkdir -p auth-catalog-service/src/auth
mkdir -p auth-catalog-service/src/users
mkdir -p auth-catalog-service/src/catalog
mkdir -p auth-catalog-service/src/enrollments
mkdir -p auth-catalog-service/src/middleware
mkdir -p auth-catalog-service/src/common
mkdir -p auth-catalog-service/proto
mkdir -p auth-catalog-service/database

# Archivos base TypeScript
cat > auth-catalog-service/package.json << 'EOF'
{
  "name": "auth-catalog-service",
  "version": "1.0.0",
  "description": "YoUSAC Auth & Catalog Microservice",
  "scripts": {
    "start": "node dist/main.js",
    "start:dev": "ts-node src/main.ts",
    "build": "tsc"
  },
  "dependencies": {
    "@nestjs/common": "^10.0.0",
    "@nestjs/core": "^10.0.0",
    "@nestjs/jwt": "^10.0.0",
    "@nestjs/platform-express": "^10.0.0",
    "@grpc/grpc-js": "^1.9.0",
    "@grpc/proto-loader": "^0.7.0",
    "bcrypt": "^5.1.0",
    "pg": "^8.11.0",
    "reflect-metadata": "^0.1.13",
    "rxjs": "^7.8.0"
  },
  "devDependencies": {
    "@types/bcrypt": "^5.0.0",
    "@types/node": "^20.0.0",
    "@types/pg": "^8.10.0",
    "typescript": "^5.0.0",
    "ts-node": "^10.9.0"
  }
}
EOF

cat > auth-catalog-service/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "module": "commonjs",
    "declaration": true,
    "removeComments": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "allowSyntheticDefaultImports": true,
    "target": "ES2021",
    "sourceMap": true,
    "outDir": "./dist",
    "baseUrl": "./",
    "incremental": true,
    "skipLibCheck": true,
    "strictNullChecks": false,
    "noImplicitAny": false
  }
}
EOF

cat > auth-catalog-service/Dockerfile << 'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["node", "dist/main.js"]
EOF

cat > auth-catalog-service/.env.example << 'EOF'
AUTH_DB_HOST=localhost
AUTH_DB_PORT=5432
AUTH_DB_NAME=yousac_auth_db
AUTH_DB_USER=yousac
AUTH_DB_PASS=yousac_secret

CATALOG_DB_HOST=localhost
CATALOG_DB_PORT=5432
CATALOG_DB_NAME=yousac_catalog_db
CATALOG_DB_USER=yousac
CATALOG_DB_PASS=yousac_secret

JWT_SECRET=supersecreto_yousac_2026
JWT_TTL=8h
PORT=3000
NODE_ENV=development
EOF

# Archivo main de entrada
cat > auth-catalog-service/src/main.ts << 'EOF'
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors();
  await app.listen(process.env.PORT || 3000);
  console.log(`Auth/Catalog service running on port ${process.env.PORT || 3000}`);
}
bootstrap();
EOF

cat > auth-catalog-service/src/app.module.ts << 'EOF'
import { Module } from '@nestjs/common';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { CatalogModule } from './catalog/catalog.module';
import { EnrollmentsModule } from './enrollments/enrollments.module';

@Module({
  imports: [
    AuthModule,
    UsersModule,
    CatalogModule,
    EnrollmentsModule,
  ],
})
export class AppModule {}
EOF

echo "✅ auth-catalog-service creado"

# ── REPRODUCTION SERVICE (Go + Gin) ─────────────────────────
mkdir -p reproduction-service/cmd
mkdir -p reproduction-service/internal/streaming
mkdir -p reproduction-service/internal/checkpoints
mkdir -p reproduction-service/internal/ratings
mkdir -p reproduction-service/internal/grpc
mkdir -p reproduction-service/proto
mkdir -p reproduction-service/database

cat > reproduction-service/go.mod << 'EOF'
module reproduction-service

go 1.22

require (
    github.com/gin-gonic/gin v1.9.1
    go.mongodb.org/mongo-driver v1.13.0
    google.golang.org/grpc v1.60.0
    google.golang.org/protobuf v1.32.0
)
EOF

cat > reproduction-service/Dockerfile << 'EOF'
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o main ./cmd/main.go

FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/main .
EXPOSE 3001 50051
CMD ["./main"]
EOF

cat > reproduction-service/cmd/main.go << 'EOF'
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
EOF

cat > reproduction-service/.env.example << 'EOF'
MONGO_URI=mongodb://yousac:yousac_secret@localhost:27017/yousac_reproduction_db?authSource=admin
GRPC_PORT=50051
HTTP_PORT=3001
ENV=development
EOF

echo "✅ reproduction-service creado"

# ── ANALYTICS SERVICE (Python + FastAPI) ────────────────────
mkdir -p analytics-service/app/metrics
mkdir -p analytics-service/app/reports
mkdir -p analytics-service/app/grpc
mkdir -p analytics-service/app/scheduler
mkdir -p analytics-service/proto
mkdir -p analytics-service/database

cat > analytics-service/requirements.txt << 'EOF'
fastapi==0.109.0
uvicorn==0.27.0
pymysql==1.1.0
grpcio==1.60.0
grpcio-tools==1.60.0
python-dotenv==1.0.0
sqlalchemy==2.0.25
apscheduler==3.10.4
EOF

cat > analytics-service/Dockerfile << 'EOF'
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 3002
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "3002"]
EOF

cat > analytics-service/app/main.py << 'EOF'
from fastapi import FastAPI
import os

app = FastAPI(title="YoUSAC Analytics Service")

@app.get("/health")
def health():
    return {"status": "ok", "service": "analytics"}

# TODO: agregar routers de metrics y reports
EOF

cat > analytics-service/.env.example << 'EOF'
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DB=yousac_analytics_db
MYSQL_USER=yousac
MYSQL_PASSWORD=yousac_secret
GRPC_REPRODUCTION_HOST=localhost
GRPC_REPRODUCTION_PORT=50051
HTTP_PORT=3002
ENV=development
EOF

echo "✅ analytics-service creado"

# ── API GATEWAY (Nginx) ──────────────────────────────────────
mkdir -p api-gateway

cat > api-gateway/Dockerfile << 'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 8080
CMD ["node", "index.js"]
EOF

cat > api-gateway/package.json << 'EOF'
{
  "name": "api-gateway",
  "version": "1.0.0",
  "description": "YoUSAC API Gateway",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js"
  },
  "dependencies": {
    "express": "^4.18.0",
    "http-proxy-middleware": "^2.0.6",
    "jsonwebtoken": "^9.0.0",
    "cors": "^2.8.5"
  },
  "devDependencies": {
    "nodemon": "^3.0.0"
  }
}
EOF

cat > api-gateway/index.js << 'EOF'
const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const AUTH_SERVICE    = process.env.AUTH_SERVICE_URL    || 'http://localhost:3000';
const REPRODUCTION_SERVICE = process.env.REPRODUCTION_SERVICE_URL || 'http://localhost:3001';
const ANALYTICS_SERVICE   = process.env.ANALYTICS_SERVICE_URL    || 'http://localhost:3002';
const JWT_SECRET      = process.env.JWT_SECRET          || 'supersecreto_yousac_2026';

// Middleware: validar JWT en rutas protegidas
const validateJWT = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ message: 'Token requerido' });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    return res.status(401).json({ message: 'Token inválido o expirado' });
  }
};

// Health check del gateway
app.get('/health', (_, res) => res.json({ status: 'ok', service: 'gateway' }));

// Rutas públicas (sin JWT)
app.use('/api/auth', createProxyMiddleware({ target: AUTH_SERVICE, changeOrigin: true }));

// Rutas protegidas
app.use('/api/catalog',      validateJWT, createProxyMiddleware({ target: AUTH_SERVICE,         changeOrigin: true }));
app.use('/api/enrollments',  validateJWT, createProxyMiddleware({ target: AUTH_SERVICE,         changeOrigin: true }));
app.use('/api/users',        validateJWT, createProxyMiddleware({ target: AUTH_SERVICE,         changeOrigin: true }));
app.use('/api/videos',       validateJWT, createProxyMiddleware({ target: REPRODUCTION_SERVICE, changeOrigin: true }));
app.use('/api/checkpoints',  validateJWT, createProxyMiddleware({ target: REPRODUCTION_SERVICE, changeOrigin: true }));
app.use('/api/ratings',      validateJWT, createProxyMiddleware({ target: REPRODUCTION_SERVICE, changeOrigin: true }));
app.use('/api/analytics',    validateJWT, createProxyMiddleware({ target: ANALYTICS_SERVICE,    changeOrigin: true }));

app.listen(8080, () => console.log('API Gateway running on port 8080'));
EOF

cat > api-gateway/.env.example << 'EOF'
AUTH_SERVICE_URL=http://auth-catalog-service:3000
REPRODUCTION_SERVICE_URL=http://reproduction-service:3001
ANALYTICS_SERVICE_URL=http://analytics-service:3002
JWT_SECRET=supersecreto_yousac_2026
PORT=8080
EOF

echo "✅ api-gateway creado"

# ── FRONTEND ─────────────────────────────────────────────────
mkdir -p frontend/src/pages
mkdir -p frontend/src/components
mkdir -p frontend/src/services
mkdir -p frontend/src/hooks
mkdir -p frontend/public

cat > frontend/package.json << 'EOF'
{
  "name": "yousac-frontend",
  "version": "1.0.0",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0",
    "axios": "^1.6.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "@vitejs/plugin-react": "^4.2.0",
    "typescript": "^5.0.0",
    "vite": "^5.0.0"
  }
}
EOF

cat > frontend/Dockerfile << 'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host"]
EOF

cat > frontend/.env.example << 'EOF'
VITE_API_URL=http://localhost:8080
EOF

cat > frontend/src/services/api.ts << 'EOF'
import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080';

const api = axios.create({ baseURL: API_URL });

// Interceptor: agregar JWT a cada request
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

export default api;
EOF

echo "✅ frontend creado"

# ── PROTO COMPARTIDO ─────────────────────────────────────────
mkdir -p proto

cp reproduction-service/proto/.gitkeep proto/.gitkeep 2>/dev/null || touch proto/.gitkeep

cat > proto/checkpoints.proto << 'EOF'
syntax = "proto3";
package reproduccion;
option go_package = "./proto";

service ReproduccionService {
  rpc GetCheckpoint     (CheckpointRequest)    returns (CheckpointResponse);
  rpc GetVideoStats     (VideoStatsRequest)    returns (VideoStatsResponse);
  rpc GetUserProgress   (UserProgressRequest)  returns (UserProgressResponse);
}

message CheckpointRequest   { string user_id = 1; string video_id = 2; }
message CheckpointResponse  {
  string user_id          = 1;
  string video_id         = 2;
  int32  position_seconds = 3;
  float  progress_percent = 4;
  bool   completed        = 5;
}
message VideoStatsRequest   { string video_id = 1; }
message VideoStatsResponse  {
  string video_id                = 1;
  int32  total_views             = 2;
  float  average_progress        = 3;
  float  recommendation_percent  = 4;
}
message UserProgressRequest { string user_id = 1; string course_id = 2; }
message UserProgressResponse {
  string user_id          = 1;
  string course_id        = 2;
  float  overall_progress = 3;
  repeated VideoProgress videos = 4;
}
message VideoProgress {
  string video_id         = 1;
  float  progress_percent = 2;
  bool   completed        = 3;
}
EOF

echo "✅ proto compartido creado"

# ── .gitignore global ────────────────────────────────────────
cat > .gitignore << 'EOF'
# Node
node_modules/
dist/
.env

# Go
*.exe
vendor/

# Python
__pycache__/
*.pyc
.venv/
venv/

# Docker
.docker/

# IDE
.idea/
.vscode/
*.swp
EOF

echo ""
echo "✅ Estructura completa creada!"
echo ""
echo "📁 Estructura final:"
echo "SA_PRACTICA_CARNET/"
echo "├── DB/                      (ya existía)"
echo "├── Documentation/           (ya existía)"
echo "├── auth-catalog-service/    ✅ nuevo"
echo "├── reproduction-service/    ✅ nuevo"
echo "├── analytics-service/       ✅ nuevo"
echo "├── api-gateway/             ✅ nuevo"
echo "├── frontend/                ✅ nuevo"
echo "├── proto/                   ✅ nuevo"
echo "├── docker-compose.local.yml (ya existía)"
echo "└── .gitignore               ✅ nuevo"
echo ""
echo "👉 Próximo paso: cd auth-catalog-service && npm install"
