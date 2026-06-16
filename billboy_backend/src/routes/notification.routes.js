const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth.middleware');
const { Notification } = require('../models');
const { Op } = require('sequelize');

router.use(authenticate);

// GET /notifications
router.get('/', async (req, res, next) => {
  try {
    const { page = 1, pageSize = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(pageSize);

    const { count, rows } = await Notification.findAndCountAll({
      where: { userId: req.user.id },
      order: [['createdAt', 'DESC']],
      limit: parseInt(pageSize),
      offset,
    });

    res.json({
      data: rows,
      unreadCount: rows.filter(n => !n.isRead).length,
      pagination: { total: count, page: parseInt(page), pageSize: parseInt(pageSize) },
    });
  } catch (error) {
    next(error);
  }
});

// PUT /notifications/:id/read
router.put('/:id/read', async (req, res, next) => {
  try {
    const notification = await Notification.findOne({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!notification) return res.status(404).json({ error: 'Notification not found' });

    await notification.update({ isRead: true });
    res.json({ message: 'Marked as read' });
  } catch (error) {
    next(error);
  }
});

// PUT /notifications/read-all
router.put('/read-all', async (req, res, next) => {
  try {
    await Notification.update({ isRead: true }, {
      where: { userId: req.user.id, isRead: false },
    });
    res.json({ message: 'All notifications marked as read' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
