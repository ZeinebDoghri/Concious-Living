"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onDailyLogWrite = exports.weeklySummary = exports.onWasteLogWrite = void 0;
const admin = require("firebase-admin");
const functions = require("firebase-functions");
admin.initializeApp();
const db = admin.firestore();
function isoWeek() {
    const now = new Date();
    const dayOfYear = Math.floor((now.getTime() - new Date(now.getFullYear(), 0, 1).getTime()) / 86400000) + 1;
    const weekNum = Math.floor((dayOfYear - now.getDay() + 10) / 7);
    return `${now.getFullYear()}-W${String(weekNum).padStart(2, '0')}`;
}
async function getTokens(entityId) {
    const snap = await db
        .collection('users')
        .where('entityId', '==', entityId)
        .get();
    return snap.docs
        .map((doc) => doc.data().fcmToken)
        .filter((token) => Boolean(token));
}
async function push(tokens, title, body) {
    if (!tokens.length)
        return;
    await admin.messaging().sendEachForMulticast({
        tokens,
        notification: { title, body },
    });
}
function quotaFrom(data) {
    var _a, _b;
    return {
        weeklyCompostGoalKg: Number((_a = data === null || data === void 0 ? void 0 : data.weeklyCompostGoalKg) !== null && _a !== void 0 ? _a : 40),
        weeklyWasteCapKg: Number((_b = data === null || data === void 0 ? void 0 : data.weeklyWasteCapKg) !== null && _b !== void 0 ? _b : 30),
    };
}
async function getCompostQuota(entityId) {
    var _a, _b;
    const restDoc = await db.collection('restaurants').doc(entityId).get();
    if (restDoc.exists) {
        return quotaFrom((_a = restDoc.data()) === null || _a === void 0 ? void 0 : _a.compostQuota);
    }
    const hotelDoc = await db.collection('hotels').doc(entityId).get();
    return quotaFrom((_b = hotelDoc.data()) === null || _b === void 0 ? void 0 : _b.compostQuota);
}
exports.onWasteLogWrite = functions.firestore
    .document('waste_logs/{entityId}/daily/{date}')
    .onWrite(async (change, context) => {
    var _a, _b, _c, _d, _e;
    if (!change.after.exists)
        return;
    const entityId = context.params.entityId;
    const quota = await getCompostQuota(entityId);
    const weekId = isoWeek();
    const weeklySnap = await db
        .collection('compost_totals')
        .doc(entityId)
        .collection('weekly')
        .doc(weekId)
        .get();
    const weeklyWaste = Number((_b = (_a = weeklySnap.data()) === null || _a === void 0 ? void 0 : _a.waste_kg) !== null && _b !== void 0 ? _b : 0);
    const weeklyCompost = Number((_d = (_c = weeklySnap.data()) === null || _c === void 0 ? void 0 : _c.compostable_kg) !== null && _d !== void 0 ? _d : 0);
    const wastePct = weeklyWaste / Math.max(quota.weeklyWasteCapKg, 1);
    const compostPct = weeklyCompost / Math.max(quota.weeklyCompostGoalKg, 1);
    const tokens = await getTokens(entityId);
    if (tokens.length === 0)
        return;
    if (wastePct > 1.0) {
        const excess = (weeklyWaste - quota.weeklyWasteCapKg).toFixed(1);
        await push(tokens, 'Waste cap exceeded', `${excess} kg over the weekly limit`);
    }
    else if (wastePct >= 0.8) {
        await push(tokens, 'Approaching waste cap', `${Math.round(wastePct * 100)}% of the weekly cap reached`);
    }
    for (const milestone of [0.5, 0.75, 1.0]) {
        const flag = `m_${milestone}_${weekId}`;
        const flagDoc = await db.collection('compost_flags').doc(entityId).get();
        if (compostPct >= milestone && !((_e = flagDoc.data()) === null || _e === void 0 ? void 0 : _e[flag])) {
            const pct = Math.round(milestone * 100);
            await push(tokens, milestone === 1.0 ? 'Compost goal reached!' : `${pct}% compost goal`, milestone === 1.0
                ? 'Congratulations. Weekly goal achieved.'
                : `You have reached ${pct}% of your compost goal`);
            await db
                .collection('compost_flags')
                .doc(entityId)
                .set({ [flag]: true }, { merge: true });
        }
    }
});
exports.weeklySummary = functions.pubsub
    .schedule('0 8 * * 1')
    .timeZone('Africa/Tunis')
    .onRun(async () => {
    var _a, _b, _c, _d;
    const week = isoWeek();
    const restaurants = await db.collection('restaurants').get();
    for (const rest of restaurants.docs) {
        const snap = await db
            .collection('compost_totals')
            .doc(rest.id)
            .collection('weekly')
            .doc(week)
            .get();
        const composted = Number((_b = (_a = snap.data()) === null || _a === void 0 ? void 0 : _a.compostable_kg) !== null && _b !== void 0 ? _b : 0);
        const goal = Number((_d = (_c = rest.data().compostQuota) === null || _c === void 0 ? void 0 : _c.weeklyCompostGoalKg) !== null && _d !== void 0 ? _d : 40);
        const pct = Math.round((composted / Math.max(goal, 1)) * 100);
        const tokens = await getTokens(rest.id);
        await push(tokens, 'Weekly FreshGuard Summary', `${composted.toFixed(1)} kg composted - ${pct}% of goal`);
    }
});
exports.onDailyLogWrite = functions.firestore
    .document('users/{uid}/daily_logs/{date}')
    .onWrite(async (change, context) => {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    const after = (_a = change.after.data()) !== null && _a !== void 0 ? _a : {};
    const before = (_b = change.before.data()) !== null && _b !== void 0 ? _b : {};
    const uid = context.params.uid;
    const userSnap = await db.collection('users').doc(uid).get();
    const limits = (_d = (_c = userSnap.data()) === null || _c === void 0 ? void 0 : _c.nutrientLimits) !== null && _d !== void 0 ? _d : {};
    const token = (_e = userSnap.data()) === null || _e === void 0 ? void 0 : _e.fcmToken;
    if (!token)
        return;
    const fields = {
        cholesterol_mg: 'Cholesterol',
        saturated_fat_g: 'Saturated Fat',
        sodium_mg: 'Sodium',
        sugar_g: 'Sugar',
    };
    for (const [key, label] of Object.entries(fields)) {
        const current = Number((_f = after[key]) !== null && _f !== void 0 ? _f : 0);
        const prev = Number((_g = before[key]) !== null && _g !== void 0 ? _g : 0);
        const limit = Number((_h = limits[key]) !== null && _h !== void 0 ? _h : 9999);
        if (current >= limit && prev < limit) {
            await admin.messaging().send({
                token,
                notification: {
                    title: 'Daily limit reached',
                    body: `You reached your ${label} limit today (${current.toFixed(1)} / ${limit})`,
                },
                data: { route: '/customer/nutrients' },
            });
        }
    }
});
//# sourceMappingURL=index.js.map