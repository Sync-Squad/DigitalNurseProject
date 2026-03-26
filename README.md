# Digital Nurse — Your AI-Powered Healthcare Companion

Digital Nurse is a comprehensive healthcare platform designed to streamline patient onboarding, monitor vital signs, and provide intelligent health insights. Built with a modern tech stack and powered by AI, it offers a seamless experience for both patients and caregivers.

---

## 🚀 Key Features

- **🔐 Secure Authentication**: Multi-method login via Email/Password and Google OAuth.
- **✨ Smooth Onboarding**: Guided profile completion for personalized healthcare tracking.
- **💳 Subscription Management**: Tiered plans (FREE, BASIC, PREMIUM) with secure Stripe integration.
- **📊 AI Health Insights**: Automated, rule-based analysis of vitals, medications, and lifestyle logs.
- **💬 AI Chat Assistant**: RAG-powered (Retrieval-Augmented Generation) assistant for personalized health queries.
- **🥗 Nutrition & Activity Analysis**: Mobile-side AI (Gemini) for instant calorie and macronutrient estimation.
- **📈 Vital Monitoring**: Comprehensive tracking and trending of essential health metrics.

---

## 🛠️ Technology Stack

### Backend
- **Framework**: [NestJS](https://nestjs.com/) (Node.js)
- **Database**: [PostgreSQL](https://www.postgresql.org/)
- **ORM**: [Prisma](https://www.prisma.io/)
- **Payments**: [Stripe SDK](https://stripe.com/docs/api)
- **Auth**: Passport.js (JWT, Google OAuth)
- **Documentation**: Swagger/OpenAPI

### Mobile
- **Framework**: [Flutter](https://flutter.dev/)
- **AI**: Google Gemini (via `google_generative_ai`)
- **State Management**: (Refer to mobile directory for details)

---

## 🏗️ Project Structure

The project follows a monorepo structure:

```text
DigitalNurse/
├── backend/          # NestJS API (Sources, Prisma schema, tests)
├── mobile/           # Flutter Application (Cross-platform mobile app)
├── assets/           # Shared static assets and design resources
├── documentation/    # Comprehensive project guides and diagrams
└── README.md         # This overview
```

---

## 🚦 Quick Start

To get the project running locally, follow these primary steps:

1. **Prerequisites**: Ensure you have Node.js (v18+), Flutter SDK, and PostgreSQL installed.
2. **Setup**: Follow the detailed guide in [SETUP_INSTRUCTIONS.md](file:///d:/Development/Digital%20Nurse/Development/SETUP_INSTRUCTIONS.md).
3. **Configuration**: Configure your environment variables in `backend/.env` (see `backend/.env.example`).
4. **Database**: Run `npx prisma migrate dev` to set up your local database schema.

For backend-specific details, see [backend/README.md](file:///d:/Development/Digital%20Nurse/Development/backend/README.md).

---

## 🤖 AI Architecture

Digital Nurse leverages AI across two main flows:
1. **Rule-Based Insights**: Automated analysis of health data patterns.
2. **Generative AI Chat**: Context-aware assistance using RAG.

For a deep dive into how our AI system is built, visit:
👉 [AI Architecture Overview](file:///d:/Development/Digital%20Nurse/Development/ai_architecture_overview.md)

---

## 📚 Project Documentation

- [Project Plan](file:///d:/Development/Digital%20Nurse/Development/ProjectPlan.md) — Roadmap and architecture details.
- [Implementation Summary](file:///d:/Development/Digital%20Nurse/Development/IMPLEMENTATION_SUMMARY.md) — Technical status and implemented features.
- [Handover Guide](file:///d:/Development/Digital%20Nurse/Development/HANDOVER.md) — Guidance for new developers.
- [Testing Guide](file:///d:/Development/Digital%20Nurse/Development/PLAN_ADHERENCE_TESTING_GUIDE.md) — How to verify system integrity.

---

## 🤝 Contributing

This project is currently proprietary. Please follow the branch strategy and commit guidelines outlined in the [Project Plan](file:///d:/Development/Digital%20Nurse/Development/ProjectPlan.md).

---

## 📄 License

Proprietary and Confidential. Registered trademark of Digital Nurse Project.
