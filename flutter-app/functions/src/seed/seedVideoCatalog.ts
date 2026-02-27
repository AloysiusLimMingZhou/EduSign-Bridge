/**
 * seedVideoCatalog — Admin utility (not deployed as Cloud Function)
 *
 * Run locally with: npx ts-node src/seed/seedVideoCatalog.ts
 *
 * Scans Cloud Storage for sign videos and fingerspelling videos,
 * then populates the RTDB signVideoCatalog and fingerspelling nodes.
 */
import * as admin from "firebase-admin";

// Initialize with default credentials
admin.initializeApp();

const STORAGE_BUCKET = "ai-real-time-voice-to-sign.firebasestorage.app";

async function seedCatalog() {
    const db = admin.database();
    const bucket = admin.storage().bucket(STORAGE_BUCKET);

    console.log("Scanning Cloud Storage for sign videos...\n");

    // --- Seed signVideoCatalog ---
    try {
        const [signFiles] = await bucket.getFiles({ prefix: "signs/" });

        for (const file of signFiles) {
            const fileName = file.name.replace("signs/", "").replace(".mp4", "");
            if (!fileName || fileName.includes("/")) continue;

            const word = fileName.toLowerCase();
            const [metadata] = await file.getMetadata();

            await db.ref(`signVideoCatalog/${word}`).set({
                videoUrl: `gs://${STORAGE_BUCKET}/${file.name}`,
                thumbnailUrl: `gs://${STORAGE_BUCKET}/thumbnails/${word}.jpg`,
                duration: 2.0, // Default; update manually if known
                addedAt: Date.now(),
            });

            console.log(`  ✅ signVideoCatalog/${word} → ${file.name} (${metadata.size} bytes)`);
        }

        console.log(`\nSeeded ${signFiles.length} sign videos.\n`);
    } catch (error) {
        console.error("Error scanning signs/:", error);
    }

    // --- Seed fingerspelling ---
    try {
        const [fingerFiles] = await bucket.getFiles({ prefix: "fingerspelling/" });

        for (const file of fingerFiles) {
            const fileName = file.name
                .replace("fingerspelling/", "")
                .replace(".mp4", "");
            if (!fileName || fileName.includes("/")) continue;

            const letter = fileName.toLowerCase();

            await db.ref(`fingerspelling/${letter}`).set({
                videoUrl: `gs://${STORAGE_BUCKET}/${file.name}`,
                duration: 1.0,
            });

            console.log(`  ✅ fingerspelling/${letter} → ${file.name}`);
        }

        console.log(`\nSeeded ${fingerFiles.length} fingerspelling videos.\n`);
    } catch (error) {
        console.error("Error scanning fingerspelling/:", error);
    }

    console.log("Done! Check your RTDB in Firebase Console.");
    process.exit(0);
}

seedCatalog().catch(console.error);
