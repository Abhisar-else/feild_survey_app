const bcrypt = require('bcryptjs');
const mysql = require('mysql2/promise');
require('dotenv').config();

async function createUser() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
  });

  const name = 'Abhisar Sharma';
  const email = 'Abhisarsharma2006@gmail.com';
  const password = 'abhisar@2006';
  const salt = await bcrypt.genSalt(10);
  const hash = await bcrypt.hash(password, salt);

  try {
    await connection.execute(
      'INSERT INTO users (name, email, password_hash, role) VALUES (?, ?, ?, ?)',
      [name, email, hash, 'admin']
    );
    console.log(`✅ User ${email} created successfully!`);
  } catch (err) {
    console.error('❌ Error creating user:', err.message);
  } finally {
    await connection.end();
  }
}

createUser();
