const { PrismaClient } = require('@prisma/client');
const admin = require('firebase-admin');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

async function testFirebaseNotification() {
  const prisma = new PrismaClient();
  
  try {
    console.log('\n--- Firebase Notification Test ---');
    
    // 1. Initialize Firebase
    if (admin.apps.length === 0) {
      if (!process.env.FIREBASE_PROJECT_ID || !process.env.FIREBASE_PRIVATE_KEY || !process.env.FIREBASE_CLIENT_EMAIL) {
         console.error('❌ Missing Firebase environment variables in .env');
         return;
      }

      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        }),
      });
      console.log('✅ Firebase Admin SDK initialized');
    }

    // 2. Find a device with a token using raw SQL to avoid model mapping issues
    const devices = await prisma.$queryRaw`SELECT "userId", "platform", "pushToken" FROM "user_devices" WHERE "pushToken" IS NOT NULL LIMIT 1`;

    if (devices.length === 0) {
      console.log('❌ No devices with push tokens found in the database.');
      return;
    }

    const device = devices[0];
    console.log(`📡 Sending test notification to:`);
    console.log(`   - User ID: ${device.userId}`);
    console.log(`   - Platform: ${device.platform}`);
    console.log(`   - Token: ${device.pushToken}`);

    // 3. Construct Message
    const message = {
      token: device.pushToken,
      notification: {
        title: 'Test Notification',
        body: 'This is a test notification from the Digital Nurse backend!',
      },
      data: {
        test: 'true',
        time: new Date().toISOString()
      }
    };

    // 4. Send Message
    const response = await admin.messaging().send(message);
    console.log('\n🚀 FCM RESPONSE:', response);
    console.log('\n✅ TEST SUCCESSFUL: The backend successfully sent the message to FCM.');
    
  } catch (error) {
    console.error('\n❌ ERROR SENDING NOTIFICATION:');
    if (error.code) {
      console.error(`   Code: ${error.code}`);
      console.error(`   Message: ${error.message}`);
      
      if (error.code === 'messaging/registration-token-not-registered' || error.code === 'messaging/invalid-registration-token') {
        console.log('\n💡 NOTE: This error is expected if the token in the database is a placeholder or expired.');
        console.log('   However, it PROVES that your Firebase credentials are correct and working!');
      }
    } else {
      console.error(error);
    }
  } finally {
    await prisma.$disconnect();
  }
}

testFirebaseNotification();
