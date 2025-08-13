// Database migration utility for schema management and version control

import { supabase, DatabaseError } from './supabaseClient';

// Migration interface
interface Migration {
  id: string;
  name: string;
  version: number;
  up: () => Promise<void>;
  down: () => Promise<void>;
  dependencies?: string[];
}

// Migration status
interface MigrationStatus {
  id: string;
  version: number;
  applied_at: string;
  checksum: string;
}

// Migration manager class
export class MigrationManager {
  private migrations: Migration[] = [];
  private readonly tableName = 'schema_migrations';

  constructor() {
    this.ensureMigrationsTable();
  }

  // Ensure migrations table exists
  private async ensureMigrationsTable(): Promise<void> {
    try {
      const { error } = await supabase.rpc('create_migrations_table_if_not_exists');
      if (error) {
        // Fallback: create table manually
        const { error: createError } = await supabase
          .from('schema_migrations')
          .select('id')
          .limit(1);
        
        if (createError && createError.code === '42P01') { // Table doesn't exist
          await this.createMigrationsTable();
        }
      }
    } catch (error) {
      console.warn('Could not ensure migrations table:', error);
    }
  }

  // Create migrations table
  private async createMigrationsTable(): Promise<void> {
    const { error } = await supabase.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS schema_migrations (
          id VARCHAR(255) PRIMARY KEY,
          version INTEGER NOT NULL,
          applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
          checksum VARCHAR(64) NOT NULL,
          execution_time_ms INTEGER
        );
        
        CREATE INDEX IF NOT EXISTS idx_schema_migrations_version 
        ON schema_migrations(version);
      `
    });

    if (error) {
      console.error('Failed to create migrations table:', error);
    }
  }

  // Register a migration
  register(migration: Migration): void {
    this.migrations.push(migration);
  }

  // Get all registered migrations
  getMigrations(): Migration[] {
    return this.migrations.sort((a, b) => a.version - b.version);
  }

  // Get applied migrations
  async getAppliedMigrations(): Promise<MigrationStatus[]> {
    try {
      const { data, error } = await supabase
        .from('schema_migrations')
        .select('*')
        .order('version', { ascending: true });

      if (error) throw new DatabaseError('Failed to fetch applied migrations', error.code, error);
      return data || [];
    } catch (error) {
      console.error('Error fetching applied migrations:', error);
      return [];
    }
  }

  // Get pending migrations
  async getPendingMigrations(): Promise<Migration[]> {
    const applied = await this.getAppliedMigrations();
    const appliedIds = new Set(applied.map(m => m.id));
    
    return this.getMigrations().filter(migration => !appliedIds.has(migration.id));
  }

  // Check if migration can be applied (dependencies satisfied)
  private async canApplyMigration(migration: Migration): Promise<boolean> {
    if (!migration.dependencies || migration.dependencies.length === 0) {
      return true;
    }

    const applied = await this.getAppliedMigrations();
    const appliedIds = new Set(applied.map(m => m.id));
    
    return migration.dependencies.every(dep => appliedIds.has(dep));
  }

  // Apply a single migration
  private async applyMigration(migration: Migration): Promise<void> {
    const startTime = Date.now();
    
    try {
      console.log(`Applying migration: ${migration.name} (${migration.id})`);
      
      // Check dependencies
      if (!(await this.canApplyMigration(migration))) {
        throw new Error(`Migration ${migration.id} has unsatisfied dependencies`);
      }

      // Apply migration
      await migration.up();
      
      // Record migration
      const checksum = this.calculateChecksum(migration);
      const executionTime = Date.now() - startTime;
      
      const { error } = await supabase
        .from('schema_migrations')
        .insert({
          id: migration.id,
          version: migration.version,
          applied_at: new Date().toISOString(),
          checksum,
          execution_time_ms: executionTime
        });

      if (error) throw new DatabaseError('Failed to record migration', error.code, error);
      
      console.log(`✓ Applied migration: ${migration.name} (${executionTime}ms)`);
    } catch (error) {
      console.error(`✗ Failed to apply migration ${migration.name}:`, error);
      throw error;
    }
  }

  // Rollback a single migration
  private async rollbackMigration(migration: Migration): Promise<void> {
    try {
      console.log(`Rolling back migration: ${migration.name} (${migration.id})`);
      
      // Rollback migration
      await migration.down();
      
      // Remove migration record
      const { error } = await supabase
        .from('schema_migrations')
        .delete()
        .eq('id', migration.id);

      if (error) throw new DatabaseError('Failed to remove migration record', error.code, error);
      
      console.log(`✓ Rolled back migration: ${migration.name}`);
    } catch (error) {
      console.error(`✗ Failed to rollback migration ${migration.name}:`, error);
      throw error;
    }
  }

  // Calculate migration checksum
  private calculateChecksum(migration: Migration): string {
    const content = `${migration.id}:${migration.version}:${migration.name}`;
    // Simple hash function (in production, use a proper hash library)
    let hash = 0;
    for (let i = 0; i < content.length; i++) {
      const char = content.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return Math.abs(hash).toString(16);
  }

  // Run all pending migrations
  async migrate(): Promise<{ applied: number; errors: string[] }> {
    const pending = await this.getPendingMigrations();
    const applied: string[] = [];
    const errors: string[] = [];

    console.log(`Found ${pending.length} pending migrations`);

    for (const migration of pending) {
      try {
        await this.applyMigration(migration);
        applied.push(migration.id);
      } catch (error) {
        errors.push(`${migration.name}: ${error instanceof Error ? error.message : 'Unknown error'}`);
        // Stop on first error
        break;
      }
    }

    return { applied: applied.length, errors };
  }

  // Rollback last N migrations
  async rollback(steps: number = 1): Promise<{ rolledBack: number; errors: string[] }> {
    const applied = await this.getAppliedMigrations();
    const toRollback = applied.slice(-steps).reverse();
    const rolledBack: string[] = [];
    const errors: string[] = [];

    console.log(`Rolling back ${toRollback.length} migrations`);

    for (const migrationStatus of toRollback) {
      const migration = this.migrations.find(m => m.id === migrationStatus.id);
      if (!migration) {
        errors.push(`Migration ${migrationStatus.id} not found in registered migrations`);
        continue;
      }

      try {
        await this.rollbackMigration(migration);
        rolledBack.push(migration.id);
      } catch (error) {
        errors.push(`${migration.name}: ${error instanceof Error ? error.message : 'Unknown error'}`);
        // Stop on first error
        break;
      }
    }

    return { rolledBack: rolledBack.length, errors };
  }

  // Get migration status
  async status(): Promise<{
    total: number;
    applied: number;
    pending: number;
    migrations: Array<{
      id: string;
      name: string;
      version: number;
      status: 'applied' | 'pending' | 'missing';
      applied_at?: string;
    }>;
  }> {
    const applied = await this.getAppliedMigrations();
    const allMigrations = this.getMigrations();
    const appliedIds = new Set(applied.map(m => m.id));

    const migrations = allMigrations.map(migration => {
      const appliedMigration = applied.find(m => m.id === migration.id);
      return {
        id: migration.id,
        name: migration.name,
        version: migration.version,
        status: appliedMigration ? 'applied' as const : 'pending' as const,
        applied_at: appliedMigration?.applied_at,
      };
    });

    // Check for missing migrations (applied but not registered)
    const registeredIds = new Set(allMigrations.map(m => m.id));
    for (const appliedMigration of applied) {
      if (!registeredIds.has(appliedMigration.id)) {
        migrations.push({
          id: appliedMigration.id,
          name: 'Unknown',
          version: appliedMigration.version,
          status: 'missing' as const,
          applied_at: appliedMigration.applied_at,
        });
      }
    }

    return {
      total: allMigrations.length,
      applied: applied.length,
      pending: allMigrations.length - applied.length,
      migrations: migrations.sort((a, b) => a.version - b.version),
    };
  }

  // Validate migration integrity
  async validate(): Promise<{ valid: boolean; errors: string[] }> {
    const applied = await this.getAppliedMigrations();
    const errors: string[] = [];

    for (const appliedMigration of applied) {
      const migration = this.migrations.find(m => m.id === appliedMigration.id);
      if (!migration) {
        errors.push(`Applied migration ${appliedMigration.id} not found in registered migrations`);
        continue;
      }

      const expectedChecksum = this.calculateChecksum(migration);
      if (appliedMigration.checksum !== expectedChecksum) {
        errors.push(`Migration ${appliedMigration.id} checksum mismatch`);
      }
    }

    return { valid: errors.length === 0, errors };
  }
}

// Create migration manager instance
export const migrationManager = new MigrationManager();

// Register built-in migrations
migrationManager.register({
  id: '001_initial_schema',
  name: 'Initial schema setup',
  version: 1,
  async up() {
    // This would contain the initial schema creation
    // For now, we'll assume it's already applied
  },
  async down() {
    // Rollback logic
  }
});

migrationManager.register({
  id: '002_plant_details_tables',
  name: 'Add plant details tables',
  version: 2,
  dependencies: ['001_initial_schema'],
  async up() {
    // This migration was already applied via SQL files
    // The actual SQL is in the migration files
  },
  async down() {
    // Rollback logic
  }
});

// Migration CLI commands (for development)
export const migrationCommands = {
  async status() {
    const status = await migrationManager.status();
    console.log('\nMigration Status:');
    console.log(`Total: ${status.total}, Applied: ${status.applied}, Pending: ${status.pending}\n`);
    
    status.migrations.forEach(migration => {
      const statusIcon = migration.status === 'applied' ? '✓' : migration.status === 'pending' ? '⏳' : '❌';
      const date = migration.applied_at ? new Date(migration.applied_at).toLocaleDateString() : '';
      console.log(`${statusIcon} ${migration.id} (v${migration.version}) - ${migration.name} ${date}`);
    });
  },

  async migrate() {
    console.log('Running migrations...');
    const result = await migrationManager.migrate();
    
    if (result.applied > 0) {
      console.log(`\n✓ Applied ${result.applied} migrations`);
    }
    
    if (result.errors.length > 0) {
      console.log('\n✗ Migration errors:');
      result.errors.forEach(error => console.log(`  - ${error}`));
    }
  },

  async rollback(steps: number = 1) {
    console.log(`Rolling back ${steps} migration(s)...`);
    const result = await migrationManager.rollback(steps);
    
    if (result.rolledBack > 0) {
      console.log(`\n✓ Rolled back ${result.rolledBack} migrations`);
    }
    
    if (result.errors.length > 0) {
      console.log('\n✗ Rollback errors:');
      result.errors.forEach(error => console.log(`  - ${error}`));
    }
  },

  async validate() {
    console.log('Validating migrations...');
    const result = await migrationManager.validate();
    
    if (result.valid) {
      console.log('✓ All migrations are valid');
    } else {
      console.log('✗ Migration validation failed:');
      result.errors.forEach(error => console.log(`  - ${error}`));
    }
  }
};

// Export for use in development
if (import.meta.env.DEV) {
  (window as any).migrations = migrationCommands;
}
