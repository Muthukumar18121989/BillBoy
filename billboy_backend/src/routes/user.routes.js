const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth.middleware');
const { UserPreference } = require('../models');

router.use(authenticate);

// GET /users/preferences
router.get('/preferences', async (req, res, next) => {
  try {
    const prefs = await UserPreference.findOne({ where: { userId: req.user.id } });
    res.json({ data: prefs });
  } catch (error) {
    next(error);
  }
});

// PUT /users/preferences
router.put('/preferences', async (req, res, next) => {
  try {
    const { currency, themeMode, visibleColumns, emailNotifications, pushNotifications, smsNotifications, customDepreciationRules } = req.body;

    const [prefs] = await UserPreference.upsert({
      userId: req.user.id,
      currency,
      themeMode,
      visibleColumns,
      emailNotifications,
      pushNotifications,
      smsNotifications,
      customDepreciationRules,
    });

    res.json({ data: prefs });
  } catch (error) {
    next(error);
  }
});

// GET /users/profile
router.get('/profile', authenticate, async (req, res) => {
  res.json({ data: req.user });
});

// PUT /users/profile
router.put('/profile', async (req, res, next) => {
  try {
    const { fullName, phone } = req.body;
    await req.user.update({ fullName, phone });
    res.json({ data: req.user });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
