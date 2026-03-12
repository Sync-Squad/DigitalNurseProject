---
name: Backend API Development - Phase 1
overview: ""
todos: []
isProject: false
---

# Backend API Development - Phase 1

## Overview

Analyze Flutter app requirements, compare with database schema, identify gaps, align Prisma schema with database, and implement RESTful NestJS APIs for all required endpoints.

## Phase 0: Flutter App Analysis & Database Gap Identification

### Flutter App API Requirements

#### 1. Medications Module

**App Model:** `id`, `name`, `dosage`, `frequency` (enum), `startDate`, `endDate`, `reminderTimes` (array), `notes`, `userId`, `medicineForm` (enum), `strength`, `doseAmount`, `periodicDays` (array)

**Database:** `medications` + `med_schedules` tables

**Key Mappings:**

- App `reminderTimes` array → DB `med_schedules.timesLocal` (JSONB)
- App `frequency` enum → DB `med_schedules.daysMask` + `timesLocal`
- App `periodicDays` → DB `daysMask` (bitmask conversion)
- App `medicineForm` enum → DB `formCode` (string lookup needed)
- App `strength` + `doseAmount` → DB `doseValue` + `doseUnitCode`

**Required APIs:**

- `GET /api/medications` - List medications
- `POST /api/medications` - Create medication + schedule
- `GET /api/medications/:id` - Get with schedule
- `PUT /api/medications/:id` - Update medication + schedule
- `DELETE /api/medications/:id` - Delete
- `GET /api/medications/:id/intakes` - Intake history
- `POST /api/medications/:id/intakes` - Log intake
- `GET /api/medications/:id/adherence` - Adherence %
- `GET /api/medications/:id/streak` - Adherence streak
- `GET /api/medications/upcoming` - Upcoming reminders

#### 2. Vitals/Health Module

**App Model:** `id`, `type` (enum), `value` (string), `timestamp`, `notes`, `userId`

**Database:** `vital_measurements` with `value1`, `value2`, `valueText`

**Key Mappings:**

- App `value` string → DB `value1`/`value2`/`valueText` (depends on type)
- Blood pressure: `value1`=systolic, `value2`=diastolic
- App `type` enum → DB `kindCode` (string mapping)
- App `timestamp` → DB `recordedAt`

**Required APIs:**

- `GET /api/vitals` - List (with filters)
- `POST /api/vitals` - Add measurement
- `GET /api/vitals/:id` - Get details
- `PUT /api/vitals/:id` - Update
- `DELETE /api/vitals/:id` - Delete
- `GET /api/vitals/latest` - Latest per kind (use view)
- `GET /api/vitals/trends` - 7-day trends (use view)
- `GET /api/vitals/abnormal` - Abnormal readings

#### 3. Caregivers Module

**App Model:** `id`, `name`, `phone`, `status`, `relationship`, `linkedPatientId`, `invitedAt`, `acceptedAt`

**Database:** `elder_assignments` + `user_invitations` tables

**Key Mappings:**

- App combines invitations + assignments
- Need to join `user_invitations` → `elder_assignments` on acceptance
- App `name` → Get from `users` via `caregiverUserId`

**Required APIs:**

- `GET /api/caregivers` - List assignments
- `POST /api/caregivers/invitations` - Send invitation
- `GET /api/caregivers/invitations` - List pending
- `POST /api/caregivers/invitations/:id/accept` - Accept
- `POST /api/caregivers/invitations/:id/decline` - Decline
- `DELETE /api/caregivers/:id` - Remove assignment
- `GET /api/caregivers/invitations/:code` - Get by code

#### 4. Lifestyle Module

**App Models:**

- Diet: `id`, `mealType` (enum), `description`, `calories`, `timestamp`, `userId`
- Exercise: `id`, `activityType` (enum), `description`, `durationMinutes`, `caloriesBurned`, `timestamp`, `userId`

**Database:** `diet_logs` + `exercise_logs`

**Key Mappings:**

- App `description` → DB `food_items` (diet) / missing in exercise_logs
- App `timestamp` → DB `log_date` (date only)
- App enums → DB string fields

**Gap:** `exercise_logs` missing `description` field

**Required APIs:**

- `GET /api/lifestyle/diet` - List diet logs
- `POST /api/lifestyle/diet` - Add diet log
- `DELETE /api/lifestyle/diet/:id` - Delete
- `GET /api/lifestyle/exercise` - List exercise logs
- `POST /api/lifestyle/exercise` - Add exercise log
- `DELETE /api/lifestyle/exercise/:id` - Delete
- `GET /api/lifestyle/summary` - Daily summary
- `GET /api/lifestyle/summary/weekly` - Weekly summary

#### 5. Documents Module

**App Model:** `id`, `title`, `type` (enum), `filePath`, `uploadDate`, `visibility` (enum), `description`, `userId`

**Database:** `user_documents` - Mostly aligned

**Required APIs:**

