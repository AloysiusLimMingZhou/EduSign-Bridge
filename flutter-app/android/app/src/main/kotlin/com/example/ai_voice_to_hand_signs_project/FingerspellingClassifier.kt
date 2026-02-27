package com.example.ai_voice_to_hand_signs_project

import kotlin.math.sqrt
import kotlin.math.abs
import kotlin.math.max

/**
 * Geometric Rule-Based ASL Fingerspelling Classifier (A–Z)
 * =========================================================
 * Classifies static ASL fingerspelling letters from a **single frame**
 * of MediaPipe Hand Landmarker output.
 *
 * No TFLite model required. Works on the same wrist-centred, scale-normalised
 * 21-landmark arrays produced by [SignLanguageAnalyzer.normalizeLandmarks].
 *
 * J and Z are excluded (motion letters — not supported in static mode).
 */
object FingerspellingClassifier {

    private const val WRIST = 0
    private const val THUMB_CMC = 1; private const val THUMB_MCP = 2
    private const val THUMB_IP = 3;  private const val THUMB_TIP = 4
    private const val INDEX_MCP = 5; private const val INDEX_PIP = 6
    private const val INDEX_DIP = 7; private const val INDEX_TIP = 8
    private const val MIDDLE_MCP = 9; private const val MIDDLE_PIP = 10
    private const val MIDDLE_DIP = 11; private const val MIDDLE_TIP = 12
    private const val RING_MCP = 13; private const val RING_PIP = 14
    private const val RING_DIP = 15; private const val RING_TIP = 16
    private const val PINKY_MCP = 17; private const val PINKY_PIP = 18
    private const val PINKY_DIP = 19; private const val PINKY_TIP = 20

    private val FINGER_TIPS = intArrayOf(THUMB_TIP, INDEX_TIP, MIDDLE_TIP, RING_TIP, PINKY_TIP)
    private val FINGER_PIPS = intArrayOf(THUMB_IP,  INDEX_PIP, MIDDLE_PIP, RING_PIP, PINKY_PIP)
    private val FINGER_MCPS = intArrayOf(THUMB_MCP, INDEX_MCP, MIDDLE_MCP, RING_MCP, PINKY_MCP)

    data class Result(val letter: Char?, val confidence: Float)

    fun classify(lm: FloatArray, minConf: Float = 0.55f): Result {
        if (isZeroed(lm)) return Result(null, 0f)

        val scores = mutableMapOf<Char, Float>()
        scores['A'] = scoreA(lm); scores['B'] = scoreB(lm)
        scores['C'] = scoreC(lm); scores['D'] = scoreD(lm)
        scores['E'] = scoreE(lm); scores['F'] = scoreF(lm)
        scores['G'] = scoreG(lm); scores['H'] = scoreH(lm)
        scores['I'] = scoreI(lm); scores['K'] = scoreK(lm)
        scores['L'] = scoreL(lm); scores['M'] = scoreM(lm)
        scores['N'] = scoreN(lm); scores['O'] = scoreO(lm)
        scores['P'] = scoreP(lm); scores['Q'] = scoreQ(lm)
        scores['R'] = scoreR(lm); scores['S'] = scoreS(lm)
        scores['T'] = scoreT(lm); scores['U'] = scoreU(lm)
        scores['V'] = scoreV(lm); scores['W'] = scoreW(lm)
        scores['X'] = scoreX(lm); scores['Y'] = scoreY(lm)

        val best = scores.maxByOrNull { it.value }!!
        return if (best.value >= minConf) Result(best.key, best.value)
        else Result(null, best.value)
    }

    private fun x(lm: FloatArray, i: Int) = lm[i * 3]
    private fun y(lm: FloatArray, i: Int) = lm[i * 3 + 1]
    private fun z(lm: FloatArray, i: Int) = lm[i * 3 + 2]

    private fun dist(lm: FloatArray, i: Int, j: Int): Float {
        val dx = x(lm, i) - x(lm, j)
        val dy = y(lm, i) - y(lm, j)
        val dz = z(lm, i) - z(lm, j)
        return sqrt(dx * dx + dy * dy + dz * dz)
    }

