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
