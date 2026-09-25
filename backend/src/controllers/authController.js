const crypto = require('crypto');
const { auth, db } = require('../config/firebase');
const brevoService = require('../config/brevo');

// In-memory or Firestore OTP storage
const otpStore = new Map();

/**
 * Generate a secure 6-digit random numeric OTP
 */
function generateOtp() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

/**
 * Hash an OTP for secure comparison
 */
function hashOtp(otp) {
  return crypto.createHash('sha256').update(otp).digest('hex');
}

/**
 * POST /api/auth/send-otp
 * Body: { email }
 */
async function sendOtp(req, res) {
  try {
    const { email } = req.body;
    if (!email || !email.includes('@')) {
      return res.status(400).json({ success: false, message: 'Valid email is required.' });
    }

    const normalizedEmail = email.trim().toLowerCase();

    // Verify user exists in Firebase Auth
    try {
      await auth.getUserByEmail(normalizedEmail);
    } catch (err) {
      if (err.code === 'auth/user-not-found') {
        return res.status(404).json({ success: false, message: 'No registered account found with this email.' });
      }
      // If emulator or dev, log and allow proceeding
      console.warn('[AuthController] User check warning:', err.message);
    }

    const otpCode = generateOtp();
    const expiresAt = Date.now() + 10 * 60 * 1000; // 10 minutes

    // Store hashed OTP
    otpStore.set(normalizedEmail, {
      hashedOtp: hashOtp(otpCode),
      expiresAt,
      attempts: 0
    });

    // Also persist to Firestore for audit and high-availability
    try {
      await db.collection('otp_verifications').doc(normalizedEmail).set({
        hashedOtp: hashOtp(otpCode),
        expiresAt: new Date(expiresAt),
        createdAt: new Date(),
        verified: false
      });
    } catch (dbErr) {
      console.warn('[AuthController] Could not write to otp_verifications in Firestore:', dbErr.message);
    }

    // Send email via Brevo
    await brevoService.sendOtpEmail(normalizedEmail, otpCode);

    return res.status(200).json({
      success: true,
      message: 'A 6-digit verification code has been sent to your email.'
    });
  } catch (error) {
    console.error('[AuthController] sendOtp error:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to send OTP.'
    });
  }
}

/**
 * POST /api/auth/verify-otp
 * Body: { email, otp }
 */
async function verifyOtp(req, res) {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) {
      return res.status(400).json({ success: false, message: 'Email and OTP are required.' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const record = otpStore.get(normalizedEmail);

    if (!record) {
      return res.status(400).json({ success: false, message: 'No active OTP request found. Please request a new code.' });
    }

    if (Date.now() > record.expiresAt) {
      otpStore.delete(normalizedEmail);
      return res.status(400).json({ success: false, message: 'The verification code has expired. Please request a new one.' });
    }

    if (record.attempts >= 5) {
      otpStore.delete(normalizedEmail);
      return res.status(429).json({ success: false, message: 'Too many incorrect attempts. Please request a new code.' });
    }

    const providedHash = hashOtp(otp.trim());
    if (providedHash !== record.hashedOtp) {
      record.attempts += 1;
      return res.status(400).json({ success: false, message: 'Invalid verification code.' });
    }

    // Generate single-use reset token
    const resetToken = crypto.randomBytes(32).toString('hex');
    record.verified = true;
    record.resetToken = resetToken;
    record.resetExpiresAt = Date.now() + 15 * 60 * 1000; // 15 mins to change password

    return res.status(200).json({
      success: true,
      message: 'OTP verified successfully.',
      resetToken
    });
  } catch (error) {
    console.error('[AuthController] verifyOtp error:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to verify OTP.'
    });
  }
}

/**
 * POST /api/auth/reset-password
 * Body: { email, resetToken, newPassword }
 */
async function resetPassword(req, res) {
  try {
    const { email, resetToken, newPassword } = req.body;
    if (!email || !resetToken || !newPassword) {
      return res.status(400).json({ success: false, message: 'Email, reset token, and new password are required.' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters.' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const record = otpStore.get(normalizedEmail);

    if (!record || !record.verified || record.resetToken !== resetToken) {
      return res.status(401).json({ success: false, message: 'Invalid or unverified reset token.' });
    }

    if (Date.now() > record.resetExpiresAt) {
      otpStore.delete(normalizedEmail);
      return res.status(400).json({ success: false, message: 'Reset token has expired.' });
    }

    // Update password in Firebase Auth via Admin SDK
    const userRecord = await auth.getUserByEmail(normalizedEmail);
    await auth.updateUser(userRecord.uid, { password: newPassword });

    // Clean up used token
    otpStore.delete(normalizedEmail);

    return res.status(200).json({
      success: true,
      message: 'Password has been reset successfully. You can now log in.'
    });
  } catch (error) {
    console.error('[AuthController] resetPassword error:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to reset password.'
    });
  }
}

module.exports = {
  sendOtp,
  verifyOtp,
  resetPassword
};
