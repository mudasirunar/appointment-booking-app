const { db, admin } = require('../config/firebase');

/**
 * POST /api/bookings/reserve
 * Atomic reservation endpoint (also can be run directly via client Firestore transaction)
 * Body: { uid, bookingId, slotId, serviceId, serviceName, servicePricePkr, staffId, staffName, startAt, endAt }
 */
async function reserveSlot(req, res) {
  try {
    const {
      uid,
      bookingId,
      slotId,
      serviceId,
      serviceName,
      servicePricePkr,
      staffId,
      staffName,
      startAt,
      endAt
    } = req.body;

    if (!uid || !bookingId || !slotId || !serviceId || !staffId || !startAt || !endAt) {
      return res.status(400).json({ success: false, message: 'Missing required booking parameters.' });
    }

    const slotRef = db.collection('slots').doc(slotId);
    const userBookingRef = db.collection('users').doc(uid).collection('bookings').doc(bookingId);

    const result = await db.runTransaction(async (transaction) => {
      // 1. Idempotency Check: Did this booking already succeed?
      const existingBookingDoc = await transaction.get(userBookingRef);
      if (existingBookingDoc.exists) {
        return { success: true, booking: existingBookingDoc.data(), idempotent: true };
      }

      // 2. Fetch the target slot
      const slotDoc = await transaction.get(slotRef);
      if (!slotDoc.exists) {
        throw new Error('SLOT_NOT_FOUND');
      }

      const slotData = slotDoc.data();

      // 3. Concurrency check: Is the slot already reserved?
      if (slotData.isReserved) {
        throw new Error('SLOT_ALREADY_RESERVED');
      }

      // 4. Past slot check: Has the appointment start time already passed?
      const slotStartTime = slotData.startAt.toDate ? slotData.startAt.toDate() : new Date(slotData.startAt);
      if (slotStartTime <= new Date()) {
        throw new Error('SLOT_IN_PAST');
      }

      // 5. Reserve slot (Strictly NO customer PII in public slot)
      transaction.update(slotRef, {
        isReserved: true,
        bookingRef: bookingId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // 6. Create private user booking
      const newBooking = {
        bookingId,
        slotId,
        serviceId,
        serviceName,
        servicePricePkr: Number(servicePricePkr),
        staffId,
        staffName,
        startAt: slotData.startAt,
        endAt: slotData.endAt,
        status: 'upcoming',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        cancelledAt: null
      };

      transaction.set(userBookingRef, newBooking);

      return { success: true, booking: newBooking };
    });

    return res.status(201).json(result);
  } catch (error) {
    console.error('[BookingController] reserveSlot error:', error.message);

    if (error.message === 'SLOT_ALREADY_RESERVED') {
      return res.status(409).json({
        success: false,
        code: 'SLOT_ALREADY_RESERVED',
        message: 'This slot was just booked by another client. Please select another time.'
      });
    }

    if (error.message === 'SLOT_IN_PAST') {
      return res.status(400).json({
        success: false,
        code: 'SLOT_IN_PAST',
        message: 'This slot has already passed and cannot be booked.'
      });
    }

    if (error.message === 'SLOT_NOT_FOUND') {
      return res.status(404).json({
        success: false,
        code: 'SLOT_NOT_FOUND',
        message: 'The requested slot does not exist.'
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Failed to complete reservation. Please try again.'
    });
  }
}

/**
 * POST /api/bookings/cancel
 * Atomic cancellation endpoint
 * Body: { uid, bookingId, slotId }
 */
async function cancelBooking(req, res) {
  try {
    const { uid, bookingId, slotId } = req.body;
    if (!uid || !bookingId || !slotId) {
      return res.status(400).json({ success: false, message: 'Missing uid, bookingId, or slotId.' });
    }

    const slotRef = db.collection('slots').doc(slotId);
    const userBookingRef = db.collection('users').doc(uid).collection('bookings').doc(bookingId);

    await db.runTransaction(async (transaction) => {
      const userBookingDoc = await transaction.get(userBookingRef);
      if (!userBookingDoc.exists) {
        throw new Error('BOOKING_NOT_FOUND');
      }

      const bookingData = userBookingDoc.data();
      if (bookingData.status === 'cancelled') {
        return; // Already cancelled, idempotent success
      }

      // Check if start time has passed
      const startAtDate = bookingData.startAt.toDate ? bookingData.startAt.toDate() : new Date(bookingData.startAt);
      if (startAtDate <= new Date()) {
        throw new Error('CANNOT_CANCEL_PAST_APPOINTMENT');
      }

      // Read slot to verify it still belongs to this booking
      const slotDoc = await transaction.get(slotRef);
      if (slotDoc.exists) {
        const slotData = slotDoc.data();
        // ONLY release slot if it is currently tied to this booking
        if (slotData.bookingRef === bookingId) {
          transaction.update(slotRef, {
            isReserved: false,
            bookingRef: null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
      }

      // Update booking status
      transaction.update(userBookingRef, {
        status: 'cancelled',
        cancelledAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    return res.status(200).json({
      success: true,
      message: 'Appointment has been cancelled and slot released.'
    });
  } catch (error) {
    console.error('[BookingController] cancelBooking error:', error.message);

    if (error.message === 'CANNOT_CANCEL_PAST_APPOINTMENT') {
      return res.status(400).json({
        success: false,
        message: 'Appointments that have already started cannot be cancelled.'
      });
    }

    if (error.message === 'BOOKING_NOT_FOUND') {
      return res.status(404).json({
        success: false,
        message: 'Booking not found.'
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Failed to cancel appointment.'
    });
  }
}

/**
 * GET /api/slots
 * Query params: ?staffId=...&date=YYYY-MM-DD
 */
async function getAvailability(req, res) {
  try {
    const { staffId, date } = req.query;
    let query = db.collection('slots');

    if (staffId) {
      query = query.where('staffId', '==', staffId);
    }

    const snapshot = await query.get();
    const slots = [];

    snapshot.forEach((doc) => {
      const data = doc.data();
      // Ensure zero PII exposed
      slots.push({
        id: doc.id,
        staffId: data.staffId,
        staffName: data.staffName,
        startAt: data.startAt,
        endAt: data.endAt,
        isReserved: data.isReserved || false
      });
    });

    return res.status(200).json({ success: true, count: slots.length, slots });
  } catch (error) {
    console.error('[BookingController] getAvailability error:', error);
    return res.status(500).json({ success: false, message: 'Failed to load availability.' });
  }
}

module.exports = {
  reserveSlot,
  cancelBooking,
  getAvailability
};
