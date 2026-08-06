
import { Controller, Get, Put, Param, Body, UseGuards, Req } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../middleware/jwt.guard';
import { RolesGuard } from '../middleware/roles.guard';
import { Roles } from '../middleware/roles.decorator';

@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // Admin: ver todos los usuarios
  @Get()
  @Roles('administrador')
  async getAllUsers() {
    return this.usersService.getAllUsers();
  }

  // Admin: ver un usuario específico
  @Get(':id')
  @Roles('administrador')
  async getUserById(@Param('id') id: string) {
    return this.usersService.getUserById(parseInt(id));
  }

  // Cualquier usuario: ver su propio perfil
  @Get('me/profile')
  async getMyProfile(@Req() req: any) {
    return this.usersService.getUserById(req.user.sub);
  }

  // Admin: asignar rol a un usuario
  @Put(':id/role')
  @Roles('administrador')
  async assignRole(
    @Param('id') id: string,
    @Body() body: { role_id: number },
    @Req() req: any,
  ) {
    return this.usersService.assignRole(
      parseInt(id),
      body.role_id,
      req.user.sub,
    );
  }

  // Admin: bloquear/desbloquear usuario
  @Put(':id/block')
  @Roles('administrador')
  async toggleBlock(
    @Param('id') id: string,
    @Body() body: { blocked: boolean },
  ) {
    return this.usersService.toggleBlock(parseInt(id), body.blocked);
  }
}
