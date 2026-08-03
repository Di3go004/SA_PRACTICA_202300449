
import { Controller, Post, Delete, Get, Body, Param, UseGuards, Req } from '@nestjs/common';
import { EnrollmentsService } from './enrollments.service';
import { JwtAuthGuard } from '../middleware/jwt.guard';
import { RolesGuard } from '../middleware/roles.guard';
import { Roles } from '../middleware/roles.decorator';

@Controller('enrollments')
@UseGuards(JwtAuthGuard, RolesGuard)
export class EnrollmentsController {
  constructor(private readonly enrollmentsService: EnrollmentsService) {}

  @Post()
  @Roles('administrador')
  async enrollStudent(
    @Body() body: { student_id: number; course_id: number },
    @Req() req: any,
  ) {
    return this.enrollmentsService.enrollStudent(
      body.student_id,
      body.course_id,
      req.user.sub,
    );
  }

  @Delete(':student_id/:course_id')
  @Roles('administrador')
  async unenrollStudent(
    @Param('student_id') studentId: string,
    @Param('course_id') courseId: string,
  ) {
    return this.enrollmentsService.unenrollStudent(
      parseInt(studentId),
      parseInt(courseId),
    );
  }

  @Get('my-courses')
  @Roles('estudiante')
  async getMyCourses(@Req() req: any) {
    return this.enrollmentsService.getStudentCourses(req.user.sub);
  }
}
