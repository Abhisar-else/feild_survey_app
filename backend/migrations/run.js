// ── Migration Runner ─────────────────────────────────────────
// Reads init.sql and executes it against the MySQL database.
// Usage: npm run migrate

const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

async function runMigrations() {
  let connection;
  try {
    // Connect WITHOUT specifying a database first (so CREATE DATABASE works)
    connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT) || 3306,
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      multipleStatements: true,
    });

    console.log('✅ Connected to MySQL server');

    const sqlPath = path.join(__dirname, 'init.sql');
    const sql = fs.readFileSync(sqlPath, 'utf-8');

    console.log('📄 Running migration script...');
    await connection.query(sql);

    console.log('✅ Migration completed successfully!');
    console.log('');
    console.log('📋 Seed users created:');
    console.log('   Admin  → admin@gmail.com  / admin123');
    console.log('   Worker → worker@gmail.com / worker123');
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    process.exit(1);
  } finally {
    if (connection) await connection.end();
    process.exit(0);
  }
}

runMigrations();
