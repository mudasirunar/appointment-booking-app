const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');

router.post('/reserve', bookingController.reserveSlot);
router.post('/cancel', bookingController.cancelBooking);
router.get('/slots', bookingController.getAvailability);

module.exports = router;
