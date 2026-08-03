
import { Injectable, ForbiddenException, NotFoundException } from '@nestjs/common';
import { AuthDatabaseService } from '../common/database.service';

@Injectable()
export class CatalogService {
  constructor(private readonly db: AuthDatabaseService) {}

  async getCatalog(user: any, filters: any, pagination: { page: number; limit: number }) {
    const offset = (pagination.page - 1) * pagination.limit;

    let query: string;
    let params: any[];

    if (user.role === 'estudiante') {
      // Estudiante: solo ve grabaciones de sus cursos inscritos
      query = `
        SELECT * FROM vw_student_catalog
        WHERE student_id = $1
        ${filters.semester  ? 'AND semester  = $2' : ''}
        ${filters.schoolId  ? 'AND school_id = $3' : ''}
        ${filters.search    ? 'AND (title ILIKE $4 OR description ILIKE $4)' : ''}
        ORDER BY created_at DESC
        LIMIT $${this.paramCount(filters) + 1}
        OFFSET $${this.paramCount(filters) + 2}
      `;
      params = [user.sub, ...this.buildFilterParams(filters), pagination.limit, offset];
    } else {
      // Docente / Admin: ven el catálogo completo 
      query = `
        SELECT * FROM vw_catalog
        WHERE 1=1
        ${filters.semester  ? "AND semester  = $1" : ''}
        ${filters.schoolId  ? "AND school_id = $2" : ''}
        ${filters.search    ? "AND (title ILIKE $3 OR description ILIKE $3)" : ''}
        ORDER BY created_at DESC
        LIMIT $${this.paramCount(filters) + 1}
        OFFSET $${this.paramCount(filters) + 2}
      `;
      params = [...this.buildFilterParams(filters), pagination.limit, offset];
    }

    const result = await this.db.catalogQuery(query, params);
    return { data: result.rows, page: pagination.page, limit: pagination.limit };
  }

  async getRecordingById(id: number, user: any) {
    const result = await this.db.catalogQuery(
      'SELECT * FROM vw_catalog WHERE recording_id = $1',
      [id],
    );

    if (!result.rows[0]) throw new NotFoundException('Grabación no encontrada');

    const recording = result.rows[0];

    // Verificar acceso si es estudiante 
    if (user.role === 'estudiante') {
      const enrolled = await this.db.catalogQuery(
        'SELECT fn_is_student_enrolled($1, $2) AS enrolled',
        [user.sub, recording.course_id],
      );
      if (!enrolled.rows[0]?.enrolled) {
        throw new ForbiddenException('No tienes acceso a esta grabación');
      }
    }

    return recording;
  }

  async getSchools() {
    const result = await this.db.catalogQuery('SELECT * FROM schools ORDER BY name');
    return result.rows;
  }

  async getCourses(schoolId?: string) {
    const query = schoolId
      ? 'SELECT * FROM vw_courses_with_teachers WHERE school_id = $1 ORDER BY name'
      : 'SELECT * FROM vw_courses_with_teachers ORDER BY name';
    const result = await this.db.catalogQuery(query, schoolId ? [schoolId] : []);
    return result.rows;
  }

  // ── Helpers privados ─────────────────────────────────────

  private buildFilterParams(filters: any): any[] {
    const params: any[] = [];
    if (filters.semester) params.push(filters.semester);
    if (filters.schoolId) params.push(filters.schoolId);
    if (filters.search)   params.push(`%${filters.search}%`);
    return params;
  }

  private paramCount(filters: any): number {
    let count = 0;
    if (filters.semester) count++;
    if (filters.schoolId) count++;
    if (filters.search)   count++;
    return count;
  }
}
