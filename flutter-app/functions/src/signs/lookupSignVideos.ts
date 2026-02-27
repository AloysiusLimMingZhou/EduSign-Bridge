/**
 * lookupSignVideos — HTTPS Callable
 * Takes an array of gloss words and looks up their sign videos
 * from RTDB signVideoCatalog. Falls back to fingerspelling for unknown words.
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getDatabase } from "firebase-admin/database";
import { getStorage } from "firebase-admin/storage";

const LOCATION = "asia-southeast1";
const STORAGE_BUCKET = "ai-real-time-voice-to-sign.firebasestorage.app";

interface SignVideoResult {
    word: string;
    type: "sign" | "fingerspelling";
    videoUrl: string;
    duration: number;
}

export const lookupSignVideos = onCall(
    { region: LOCATION, memory: "256MiB", timeoutSeconds: 30 },
    async (request) => {
        if (!request.auth) {
            throw new HttpsError("unauthenticated", "User must be authenticated.");
        }

        const { glossWords } = request.data as {
            glossWords: string[];
        };

        if (!glossWords || !Array.isArray(glossWords) || glossWords.length === 0) {
            throw new HttpsError(
                "invalid-argument",
                "glossWords must be a non-empty array of strings."
            );
        }

        const db = getDatabase();
        const storage = getStorage();
        const bucket = storage.bucket(STORAGE_BUCKET);
        const results: SignVideoResult[] = [];

        for (const word of glossWords) {
            const normalizedWord = word.toLowerCase().trim();

            // 1. Try signVideoCatalog in RTDB
            const signSnapshot = await db
                .ref(`signVideoCatalog/${normalizedWord}`)
                .get();

            if (signSnapshot.exists()) {
                const data = signSnapshot.val();

                // Generate signed URL for the video
                let videoUrl = data.videoUrl;
                if (videoUrl && videoUrl.startsWith("gs://")) {
                    // Convert gs:// path to signed download URL
                    const filePath = videoUrl.replace(`gs://${STORAGE_BUCKET}/`, "");
                    const [url] = await bucket.file(filePath).getSignedUrl({
                        action: "read",
                        expires: Date.now() + 60 * 60 * 1000, // 1 hour
                    });
                    videoUrl = url;
                }

                results.push({
                    word: normalizedWord,
                    type: "sign",
                    videoUrl: videoUrl,
                    duration: data.duration || 2.0,
                });
            } else {
                // 2. Fallback: fingerspelling each letter
                for (const letter of normalizedWord) {
                    if (!/[a-z]/.test(letter)) continue; // Skip non-letter characters

                    const fingerSnapshot = await db
                        .ref(`fingerspelling/${letter}`)
                        .get();

                    if (fingerSnapshot.exists()) {
                        const data = fingerSnapshot.val();

                        let videoUrl = data.videoUrl;
                        if (videoUrl && videoUrl.startsWith("gs://")) {
                            const filePath = videoUrl.replace(`gs://${STORAGE_BUCKET}/`, "");
                            const [url] = await bucket.file(filePath).getSignedUrl({
                                action: "read",
                                expires: Date.now() + 60 * 60 * 1000,
                            });
                            videoUrl = url;
                        }

                        results.push({
                            word: letter,
                            type: "fingerspelling",
                            videoUrl: videoUrl,
                            duration: data.duration || 1.0,
                        });
                    }
                }
            }
        }

        console.log(
            `lookupSignVideos: ${glossWords.length} words → ${results.length} videos`
        );

        return { videos: results };
    }
);
