
import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { Pool } from 'pg';

@Injectable()
export class AuthDatabaseService implements OnModuleInit, OnModuleDestroy {
  private authPool: Pool;
  private catalogPool: Pool;

  onModuleInit() {
    // Conexión a yousac_auth_db
    this.authPool = new Pool({
      host:     process.env.AUTH_DB_HOST     || 'localhost',
      port:     parseInt(process.env.AUTH_DB_PORT || '5432'),
      database: process.env.AUTH_DB_NAME     || 'yousac_auth_db',
      user:     process.env.AUTH_DB_USER     || 'yousac',
      password: process.env.AUTH_DB_PASS     || 'yousac_secret',
    });

    // Conexión a yousac_catalog_db
    this.catalogPool = new Pool({
      host:     process.env.CATALOG_DB_HOST  || 'localhost',
      port:     parseInt(process.env.CATALOG_DB_PORT || '5432'),
      database: process.env.CATALOG_DB_NAME  || 'yousac_catalog_db',
      user:     process.env.CATALOG_DB_USER  || 'yousac',
      password: process.env.CATALOG_DB_PASS  || 'yousac_secret',
    });

    console.log('Conexiones a PostgreSQL establecidas');
  }

  async onModuleDestroy() {
    await this.authPool.end();
    await this.catalogPool.end();
  }

  // Ejecuta queries en yousac_auth_db
  async authQuery(text: string, params?: any[]) {
    return this.authPool.query(text, params);
  }

  // Ejecuta queries en yousac_catalog_db
  async catalogQuery(text: string, params?: any[]) {
    return this.catalogPool.query(text, params);
  }
}
