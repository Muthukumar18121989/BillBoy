const nodemailer = require('nodemailer');
const { Notification, User, UserPreference } = require('../models');
const { sendPushNotification } = require('../config/firebase');
const logger = require('../utils/logger');

const WARRANTY_REMINDER_DAYS = [90, 60, 30, 15, 7, 1];

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT || '587'),
  secure: false,
  auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
});

class NotificationService {
  async scheduleWarrantyReminders(userId, billId, productName, warrantyEndDate) {
    const end = new Date(warrantyEndDate);
    const notifications = [];

    for (const days of WARRANTY_REMINDER_DAYS) {
      const scheduledAt = new Date(end);
      scheduledAt.setDate(scheduledAt.getDate() - days);

      if (scheduledAt > new Date()) {
        notifications.push({
          userId,
          billId,
          type: 'warranty_expiry',
          title: 'Warranty Reminder',
          message: `Your ${productName} warranty expires in ${days} day${days !== 1 ? 's' : ''}.`,
          channel: 'push',
          scheduledAt,
        });
      }
    }

    await Notification.bulkCreate(notifications);
    logger.info(`Scheduled ${notifications.length} warranty reminders for bill ${billId}`);
  }

  async sendDueNotifications() {
    const due = await Notification.findAll({
      where: {
        sentAt: null,
        scheduledAt: { $lte: new Date() },
      },
      include: [{ model: User }],
      limit: 100,
    });

    for (const notification of due) {
      try {
        await this.sendNotification(notification);
        await notification.update({ sentAt: new Date() });
      } catch (error) {
        logger.error(`Failed to send notification ${notification.id}:`, error);
      }
    }

    return due.length;
  }

  async sendNotification(notification) {
    const user = notification.User;
    if (!user) return;

    const prefs = await UserPreference.findOne({ where: { userId: user.id } });

    if (prefs?.pushNotifications && user.fcmToken) {
      try {
        await sendPushNotification(user.fcmToken, notification.title, notification.message, {
          billId: notification.billId || '',
          type: notification.type,
        });
      } catch (error) {
        logger.warn('Push notification failed:', error.message);
      }
    }

    if (prefs?.emailNotifications) {
      try {
        await transporter.sendMail({
          from: process.env.EMAIL_FROM,
          to: user.email,
          subject: notification.title,
          html: this._buildEmailTemplate(notification.title, notification.message),
        });
      } catch (error) {
        logger.warn('Email notification failed:', error.message);
      }
    }
  }

  _buildEmailTemplate(title, message) {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: 'Poppins', sans-serif; background: #f8f9fe; margin: 0; padding: 20px; }
          .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 16px; overflow: hidden; }
          .header { background: linear-gradient(135deg, #6C63FF, #4A42D6); padding: 32px; text-align: center; }
          .header h1 { color: white; margin: 0; font-size: 24px; }
          .body { padding: 32px; }
          .message { background: #f8f9fe; border-radius: 12px; padding: 20px; margin: 20px 0; }
          .footer { text-align: center; color: #9CA3AF; font-size: 12px; padding: 20px; }
          .btn { display: inline-block; background: #6C63FF; color: white; padding: 12px 24px; border-radius: 8px; text-decoration: none; font-weight: 600; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>BillBoy</h1>
            <p style="color: rgba(255,255,255,0.8); margin: 8px 0 0">Never lose a bill. Never miss a warranty.</p>
          </div>
          <div class="body">
            <h2>${title}</h2>
            <div class="message">
              <p>${message}</p>
            </div>
            <a href="#" class="btn">View in BillBoy</a>
          </div>
          <div class="footer">
            <p>&copy; 2026 BillBoy. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }
}

module.exports = new NotificationService();
