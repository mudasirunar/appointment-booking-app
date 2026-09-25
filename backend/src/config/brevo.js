const Brevo = require('@getbrevo/brevo');

class BrevoEmailService {
  constructor() {
    this.apiKey = process.env.BREVO_API_KEY || '';
    this.senderEmail = process.env.BREVO_SENDER_EMAIL || 'noreply@salonbooking.com';
    this.senderName = process.env.BREVO_SENDER_NAME || 'Salon Appointment Booking';
    
    this.apiInstance = new Brevo.TransactionalEmailsApi();
    if (this.apiKey) {
      this.apiInstance.setApiKey(Brevo.TransactionalEmailsApiApiKeys.apiKey, this.apiKey);
    }
  }

  /**
   * Send a 6-digit OTP code to a user's email address
   * @param {string} toEmail 
   * @param {string} otpCode 
   */
  async sendOtpEmail(toEmail, otpCode) {
    if (!this.apiKey) {
      console.warn(`[Brevo Email Service] No BREVO_API_KEY configured. Mock sending OTP ${otpCode} to ${toEmail}`);
      return { success: true, mocked: true };
    }

    const sendSmtpEmail = new Brevo.SendSmtpEmail();
    sendSmtpEmail.subject = 'Your Verification Code - Salon Appointment Booking';
    sendSmtpEmail.htmlContent = `
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 540px; margin: 0 auto; padding: 32px 24px; background: #ffffff; border: 1px solid #e5e7eb; border-radius: 12px;">
        <h2 style="color: #1a1d20; margin-top: 0; font-size: 22px; font-weight: 600;">Reset Your Password</h2>
        <p style="color: #4b5563; font-size: 15px; line-height: 1.5;">
          You requested to reset your password for your Salon Appointment Booking account. Use the 6-digit verification code below:
        </p>
        <div style="margin: 28px 0; text-align: center;">
          <span style="display: inline-block; font-size: 32px; font-weight: 700; letter-spacing: 6px; color: #1a1d20; background: #f8f9fa; border: 1px solid #e5e7eb; padding: 14px 28px; border-radius: 10px;">
            ${otpCode}
          </span>
        </div>
        <p style="color: #6b7280; font-size: 13px; margin-bottom: 0;">
          This code is valid for 10 minutes. If you did not request this code, you can safely ignore this email.
        </p>
      </div>
    `;
    sendSmtpEmail.sender = { name: this.senderName, email: this.senderEmail };
    sendSmtpEmail.to = [{ email: toEmail }];

    try {
      const result = await this.apiInstance.sendTransacEmail(sendSmtpEmail);
      console.log(`[Brevo Email Service] OTP email dispatched to ${toEmail}. Message ID: ${result?.body?.messageId || 'sent'}`);
      return { success: true, messageId: result?.body?.messageId };
    } catch (error) {
      console.error('[Brevo Email Service] Error sending email via Brevo:', error?.response?.body || error.message);
      throw error;
    }
  }
}

module.exports = new BrevoEmailService();
