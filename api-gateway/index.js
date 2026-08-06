// api-gateway/index.js
const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const AUTH_SERVICE        = process.env.AUTH_SERVICE_URL        || 'http://localhost:3000';
const CATALOG_SERVICE     = process.env.CATALOG_SERVICE_URL     || 'http://localhost:3003';
const REPRODUCTION_SERVICE = process.env.REPRODUCTION_SERVICE_URL || 'http://localhost:3001';
const ANALYTICS_SERVICE   = process.env.ANALYTICS_SERVICE_URL   || 'http://localhost:3002';
const JWT_SECRET          = process.env.JWT_SECRET              || 'supersecreto_yousac_2026';

// Middleware: validar JWT
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

// Health check
app.get('/health', (_, res) => res.json({ status: 'ok', service: 'gateway' }));

// ── Rutas públicas (sin JWT) ─────────────────────────────────
app.use('/api/auth', createProxyMiddleware({
  target: AUTH_SERVICE,
  changeOrigin: true,
}));

// ── Rutas protegidas ─────────────────────────────────────────

// Auth service: usuarios y roles
app.use('/api/users', validateJWT, createProxyMiddleware({
  target: AUTH_SERVICE,
  changeOrigin: true,
}));

// Catalog service: catálogo, escuelas, cursos
app.use('/api/catalog', validateJWT, createProxyMiddleware({
  target: CATALOG_SERVICE,
  changeOrigin: true,
}));

// Catalog service: inscripciones
app.use('/api/enrollments', validateJWT, createProxyMiddleware({
  target: CATALOG_SERVICE,
  changeOrigin: true,
}));

// Reproduction service: videos, checkpoints, ratings
app.use('/api/videos',      validateJWT, createProxyMiddleware({ target: REPRODUCTION_SERVICE, changeOrigin: true }));
app.use('/api/checkpoints', validateJWT, createProxyMiddleware({ target: REPRODUCTION_SERVICE, changeOrigin: true }));
app.use('/api/ratings',     validateJWT, createProxyMiddleware({ target: REPRODUCTION_SERVICE, changeOrigin: true }));

// Analytics service
app.use('/api/analytics', validateJWT, createProxyMiddleware({
  target: ANALYTICS_SERVICE,
  changeOrigin: true,
}));

app.listen(8080, () => console.log('✅ API Gateway running on port 8080'));