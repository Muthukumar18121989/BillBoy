const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth.middleware');
const { Bill } = require('../models');
const { Op, fn, col, literal } = require('sequelize');

router.use(authenticate);

// GET /analytics/spending-by-category
router.get('/spending-by-category', async (req, res, next) => {
  try {
    const { year } = req.query;
    const where = { userId: req.user.id, isDeleted: false };
    if (year) {
      where.purchaseDate = {
        [Op.between]: [`${year}-01-01`, `${year}-12-31`],
      };
    }

    const data = await Bill.findAll({
      where,
      attributes: [
        'category',
        [fn('SUM', col('purchase_amount')), 'total'],
        [fn('COUNT', col('id')), 'count'],
      ],
      group: ['category'],
      order: [[literal('total'), 'DESC']],
    });

    res.json({ data });
  } catch (error) {
    next(error);
  }
});

// GET /analytics/monthly-spending
router.get('/monthly-spending', async (req, res, next) => {
  try {
    const { year = new Date().getFullYear() } = req.query;

    const data = await Bill.findAll({
      where: {
        userId: req.user.id,
        isDeleted: false,
        purchaseDate: {
          [Op.between]: [`${year}-01-01`, `${year}-12-31`],
        },
      },
      attributes: [
        [fn('TO_CHAR', col('purchase_date'), 'YYYY-MM'), 'month'],
        [fn('SUM', col('purchase_amount')), 'total'],
        [fn('COUNT', col('id')), 'count'],
      ],
      group: [literal("TO_CHAR(purchase_date, 'YYYY-MM')")],
      order: [[literal("TO_CHAR(purchase_date, 'YYYY-MM')"), 'ASC']],
    });

    res.json({ data });
  } catch (error) {
    next(error);
  }
});

// GET /analytics/warranty-overview
router.get('/warranty-overview', async (req, res, next) => {
  try {
    const data = await Bill.findAll({
      where: {
        userId: req.user.id,
        isDeleted: false,
        warrantyEndDate: { [Op.ne]: null },
      },
      attributes: [
        'warrantyStatus',
        [fn('COUNT', col('id')), 'count'],
      ],
      group: ['warrantyStatus'],
    });

    res.json({ data });
  } catch (error) {
    next(error);
  }
});

// GET /analytics/depreciation-summary
router.get('/depreciation-summary', async (req, res, next) => {
  try {
    const bills = await Bill.findAll({
      where: {
        userId: req.user.id,
        isDeleted: false,
        currentValue: { [Op.ne]: null },
      },
      attributes: ['category', 'purchaseAmount', 'currentValue'],
    });

    const summary = bills.reduce((acc, bill) => {
      const cat = bill.category;
      if (!acc[cat]) acc[cat] = { originalValue: 0, currentValue: 0, count: 0 };
      acc[cat].originalValue += parseFloat(bill.purchaseAmount);
      acc[cat].currentValue += parseFloat(bill.currentValue);
      acc[cat].count++;
      return acc;
    }, {});

    const data = Object.entries(summary).map(([category, vals]) => ({
      category,
      ...vals,
      totalLoss: vals.originalValue - vals.currentValue,
      depreciationPct: ((vals.originalValue - vals.currentValue) / vals.originalValue * 100).toFixed(1),
    }));

    res.json({ data });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
