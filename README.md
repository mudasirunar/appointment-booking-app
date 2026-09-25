# Salon Appointment Booking App

A mobile appointment booking application built with Flutter, Firebase Cloud Firestore, Firebase Authentication, and a Node.js companion service deployed live on Vercel with Brevo (Sendinblue) transactional email integration. The application enables salon clients to explore catalog services, select a preferred staff member and date, reserve 30-minute time slots in real time, and manage their appointments with race-condition prevention, idempotent retries, and atomic cancellation workflows.

---

## Table of Contents
- [1. Overview & Architecture](#1-overview--architecture)
- [2. Project Setup & Getting Started](#2-project-setup--getting-started)
- [3. Packages & Tech Stack](#3-packages--tech-stack)
- [4. Data Model & Schemas](#4-data-model--schemas)
- [5. Timezone Architecture (Asia/Karachi PKT UTC+5)](#5-timezone-architecture-asiakarachi-pkt-utc5)
- [6. Concurrency, Atomicity & Idempotency](#6-concurrency-atomicity--idempotency)
- [7. Firestore Security Rules & Access Control](#7-firestore-security-rules--access-control)
- [8. Application Flow & Screen Hubs](#8-application-flow--screen-hubs)
- [9. The 5 Mandatory UI States](#9-the-5-mandatory-ui-states)
- [10. Database Seeding Instructions](#10-database-seeding-instructions)
- [11. Test Evidence & Validation](#11-test-evidence--validation)
- [12. Known Limitations](#12-known-limitations)
- [13. AI Assistance Disclosure](#13-ai-assistance-disclosure)

---

## 1. Overview & Architecture

The solution implements a layered Clean Architecture separating presentation, business logic, domain models, and data services.

```
appointment-booking-app/
├── appointment_booking_app/         # Flutter Mobile Client (Android & iOS)
│   ├── android/                     # Android build configuration & adaptive icons
│   ├── ios/                         # iOS build configuration & app icon sets
│   ├── lib/
│   │   ├── core/                    # Constants, business rules, theme engine, shared widgets
│   │   │   ├── theme/               # AppTheme, color tokens, light/dark palettes
│   │   │   ├── utils/               # TimezoneUtil (Asia/Karachi UTC+5), validators
│   │   │   └── widgets/             # FloatingGlassNavBar, CustomButton, AppSnackBar, etc.
│   │   ├── models/                  # ServiceModel, StaffModel, SlotModel, BookingModel
│   │   ├── providers/               # AuthProvider, AvailabilityProvider, BookingProvider, ThemeProvider
│   │   ├── services/                # AuthService, BookingService, BackendApiService
│   │   ├── views/                   # Presentation Layer
│   │   │   ├── auth/                # LoginScreen, SignUpScreen, ForgotPasswordScreen, AuthGate
│   │   │   ├── catalog/             # ServicesScreen, StaffAvailabilityScreen
│   │   │   ├── booking/             # BookingReviewScreen, BookingSuccessScreen, MyBookingsScreen
│   │   │   ├── profile/             # ProfileScreen (Bento stats, Edit Name, Theme Switcher)
│   │   │   └── navigation/          # MainNavigationShell (IndexedStack + FloatingGlassNavBar)
│   │   └── main.dart                # App entrypoint with multi-provider setup
│   ├── test/                        # Automated unit & domain tests (widget_test.dart)
│   └── pubspec.yaml
├── backend/                         # Node.js Companion Backend Service
│   ├── src/
│   │   ├── config/                  # Firebase Admin SDK & Brevo API client configurations
│   │   ├── controllers/             # Auth/OTP & Catalog controllers
│   │   ├── routes/                  # Express API routes (/api/auth)
│   │   ├── scripts/                 # seedCatalog.js (Firestore database seeder)
│   │   └── server.js                # Express app entrypoint
│   ├── package.json
│   ├── vercel.json                  # Serverless deployment configuration
│   └── .env.example
├── docs/                            # Engineering documentation
│   ├── PRD.md                       # Product Requirements Document
│   ├── ARCHITECTURE.md              # System Architecture & Database Design
│   ├── DESIGN.md                    # Visual Guidelines & Design Tokens
│   ├── AGENTS.md                    # Code Standards & Safety Constraints
│   └── TASK_TRACKER.md              # Milestone tracking & phase breakdown
├── firestore.rules                  # Production Firestore Security Rules
└── README.md
```

### Live Deployments
- **Backend Service:** `https://appointment-booking-app-backend-seven.vercel.app`
- **Health Check Endpoint:** `GET https://appointment-booking-app-backend-seven.vercel.app/api/health`

---

## 2. Project Setup & Getting Started

### Prerequisites
- **Flutter SDK:** Version 3.19+ (`flutter --version`)
- **Dart SDK:** Version 3.3+
- **Node.js:** Version 18+ and npm
- **Firebase Project:** Cloud Firestore and Firebase Authentication enabled

### A. Companion Backend Setup (Node.js & Brevo OTP)
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
   Add your Firebase credentials and Brevo API key:
   ```env
   PORT=5000
   FIREBASE_PROJECT_ID=appointment-booking-app-968b5
   FIREBASE_CLIENT_EMAIL=firebase-adminsdk-...@...iam.gserviceaccount.com
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
   BREVO_API_KEY=xkeysib-...
   BREVO_SENDER_EMAIL=your-verified-sender@domain.com
   BREVO_SENDER_NAME="Salon Appointments"
   ```
4. Run the catalog seed script to populate Firestore:
   ```bash
   npm run seed
   ```
5. Start local backend server (optional if using live Vercel backend):
   ```bash
   npm run dev
   # Runs on http://localhost:5000
   ```

### B. Mobile Application Setup (Flutter)
1. Navigate to the mobile app directory:
   ```bash
   cd appointment_booking_app
   ```
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Run static analysis to verify code health:
   ```bash
   flutter analyze
   ```
4. Execute automated tests:
   ```bash
   flutter test
   ```
5. Launch the application on a connected device or simulator:
   ```bash
   flutter run
   ```

---

## 3. Packages & Tech Stack

### Flutter Client
- **`provider` (`^6.1.2`):** Declarative reactive state management separating business logic from UI.
- **`firebase_core` & `firebase_auth` (`^3.1.0` / `^5.1.1`):** Authentication with email/password and session state.
- **`cloud_firestore` (`^5.0.1`):** Real-time database streams and atomic transaction execution.
- **`shared_preferences` (`^2.3.2`):** Local persistence for user theme preference (`ThemeMode.system`, `light`, `dark`).
- **`intl` (`^0.19.0`):** Date formatting, calendar math, and currency formatting.
- **`http` (`^1.2.1`):** REST communication with the Brevo OTP backend.
- **`uuid` (`^4.4.0`):** Client-side unique ID generation for idempotent booking submissions.
- **`google_fonts` (`^6.2.1`):** Typography utilizing Google's Inter font.
- **`cupertino_icons` (`^1.0.8`):** Clean iconography.

### Backend Companion
- **`express` (`^4.19.2`):** Fast, minimalist Node.js web server.
- **`firebase-admin` (`^12.1.0`):** Privileged administrative database access for seeding and secure password reset.
- **`@getbrevo/brevo` (`^2.0.0`):** Official Brevo (formerly Sendinblue) transactional email API.
- **`cors` & `dotenv`:** Middleware and configuration.

---

## 4. Data Model & Schemas

### `services/{serviceId}`
Public read-only catalog defining salon offerings.
- `id` (string): Unique identifier (e.g., `service_haircut_styling`).
- `name` (string): Service title.
- `description` (string): Detailed explanation.
- `durationMinutes` (number): Fixed duration (30 minutes across all services).
- `pricePkr` (number): Price in Pakistani Rupees (PKR).
- `imageUrl` (string): High-resolution curated imagery.
- `createdAt` (timestamp): Server timestamp.

### `staff/{staffId}`
Public read-only staff catalog.
- `id` (string): Unique identifier (e.g., `staff_hamza_khan`, `staff_ayesha_malik`).
- `name` (string): Stylist full name.
- `role` (string): Specialty / title.
- `avatarUrl` (string): Stylist profile picture URL.
- `active` (boolean): Availability flag.

### `slots/{slotId}`
Real-time availability slot tracking. **Strictly contains ZERO customer PII** (no names, emails, or phone numbers).
- **Canonical Deterministic ID:** `${staffId}_${startAtIsoUtc}` (e.g., `staff_hamza_khan_2026-09-26T05:00:00.000Z`).
- `staffId` (string): Reference to assigned staff member.
- `staffName` (string): Staff display name snapshot.
- `startAt` (timestamp): Slot start UTC timestamp.
- `endAt` (timestamp): Slot end UTC timestamp (`startAt` + 30 minutes).
- `isReserved` (boolean): Active reservation flag.
- `bookingRef` (string | null): Active booking reference ID or null if unreserved.
- `updatedAt` (timestamp): Last modification timestamp.

### `users/{userId}/bookings/{bookingId}`
Private user booking documents isolated strictly under each client's UID.
- `bookingId` (string): Unique client-generated reference (e.g., `BK-847291`).
- `slotId` (string): Canonical slot ID.
- `serviceId` (string): Booked service ID.
- `serviceName` (string): Service name snapshot at time of booking.
- `servicePricePkr` (number): Price snapshot in PKR.
- `staffId` (string): Stylist ID.
- `staffName` (string): Stylist name snapshot.
- `startAt` (timestamp): UTC appointment start time.
- `endAt` (timestamp): UTC appointment end time.
- `status` (string): `'upcoming'` | `'past'` | `'cancelled'`.
- `clientNotes` (string): Optional client special instructions.
- `createdAt` (timestamp): Booking creation timestamp.
- `cancelledAt` (timestamp | null): Cancellation timestamp if cancelled.

---

## 5. Timezone Architecture (`Asia/Karachi` PKT UTC+5)

The salon operates exclusively within the **`Asia/Karachi` (PKT, UTC+5)** business timezone.
1. **UTC Storage Standard:** All timestamps stored in Firestore use UTC `Timestamp` values.
2. **Business Operating Window:**
   - Operating days: Monday through Saturday.
   - Operating hours: 10:00 to 18:00 PKT (10:00 AM to 6:00 PM PKT).
   - Sunday is strictly closed (zero slots generated; friendly empty state displayed).
   - Fixed slot duration: Exactly 30 minutes.
   - Last slot of the day: 17:30 PKT (concludes at 18:00 PKT).
3. **Cross-Timezone Client Support:**
   - Clients in any physical device timezone compute calendar dates, 14-day booking horizons, and slot intervals according to `Asia/Karachi`.
   - Every appointment date and time displayed in the application is explicitly labeled with `PKT` to eliminate client ambiguity.
4. **Past Slot Filtering:** Slots whose `startAt` is in the past relative to the current UTC time are automatically filtered out from availability grids.

---

## 6. Concurrency, Atomicity & Idempotency

### A. Preventing Double-Booking (Atomic Firestore Transaction)
To prevent race conditions where two clients attempt to book the same slot at the exact same moment:
1. Every time slot uses a canonical deterministic document ID: `${staffId}_${startAtIso}`.
2. Booking execution runs inside a Firestore atomic transaction (`runTransaction`):
   - The transaction reads `slots/{slotId}`.
   - It validates that `isReserved == false` and `startAt > request.time`.
   - If `isReserved == true`, the transaction aborts and throws `BookingConflictException`.
   - If available, it simultaneously updates `slots/{slotId}` (`isReserved: true`, `bookingRef: bookingId`) and writes the private record to `users/{uid}/bookings/{bookingId}`.
3. If two clients tap "Confirm" simultaneously, exactly one commits. The losing client's transaction aborts, triggering the **Conflict Recovery Modal** which prompts them to pick another time while refreshing availability in real time.

### B. Idempotency & Double-Tap Prevention
1. **Debounce Guard:** The submission button enters a disabled state with a progress indicator immediately on the first touch (`_isSubmitting`).
2. **Client-Generated Key:** The client generates a unique `bookingId` (`BK-XXXXXXXX`) when loading the Review screen. If a network timeout occurs during transaction execution, retrying with the same `bookingId` is idempotent: the transaction verifies the record and returns the existing booking without double-reserving or failing.

### C. Atomic Cancellation & Slot Release
1. Clients can cancel upcoming appointments strictly before `startAt` has elapsed.
2. The cancellation runs inside a Firestore atomic transaction:
   - Validates that `booking.startAt > DateTime.now()`.
   - Verifies that `slots/{slotId}.bookingRef == bookingId` to guarantee the slot still belongs to this specific appointment.
   - Updates `users/{uid}/bookings/{bookingId}.status` to `'cancelled'` with `cancelledAt`.
   - Atomically releases the slot (`isReserved: false`, `bookingRef: null`).
3. Replaying an old cancellation will never release a newly created reservation for the same slot.

---

## 7. Firestore Security Rules & Access Control

Security rules in `firestore.rules` enforce strict data isolation and schema validation at the database layer:
1. **Catalog Collections (`services`, `staff`):**
   - Public read-only (`allow read: if true;`).
   - Client writes, edits, and deletions are unconditionally rejected (`allow write: if false;`).
2. **Availability Slots (`slots`):**
   - Public read allowed.
   - Creation and deletion restricted to Admin SDK (`allow create, delete: if false;`).
   - Updates restricted to authenticated users performing valid slot reservations or cancellations.
   - **Zero Customer PII:** Writes containing `customerName`, `email`, or `phoneNumber` are unconditionally denied.
   - **Past-Slot Rejection:** Prevents reservations where `startAt <= request.time`.
3. **Private Bookings (`users/{userId}/bookings/{bookingId}`):**
   - Reads and writes permitted **only** if `request.auth.uid == userId`.
   - Deletions are disabled (`allow delete: if false;`) to preserve historical audit records.
   - Transitions permitted only from `'upcoming'` to `'cancelled'` before appointment start.
4. **OTP Verifications (`otp_verifications`):**
   - Client access completely denied (`allow read, write: if false;`). Accessible exclusively by the Node.js backend using the Firebase Admin SDK.

---

## 8. Application Flow & Screen Hubs

### 1. Main Navigation Shell (`MainNavigationShell`)
- Hosts an `IndexedStack` preserving scroll positions and view state across all 3 primary hubs.
- Overlayed with the **Floating Glass Navigation Bar (`FloatingGlassNavBar`)**:
  - 20px blur glassmorphism with subtle hairline border.
  - Interactive sliding pill indicator highlighting the active tab in Warm Gold (`#C49A58`).
  - Swiping and drag gesture recognition with tactile haptic feedback.
  - Live upcoming appointments badge on the Bookings tab.

### 2. Services Catalog Screen (`ServicesScreen`)
- Full edge-to-edge layout with content scrolling behind the top status bar.
- Dynamic greeting based on PKT local time and user's display name.
- Live salon operating status pill ("Open Today until 6:00 PM PKT" or "Closed Today (Sunday)").
- 3 curated salon services with PKR pricing, 30-minute duration tag, and smooth hero image transitions.

### 3. Staff & Availability Screen (`StaffAvailabilityScreen`)
- Stylist selector cards (Hamza Khan & Ayesha Malik) with active badges.
- Horizontal 14-day calendar selector (today + 13 days) aligned to `Asia/Karachi`.
- Sunday closed empty state informing clients of operating hours.
- 10:00 - 18:00 PKT slots grid with real-time Firestore stream updates.
- Past slots automatically disabled or hidden.

### 4. Booking Review Screen (`BookingReviewScreen`)
- Detailed summary: service card, stylist profile, appointment interval in PKT, client name & email.
- Optional special instructions / client notes input.
- Salon policy callout (30-min duration, cancellation policy).
- Docked primary action button with double-tap prevention debounce.

### 5. Booking Success Screen (`BookingSuccessScreen`)
- Animated green checkmark badge with smooth scale & fade.
- Reference ID pill with tap-to-copy action: animated switch to checkmark with `HapticFeedback.mediumImpact()`, auto-reverting after 2 seconds.
- Dual quick actions: *"View in My Bookings"* (switches to Bookings tab) and *"Back to Salon Services"* (returns to catalog).

### 6. My Bookings Screen (`MyBookingsScreen`)
- 3 segmented tabs:
  - **Upcoming:** Chronologically sorted (soonest first) with real-time active status tag.
  - **Past:** Completed appointments sorted by start time descending.
  - **Cancelled:** Cancelled appointments sorted by `cancelledAt` descending.
- Animated copy-to-clipboard pill with haptic feedback on booking reference IDs.
- Empty states with curated icons and a **centered CTA button** (*"Book an Appointment"*) that switches to the catalog.
- Atomic cancellation modal with confirmation prompt and instant slot release.

### 7. Profile & Account Hub (`ProfileScreen`)
- User identity card with initials avatar and email display.
- Inline **Edit Display Name** modal syncing immediately with Firebase Auth.
- **Bento Statistics Grid**:
  - Total Bookings count.
  - Active Appointments count.
  - Total Salon Investment in PKR.
- **Fluid Theme Switcher Pill** (System | Light | Dark):
  - Defaults strictly to device system theme.
  - Persists preference locally via `SharedPreferences`.
  - Dynamically updates app brightness and synchronizes system status bar icons.
- Styled **Sign Out** confirmation dialog with listener cleanup.

---

## 9. The 5 Mandatory UI States

| UI State | Implementation | Location |
| :--- | :--- | :--- |
| **1. Loading** | Shimmer skeletons for services, slot grid shimmer, and disabled button spinners during network transactions. | `ServicesScreen`, `StaffAvailabilityScreen`, `BookingReviewScreen` |
| **2. Empty** | • Sunday closed illustration & message.<br>• Fully booked slot notification.<br>• Empty bookings tab with centered *"Book an Appointment"* CTA button. | `StaffAvailabilityScreen`, `MyBookingsScreen` |
| **3. Error** | Floating `AppSnackBar` alerts, network error view with retry button, and inline form validation. | `AppSnackBar`, `AppErrorView`, `AuthService` |
| **4. Success** | Animated checkmark badge, reference ID copy pill with haptics, and password reset success modal. | `BookingSuccessScreen`, `ForgotPasswordScreen` |
| **5. Conflict** | Slot conflict bottom sheet informing user that the slot was claimed by another client, with immediate return to refreshed slot grid. | `BookingReviewScreen` (`BookingConflictException`) |

---

## 10. Database Seeding Instructions

The backend service includes an automated Firestore catalog and slot seeding script:

```bash
cd backend
npm run seed
```

This script:
1. Populates 3 predefined salon services (Haircut & Styling, Beard Grooming & Shape, Express Revitalizing Facial) at 30 minutes duration.
2. Populates 2 salon stylists (Hamza Khan, Ayesha Malik).
3. Generates 30-minute availability slots across the next 14 calendar days (today through next 13 days) between 10:00 and 18:00 PKT (excluding Sundays and past slots).

---

## 11. Test Evidence & Validation

Automated unit and domain tests are located in `appointment_booking_app/test/widget_test.dart`.

```bash
cd appointment_booking_app
flutter test
```

### Test Results
```
00:00 +0: Timezone & Domain Tests (Asia/Karachi PKT UTC+5) 14 calendar days generation returns exactly 14 dates
00:00 +1: Timezone & Domain Tests (Asia/Karachi PKT UTC+5) Sunday detection works accurately
00:00 +2: Timezone & Domain Tests (Asia/Karachi PKT UTC+5) ServiceModel serialization and formatting
00:00 +3: Timezone & Domain Tests (Asia/Karachi PKT UTC+5) SlotModel formatting and past status
00:00 +4: Timezone & Domain Tests (Asia/Karachi PKT UTC+5) BookingModel serialization and formatted values
00:00 +5: Timezone & Domain Tests (Asia/Karachi PKT UTC+5) BookingConflictException and PastSlotException have descriptive messages
00:00 +6: Timezone & Domain Tests (Asia/Karachi PKT UTC+5) ThemeProvider initializes with ThemeMode.system and updates mode
00:00 +7: All tests passed!
```

### Static Analysis
```bash
flutter analyze
# Analyzing appointment_booking_app...
# No issues found! (ran in 1.8s)
```

---

## 12. Known Limitations

1. **Admin Management:** Catalog services and staff members are managed via seed scripts and Firebase Admin SDK; no customer-facing admin panel is included.
2. **Rescheduling:** Rescheduling is handled by cancelling the existing appointment and booking a new slot.
3. **Payments:** Payment processing is out of scope; prices in PKR are recorded as snapshots on booking records.

---

## 13. AI Assistance Disclosure

In accordance with project requirements, AI tooling (Google DeepMind Antigravity) was utilized to assist with documentation drafting, architectural modeling, code structure organization, and static analysis verification. All business rules, transactions, and security policies were reviewed and validated against assignment specifications.
