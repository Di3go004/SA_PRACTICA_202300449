// src/common/database.service.ts
// Principio D: los módulos dependen de esta abstracción, no directamente de pg
import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { Pool } from 'pg';

@Injectable()
export class CatalogDatabaseService implements OnModuleInit, OnModuleDestroy {
  private catalogPool: Pool;

  onModuleInit() {
    this.catalogPool = new Pool({
      host:     process.env.CATALOG_DB_HOST || 'localhost',
      port:     parseInt(process.env.CATALOG_DB_PORT || '5432'),
      database: process.env.CATALOG_DB_NAME || 'yousac_catalog_db',
      user:     process.env.CATALOG_DB_USER || 'yousac',
      password: process.env.CATALOG_DB_PASS || 'yousac_secret',
    });
    console.log('✅ Conectado a yousac_catalog_db');
  }

  async onModuleDestroy() {
    await this.catalogPool.end();
  }

  async query(text: string, params?: any[]) {
    return this.catalogPool.query(text, params);
  }
}
