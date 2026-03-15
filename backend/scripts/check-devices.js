const { PrismaClient } = require('@prisma/client');

async function main() {
  const prisma = new PrismaClient();
  try {
    const devices = await prisma.userDevice.findMany({
      where: {
        pushToken: { not: null },
      },
      include: {
        user: true,
      },
    });

    if (devices.length === 0) {
      console.log('No devices with push tokens found in the database.');
    } else {
      console.log(`Found ${devices.length} devices with push tokens:`);
      devices.forEach((device) => {
        console.log(`- User ID: ${device.userId}, User: ${device.user.email}, Device ID: ${device.deviceId}`);
      });
    }
  } catch (err) {
    console.error('Error querying database:', err);
  } finally {
    await prisma.$disconnect();
  }
}

main();