    private fun isFingerOpen(lm: FloatArray, f: Int): Boolean {
        if (f == 0) return dist(lm, FINGER_TIPS[0], THUMB_CMC) > 0.40f
        val tipDist = dist(lm, FINGER_TIPS[f], WRIST)
        val pipDist = dist(lm, FINGER_PIPS[f], WRIST)
        return tipDist > pipDist * 0.85f && dist(lm, FINGER_TIPS[f], FINGER_MCPS[f]) > 0.32f
    }

    private fun isExtended(lm: FloatArray, f: Int, threshold: Float = 0.35f): Boolean {
        return dist(lm, FINGER_TIPS[f], FINGER_MCPS[f]) > threshold
    }

    private fun curlRatio(lm: FloatArray, f: Int): Float {
        if (f == 0) {
            val dTip = dist(lm, FINGER_TIPS[0], WRIST)
            val dRef = dist(lm, THUMB_MCP, WRIST)
            if (dRef < 1e-5f) return 0f
            return (1f - dTip / dRef).coerceIn(0f, 1f)
        }
        val dTip = dist(lm, FINGER_TIPS[f], WRIST)
        val dPip = dist(lm, FINGER_PIPS[f], WRIST)
        if (dPip < 1e-5f) return 0f
        return (1f - dTip / dPip).coerceIn(0f, 1f)
    }

    private fun tipsTouching(lm: FloatArray, i: Int, j: Int, threshold: Float = 0.18f): Boolean =
        dist(lm, i, j) < threshold

    private fun fingersSpread(lm: FloatArray, f1: Int, f2: Int, threshold: Float = 0.20f): Boolean =
        dist(lm, FINGER_TIPS[f1], FINGER_TIPS[f2]) > threshold

    private fun thumbIsLateral(lm: FloatArray): Boolean =
        abs(x(lm, THUMB_TIP) - x(lm, INDEX_MCP)) > 0.15f

    private fun thumbAcrossFingers(lm: FloatArray): Boolean {
        val tx = x(lm, THUMB_TIP)
        val ix = x(lm, INDEX_MCP)
        val rx = x(lm, RING_MCP)
        val lo = minOf(ix, rx)
        val hi = maxOf(ix, rx)
        return tx > lo - 0.05f && tx < hi + 0.05f
    }

    private fun fingerTipBelowPip(lm: FloatArray, f: Int): Boolean =
        y(lm, FINGER_TIPS[f]) > y(lm, FINGER_PIPS[f])

    private fun isZeroed(lm: FloatArray): Boolean = lm.all { abs(it) < 1e-5f }


    // ── Per-letter scorers (Matched exactly to Python dataset results) ────────

