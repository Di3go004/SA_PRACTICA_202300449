// src/main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import * as cookieParser from 'cookie-parser';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.use(cookieParser());
  app.enableCors();
  const port = process.env.PORT || 3003;
  await app.listen(port);
  console.log(`✅ Catalog service running on port ${port}`);
}
bootstrap();
