const { PrismaClient } = require('@prisma/client');
const admin = require('firebase-admin');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

async function main() {
  const prisma = new PrismaClient();
  
  try {
    console.log('\n--- FETCHING DEVICE FROM DATABASE ---');
    // Using raw SQL to bypass any model/mapping issues in scripts
    const devices = await prisma.$queryRaw`SELECT "userId", "platform", "pushToken" FROM "user_devices" WHERE "pushToken" IS NOT NULL LIMIT 1`;
    
    if (devices.length === 0) {
      console.log('❌ No devices with push tokens found. Please register a device in the app first.');
      return;
    }

    const device = devices[0];
    console.log(`✅ Found Device: User ${device.userId} (${device.platform})`);

    console.log('\n--- INITIALIZING FIREBASE ---');
    if (!process.env.FIREBASE_PROJECT_ID || !process.env.FIREBASE_PRIVATE_KEY || !process.env.FIREBASE_CLIENT_EMAIL) {
        console.error('❌ Missing Firebase environment variables in .env');
        return;
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

    console.log('\n--- SENDING TEST NOTIFICATION ---');
    const message = {
      token: device.pushToken,
      notification: {
        title: 'Digital Nurse Test',
        body: 'Your Firebase credentials are working!',
      },
    };

    const response = await admin.messaging().send(message);
    console.log('🚀 FCM Success Response:', response);

  } catch (error) {
    if (error.code) {
      console.log(`\n⚠️  FIREBASE RETURNED AN ERROR: ${error.code}`);
      console.log(`   ${error.message}`);
      
      if (error.code === 'messaging/registration-token-not-registered' || error.code === 'messaging/invalid-registration-token') {
        console.log('\n✅ VERIFICATION SUCCESSFUL: Your credentials are correct!');
        console.log('   (The error above is only because the token in the database is not a real device)');
      }
    } else {
      console.error('\n❌ SCRIPT ERROR:', error.message);
    }
  } finally {
    await prisma.$disconnect();
  }
}

main();
