# Salon Appointment Booking Backend

A lightweight Node.js & Express backend providing:
1. **Brevo Transactional Email Integration:** Sends secure 6-digit OTP codes for user password reset.
2. **Atomic Booking & Cancellation API:** Backstop for atomic slot concurrency checking and idempotency.
3. **Firestore Seeding Script:** Automatically seeds 3 services, 2 staff members, and 14-day 30-minute slots honoring `Asia/Karachi` business hours (10:00 - 18:00, Sundays closed).

---

## Getting Started

### 1. Prerequisites
- Node.js (v18+)
- npm or yarn

### 2. Environment Setup
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Fill in your credentials:
```env
PORT=5000
BREVO_API_KEY=xkeysib-...
BREVO_SENDER_EMAIL=your-verified-email@example.com
BREVO_SENDER_NAME="Salon Appointment Booking"
FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json
```

### 3. Install Dependencies
```bash
npm install
```

### 4. Seed Services, Staff & Slots
Run the automated seed script to populate Firestore:
```bash
npm run seed
```

### 5. Start Server
```bash
npm start
# or development with auto-reload:
npm run dev
```

---

## API Endpoints

### Auth / OTP Endpoints
- `POST /api/auth/send-otp` — `{ email: string }`
- `POST /api/auth/verify-otp` — `{ email: string, otp: string }`
- `POST /api/auth/reset-password` — `{ email: string, resetToken: string, newPassword: string }`

### Bookings & Availability Endpoints
- `GET /api/bookings/slots` — Public availability (Zero customer PII)
- `POST /api/bookings/reserve` — Atomic slot reservation with conflict detection
- `POST /api/bookings/cancel` — Atomic cancellation with ownership validation