- `GET /api/documents` - List (with type filter)
- `POST /api/documents` - Upload (multipart)
- `GET /api/documents/:id` - Get details
- `GET /api/documents/:id/file` - Download
- `PUT /api/documents/:id` - Update metadata
- `DELETE /api/documents/:id` - Delete
- `PUT /api/documents/:id/visibility` - Update visibility

#### 6. Notifications Module

**App Model:** `id`, `title`, `body`, `type` (enum), `timestamp`, `isRead`, `actionData` (JSON)

**Database:** `notifications`

**Gap:** Missing `actionData` JSON field

**Required APIs:**

- `GET /api/notifications` - List (read/unread filter)
- `GET /api/notifications/unread` - Unread only
- `GET /api/notifications/unread/count` - Unread count
- `POST /api/notifications/:id/read` - Mark read
- `POST /api/notifications/read-all` - Mark all read
- `DELETE /api/notifications/:id` - Delete

#### 7. Users Module (Update Required)

**App Model:** `id`, `email`, `name`, `role` (enum), `subscriptionTier` (enum), `age`, `medicalConditions`, `emergencyContact`, `phone`

**Database:** `users` + `user_roles` + `subscriptions`

**Gaps:** Missing `medicalConditions`, `emergencyContact` fields

**Required APIs:**

- `GET /api/users/profile` - Get current user
- `PUT /api/users/profile` - Update profile

#### 8. Supporting Modules

- **Lookups:** `GET /api/lookups/:domain` - Enum mappings
- **Devices:** `POST /api/devices` - Register for push
- **Roles:** `GET /api/roles`, `GET /api/users/:id/roles`

### Database Schema Gaps Identified

1. **Missing Columns:**
  - `exercise_logs.description` - App needs description field
  - `notifications.actionData` - App needs JSON field for action data
  - `users.medicalConditions` - App expects this
  - `users.emergencyContact` - App expects this
2. **Enum Mappings Needed:**
  - Medicine forms, frequencies, vital types, meal types, activity types, document types, notification types
  - Create lookup service for enum ↔ DB code mappings
3. **Data Structure Differences:**
  - Medications: reminderTimes array ↔ med_schedules table
  - Vitals: single value string ↔ value1/value2/valueText
  - Caregivers: combined model ↔ separate invitations + assignments

## Implementation Plan

### Phase 1.1: Database Schema Updates

1. **Add missing columns via SQL:**
  ```sql
   ALTER TABLE exercise_logs ADD COLUMN description TEXT;
   ALTER TABLE notifications ADD COLUMN actionData JSONB;
   ALTER TABLE users ADD COLUMN medicalConditions TEXT;
   ALTER TABLE users ADD COLUMN emergencyContact TEXT;
  ```
2. **Update Prisma schema:**
  - Run `npx prisma db pull` to introspect
  - Add missing fields manually
  - Add relationships and indexes
  - Generate client: `npx prisma generate`

### Phase 1.2: Core Modules (Priority 1)

1. **Medications Module** (`src/medications/`)
  - CRUD with schedule management
  - reminderTimes ↔ med_schedules mapping
  - Intake logging
  - Adherence calculations
2. **Health/Vitals Module** (`src/vitals/`)
  - CRUD with type/value mapping
  - Use views for latest/trends
  - Abnormal detection

### Phase 1.3: Caregiver Module (Priority 2)

1. **Caregivers Module** (`src/caregivers/`)
  - Invitation flow
  - Assignment management
  - Join with users for names

### Phase 1.4: Lifestyle Module (Priority 3)

1. **Lifestyle Module** (`src/lifestyle/`)
  - Diet and exercise CRUD
  - Daily/weekly summaries

### Phase 1.5: Documents & Notifications (Priority 4)

1. **Documents Module** (`src/documents/`)
  - File upload (multipart)
  - Storage handling
2. **Notifications Module** (`src/notifications/`)
  - CRUD with read tracking

### Phase 1.6: Supporting Modules (Priority 5)

1. **Lookups Module** (`src/lookups/`) - Enum mappings
2. **Devices Module** (`src/devices/`) - Push registration
3. **Update Existing** - Users, subscriptions, auth

## Technical Decisions

1. **ID Types**: Prisma `BigInt` → string in API responses
2. **Enum Mappings**: Lookup service for app enums ↔ DB codes
3. **File Storage**: Local filesystem (S3-ready structure)
4. **JSON Fields**: Prisma Json type for JSONB
5. **Validation**: class-validator DTOs with enum validation
6. **Swagger**: Document all endpoints with enum types
7. **Error Handling**: Consistent format across modules
8. **Database Views**: Prisma raw queries for views

## File Structure

```
backend/src/
├── medications/
│   ├── medications.controller.ts
│   ├── medications.service.ts
│   ├── medications.module.ts
│   ├── dto/
│   └── mappers/
├── vitals/
├── caregivers/
├── lifestyle/
├── documents/
├── notifications/
├── lookups/
├── roles/
├── devices/
└── common/
    └── mappers/
```

