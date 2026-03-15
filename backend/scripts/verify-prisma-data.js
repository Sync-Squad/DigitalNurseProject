const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function verify() {
  try {
    console.log('--- Verifying Database Connection ---');
    const roles = await prisma.role.findMany();
    console.log('Roles found in DB:', roles.map(r => r.roleCode).join(', '));
    
    if (roles.length > 0) {
      console.log('✅ Base data is present.');
    } else {
      console.log('⚠️ No roles found. Seeding might be incomplete.');
    }

    const userCount = await prisma.user.count();
    console.log('Total users in DB:', userCount);
    
    console.log('--- Verification Complete ---');
  } catch (err) {
    console.error('❌ Verification failed:', err.message);
  } finally {
    await prisma.$disconnect();
  }
}

verify();
