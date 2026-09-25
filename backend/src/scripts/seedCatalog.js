require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const { db, admin } = require('../config/firebase');

const SERVICES = [
  {
    id: 'service_haircut_styling',
    name: 'Haircut & Styling',
    description: 'Precision scissor cut, hair wash, scalp massage, and custom blow-dry styling.',
    durationMinutes: 30,
    pricePkr: 2500,
  },
  {
    id: 'service_beard_grooming',
    name: 'Beard Grooming & Shape',
    description: 'Hot towel prep, straight razor detailing, beard oil treatment, and shaping.',
    durationMinutes: 30,
    pricePkr: 1500,
  },
  {
    id: 'service_facial_refresh',
    name: 'Express Revitalizing Facial',
    description: 'Deep pore cleansing, botanical exfoliation, mask treatment, and hydration.',
    durationMinutes: 30,
    pricePkr: 3500,
  }
];

const STAFF = [
  {
    id: 'staff_hamza_khan',
    name: 'Hamza Khan',
    role: 'Master Stylist & Barber',
    avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    active: true
  },
  {
    id: 'staff_ayesha_malik',
    name: 'Ayesha Malik',
    role: 'Senior Hair & Skin Specialist',
    avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
    active: true
  }
];

/**
 * Generate 30-minute slots for the next 14 calendar days (today + 13 days)
 * Timezone: Asia/Karachi (UTC+5)
 * Hours: 10:00 to 18:00 (10:00 AM to 6:00 PM), Sunday closed. Last slot starts at 17:30.
 */
function generateSlotsForStaff(staffList, daysCount = 14) {
  const slots = [];
  const now = new Date();
  
  // Asia/Karachi is UTC+5 (300 minutes ahead of UTC)
  const PKT_OFFSET_MS = 5 * 60 * 60 * 1000;

  for (let d = 0; d < daysCount; d++) {
    // Current target day in UTC
    const targetDateUtc = new Date(now.getTime() + d * 24 * 60 * 60 * 1000);
    // Convert to Asia/Karachi date components
    const targetPkt = new Date(targetDateUtc.getTime() + PKT_OFFSET_MS);
    
    const year = targetPkt.getUTCFullYear();
    const month = targetPkt.getUTCMonth(); // 0-indexed
    const day = targetPkt.getUTCDate();
    const dayOfWeek = targetPkt.getUTCDay(); // 0 = Sunday, 1 = Monday, ..., 6 = Saturday

    // Sunday (0) is closed
    if (dayOfWeek === 0) {
      continue;
    }

    // Slots from 10:00 to 17:30 (last slot ends at 18:00)
    for (let hour = 10; hour < 18; hour++) {
      for (const minute of [0, 30]) {
        // Last slot starts at 17:30
        if (hour === 17 && minute > 30) continue;

        // Construct UTC ISO timestamp corresponding to this PKT time
        // PKT time: YYYY-MM-DD HH:MM:00 -> UTC is PKT minus 5 hours
        const slotStartUtc = new Date(Date.UTC(year, month, day, hour - 5, minute, 0));
        const slotEndUtc = new Date(slotStartUtc.getTime() + 30 * 60 * 1000);

        // Exclude slots that have already started
        if (slotStartUtc <= now) {
          continue;
        }

        const isoString = slotStartUtc.toISOString();

        for (const staff of staffList) {
          // Canonical ID format: ${staffId}_${startAtIso}
          const slotId = `${staff.id}_${isoString}`;

          slots.push({
            id: slotId,
            staffId: staff.id,
            staffName: staff.name,
            startAt: slotStartUtc,
            endAt: slotEndUtc,
            isReserved: false,
            bookingRef: null,
            reservedByUid: null,
          });
        }
      }
    }
  }

  return slots;
}

async function seed() {
  console.log('--- Starting Firestore Catalog & Slots Seeding ---');

  // 1. Seed Services
  const servicesBatch = db.batch();
  for (const s of SERVICES) {
    const docRef = db.collection('services').doc(s.id);
    servicesBatch.set(docRef, {
      ...s,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }
  await servicesBatch.commit();
  console.log(`✓ Seeded ${SERVICES.length} services.`);

  // 2. Seed Staff (and cleanup previous)
  await db.collection('staff').doc('staff_alex_carter').delete().catch(() => {});
  await db.collection('staff').doc('staff_maya_lin').delete().catch(() => {});

  const staffBatch = db.batch();
  for (const st of STAFF) {
    const docRef = db.collection('staff').doc(st.id);
    staffBatch.set(docRef, {
      ...st,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }
  await staffBatch.commit();
  console.log(`✓ Seeded ${STAFF.length} staff members (${STAFF.map(s => s.name).join(', ')}).`);

  // 3. Seed Slots
  const slots = generateSlotsForStaff(STAFF, 14);
  console.log(`Generated ${slots.length} upcoming slots across 14 days (Sunday excluded).`);

  // Commit in chunks of 450 (Firestore limit is 500 per batch)
  const chunkSize = 450;
  for (let i = 0; i < slots.length; i += chunkSize) {
    const chunk = slots.slice(i, i + chunkSize);
    const batch = db.batch();
    for (const slot of chunk) {
      const docRef = db.collection('slots').doc(slot.id);
      batch.set(docRef, {
        staffId: slot.staffId,
        staffName: slot.staffName,
        startAt: slot.startAt,
        endAt: slot.endAt,
        isReserved: false,
        bookingRef: null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true }); // merge: true preserves any existing reservation
    }
    await batch.commit();
    console.log(`  Committed batch ${Math.floor(i / chunkSize) + 1}/${Math.ceil(slots.length / chunkSize)}`);
  }

  console.log('✓ Slot seeding completed successfully!');
  process.exit(0);
}

if (require.main === module) {
  seed().catch((err) => {
    console.error('Seeding failed:', err);
    process.exit(1);
  });
}

module.exports = {
  SERVICES,
  STAFF,
  generateSlotsForStaff
};