    private fun scoreA(lm: FloatArray): Float {
        val checks = listOf(
            !isFingerOpen(lm, 1), !isFingerOpen(lm, 2),
            !isFingerOpen(lm, 3), !isFingerOpen(lm, 4),
            thumbIsLateral(lm),
            !thumbAcrossFingers(lm)
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreB(lm: FloatArray): Float {
        val checks = listOf(
            isFingerOpen(lm, 1), isFingerOpen(lm, 2),
            isFingerOpen(lm, 3), isFingerOpen(lm, 4),
            !isExtended(lm, 0, 0.20f),
            !fingersSpread(lm, 1, 2, 0.22f), !fingersSpread(lm, 2, 3, 0.22f)
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreC(lm: FloatArray): Float {
        val thumbIdxGap = dist(lm, THUMB_TIP, INDEX_TIP)
        val checks = listOf(
            isExtended(lm, 0, 0.20f),
            thumbIdxGap > 0.30f,
            thumbIdxGap < 0.80f,
            !fingersSpread(lm, 1, 2, 0.30f),
            !thumbAcrossFingers(lm),
            dist(lm, MIDDLE_TIP, RING_TIP) < 0.30f
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreD(lm: FloatArray): Float {
        val checks = listOf(
            isFingerOpen(lm, 1),
            !isFingerOpen(lm, 2), !isFingerOpen(lm, 3), !isFingerOpen(lm, 4),
            tipsTouching(lm, THUMB_TIP, MIDDLE_TIP, 0.35f) || tipsTouching(lm, THUMB_TIP, MIDDLE_PIP, 0.35f)
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreE(lm: FloatArray): Float {
        val checks = listOf(
            !isFingerOpen(lm, 1), !isFingerOpen(lm, 2),
            !isFingerOpen(lm, 3), !isFingerOpen(lm, 4),
            thumbAcrossFingers(lm),
            y(lm, THUMB_TIP) >= y(lm, INDEX_TIP) - 0.12f
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreF(lm: FloatArray): Float {
        val checks = listOf(
            tipsTouching(lm, THUMB_TIP, INDEX_TIP, 0.28f),
            isFingerOpen(lm, 2), isFingerOpen(lm, 3), isFingerOpen(lm, 4),
            !isFingerOpen(lm, 1)
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreG(lm: FloatArray): Float {
        val idxVX = x(lm, INDEX_TIP) - x(lm, INDEX_MCP)
        val idxVY = y(lm, INDEX_TIP) - y(lm, INDEX_MCP)
        val checks = listOf(
            isExtended(lm, 1), abs(idxVX) > abs(idxVY),
            !isFingerOpen(lm, 2), !isFingerOpen(lm, 3), !isFingerOpen(lm, 4),
            isExtended(lm, 0, 0.15f)
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreH(lm: FloatArray): Float {
        val iVX = abs(x(lm, INDEX_TIP) - x(lm, INDEX_MCP))
        val iVY = abs(y(lm, INDEX_TIP) - y(lm, INDEX_MCP))
        val checks = listOf(
            isExtended(lm, 1), isExtended(lm, 2),
            !isFingerOpen(lm, 3), !isFingerOpen(lm, 4),
            !fingersSpread(lm, 1, 2, 0.25f),
            iVX > iVY
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreI(lm: FloatArray): Float {
        val checks = listOf(
            !isFingerOpen(lm, 1), !isFingerOpen(lm, 2), !isFingerOpen(lm, 3),
            isFingerOpen(lm, 4),
            !thumbIsLateral(lm)
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreK(lm: FloatArray): Float {
        val checks = listOf(
            isFingerOpen(lm, 1), isFingerOpen(lm, 2),
            !isFingerOpen(lm, 3), !isFingerOpen(lm, 4),
            fingersSpread(lm, 1, 2, 0.15f),
            isExtended(lm, 0, 0.20f)
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreL(lm: FloatArray): Float {
        val idxVX = abs(x(lm, INDEX_TIP) - x(lm, INDEX_MCP))
        val idxVY = abs(y(lm, INDEX_TIP) - y(lm, INDEX_MCP))
        val checks = listOf(
            isFingerOpen(lm, 1), !isFingerOpen(lm, 2),
            !isFingerOpen(lm, 3), !isFingerOpen(lm, 4),
            isExtended(lm, 0, 0.25f), thumbIsLateral(lm),
            idxVY > idxVX
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreM(lm: FloatArray): Float {
        val checks = listOf(
            !isFingerOpen(lm, 1), !isFingerOpen(lm, 2),
            !isFingerOpen(lm, 3), !isFingerOpen(lm, 4),
            thumbIsLateral(lm),
            thumbAcrossFingers(lm),
            (y(lm, MIDDLE_TIP) - y(lm, THUMB_TIP)) > 0.18f,
            abs(y(lm, RING_TIP) - y(lm, MIDDLE_TIP)) < 0.12f
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreN(lm: FloatArray): Float {
        val checks = listOf(
            !isFingerOpen(lm, 1), !isFingerOpen(lm, 2),
            !isFingerOpen(lm, 3), !isFingerOpen(lm, 4),
            thumbIsLateral(lm),
            thumbAcrossFingers(lm),
            (y(lm, MIDDLE_TIP) - y(lm, THUMB_TIP)) > 0.18f,
            (y(lm, RING_TIP) - y(lm, MIDDLE_TIP)) > 0.15f
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreO(lm: FloatArray): Float {
        val thumbIdxDist = dist(lm, THUMB_TIP, INDEX_TIP)
        val checks = listOf(
            thumbIdxDist < 0.28f,
            dist(lm, THUMB_TIP, MIDDLE_TIP) < 0.35f,
            !thumbAcrossFingers(lm)
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreP(lm: FloatArray): Float {
        val idxVY = y(lm, INDEX_TIP) - y(lm, INDEX_MCP)
        val checks = listOf(
            isExtended(lm, 1), isExtended(lm, 2),
            !isFingerOpen(lm, 3), !isFingerOpen(lm, 4),
            idxVY > 0.08f
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreQ(lm: FloatArray): Float {
        val idxVY = y(lm, INDEX_TIP) - y(lm, INDEX_MCP)
        val checks = listOf(
            isExtended(lm, 1), idxVY > 0.08f,
            !isFingerOpen(lm, 2), !isFingerOpen(lm, 3), !isFingerOpen(lm, 4)
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreR(lm: FloatArray): Float {
        val checks = listOf(
            isExtended(lm, 1), isExtended(lm, 2),
            !isFingerOpen(lm, 3), !isFingerOpen(lm, 4),
            dist(lm, INDEX_TIP, MIDDLE_TIP) < 0.15f,
            dist(lm, INDEX_TIP, MIDDLE_TIP) < dist(lm, INDEX_MCP, MIDDLE_MCP) - 0.02f
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreS(lm: FloatArray): Float {
        val checks = listOf(
            !isFingerOpen(lm, 1), !isFingerOpen(lm, 2),
            !isFingerOpen(lm, 3), !isFingerOpen(lm, 4),
            thumbAcrossFingers(lm),
            dist(lm, THUMB_TIP, MIDDLE_PIP) < 0.30f,
            (y(lm, MIDDLE_TIP) - y(lm, THUMB_TIP)) < 0.18f,
            dist(lm, THUMB_TIP, MIDDLE_PIP) < dist(lm, THUMB_TIP, INDEX_PIP) + 0.02f
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreT(lm: FloatArray): Float {
        val checks = listOf(
            !isFingerOpen(lm, 1), !isFingerOpen(lm, 2),
            !isFingerOpen(lm, 3), !isFingerOpen(lm, 4),
            thumbAcrossFingers(lm),
            dist(lm, THUMB_TIP, INDEX_PIP) < 0.20f,
            dist(lm, THUMB_TIP, INDEX_PIP) < dist(lm, THUMB_TIP, MIDDLE_PIP) - 0.02f
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreU(lm: FloatArray): Float {
        val idxMidDist = dist(lm, INDEX_TIP, MIDDLE_TIP)
        val checks = listOf(
            isFingerOpen(lm, 1), isFingerOpen(lm, 2),
            !isFingerOpen(lm, 3), !isFingerOpen(lm, 4),
            idxMidDist < 0.20f,
            dist(lm, INDEX_TIP, MIDDLE_TIP) >= dist(lm, INDEX_MCP, MIDDLE_MCP) - 0.02f
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreV(lm: FloatArray): Float {
        val idxMidDist = dist(lm, INDEX_TIP, MIDDLE_TIP)
        val checks = listOf(
            isFingerOpen(lm, 1), isFingerOpen(lm, 2),
            !isFingerOpen(lm, 3), !isFingerOpen(lm, 4),
            idxMidDist > 0.18f,
            fingersSpread(lm, 1, 2, 0.18f)
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreW(lm: FloatArray): Float {
        val checks = listOf(
            isFingerOpen(lm, 1), isFingerOpen(lm, 2), isFingerOpen(lm, 3),
            !isFingerOpen(lm, 4),
            fingersSpread(lm, 1, 2, 0.15f), fingersSpread(lm, 2, 3, 0.15f)
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreX(lm: FloatArray): Float {
        val tipHooked = y(lm, INDEX_TIP) > y(lm, INDEX_DIP) - 0.05f
        val checks = listOf(
            dist(lm, INDEX_PIP, WRIST) > 0.30f,
            tipHooked,
            !isFingerOpen(lm, 2), !isFingerOpen(lm, 3), !isFingerOpen(lm, 4),
            !isFingerOpen(lm, 1),
            !thumbAcrossFingers(lm)
        )
        return checks.count { it }.toFloat() / checks.size
    }

    private fun scoreY(lm: FloatArray): Float {
        val checks = listOf(
            isExtended(lm, 0, 0.25f), thumbIsLateral(lm),
            !isFingerOpen(lm, 1), !isFingerOpen(lm, 2), !isFingerOpen(lm, 3),
            isFingerOpen(lm, 4),
            dist(lm, THUMB_TIP, PINKY_TIP) > 0.50f
        )
        return checks.count { it }.toFloat() / checks.size
    }
}
