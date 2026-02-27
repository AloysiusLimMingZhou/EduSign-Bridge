/**
 * speechToText — HTTPS Callable
 * Takes base64-encoded audio and uses Google Cloud Speech-to-Text
 * to transcribe it into text.
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import speech from "@google-cloud/speech";

const LOCATION = "asia-southeast1";

export const speechToText = onCall(
    { region: LOCATION, memory: "512MiB", timeoutSeconds: 120 },
    async (request) => {
        if (!request.auth) {
            throw new HttpsError("unauthenticated", "User must be authenticated.");
        }

        const { audioBase64, lang, encoding, sampleRateHertz } = request.data as {
            audioBase64: string;
            lang?: string;
            encoding?: string;
            sampleRateHertz?: number;
        };

        if (!audioBase64 || typeof audioBase64 !== "string") {
            throw new HttpsError(
                "invalid-argument",
                "audioBase64 must be a non-empty base64 string."
            );
        }

        const languageCode = lang || "en-US";

        try {
            const client = new speech.SpeechClient();

            const [response] = await client.recognize({
                config: {
                    encoding: (encoding as any) || "LINEAR16",
                    sampleRateHertz: sampleRateHertz || 16000,
                    languageCode: languageCode,
                    enableAutomaticPunctuation: true,
                    model: "latest_long",
                },
                audio: {
                    content: audioBase64,
                },
            });

            const transcription = response.results
                ?.map((result) => result.alternatives?.[0]?.transcript || "")
                .join(" ")
                .trim() || "";

            console.log(`speechToText [${languageCode}]: "${transcription.substring(0, 100)}..."`);

            return {
                text: transcription,
                confidence: response.results?.[0]?.alternatives?.[0]?.confidence || 0,
            };
        } catch (error: any) {
            console.error("speechToText error:", error);
            throw new HttpsError("internal", `STT API error: ${error.message}`);
        }
    }
);
