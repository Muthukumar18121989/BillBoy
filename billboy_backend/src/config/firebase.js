const admin = require('firebase-admin');
const logger = require('../utils/logger');

let firebaseApp;

const initializeFirebase = () => {
  if (admin.apps.length > 0) {
    firebaseApp = admin.apps[0];
    return;
  }

  try {
    const serviceAccount = {
      type: 'service_account',
      project_id: process.env.FIREBASE_PROJECT_ID,
      private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
      private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      client_email: process.env.FIREBASE_CLIENT_EMAIL,
      client_id: process.env.FIREBASE_CLIENT_ID,
    };

    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });

    logger.info('Firebase Admin initialized');
  } catch (error) {
    logger.error('Firebase initialization failed:', error);
    throw error;
  }
};

const verifyToken = async (token) => {
  return await admin.auth().verifyIdToken(token);
};

const sendPushNotification = async (token, title, body, data = {}) => {
  const message = {
    notification: { title, body },
    data,
    token,
  };
  return await admin.messaging().send(message);
};

const sendMulticastNotification = async (tokens, title, body, data = {}) => {
  const message = {
    notification: { title, body },
    data,
    tokens,
  };
  return await admin.messaging().sendEachForMulticast(message);
};

module.exports = { initializeFirebase, verifyToken, sendPushNotification, sendMulticastNotification };
