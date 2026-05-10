import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

admin.initializeApp();

const db = admin.firestore();

type CompostQuota = {
  weeklyCompostGoalKg: number;
  weeklyWasteCapKg: number;
};

function isoWeek(): string {
  const now = new Date();
  const dayOfYear = Math.floor(
    (now.getTime() - new Date(now.getFullYear(), 0, 1).getTime()) / 86400000,
  ) + 1;
  const weekNum = Math.floor((dayOfYear - now.getDay() + 10) / 7);
  return `${now.getFullYear()}-W${String(weekNum).padStart(2, '0')}`;
}

async function getTokens(entityId: string): Promise<string[]> {
  const snap = await db
    .collection('users')
    .where('entityId', '==', entityId)
    .get();

  return snap.docs
    .map((doc) => doc.data().fcmToken)
    .filter((token): token is string => Boolean(token));
}

async function push(tokens: string[], title: string, body: string) {
  if (!tokens.length) return;
  await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {title, body},
  });
}

function quotaFrom(data: FirebaseFirestore.DocumentData | undefined): CompostQuota {
  return {
    weeklyCompostGoalKg: Number(data?.weeklyCompostGoalKg ?? 40),
    weeklyWasteCapKg: Number(data?.weeklyWasteCapKg ?? 30),
  };
}

async function getCompostQuota(entityId: string): Promise<CompostQuota> {
  const restDoc = await db.collection('restaurants').doc(entityId).get();
  if (restDoc.exists) {
    return quotaFrom(restDoc.data()?.compostQuota);
  }

  const hotelDoc = await db.collection('hotels').doc(entityId).get();
  return quotaFrom(hotelDoc.data()?.compostQuota);
}

export const onWasteLogWrite = functions.firestore
  .document('waste_logs/{entityId}/daily/{date}')
  .onWrite(async (change, context) => {
    if (!change.after.exists) return;

    const entityId = context.params.entityId as string;
    const quota = await getCompostQuota(entityId);
    const weekId = isoWeek();

    const weeklySnap = await db
      .collection('compost_totals')
      .doc(entityId)
      .collection('weekly')
      .doc(weekId)
      .get();

    const weeklyWaste = Number(weeklySnap.data()?.waste_kg ?? 0);
    const weeklyCompost = Number(weeklySnap.data()?.compostable_kg ?? 0);
    const wastePct = weeklyWaste / Math.max(quota.weeklyWasteCapKg, 1);
    const compostPct = weeklyCompost / Math.max(quota.weeklyCompostGoalKg, 1);

    const tokens = await getTokens(entityId);
    if (tokens.length === 0) return;

    if (wastePct > 1.0) {
      const excess = (weeklyWaste - quota.weeklyWasteCapKg).toFixed(1);
      await push(
        tokens,
        'Waste cap exceeded',
        `${excess} kg over the weekly limit`,
      );
    } else if (wastePct >= 0.8) {
      await push(
        tokens,
        'Approaching waste cap',
        `${Math.round(wastePct * 100)}% of the weekly cap reached`,
      );
    }

    for (const milestone of [0.5, 0.75, 1.0]) {
      const flag = `m_${milestone}_${weekId}`;
      const flagDoc = await db.collection('compost_flags').doc(entityId).get();
      if (compostPct >= milestone && !flagDoc.data()?.[flag]) {
        const pct = Math.round(milestone * 100);
        await push(
          tokens,
          milestone === 1.0 ? 'Compost goal reached!' : `${pct}% compost goal`,
          milestone === 1.0
            ? 'Congratulations. Weekly goal achieved.'
            : `You have reached ${pct}% of your compost goal`,
        );
        await db
          .collection('compost_flags')
          .doc(entityId)
          .set({[flag]: true}, {merge: true});
      }
    }
  });

export const weeklySummary = functions.pubsub
  .schedule('0 8 * * 1')
  .timeZone('Africa/Tunis')
  .onRun(async () => {
    const week = isoWeek();
    const restaurants = await db.collection('restaurants').get();

    for (const rest of restaurants.docs) {
      const snap = await db
        .collection('compost_totals')
        .doc(rest.id)
        .collection('weekly')
        .doc(week)
        .get();

      const composted = Number(snap.data()?.compostable_kg ?? 0);
      const goal = Number(rest.data().compostQuota?.weeklyCompostGoalKg ?? 40);
      const pct = Math.round((composted / Math.max(goal, 1)) * 100);
      const tokens = await getTokens(rest.id);

      await push(
        tokens,
        'Weekly FreshGuard Summary',
        `${composted.toFixed(1)} kg composted - ${pct}% of goal`,
      );
    }
  });

export const onDailyLogWrite = functions.firestore
  .document('users/{uid}/daily_logs/{date}')
  .onWrite(async (change, context) => {
    const after = change.after.data() ?? {};
    const before = change.before.data() ?? {};
    const uid = context.params.uid as string;

    const userSnap = await db.collection('users').doc(uid).get();
    const limits = userSnap.data()?.nutrientLimits ?? {};
    const token = userSnap.data()?.fcmToken;
    if (!token) return;

    const fields: Record<string, string> = {
      cholesterol_mg: 'Cholesterol',
      saturated_fat_g: 'Saturated Fat',
      sodium_mg: 'Sodium',
      sugar_g: 'Sugar',
    };

    for (const [key, label] of Object.entries(fields)) {
      const current = Number(after[key] ?? 0);
      const prev = Number(before[key] ?? 0);
      const limit = Number(limits[key] ?? 9999);
      if (current >= limit && prev < limit) {
        await admin.messaging().send({
          token,
          notification: {
            title: 'Daily limit reached',
            body: `You reached your ${label} limit today (${current.toFixed(
              1,
            )} / ${limit})`,
          },
          data: {route: '/customer/nutrients'},
        });
      }
    }
  });
