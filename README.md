# Salon Appointment Booking App

A mobile appointment booking application built with Flutter, Firebase, and a Node.js companion service. The application enables salon clients to explore catalog services, select a preferred staff member and date, reserve 30-minute time slots in real time, and manage their appointments with race-condition prevention and cancellation workflows.

---

## Table of Contents
- [1. Overview & Architecture](#1-overview--architecture)
- [2. Project Setup & Getting Started](#2-project-setup--getting-started)
- [3. Packages & Tech Stack](#3-packages--tech-stack)
- [4. Data Model](#4-data-model)
- [5. Timezone Approach (Asia/Karachi)](#5-timezone-approach-asiakarachi)
- [6. Concurrency, Atomicity & Idempotency](#6-concurrency-atomicity--idempotency)
- [7. Firestore Security Rules & Access Control](#7-firestore-security-rules--access-control)
- [8. Database Seeding Instructions](#8-database-seeding-instructions)
- [9. Test Evidence & Validation](#9-test-evidence--validation)
- [10. Known Limitations](#10-known-limitations)
- [11. AI Assistance Disclosure](#11-ai-assistance-disclosure)

---

## 1. Overview & Architecture

The solution consists of two primary components:
1. **Mobile Application (`appointment_booking_app/`):** Built with Flutter, supporting Android and iOS. Implements clean architecture, Provider state management, and real-time Firestore listeners.
2. **Companion Backend Service (`backend/`):** Built with Node.js and Express. Provides transactional email integration via Brevo for 6-digit OTP password reset and administrative database seeding.

```
appointment-booking-app/
├── appointment_booking_app/         # Flutter Mobile App (Android & iOS)
│   ├── android/
│   ├── ios/
│   ├── lib/
│   │   ├── core/                   # Constants, business rules, theme, utils
│   │   ├── models/                  # Service, Staff, Slot, Booking data models
│   │   ├── providers/               # State management (Auth, Availability, Booking)
│   │   ├── services/                # Firebase, Backend API, Timezone service
│   │   ├── views/                   # Auth, Catalog, Availability, Review, Bookings
│   │   └── main.dart
│   └── pubspec.yaml
├── backend/                         # Node.js Companion Backend
│   ├── src/
│   │   ├── config/                  # Firebase Admin & Brevo configurations
│   │   ├── controllers/             # Auth/OTP & Booking controllers
│   │   ├── routes/                  # Express routes
│   │   ├── scripts/                 # Firestore seed script (services, staff, slots)
│   │   └── server.js
│   ├── package.json
│   └── .env.example
├── firestore.rules                  # Firestore security rules
└── README.md
```

---

## 2. Project Setup & Getting Started

### Prerequisites
- **Flutter SDK:** Version 3.13+ (`flutter --version`)
- **Dart SDK:** Version 3.0+
- **Node.js:** Version 18+ and npm
- **Firebase Project:** Cloud Firestore and Firebase Authentication enabled

### A. Companion Backend Setup
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Configure environment variables:
   ```bash
   cp .env.example .env
   ```
   Add your Brevo API key, sender details, and Firebase service account path to `.env`.
4. Run the catalog seed script to populate Firestore:
   ```bash
   npm run seed
   ```
5. Start the backend server:
   ```bash
   npm run dev
   # Server runs on http://localhost:5000
   ```

### B. Mobile App Setup
1. Navigate to the Flutter app directory:
   ```bash
   cd appointment_booking_app
   ```
2. Install Flutter packages:
   ```bash
   flutter pub get
   ```
3. Run the application on your connected Android or iOS device / emulator:
   ```bash
   flutter run
   ```

---

## 3. Packages & Tech Stack

### Flutter Client
- **`provider`:** Declarative state management separating business logic from UI.
- **`intl`:** Date formatting, currency rendering, and calendar manipulation.
- **`http`:** REST client for communication with the Brevo OTP backend.
- **`uuid`:** Client-side unique ID generation for idempotent booking submissions.
- **`google_fonts`:** Typography utilizing Inter for a clean aesthetic.
- **`cupertino_icons`:** Standard iOS-style icon assets.

### Backend Companion
- **`express`:** Fast, unopinionated web framework for Node.js.
- **`firebase-admin`:** Privileged administrative access for data seeding and password updates.
- **`@getbrevo/brevo`:** Official Brevo (Sendinblue) transactional email API client.
- **`cors`:** Cross-Origin Resource Sharing middleware.
- **`dotenv`:** Environment variable configuration.

---

## 4. Data Model

### `services/{serviceId}`
Public read-only service catalog.
- `id` (string): Unique identifier (e.g., `service_haircut_styling`).
- `name` (string): Display name.
- `description` (string): Service description.
- `durationMinutes` (number): Fixed duration (30 minutes).
- `pricePkr` (number): Price in PKR.
- `createdAt` (timestamp): Server timestamp.

### `staff/{staffId}`
Public read-only staff catalog.
- `id` (string): Unique identifier (e.g., `staff_alex_carter`).
- `name` (string): Full name.
- `role` (string): Staff title / specialty.
- `avatarUrl` (string): Profile image URL.
- `active` (boolean): Availability toggle.

### `slots/{slotId}`
Public real-time availability tracking. **Contains zero customer PII** (no names, emails, or phone numbers).
- **Canonical ID:** `${staffId}_${startAtUtcIso}` (e.g. `staff_alex_2026-09-26T05:00:00.000Z`).
- `staffId` (string): Reference to staff member.
- `staffName` (string): Staff display name snapshot.
- `startAt` (timestamp): UTC start timestamp.
- `endAt` (timestamp): UTC end timestamp (startAt + 30 mins).
- `isReserved` (boolean): Flag indicating slot reservation state.
- `bookingRef` (string | null): Active booking reference ID or null if available.
- `updatedAt` (timestamp): Last modified timestamp.

### `users/{userId}/bookings/{bookingId}`
Private user booking documents isolated under each user's UID.
- `bookingId` (string): Unique booking reference (e.g., `BK-918273`).
- `slotId` (string): Canonical slot ID.
- `serviceId` (string): Service identifier.
- `serviceName` (string): Service name snapshot at time of booking.
- `servicePricePkr` (number): Price snapshot in PKR.
- `staffId` (string): Assigned staff ID.
- `staffName` (string): Assigned staff name.
- `startAt` (timestamp): UTC appointment start time.
- `endAt` (timestamp): UTC appointment end time.
- `status` (string): `'upcoming'` | `'past'` | `'cancelled'`.
- `createdAt` (timestamp): Creation timestamp.
- `cancelledAt` (timestamp | null): Cancellation timestamp.

---

## 5. Timezone Approach (`Asia/Karachi`)

The salon operates exclusively within the **`Asia/Karachi` (PKT, UTC+5)** business timezone.
- **Storage Standard:** All timestamps in Firestore are stored as UTC `Timestamp` values.
- **Business Hours Enforcement:**
  - Operating days: Monday through Saturday.
  - Sunday is closed (no slots are generated or displayed).
  - Operating hours: 10:00 to 18:00 PKT.
  - Last slot start time: 17:30 PKT (concludes at 18:00 PKT).
- **Cross-Timezone Client Support:**
  - Clients located in different timezones compute calendar dates and slot windows aligned to `Asia/Karachi`.
  - Every appointment time displayed in the application is explicitly annotated with the timezone tag (`PKT`) to avoid ambiguity.
- **Past Slot Filtering:** Slots whose `startAt` is less than or equal to current UTC time are automatically filtered out from availability.

---

## 6. Concurrency, Atomicity & Idempotency

### A. Preventing Double-Booking (Atomic Slot Reservation)
To ensure two users cannot book the same slot simultaneously:
1. Every time slot uses a canonical deterministic document ID: `${staffId}_${startAtIso}`.
2. Slot reservations execute inside a **Firestore Transaction**:
   - The transaction reads the target document in `slots/{slotId}`.
   - It verifies that `isReserved == false` and `startAt > request.time`.
   - If already reserved, the transaction aborts with a conflict error (`409 Conflict`).
   - If available, the transaction marks `slots/{slotId}.isReserved = true` with `bookingRef = bookingId`, and creates the private record in `users/{uid}/bookings/{bookingId}` atomically.
3. If two clients confirm simultaneously, exactly one commits. The second transaction re-reads the updated slot, detects `isReserved == true`, and prompts the user with a conflict alert while refreshing availability.

### B. Idempotent Retry & Double-Tap Prevention
1. **Immediate Debounce:** The "Confirm Booking" action button enters a disabled loading state immediately upon the first touch.
2. **Client-Generated Key:** The client generates a unique `bookingId` upon reaching the Review screen. If a network interruption occurs during submission, retrying uses the same `bookingId`.
3. The transaction detects if a booking with that ID already exists and returns the confirmed record without duplicate slot reservations.

### C. Atomic Cancellation
1. Users may cancel upcoming appointments strictly before `startAt`.
2. The cancellation transaction:
   - Verifies the appointment is still in the future.
   - Checks that `slots/{slotId}.bookingRef == bookingId` to guarantee the slot still belongs to this specific appointment.
   - Updates `users/{uid}/bookings/{bookingId}.status` to `'cancelled'` with `cancelledAt`.
   - Releases the slot (`isReserved = false`, `bookingRef = null`).
3. Replaying an old cancellation will never release a newly created reservation for the same slot.

---

## 7. Firestore Security Rules & Access Control

Security rules in `firestore.rules` enforce data isolation and integrity at the database layer:
1. **Catalog Collections (`services`, `staff`):** Public read-only; all client writes, edits, and deletions are denied.
2. **Availability Slots (`slots`):**
   - Public read allowed.
   - Client writes are restricted to atomic reservation/cancellation transitions.
   - **Privacy Enforcement:** Writes containing `customerName`, `email`, or `phoneNumber` are unconditionally rejected.
   - **Past-Slot Rejection:** Prevents reservations where `startAt <= request.time`.
3. **Private Bookings (`users/{userId}/bookings/{bookingId}`):**
   - Direct reads and writes are permitted **only** if `request.auth.uid == userId`.
   - Users cannot view, modify, or cancel other users' bookings.
   - Document deletion is disabled (`allow delete: if false;`) to preserve audit trails.

---

## 8. Database Seeding Instructions

The backend repository includes an automated seed script:
```bash
cd backend
npm run seed
```

This script:
1. Populates 3 predefined salon services (Haircut & Styling, Beard Grooming & Shape, Express Revitalizing Facial) at 30 minutes duration.
2. Populates 2 salon staff members (Alex Carter, Maya Lin).
3. Generates 30-minute availability slots across the next 14 calendar days (today through next 13 days) between 10:00 and 18:00 PKT (excluding Sundays and past slots).

---

## 9. Test Evidence & Validation

### 1. Business Hours & Timezone Validation
- Verified Sunday returns zero available slots.
- Verified final slot of each working day starts at 17:30 PKT.
- Verified slots in the past relative to the current UTC timestamp are excluded.
- Verified slots display explicit `PKT` timezone annotations across non-Karachi device locales.

### 2. Concurrency & Race-Condition Validation
- Simulated two simultaneous booking requests targeting the exact same canonical slot ID.
- **Result:** Exactly one transaction committed successfully; the concurrent transaction aborted with `SLOT_ALREADY_RESERVED`. The losing client received a 409 conflict alert and refreshed slots.

### 3. Idempotent Retry Validation
- Repeated network requests using identical `bookingId` parameters resulted in idempotent confirmations without creating duplicate booking records or slot lock failures.

### 4. Cancellation & Slot Release Validation
- Future appointment cancellation verified: slot status reverted to `isReserved: false`, and private booking updated to `status: 'cancelled'`.
- Replaying a cancelled request against a re-booked slot verified the new reservation remained intact due to the `bookingRef` ownership check.
- Attempting to cancel an appointment whose start time had elapsed was rejected.

### 5. Access Control & Privacy Validation
- Querying another user's subcollection (`/users/{otherUid}/bookings`) via Firebase rules testing resulted in `permission-denied`.
- Writing customer PII into public slots was denied by schema validation rules.

---

## 10. Known Limitations

1. **Catalog Management:** Catalog services and staff members are managed via seed scripts and Admin SDK; no customer-facing admin panel is included.
2. **Rescheduling:** Rescheduling is handled by cancelling the existing appointment and booking a new slot.
3. **Payments:** Payment gateway processing is outside the scope of this demonstration application; prices in PKR are recorded as snapshots on booking documents.

---

## 11. AI Assistance Disclosure

In accordance with project requirements, AI tooling (Google DeepMind Antigravity) was utilized to assist with documentation drafting, architectural modeling, code structure organization, and static analysis verification. All business rules, transactions, and security policies were reviewed and validated against assignment specifications.
