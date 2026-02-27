/**
 * onUserCreated — Auth trigger
 * Automatically creates a user profile in RTDB when a new user signs up.
 */
import { user } from "firebase-functions/v1/auth";
import * as admin from "firebase-admin";

// Initialize Firebase Admin (safe to call multiple times — no-ops if already initialized)
if (admin.apps.length === 0) {
    admin.initializeApp();
}

export const onUserCreated = user().onCreate(async (userRecord) => {
    const db = admin.database();
    const uid = userRecord.uid;

    const profileRef = db.ref(`users/${uid}`);

    // Check if profile already exists (e.g., created by Flutter client)
    const snapshot = await profileRef.get();
    if (snapshot.exists()) {
        console.log(`Profile already exists for user ${uid}, skipping.`);
        return;
    }

    // Create profile
    const profile = {
        displayName: userRecord.displayName || "",
        email: userRecord.email || "",
        photoUrl: userRecord.photoURL || null,
        preferredLanguage: "en",
        createdAt: Date.now(),
        lastActiveAt: Date.now(),
    };

    await profileRef.set(profile);
    console.log(`Created RTDB profile for user ${uid}`);
});
