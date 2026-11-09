/**
 * This is the missing link between "app detects a crash" and "family phone
 * actually buzzes." The Flutter app CANNOT push-notify someone else's phone
 * directly — that would require exposing a secret server key inside the app,
 * which anyone could extract and abuse. So this one small function runs on
 * Firebase's servers instead, and does that sending safely.
 *
 * What it does:
 *   1. Watches for new documents in riders/{uid}/alerts/{alertId}
 *   2. Reads that rider's emergency contacts
 *   3. Sends each contact a real push notification via Firebase Cloud
 *      Messaging, using their saved fcmToken (saved automatically the first
 *      time a contact opens the app and logs in)
 *
 * SETUP (one-time, on your machine, inside this `functions` folder):
 *   npm install
 *   firebase deploy --only functions
 *
 * Note: Cloud Functions requires Firebase's "Blaze" (pay-as-you-go) plan to
 * deploy at all — even though the free monthly quota is generous enough that
 * personal-scale testing should cost $0, Firebase requires a billing account
 * on file. If you'd rather avoid that entirely for now, the app still works
 * end-to-end WITHOUT this function — the SOS screen still detects crashes,
 * shows the alert, and logs it to Firestore. You just won't get the family
 * member's phone to buzz automatically until this piece is deployed.
 */

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

exports.notifyOnAlert = onDocumentCreated('riders/{riderId}/alerts/{alertId}', async (event) => {
  const alert = event.data.data();
  const riderId = event.params.riderId;

  const db = getFirestore();
  const riderDoc = await db.collection('riders').doc(riderId).get();
  const riderName = riderDoc.data()?.name || 'Your rider';

  const contactsSnap = await db.collection('riders').doc(riderId).collection('contacts').get();
  const tokens = [];
  for (const doc of contactsSnap.docs) {
    const c = doc.data();
    if (c.linkedUid) {
      const linkedRider = await db.collection('riders').doc(c.linkedUid).get();
      const token = linkedRider.data()?.fcmToken;
      if (token) tokens.push(token);
    }
  }

  if (tokens.length === 0) {
    console.log(`No registered device tokens for ${riderId}'s emergency contacts yet.`);
    return;
  }

  const isCrash = alert.type === 'auto_crash';
  const mapsLink = `https://www.openstreetmap.org/?mlat=${alert.lat}&mlon=${alert.lng}#map=17/${alert.lat}/${alert.lng}`;

  await getMessaging().sendEachForMulticast({
    tokens,
    notification: {
      title: isCrash ? `🚨 Possible crash — ${riderName}` : `🆘 SOS from ${riderName}`,
      body: `Tap to see their live location. ${mapsLink}`,
    },
    data: {
      type: alert.type,
      lat: String(alert.lat),
      lng: String(alert.lng),
      riderId,
    },
    android: { priority: 'high' },
  });

  console.log(`Notified ${tokens.length} contact(s) for rider ${riderId}`);
});
