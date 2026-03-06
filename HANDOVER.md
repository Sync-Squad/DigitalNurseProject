# 🏥 Digital Nurse Project Handover Document

This document serves as a comprehensive guide for the next developer taking over the Digital Nurse project. It covers the architecture, tech stack, setup, and current status of the project.

---

## 📌 Project Overview
Digital Nurse is a healthcare platform designed to bridge the gap between patients (elderly/chronic care) and their caregivers. It provides medication reminders, vitals tracking, lifestyle logging, and document management with role-based access control.

---

## 🛠️ Tech Stack

### 🔹 Backend
- **Framework**: [NestJS](https://nestjs.com/) (Node.js)
- **Language**: TypeScript
- **Database**: PostgreSQL with [Prisma ORM](https://www.prisma.io/)
- **Authentication**: Passport.js (JWT, Google OAuth, Local)
- **Payments**: [Stripe](https://stripe.com/)
- **Validation**: `class-validator`, `class-transformer`

### 🔹 Mobile App
- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: Provider
- **Local Storage**: `shared_preferences`, `flutter_secure_storage`
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Networking**: Dio

### 🔹 Web Portal (React)
- **Framework**: [React](https://react.dev/) + [Vite](https://vitejs.dev/)
- **Styling**: Tailwind CSS, Lucide Icons, Radix UI
- **Build Tool**: Vite

---

## 🏗️ Architecture & Monorepo Structure

Digital Nurse uses a monorepo structure to keep backend, web, and mobile code in one place.

```text
DigitalNurseProject/
├── backend/            # NestJS API (Primary backend)
├── mobile/             # Flutter App
├── web/portal/        # React-based Admin & Care Package Portal
├── prisma/             # shared database schema (typically in backend/)
├── assets/             # Shared design assets
└── docs/               # Project documentation
```

### Key Integrations
1. **Stripe**: Handles subscriptions (Free, Basic, Premium).
2. **Firebase**: Used for Push Notifications and potentially Auth/Analytics.
3. **Google OAuth**: Social login integration.

---

## 🚀 Setup & Configuration

### 1. Backend Setup
```bash
cd backend
npm install
cp .env.example .env  # Add your DB URL, Stripe keys, and JWT secrets
npx prisma generate
npx prisma migrate dev
npm run start:dev
```

### 2. Mobile Setup
```bash
cd mobile
flutter pub get
# Ensure you have google-services.json for Android and GoogleService-Info.plist for iOS
flutter run
```

### 3. Web Portal Setup
```bash
cd web/portal
npm install
npm run dev
```

---

## 📂 Key Modules & Components

### Backend (`backend/src`)
- `auth/`: Handles registration, login, and Google OAuth flow.
- `users/`: Profile management and onboarding tracking.
- `subscriptions/`: Stripe integration, plan management, and webhooks.
- `common/`: Guards (`JwtAuthGuard`), decorators (`@Public`, `@CurrentUser`), and filters.

### Mobile (`mobile/lib`)
- `core/`: Constants, services (FCM, Notifications), and utilities.
- `providers/`: State management (MedicationProvider, UserProvider).
- `screens/`: UI for Auth, Dashboard, Vitals, and Meds.

### Web (`web/portal/src`)
- `components/`: UI library using Radix/Tailwind.
- `lib/`: Utility functions and API clients.

---

## 📡 API & Data Flow
The Backend exposes a RESTful API at `http://localhost:3000/api`.
- **Swagger Docs**: Available at `/api/docs` when running.
- **Health Check**: `/api/health`.

### Authentication Flow
1. Client logs in via `/auth/login`.
2. Backend returns `accessToken` (short-lived) and `refreshToken` (long-lived).
3. Client stores tokens securely (`flutter_secure_storage` for mobile).
4. Protected routes require `Authorization: Bearer <token>`.

---

## 🚢 Deployment & DevOps
- **Target**: Linux Server (Ubuntu 20.04+).
- **Process Manager**: PM2 is used to manage the NestJS process.
- **Web Server**: Nginx acts as a reverse proxy for the API and serves static web files.
- **SSL**: Managed via Let's Encrypt / Certbot.

---

## ⚠️ Known Issues & Roadmap

### Current Status
- ✅ Backend Core (Auth, Users, Stripe)
- ✅ Mobile Foundation (UI, FCM, Notifications)
- ✅ Web Portal Foundation (Layout, Auth views)
- ⚠️ **Easypaisa/JazzCash**: Planned for local (Pakistan) payment support but not yet implemented.
- ⚠️ **Email Service**: Basic setup exists; needs production-ready SMTP integration.

### Immediate Next Steps
1. **Sync Environments**: Ensure `google-services.json` is synced across team members.
2. **Testing**: Run `npx prisma studio` to verify database state during manual testing.
3. **CI/CD**: Set up GitHub Actions for automated linting and build checks.

---

## 📞 Handover Contacts
- If you have questions about the Stripe flow, check [subscriptions.service.ts](file:///e:/DEVELOPMENTTTTTTTTTTTTTTTT/DigitalNurseProject/backend/src/subscriptions/subscriptions.service.ts).
- For FCM testing, refer to [FCM_TESTING_GUIDE.md](file:///e:/DEVELOPMENTTTTTTTTTTTTTTTT/DigitalNurseProject/mobile/FCM_TESTING_GUIDE.md).

Good luck with the project! 🚀
