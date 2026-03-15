const { Client } = require('pg');
require('dotenv').config();

async function checkDb() {
  const client = new Client({
    connectionString: process.env.DATABASE_URL,
  });

  try {
    await client.connect();
    console.log('Successfully connected to the database!');
    
    // Check for vector extension
    const extensionRes = await client.query("SELECT * FROM pg_extension WHERE extname = 'vector'");
    if (extensionRes.rows.length > 0) {
      console.log('pgvector extension is installed.');
    } else {
      console.log('pgvector extension is NOT installed.');
    }

    // List tables
    const tablesRes = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
    `);
    console.log('Tables found:', tablesRes.rows.map(r => r.table_name).join(', '));

  } catch (err) {
    console.error('Database connection error:', err.message);
  } finally {
    await client.end();
  }
}

checkDb();
