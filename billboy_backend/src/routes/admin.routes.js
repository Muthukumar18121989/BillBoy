const express = require('express');
const router = express.Router();
const { authenticate, adminOnly } = require('../middleware/auth.middleware');
const { User, Bill, Notification, OcrResult } = require('../models');
const { fn, col, literal } = require('sequelize');

router.use(authenticate, adminOnly);

// GET /admin/stats
router.get('/stats', async (req, res, next) => {
  try {
    const [totalUsers, totalBills, totalNotifications] = await Promise.all([
      User.count({ where: { isActive: true } }),
      Bill.count({ where: { isDeleted: false } }),
      Notification.count(),
    ]);

    const billsByCategory = await Bill.findAll({
      where: { isDeleted: false },
      attributes: ['category', [fn('COUNT', col('id')), 'count']],
      group: ['category'],
    });

    const ocrStats = await OcrResult.findAll({
      attributes: [
        'provider',
        [fn('COUNT', col('id')), 'count'],
        [fn('AVG', col('processing_time_ms')), 'avgTimeMs'],
        [fn('AVG', col('confidence')), 'avgConfidence'],
      ],
      group: ['provider'],
    });

    res.json({
      data: { totalUsers, totalBills, totalNotifications, billsByCategory, ocrStats },
    });
  } catch (error) {
    next(error);
  }
});

// GET /admin/users
router.get('/users', async (req, res, next) => {
  try {
    const { page = 1, pageSize = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(pageSize);

    const { count, rows } = await User.findAndCountAll({
      attributes: { exclude: ['fcmToken'] },
      order: [['createdAt', 'DESC']],
      limit: parseInt(pageSize),
      offset,
    });

    res.json({ data: rows, pagination: { total: count, page: parseInt(page) } });
  } catch (error) {
    next(error);
  }
});

// PUT /admin/users/:id/status
router.put('/users/:id/status', async (req, res, next) => {
  try {
    const { isActive } = req.body;
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    await user.update({ isActive });
    res.json({ message: `User ${isActive ? 'activated' : 'deactivated'}` });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
