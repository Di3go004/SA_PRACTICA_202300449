import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { DatabaseModule } from './common/database.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { CatalogModule } from './catalog/catalog.module';
import { EnrollmentsModule } from './enrollments/enrollments.module';

@Module({
  imports: [
    DatabaseModule,
    AuthModule,
    UsersModule,
    CatalogModule,
    EnrollmentsModule,
  ],
  controllers: [AppController],
})
export class AppModule {}
