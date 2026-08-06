// src/middleware/jwt.guard.ts
// Principio S: solo valida JWT, no hace nada más
// El catalog-service valida el JWT generado por el auth-service
import { Injectable, CanActivate, ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();

    const token =
      request.headers.authorization?.split(' ')[1] ||
      request.cookies?.session_token;

    if (!token) throw new UnauthorizedException('Token de autenticación requerido');

    try {
      request.user = this.jwtService.verify(token);
      return true;
    } catch {
      throw new UnauthorizedException('Token inválido o expirado');
    }
  }
}
