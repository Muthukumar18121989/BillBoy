const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth.middleware');
const { User, UserPreference } = require('../models');
const { verifyToken } = require('../config/firebase');
const { v4: uuidv4 } = require('uuid');
const logger = require('../utils/logger');

// POST /auth/register - Sync Firebase user to PostgreSQL
router.post('/register', async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Token required' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = await verifyToken(token);

    const { fullName, phone } = req.body;

    let user = await User.findOne({ where: { firebaseUid: decoded.uid } });
    if (!user) {
      user = await User.create({
        id: uuidv4(),
        firebaseUid: decoded.uid,
        fullName: fullName || decoded.name || '',
        email: decoded.email,
        phone,
        emailVerified: decoded.email_verified || false,
      });

      await UserPreference.create({
        id: uuidv4(),
        userId: user.id,
      });
    }

    res.json({ data: user, message: 'User registered successfully' });
  } catch (error) {
    next(error);
  }
});

// GET /auth/me
router.get('/me', authenticate, async (req, res) => {
  res.json({ data: req.user });
});

// PUT /auth/fcm-token - Update FCM token
router.put('/fcm-token', authenticate, async (req, res, next) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) return res.status(400).json({ error: 'fcmToken is required' });

    await req.user.update({ fcmToken });
    res.json({ message: 'FCM token updated' });
  } catch (error) {
    next(error);
  }
});

// DELETE /auth/account - Delete account
router.delete('/account', authenticate, async (req, res, next) => {
  try {
    await req.user.update({ isActive: false });
    res.json({ message: 'Account deactivated' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
