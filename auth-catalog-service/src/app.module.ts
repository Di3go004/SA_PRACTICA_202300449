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
