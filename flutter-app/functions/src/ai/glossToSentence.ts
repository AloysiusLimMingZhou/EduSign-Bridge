/**
 * glossToSentence — HTTPS Callable
 * Takes raw gloss words (e.g., ["HELLO", "HOW", "YOU"]) and uses Gemini
 * to convert them into a natural English sentence.
 * 
 * Optionally accepts an `emotion` parameter to make the sentence
 * reflect the signer's detected emotional tone.
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { VertexAI } from "@google-cloud/vertexai";

const PROJECT_ID = "ai-real-time-voice-to-sign";
const LOCATION = "asia-southeast1";
const MODEL = "gemini-2.5-flash";

export const glossToSentence = onCall(
    { region: LOCATION, memory: "512MiB", timeoutSeconds: 60 },
    async (request) => {
        // Ensure user is authenticated
        if (!request.auth) {
            throw new HttpsError("unauthenticated", "User must be authenticated.");
        }

        const { glossWords, lang, emotion } = request.data as {
            glossWords: string[];
            lang?: string;
            emotion?: string;
        };

        if (!glossWords || !Array.isArray(glossWords) || glossWords.length === 0) {
            throw new HttpsError(
                "invalid-argument",
                "glossWords must be a non-empty array of strings."
            );
        }

        const language = lang || "en";

        try {
            const vertexAI = new VertexAI({ project: PROJECT_ID, location: LOCATION });
            const model = vertexAI.getGenerativeModel({ model: MODEL });

            // Build emotion context if provided
            let emotionContext = "";
            if (emotion && emotion !== "neutral") {
                const emotionDescriptions: Record<string, string> = {
                    "happy": "The signer appears happy and cheerful. Make the sentence sound warm and positive.",
                    "angry": "The signer appears frustrated or angry. Make the sentence sound firm and assertive.",
                    "down": "The signer appears sad or down. Make the sentence sound empathetic and gentle.",
                    "confused": "The signer appears confused or uncertain. Make the sentence reflect this uncertainty naturally.",
                    "questioning": "The signer appears to be asking a question or being inquisitive. Frame the sentence as a question if appropriate.",
                };
                emotionContext = emotionDescriptions[emotion] || "";
            }

            const prompt = `You are a sign language interpreter assistant. Convert the following sign language gloss or fingerspelled letter sequence into a natural, grammatically correct ${language} sentence. 

Input sequence: ${glossWords.join(" ")}
${emotionContext ? `\nEmotional context: ${emotionContext}` : ""}

Rules:
1. Output ONLY the natural sentence or word, nothing else. Do not add quotes, markdown formatting, or explanations.
2. If the input consists mostly of single letters (e.g., "H E L L O", "A P P L E"), concatenate them into the intended word.
3. If the input contains a mix of spelled words and gloss signs, combine them logically (e.g., "MY N A M E I S B O B" -> "My name is Bob").
4. Correct any obvious misspellings that might occur during fast fingerspelling (e.g., "A P L E" -> "Apple", "H E L L L O" -> "Hello").
5. Make the sentence sound natural and conversational.
6. If an emotional context is provided, subtly reflect it in word choice and tone if the input is a full sentence.`;

            const result = await model.generateContent(prompt);
            const response = result.response;
            const sentence =
                response.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || "";

            console.log(
                `glossToSentence: [${glossWords.join(", ")}] (emotion: ${emotion || "none"}) → "${sentence}"`
            );

            return { sentence };
        } catch (error: any) {
            console.error("glossToSentence error:", error);
            throw new HttpsError("internal", `Gemini API error: ${error.message}`);
        }
    }
);
