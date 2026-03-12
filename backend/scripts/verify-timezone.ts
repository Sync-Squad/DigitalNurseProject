import { PrismaClient } from '@prisma/client';

async function main() {
  const prisma = new PrismaClient();
  try {
    console.log('--- Database Timezone Diagnostic ---');
    
    // Check session timezone
    const tzResult: any = await prisma.$queryRaw`SHOW timezone;`;
    console.log('Session Timezone:', tzResult[0]?.TimeZone || 'Unknown');

    // Check current time from DB
    const nowResult: any = await prisma.$queryRaw`SELECT now();`;
    console.log('Database current time (now()):', nowResult[0]?.now);

    // Check a recent MedIntake record - find without select to see actual keys
    const latestIntake = await prisma.medIntake.findFirst({
      orderBy: { createdAt: 'desc' },
    });

    if (latestIntake) {
      console.log('\n--- Latest MedIntake Record ---');
      const intake = latestIntake as any;
      console.log('Available keys:', Object.keys(intake));
      
      const id = intake.medIntakeId || intake.intakeId || 'Unknown ID';
      console.log('ID:', id.toString());
      console.log('dueAt:', intake.dueAt);
      console.log('takenAt:', intake.takenAt);
      console.log('createdAt:', intake.createdAt);
      console.log('updatedAt:', intake.updatedAt);
    } else {
      console.log('\nNo MedIntake records found.');
    }

  } catch (error) {
    console.error('Error during diagnostic:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
