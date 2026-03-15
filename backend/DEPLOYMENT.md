# Railway Deployment Guide

This guide will walk you through deploying the Digital Nurse backend API to Railway's free tier platform.

## Prerequisites

- GitHub account
- Railway account (create at [railway.app](https://railway.app))
- Existing PostgreSQL database connection string from your Linux server
- Node.js 18+ installed locally (for testing)

## Step 1: Prepare Your Repository

Ensure your backend code is pushed to a GitHub repository. Railway will deploy directly from GitHub.

## Step 2: Create Railway Account and Project

1. Go to [railway.app](https://railway.app) and sign up/login
2. Click "New Project"
3. Select "Deploy from GitHub repo"
4. Authorize Railway to access your GitHub account if prompted
5. Select your repository containing the backend code
6. Railway will automatically detect it's a Node.js project

## Step 3: Configure Build Settings

Railway should auto-detect the build settings, but verify:

1. **Root Directory**: Set to `backend` (if your repo has frontend/backend structure)
   - Go to Settings → Root Directory → Set to `backend`

2. **Build Command**: Should be `npm run build`
   - Railway will use the `railway.json` configuration

3. **Start Command**: Should be `npm run start:prod`
   - Railway will use the `Procfile` configuration

## Step 4: Configure Environment Variables

In Railway dashboard, go to **Variables** tab and add the following environment variables:

### Required Variables

```bash
# Database Connection (from your Linux server)
DATABASE_URL=postgresql://username:password@your-server-ip:5432/database_name

# Server Configuration
NODE_ENV=production
PORT=3000  # Railway sets this automatically, but you can override

# CORS Configuration
FRONTEND_URL=*  # Allow all origins for testing (change to specific domain later)

# JWT Authentication Secrets
# Generate strong secrets using: openssl rand -base64 32
JWT_SECRET=your-generated-secret-here
JWT_REFRESH_SECRET=your-generated-refresh-secret-here
JWT_EXPIRATION=7d
JWT_REFRESH_EXPIRATION=30d
```

### Optional Variables (only if using these features)

```bash
# Google OAuth (if using Google sign-in)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_CALLBACK_URL=https://your-app.railway.app/api/auth/google/callback

# Stripe Payments (if using Stripe)
STRIPE_SECRET_KEY=your-stripe-secret-key
STRIPE_BASIC_PRICE_ID=price_basic
STRIPE_PREMIUM_PRICE_ID=price_premium
```

### Generating JWT Secrets

Run these commands locally to generate secure secrets:

```bash
# Generate JWT_SECRET
openssl rand -base64 32

# Generate JWT_REFRESH_SECRET
openssl rand -base64 32
```

Copy the output and paste into Railway environment variables.

## Step 5: Database Configuration

### Ensure Database Allows External Connections

Your Linux server database must allow connections from Railway's infrastructure:

1. **PostgreSQL Configuration** (`postgresql.conf`):
   ```
   listen_addresses = '*'
   ```

2. **PostgreSQL Access Control** (`pg_hba.conf`):
   ```
   host    all    all    0.0.0.0/0    md5
   ```

3. **Firewall Rules**: Allow incoming connections on port 5432 from Railway IPs
   - Railway uses dynamic IPs, so you may need to allow all IPs or use a VPN/proxy

4. **Test Connection**: Verify your `DATABASE_URL` works from outside your network

### Run Prisma Migrations

After deployment, you may need to run migrations:

1. In Railway dashboard, go to your service
2. Click on the "Deployments" tab
3. Click on the latest deployment
4. Open the "Logs" tab
5. You can run migrations via Railway's CLI or add a build script

Alternatively, add a post-deploy script in `package.json`:

```json
{
  "scripts": {
    "postbuild": "npx prisma generate",
    "postdeploy": "npx prisma migrate deploy"
  }
}
```

## Step 6: Deploy

1. Railway will automatically deploy when you push to your GitHub repository
2. You can also trigger a manual deploy from the Railway dashboard
3. Monitor the deployment logs in Railway dashboard
4. Wait for deployment to complete (usually 2-5 minutes)

## Step 7: Verify Deployment

Once deployed, Railway will provide a public URL like:
```
https://your-app-name.railway.app
```

Test the following endpoints:

1. **Health Check**: 
   ```
   GET https://your-app-name.railway.app/api/health
   ```

2. **Swagger Documentation**: 
   ```
   GET https://your-app-name.railway.app/api/docs
   ```

3. **API Base URL** (for mobile app):
   ```
   https://your-app-name.railway.app/api
   ```

## Step 8: Configure Custom Domain (Optional)

If you want a custom domain:

1. Go to Settings → Domains
2. Add your custom domain
3. Follow Railway's DNS configuration instructions
4. Update `FRONTEND_URL` environment variable to your custom domain

## Troubleshooting

### Build Fails

- Check Railway logs for specific errors
- Verify `package.json` has correct build scripts
- Ensure Node.js version is compatible (Railway uses Node 18+ by default)

### Database Connection Errors

- Verify `DATABASE_URL` is correct
- Check database server allows external connections
- Verify firewall rules allow Railway IPs
- Test connection string locally first

### Application Crashes

- Check Railway logs for runtime errors
- Verify all required environment variables are set
- Ensure Prisma client is generated (`npx prisma generate`)
- Check if migrations need to be run

### CORS Errors

- Verify `FRONTEND_URL` is set correctly
- For testing, use `*` to allow all origins
- For production, specify exact mobile app origin

## Railway Free Tier Limits

- **$5 monthly credit** (usually sufficient for low-traffic testing)
- **512MB RAM** per service
- **1GB storage**
- **Unlimited deployments**
- **Automatic HTTPS/SSL**

## Monitoring

- View logs in Railway dashboard → Your Service → Logs
- Monitor resource usage in Railway dashboard
- Set up alerts for service failures (available in paid plans)

## Updating Deployment

Simply push changes to your GitHub repository. Railway will automatically:
1. Detect the changes
2. Build the new version
3. Deploy it
4. Keep the old version running until the new one is ready

## Next Steps

After successful deployment:

1. Copy your Railway API URL: `https://your-app-name.railway.app/api`
2. Configure your mobile app to use this URL (see `MOBILE_CONFIG.md`)
3. Test authentication endpoints
4. Test API endpoints from your mobile app
5. Monitor logs for any issues

## Additional Resources

- [Railway Documentation](https://docs.railway.app/)
- [NestJS Deployment Guide](https://docs.nestjs.com/recipes/deployment)
- [Prisma Deployment Guide](https://www.prisma.io/docs/guides/deployment)

## Push Notifications (Firebase)

The system is now integrated with Firebase Cloud Messaging (FCM). To enable push notifications:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Open Project Settings → Service Accounts
3. Click "Generate new private key"
4. Note Down the values from the JSON and add them to your `.env` file:
   ```env
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
   ```
5. Run `npm install` to install `firebase-admin`.

### Testing Push Notifications

Use the new test endpoint to send a manual push to a user:
```bash
POST /api/notifications/test-push
{
  "userId": "1",
  "title": "Hello",
  "message": "This is a test notification"
}
```
