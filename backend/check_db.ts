import { PrismaClient } from '@prisma/client';

async function main() {
  const prisma = new PrismaClient();
  try {
    const count = await prisma.$queryRaw`SELECT COUNT(*) as count FROM ai_insights`;
    console.log('Total insights:', count);

    const samples = await prisma.$queryRaw`SELECT * FROM ai_insights LIMIT 5`;
    console.log('Sample insights:', JSON.stringify(samples, (key, value) => 
      typeof value === 'bigint' ? value.toString() : value, 2));

    const users = await prisma.$queryRaw`SELECT "userId", full_name, role_code 
      FROM users u 
      JOIN user_roles ur ON u."userId" = ur."userId" 
      JOIN roles r ON ur."role_id" = r."role_id" 
      LIMIT 10`;
    // Note: I need to check exact column names for users and roles.
    // Based on schema: userId, full_name. Roles table: roleId, roleCode. UserRole: userId, roleId.
    
    const usersCorrected = await prisma.$queryRaw`
      SELECT u."userId"::text, u.full_name, r."roleCode"
      FROM users u
      LEFT JOIN user_roles ur ON u."userId" = ur."userId"
      LEFT JOIN roles r ON ur."roleId" = r."roleId"
      LIMIT 10
    `;
    console.log('Sample users:', usersCorrected);

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
