// @ts-nocheck
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import * as express from 'express';
import { join } from 'path';
import { AuthService } from './auth/auth.service';
import { CaregiversService } from './caregivers/caregivers.service';

// BigInt serialization patch
(BigInt.prototype as any).toJSON = function () {
  return this.toString();
};

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    rawBody: true, // Required for Stripe webhooks
  });

  // Serve static files from the uploads directory
  const expressApp = app.getHttpAdapter().getInstance();
  expressApp.use('/uploads', express.static(join(process.cwd(), 'uploads')));

  // Enable CORS for multiple origins (web portal, mobile app, etc.)
  const allowedOrigins = process.env.FRONTEND_URL
    ? process.env.FRONTEND_URL.split(',').map((url) => url.trim())
    : []; // Default: empty, will be determined by logic below

  // Determine if we're in development mode (allow more permissive CORS)
  const isDevelopment = process.env.NODE_ENV !== 'production';
  const allowWildcard = allowedOrigins.includes('*');

  app.enableCors({
    origin: (origin: string | undefined, callback: (err: Error | null, origin?: string | boolean) => void) => {
      // Allow requests with no origin (like mobile apps or Postman)
      if (!origin) return callback(null, true);

      // Always allow localhost/127.0.0.1 origins (for local development, even when backend is remote)
      // This enables scenarios where frontend runs locally but backend is deployed remotely
      if (
        origin.startsWith('http://localhost:') ||
        origin.startsWith('http://127.0.0.1:') ||
        origin.startsWith('https://localhost:') ||
        origin.startsWith('https://127.0.0.1:')
      ) {
        return callback(null, origin);
      }

      // Check against allowed origins from environment variable FIRST
      // This takes precedence over automatic rules
      if (allowWildcard) {
        // Wildcard allows all origins (useful for development/testing)
        return callback(null, origin);
      }

      if (allowedOrigins.includes(origin)) {
        return callback(null, origin);
      }

      // In development mode: Allow IP-based origins (same host with different ports)
      // This handles scenarios like backend on :3000, frontend on :92, same IP
      // Example: http://100.42.177.77:3000 (backend) allowing http://100.42.177.77:92 (frontend)
      if (isDevelopment) {
        try {
          const originUrl = new URL(origin);
          const originHost = originUrl.hostname;

          // Allow any numeric IP address format in development (allows same-host, different ports)
          // Matches patterns like: 100.42.177.77, 192.168.1.1, 10.0.0.1, etc.
          const isIPAddress = /^\d+\.\d+\.\d+\.\d+$/.test(originHost);

          if (isIPAddress) {
            return callback(null, origin);
          }
        } catch (e) {
          // Invalid URL format, will be rejected below
        }
      }

      // Origin not allowed
      console.warn(`[CORS] Rejected origin: ${origin}. Allowed: ${allowedOrigins.join(', ') || (isDevelopment ? 'development mode (same-host allowed)' : 'none')}`);
      callback(new Error(`CORS: Origin '${origin}' is not allowed. Allowed origins: ${allowedOrigins.join(', ') || 'none'}`));
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'X-Requested-With'],
    exposedHeaders: ['Authorization'],
    maxAge: 86400, // 24 hours - cache preflight requests
  });

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  // API prefix
  app.setGlobalPrefix('api');

  // Swagger documentation
  const config = new DocumentBuilder()
    .setTitle('Digital Nurse API')
    .setDescription('API documentation for Digital Nurse application')
    .setVersion('1.0')
    .addBearerAuth()
    .addTag('Authentication', 'Authentication endpoints')
    .addTag('Users', 'User management endpoints')
    .addTag('Subscriptions', 'Subscription management endpoints')
    .addTag('Medications', 'Medication management endpoints')
    .addTag('Vitals', 'Health vital measurements endpoints')
    .addTag('Caregivers', 'Caregiver management endpoints')
    .addTag('Lifestyle', 'Diet and exercise logging endpoints')
    .addTag('Documents', 'Document management endpoints')
    .addTag('Notifications', 'Notification management endpoints')
    .addTag('Lookups', 'Lookup values endpoints')
    .addTag('Devices', 'Device management endpoints')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  // Email verification GET endpoint (outside /api prefix)
  const authService = app.get(AuthService);
  const caregiversService = app.get(CaregiversService);

  // Registration page endpoint (outside /api prefix) for caregiver invitations
  expressApp.get('/register', async (req: any, res: any) => {
    const inviteCode = req.query.inviteCode as string;

    if (!inviteCode) {
      return res.status(400).send(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>Registration - Digital Nurse</title>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
              display: flex;
              justify-content: center;
              align-items: center;
              min-height: 100vh;
              margin: 0;
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              color: #333;
            }
            .container {
              background: white;
              padding: 2rem;
              border-radius: 12px;
              box-shadow: 0 10px 40px rgba(0,0,0,0.2);
              max-width: 500px;
              text-align: center;
            }
            h1 { color: #e74c3c; margin-top: 0; }
            p { line-height: 1.6; color: #666; }
            .error-icon { font-size: 48px; margin-bottom: 1rem; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="error-icon">⚠️</div>
            <h1>Invalid Registration Link</h1>
            <p>No invitation code was provided. Please check your email and click the registration link again.</p>
          </div>
        </body>
        </html>
      `);
    }

    try {
      const invitation = await caregiversService.getInvitationByCode(inviteCode);
      const patientName = invitation.elderUser?.name || 'your loved one';

      return res.status(200).send(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>Caregiver Registration - Digital Nurse</title>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
              display: flex;
              justify-content: center;
              align-items: center;
              min-height: 100vh;
              margin: 0;
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              color: #333;
            }
            .container {
              background: white;
              padding: 2rem;
              border-radius: 12px;
              box-shadow: 0 10px 40px rgba(0,0,0,0.2);
              max-width: 500px;
              text-align: center;
            }
            h1 { color: #14b8a6; margin-top: 0; }
            p { line-height: 1.6; color: #666; margin: 1rem 0; }
            .invite-code {
              background: #f9fafb;
              padding: 1.5rem;
              border-radius: 8px;
              margin: 1.5rem 0;
              border: 2px dashed #14b8a6;
            }
            .code {
              font-size: 24px;
              font-weight: 700;
              color: #14b8a6;
              font-family: monospace;
              letter-spacing: 2px;
              margin: 0.5rem 0;
            }
            .instructions {
              background: #f0f9ff;
              padding: 1rem;
              border-radius: 8px;
              margin: 1.5rem 0;
              text-align: left;
            }
            .instructions ol {
              margin: 0.5rem 0;
              padding-left: 1.5rem;
            }
            .instructions li {
              margin: 0.5rem 0;
              color: #666;
            }
            .success-icon { font-size: 48px; margin-bottom: 1rem; }
            .expiry {
              font-size: 0.9rem;
              color: #999;
              margin-top: 1.5rem;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="success-icon">👋</div>
            <h1>You've Been Invited!</h1>
            <p><strong>${patientName}</strong> has invited you to be their caregiver on Digital Nurse.</p>
            <div class="invite-code">
              <p style="margin: 0 0 0.5rem 0; color: #666; font-size: 14px; font-weight: 600;">
                Your Invitation Code:
              </p>
              <div class="code">${inviteCode}</div>
            </div>
            <div class="instructions">
              <p style="margin: 0 0 0.5rem 0; color: #333; font-weight: 600;">To complete your registration:</p>
              <ol>
                <li>Open the Digital Nurse mobile app</li>
                <li>Go to the registration screen</li>
                <li>Select "Caregiver" as your role</li>
                <li>Enter the invitation code above</li>
                <li>Complete your registration</li>
              </ol>
            </div>
            <p class="expiry">This invitation will expire in 7 days.</p>
          </div>
        </body>
        </html>
      `);
    } catch (error: any) {
      // Handle NestJS exceptions (HttpException has getStatus method)
      let statusCode = 500;
      if (error.status) {
        statusCode = error.status;
      } else if (error.statusCode) {
        statusCode = error.statusCode;
      } else if (typeof error.getStatus === 'function') {
        statusCode = error.getStatus();
      }

      const message = error.message || 'An error occurred while validating the invitation';
      const isExpired = message.includes('expired') || message.includes('Expired');
      const isAlreadyProcessed = message.includes('already processed') || message.includes('Already processed');
      const isNotFound = message.includes('not found') || message.includes('Not found');

      let errorTitle = 'Invalid Invitation';
      let errorIcon = '❌';
      let errorMessage = message;

      if (isExpired) {
        errorTitle = 'Invitation Expired';
        errorIcon = '⏰';
        errorMessage = 'This invitation has expired. Please ask for a new invitation.';
      } else if (isAlreadyProcessed) {
        errorTitle = 'Invitation Already Used';
        errorIcon = 'ℹ️';
        errorMessage = 'This invitation has already been used. If you have an account, please log in.';
      } else if (isNotFound) {
        errorTitle = 'Invitation Not Found';
        errorIcon = '⚠️';
        errorMessage = 'This invitation code is invalid. Please check your email and try again.';
      }

      return res.status(statusCode).send(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>${errorTitle} - Digital Nurse</title>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
              display: flex;
              justify-content: center;
              align-items: center;
              min-height: 100vh;
              margin: 0;
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              color: #333;
            }
            .container {
              background: white;
              padding: 2rem;
              border-radius: 12px;
              box-shadow: 0 10px 40px rgba(0,0,0,0.2);
              max-width: 500px;
              text-align: center;
            }
            h1 { 
              color: ${isAlreadyProcessed ? '#3498db' : '#e74c3c'}; 
              margin-top: 0; 
            }
            p { line-height: 1.6; color: #666; }
            .error-icon { font-size: 48px; margin-bottom: 1rem; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="error-icon">${errorIcon}</div>
            <h1>${errorTitle}</h1>
            <p>${errorMessage}</p>
          </div>
        </body>
        </html>
      `);
    }
  });

  expressApp.get('/email-verification', async (req: any, res: any) => {
    const token = req.query.token as string;

    if (!token) {
      return res.status(400).send(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>Email Verification - Digital Nurse</title>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
              display: flex;
              justify-content: center;
              align-items: center;
              min-height: 100vh;
              margin: 0;
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              color: #333;
            }
            .container {
              background: white;
              padding: 2rem;
              border-radius: 12px;
              box-shadow: 0 10px 40px rgba(0,0,0,0.2);
              max-width: 500px;
              text-align: center;
            }
            h1 { color: #e74c3c; margin-top: 0; }
            p { line-height: 1.6; color: #666; }
            .error-icon { font-size: 48px; margin-bottom: 1rem; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="error-icon">⚠️</div>
            <h1>Verification Link Invalid</h1>
            <p>No verification token was provided. Please check your email and click the verification link again.</p>
          </div>
        </body>
        </html>
      `);
    }

    try {
      const result = await authService.verifyEmail(token);
      return res.status(200).send(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>Email Verified - Digital Nurse</title>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
              display: flex;
              justify-content: center;
              align-items: center;
              min-height: 100vh;
              margin: 0;
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              color: #333;
            }
            .container {
              background: white;
              padding: 2rem;
              border-radius: 12px;
              box-shadow: 0 10px 40px rgba(0,0,0,0.2);
              max-width: 500px;
              text-align: center;
            }
            h1 { color: #27ae60; margin-top: 0; }
            p { line-height: 1.6; color: #666; }
            .success-icon { font-size: 48px; margin-bottom: 1rem; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="success-icon">✅</div>
            <h1>Email Verified Successfully!</h1>
            <p>Your email address has been verified. You can now log in to your Digital Nurse account.</p>
            <p style="margin-top: 1.5rem; font-size: 0.9rem; color: #999;">You can close this window and return to the app.</p>
          </div>
        </body>
        </html>
      `);
    } catch (error: any) {
      const statusCode = error.status || 500;
      const message = error.message || 'An error occurred during verification';
      const isExpired = message.includes('expired');
      const isAlreadyVerified = message.includes('already been verified');
      const isInvalid = message.includes('Invalid');

      let errorTitle = 'Verification Failed';
      let errorIcon = '❌';
      let errorMessage = message;

      if (isExpired) {
        errorTitle = 'Verification Link Expired';
        errorIcon = '⏰';
        errorMessage = 'This verification link has expired. Please request a new verification email.';
      } else if (isAlreadyVerified) {
        errorTitle = 'Already Verified';
        errorIcon = 'ℹ️';
        errorMessage = 'This email address has already been verified. You can log in to your account.';
      } else if (isInvalid) {
        errorTitle = 'Invalid Verification Link';
        errorIcon = '⚠️';
        errorMessage = 'This verification link is invalid. Please check your email and try again.';
      }

      return res.status(statusCode).send(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>${errorTitle} - Digital Nurse</title>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
              display: flex;
              justify-content: center;
              align-items: center;
              min-height: 100vh;
              margin: 0;
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              color: #333;
            }
            .container {
              background: white;
              padding: 2rem;
              border-radius: 12px;
              box-shadow: 0 10px 40px rgba(0,0,0,0.2);
              max-width: 500px;
              text-align: center;
            }
            h1 { 
              color: ${isAlreadyVerified ? '#3498db' : '#e74c3c'}; 
              margin-top: 0; 
            }
            p { line-height: 1.6; color: #666; }
            .error-icon { font-size: 48px; margin-bottom: 1rem; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="error-icon">${errorIcon}</div>
            <h1>${errorTitle}</h1>
            <p>${errorMessage}</p>
          </div>
        </body>
        </html>
      `);
    }
  });

  const port = process.env.PORT || 3000;
  await app.listen(port);

  console.log(`🚀 Application is running on: http://localhost:${port}`);
  console.log(`📚 Swagger documentation: http://localhost:${port}/api/docs`);
}
bootstrap();
