/**
 * Cloud Functions entry point.
 * Exports all callable and trigger functions.
 */

// Auth triggers
export { onUserCreated } from "./auth/onUserCreated";

// AI functions (Gemini)
export { glossToSentence } from "./ai/glossToSentence";
export { sentenceToGloss } from "./ai/sentenceToGloss";

// Vertex AI STT/TTS
export { speechToText } from "./ai/speechToText";
export { textToSpeech } from "./ai/textToSpeech";

// Translation
export { translateText } from "./translation/translateText";

// Sign video lookup
export { lookupSignVideos } from "./signs/lookupSignVideos";
