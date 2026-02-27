/**
 * translateText — HTTPS Callable
 * Uses Google Cloud Translation API to translate text
 * between any of the 12 supported languages.
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { v2 as Translate } from "@google-cloud/translate";

const LOCATION = "asia-southeast1";

// Supported languages
const SUPPORTED_LANGUAGES = [
    "en", "ms", "zh", "ja", "ko", "hi",
    "ta", "th", "vi", "id", "fr", "ar",
];

export const translateText = onCall(
    { region: LOCATION, memory: "256MiB", timeoutSeconds: 30 },
    async (request) => {
        if (!request.auth) {
            throw new HttpsError("unauthenticated", "User must be authenticated.");
        }

        const { text, sourceLang, targetLang } = request.data as {
            text: string;
            sourceLang?: string;
            targetLang: string;
        };

        if (!text || typeof text !== "string" || text.trim() === "") {
            throw new HttpsError("invalid-argument", "text must be a non-empty string.");
        }

        if (!targetLang) {
            throw new HttpsError("invalid-argument", "targetLang is required.");
        }

        if (!SUPPORTED_LANGUAGES.includes(targetLang)) {
            throw new HttpsError(
                "invalid-argument",
                `Unsupported target language: ${targetLang}. Supported: ${SUPPORTED_LANGUAGES.join(", ")}`
            );
        }

        try {
            const translate = new Translate.Translate();

            const [translation] = await translate.translate(text, {
                from: sourceLang || undefined,
                to: targetLang,
            });

            const translatedText = typeof translation === "string" ? translation : "";

            // Detect source language if not provided
            const [detections] = sourceLang ? [[{ language: sourceLang }]] : await translate.detect(text);
            const detectedSourceLang = Array.isArray(detections)
                ? (detections[0] as any)?.language || "unknown"
                : (detections as any)?.language || "unknown";

            console.log(
                `translateText [${detectedSourceLang}→${targetLang}]: "${text.substring(0, 50)}" → "${translatedText.substring(0, 50)}"`
            );

            return {
                translatedText,
                detectedSourceLang,
                targetLang,
            };
        } catch (error: any) {
            console.error("translateText error:", error);
            throw new HttpsError("internal", `Translation API error: ${error.message}`);
        }
    }
);
