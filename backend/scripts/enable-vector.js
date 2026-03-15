const { Client } = require('pg');
require('dotenv').config();

async function enableVector() {
  const client = new Client({
    connectionString: process.env.DATABASE_URL,
  });

  try {
    await client.connect();
    console.log('Connected to DB. Attempting to enable pgvector extension...');
    await client.query('CREATE EXTENSION IF NOT EXISTS vector');
    console.log('Extension "vector" enabled successfully (or already existed).');
  } catch (err) {
    console.error('Error enabling extension:', err.message);
    console.warn('\nIMPORTANT: Your database user may lack permissions to enable extensions.');
    console.warn('If this fails, please run "CREATE EXTENSION IF NOT EXISTS vector" as a superuser (e.g., using pgAdmin or your DB provider dashboard).');
  } finally {
    await client.end();
  }
}

enableVector();
