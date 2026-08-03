
import { Injectable, BadRequestException } from '@nestjs/common';
import { AuthDatabaseService } from '../common/database.service';

@Injectable()
export class EnrollmentsService {
  constructor(private readonly db: AuthDatabaseService) {}

  async enrollStudent(studentId: number, courseId: number, adminId: number) {
    try {
      // Usamos el SP sp_enroll_student de catalog_db.sql 
      await this.db.catalogQuery('CALL sp_enroll_student($1, $2, $3)', [
        studentId,
        courseId,
        adminId,
      ]);
      return { message: 'Estudiante inscrito exitosamente' };
    } catch (error: any) {
      throw new BadRequestException(error.message);
    }
  }

  async unenrollStudent(studentId: number, courseId: number) {
    await this.db.catalogQuery('CALL sp_unenroll_student($1, $2)', [
      studentId,
      courseId,
    ]);
    return { message: 'Inscripción eliminada exitosamente' };
  }

  async getStudentCourses(studentId: number) {
    // Usamos la función fn_get_student_courses de catalog_db.sql
    const result = await this.db.catalogQuery(
      'SELECT * FROM fn_get_student_courses($1)',
      [studentId],
    );
    return result.rows;
  }
}
