const { PrismaClient } = require('@prisma/client');

async function main() {
  const prisma = new PrismaClient();
  try {
    // Check if there are any devices with push tokens
    const devices = await prisma.$queryRaw`SELECT "userId", "platform", "pushToken" FROM "user_devices" WHERE "pushToken" IS NOT NULL`;
    
    if (devices.length === 0) {
      console.log('\n--- NO DEVICES FOUND ---');
      console.log('To test notifications, a mobile device must first register its push token in the database.');
      console.log('You can manually add a dummy device for testing if you have a valid FCM token from a real device.');
    } else {
      console.log(`\n--- FOUND ${devices.length} REGISTERED DEVICES ---`);
      devices.forEach((d, i) => {
        console.log(`${i+1}. User ID: ${d.userId} | Platform: ${d.platform} | Token: ${d.pushToken.substring(0, 15)}...`);
      });
    }
  } catch (err) {
    console.error('Error querying database:', err);
  } finally {
    await prisma.$disconnect();
  }
}

main();
