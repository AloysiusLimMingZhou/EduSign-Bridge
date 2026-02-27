/**
 * sentenceToGloss — HTTPS Callable
 * Takes a natural sentence and uses Gemini to convert it into
 * sign language gloss words for video lookup.
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { VertexAI } from "@google-cloud/vertexai";

const PROJECT_ID = "ai-real-time-voice-to-sign";
const LOCATION = "asia-southeast1";
const MODEL = "gemini-2.5-flash";

export const sentenceToGloss = onCall(
    { region: LOCATION, memory: "512MiB", timeoutSeconds: 60 },
    async (request) => {
        if (!request.auth) {
            throw new HttpsError("unauthenticated", "User must be authenticated.");
        }

        const { sentence, lang } = request.data as {
            sentence: string;
            lang?: string;
        };

        if (!sentence || typeof sentence !== "string" || sentence.trim() === "") {
            throw new HttpsError(
                "invalid-argument",
                "sentence must be a non-empty string."
            );
        }

        const language = lang || "en";

        try {
            const vertexAI = new VertexAI({ project: PROJECT_ID, location: LOCATION });
            const model = vertexAI.getGenerativeModel({ model: MODEL });

            const prompt = `You are a sign language interpreter assistant. Convert the following ${language} sentence into sign language gloss notation.

Sentence: "${sentence}"

Rules:
- Output ONLY the gloss words separated by spaces, nothing else.
- Use UPPERCASE for all gloss words.
- Remove articles (a, an, the), prepositions, and other function words that don't have sign equivalents.
- Keep the core meaning words in their base form.
- Use common ASL gloss conventions.

Example input: "How are you doing today?"
Example output: HOW YOU TODAY

Now convert the sentence above:`;

            const result = await model.generateContent(prompt);
            const response = result.response;
            const glossText =
                response.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || "";

            // Parse into array
            const glossWords = glossText
                .split(/\s+/)
                .map((w: string) => w.toUpperCase().replace(/[^A-Z_]/g, ""))
                .filter((w: string) => w.length > 0);

            console.log(`sentenceToGloss: "${sentence}" → [${glossWords.join(", ")}]`);

            return { glossWords };
        } catch (error: any) {
            console.error("sentenceToGloss error:", error);
            throw new HttpsError("internal", `Gemini API error: ${error.message}`);
        }
    }
);
