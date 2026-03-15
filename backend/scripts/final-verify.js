const { PrismaClient } = require('@prisma/client');
const admin = require('firebase-admin');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

async function main() {
  const prisma = new PrismaClient();
  
  try {
    console.log('\n--- FETCHING DEVICE FROM DATABASE ---');
    const devices = await prisma.$queryRaw`SELECT "userId", "platform", "pushToken" FROM "user_devices" WHERE "pushToken" IS NOT NULL LIMIT 1`;
    
    if (devices.length === 0) {
      console.log('❌ No devices with push tokens found.');
      return;
    }

    const device = devices[0];
    console.log(`✅ Found Device: User ${device.userId} (${device.platform})`);

    console.log('\n--- INITIALIZING FIREBASE ---');
    if (!process.env.FIREBASE_PROJECT_ID || !process.env.FIREBASE_PRIVATE_KEY || !process.env.FIREBASE_CLIENT_EMAIL) {
        throw new Error('Missing Firebase environment variables');
    }

    if (admin.apps.length === 0) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        }),
      });
    }
    console.log('✅ Firebase Admin SDK initialized');

    console.log('\n--- SENDING NOTIFICATION ---');
    const message = {
      token: device.pushToken,
      notification: {
        title: 'Test Notification',
        body: 'Credentials Verified!',
      },
    };

    const response = await admin.messaging().send(message);
    console.log('🚀 FCM Success Response:', response);

  } catch (error) {
    console.log('\n❌ NOTIFICATION ERROR:');
    console.log(`   Code: ${error.code}`);
    console.log(`   Message: ${error.message}`);
    
    if (error.code === 'messaging/registration-token-not-registered' || error.code === 'messaging/invalid-registration-token') {
      console.log('\n✅ VERIFICATION SUCCESSFUL: Your credentials work!');
    } else {
      console.log('\n❌ VERIFICATION FAILED: The error above indicates a problem with the service account or connectivity.');
      if (error.message.includes('time')) {
        console.log('💡 TIP: Check if your system time is correctly synchronized.');
      }
    }
  } finally {
    await prisma.$disconnect();
  }
}

main();
