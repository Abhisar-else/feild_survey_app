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

  const users = [
    { email: 'test@gmail.com', pass: 'test1234' },
    { email: 'abhisarsharma2006@gmail.com', pass: 'abhisar@2006' }
  ];

  for (const u of users) {
    const salt = await bcrypt.genSalt(10);
    const hash = await bcrypt.hash(u.pass, salt);
    try {
      await connection.execute('DELETE FROM users WHERE email = ?', [u.email]);
      await connection.execute(
        'INSERT INTO users (name, email, password_hash, role) VALUES (?, ?, ?, ?)',
        ['User', u.email, hash, 'admin']
      );
      console.log(`✅ User ${u.email} created with password: ${u.pass}`);
    } catch (err) {
      console.error('❌ Error:', err.message);
    }
  }
  await connection.end();
}

createUser();
