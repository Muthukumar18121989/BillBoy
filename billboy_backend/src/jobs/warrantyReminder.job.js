const cron = require('node-cron');
const { Bill, Notification, User } = require('../models');
const { Op } = require('sequelize');
const NotificationService = require('../services/notification.service');
const logger = require('../utils/logger');

const WARRANTY_REMINDER_DAYS = [90, 60, 30, 15, 7, 1];

const initWarrantyReminderJob = () => {
  // Run daily at 9 AM
  cron.schedule('0 9 * * *', async () => {
    logger.info('Running warranty reminder job...');

    try {
      const now = new Date();

      for (const days of WARRANTY_REMINDER_DAYS) {
        const targetDate = new Date(now);
        targetDate.setDate(targetDate.getDate() + days);
        const dateStr = targetDate.toISOString().split('T')[0];

        const bills = await Bill.findAll({
          where: {
            warrantyEndDate: dateStr,
            isDeleted: false,
          },
          include: [{ model: User }],
        });

        for (const bill of bills) {
          const user = bill.User;
          if (!user) continue;

          // Check if notification already sent
          const existing = await Notification.findOne({
            where: {
              billId: bill.id,
              userId: user.id,
              message: { [Op.like]: `%${days} day%` },
              sentAt: { [Op.ne]: null },
            },
          });

          if (!existing) {
            const notification = await Notification.create({
              userId: user.id,
              billId: bill.id,
              type: 'warranty_expiry',
              title: 'Warranty Expiry Alert',
              message: `Your ${bill.productName} warranty expires in ${days} day${days !== 1 ? 's' : ''}. Take action now!`,
              channel: 'push',
              scheduledAt: now,
            });

            try {
              notification.User = user;
              await NotificationService.sendNotification(notification);
              await notification.update({ sentAt: now });
              logger.info(`Warranty reminder sent for bill ${bill.id} (${days} days)`);
            } catch (err) {
              logger.error(`Failed to send reminder for bill ${bill.id}:`, err);
            }
          }
        }
      }

      logger.info('Warranty reminder job completed');
    } catch (error) {
      logger.error('Warranty reminder job failed:', error);
    }
  }, {
    timezone: 'Asia/Kolkata',
  });

  // Also update warranty statuses daily
  cron.schedule('0 0 * * *', async () => {
    logger.info('Updating warranty statuses...');
    try {
      const now = new Date().toISOString().split('T')[0];
      const soon = new Date();
      soon.setDate(soon.getDate() + 30);
      const soonStr = soon.toISOString().split('T')[0];

      // Expired
      await Bill.update(
        { warrantyStatus: 'expired' },
        { where: { warrantyEndDate: { [Op.lt]: now }, warrantyStatus: { [Op.ne]: 'expired' } } }
      );

      // Expiring soon
      await Bill.update(
        { warrantyStatus: 'expiringSoon' },
        { where: { warrantyEndDate: { [Op.between]: [now, soonStr] }, warrantyStatus: 'active' } }
      );

      logger.info('Warranty statuses updated');
    } catch (error) {
      logger.error('Warranty status update failed:', error);
    }
  }, { timezone: 'Asia/Kolkata' });

  logger.info('Warranty reminder jobs initialized');
};

module.exports = { initWarrantyReminderJob };
