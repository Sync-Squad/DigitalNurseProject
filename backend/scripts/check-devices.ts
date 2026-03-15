import { PrismaClient } from '@prisma/client';

async function main() {
  const prisma = new PrismaClient();
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
      console.log(`- User ID: ${device.userId}, User: ${device.user.email}, Device ID: ${device.deviceId}, Token: ${device.pushToken?.substring(0, 20)}...`);
    });
  }

  await prisma.$disconnect();
}

main();
