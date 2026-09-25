const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

function initializeFirebase() {
  if (admin.apps.length > 0) {
    return admin;
  }

  // 1. Direct JSON string in environment variable (Ideal for Vercel)
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    try {
      const parsed = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      admin.initializeApp({
        credential: admin.credential.cert(parsed)
      });
      console.log('[Firebase Admin] Initialized with FIREBASE_SERVICE_ACCOUNT_JSON env variable.');
      return admin;
    } catch (e) {
      console.error('[Firebase Admin] Failed to parse FIREBASE_SERVICE_ACCOUNT_JSON:', e.message);
    }
  }

  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH 
    ? path.resolve(process.env.FIREBASE_SERVICE_ACCOUNT_PATH)
    : path.resolve(__dirname, '../../serviceAccountKey.json');

  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('[Firebase Admin] Initialized with service account file.');
  } else if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      })
    });
    console.log('[Firebase Admin] Initialized with environment credentials.');
  } else {
    // Development / Emulator fallback
    admin.initializeApp({
      projectId: process.env.FIREBASE_PROJECT_ID || 'demo-appointment-booking'
    });
    console.warn('[Firebase Admin] Initialized with default project ID (emulator/dev mode).');
  }

  return admin;
}

const adminInstance = initializeFirebase();
const db = adminInstance.firestore();
const auth = adminInstance.auth();

module.exports = {
  admin: adminInstance,
  db,
  auth
};
