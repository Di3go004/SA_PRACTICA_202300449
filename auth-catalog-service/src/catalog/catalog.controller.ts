
import { Controller, Get, Query, Param, UseGuards, Req } from '@nestjs/common';
import { CatalogService } from './catalog.service';
import { JwtAuthGuard } from '../middleware/jwt.guard';

@Controller('catalog')
@UseGuards(JwtAuthGuard)
export class CatalogController {
  constructor(private readonly catalogService: CatalogService) {}

  @Get()
  async getCatalog(
    @Req() req: any,
    @Query('semester') semester?: string,
    @Query('year') year?: string,
    @Query('school_id') schoolId?: string,
    @Query('course_id') courseId?: string,
    @Query('teacher_id') teacherId?: string,
    @Query('tag') tag?: string,
    @Query('search') search?: string,
    @Query('page') page = '1',
    @Query('limit') limit = '20',
  ) {
    const filters = { semester, year, schoolId, courseId, teacherId, tag, search };
    const pagination = { page: parseInt(page), limit: parseInt(limit) };
    return this.catalogService.getCatalog(req.user, filters, pagination);
  }

  @Get('schools')
  async getSchools() {
    return this.catalogService.getSchools();
  }

  @Get('courses')
  async getCourses(@Query('school_id') schoolId?: string) {
    return this.catalogService.getCourses(schoolId);
  }

  @Get(':id')
  async getRecording(@Param('id') id: string, @Req() req: any) {
    return this.catalogService.getRecordingById(parseInt(id), req.user);
  }
}
