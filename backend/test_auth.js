const bcrypt = require('bcryptjs');
const mysql = require('mysql2/promise');
require('dotenv').config();

async function testAuth() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
  });

  const email = 'Abhisarsharma2006@gmail.com';
  const password = 'abhisar@2006';

  try {
    const [users] = await connection.execute('SELECT * FROM users WHERE email = ?', [email]);
    if (users.length === 0) {
      console.log('❌ User not found');
      return;
    }

    const user = users[0];
    console.log('User found:', user.email);

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (isMatch) {
      console.log('✅ Password matches!');
    } else {
      console.log('❌ Password DOES NOT match!');
    }
  } catch (err) {
    console.error('Error:', err.message);
  } finally {
    await connection.end();
  }
}

testAuth();
