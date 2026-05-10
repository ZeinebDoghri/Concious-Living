import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

admin.initializeApp();

const db = admin.firestore();

type CompostQuota = {
  weeklyCompostGoalKg: number;
  weeklyWasteCapKg: number;
};

export const onWasteLogWrite = functions.firestore
  .document("waste_logs/{entityId}/daily/{date}")
  .onWrite(async (change, context) => {
    if (!change.after.exists) return;

    const entityId = context.params.entityId;
    const quota = await getCompostQuota(entityId);
    const isoWeek = getIsoWeek(new Date());
    const weeklySnap = await db
      .collection("compost_totals")
      .doc(entityId)
      .collection("weekly")
      .doc(isoWeek)
      .get();
    const weeklyWaste = Number(weeklySnap.data()?.waste_kg ?? 0);
    const weeklyCompost = Number(weeklySnap.data()?.compostable_kg ?? 0);
    const wastePct = weeklyWaste / Math.max(quota.weeklyWasteCapKg, 1);
    const compostPct = weeklyCompost / Math.max(quota.weeklyCompostGoalKg, 1);

    const tokens = await getEntityTokens(entityId);
    if (tokens.length === 0) return;

    if (wastePct > 1.0) {
      const excess = (weeklyWaste - quota.weeklyWasteCapKg).toFixed(1);
      await sendPush(
        tokens,
        "Seuil waste depasse",
        `Depassement de ${excess} kg cette semaine`,
      );
      await writeAlert(
        entityId,
        "waste_cap_exceeded",
        "critical",
        `Waste depasse de ${excess} kg`,
      );
    } else if (wastePct >= 0.8 && wastePct < 1.0) {
      await sendPush(
        tokens,
        "Approche du seuil waste",
        `${Math.round(wastePct * 100)}% du cap atteint`,
      );
    }

    for (const milestone of [0.5, 0.75, 1.0]) {
      const flag = `milestone_${milestone}_${isoWeek}`;
      const flagDoc = await db.collection("compost_flags").doc(entityId).get();
      if (compostPct >= milestone && !flagDoc.data()?.[flag]) {
        const pct = Math.round(milestone * 100);
        await sendPush(
          tokens,
          `Objectif compost ${pct}%!`,
          milestone === 1.0
            ? "Felicitations ! Objectif hebdomadaire atteint !"
            : `Vous avez atteint ${pct}% de votre objectif compost`,
        );
        await db
          .collection("compost_flags")
          .doc(entityId)
          .set({[flag]: true}, {merge: true});
        if (milestone === 1.0) {
          await db
            .collection("compost_flags")
            .doc(entityId)
            .set({show_confetti: true}, {merge: true});
        }
      }
    }
  });

export const weeklySummary = functions.pubsub
  .schedule("0 8 * * 1")
  .timeZone("Africa/Tunis")
  .onRun(async () => {
    const isoWeek = getPreviousIsoWeek(new Date());
    await sendWeeklySummaries("restaurants", isoWeek);
    await sendWeeklySummaries("hotels", isoWeek);
  });

export const onDailyLogWrite = functions.firestore
  .document("users/{uid}/daily_logs/{date}")
  .onWrite(async (change, context) => {
    const data = change.after.data();
    if (!data) return;

    const uid = context.params.uid;
    const userSnap = await db.collection("users").doc(uid).get();
    const limits = userSnap.data()?.nutrientLimits ?? {};
    const fields: Record<string, string> = {
      cholesterol_mg: "Cholesterol",
      saturated_fat_g: "Graisses saturees",
      sodium_mg: "Sodium",
      sugar_g: "Sucre",
    };

    for (const [key, label] of Object.entries(fields)) {
      const current = Number(data[key] ?? 0);
      const limit = Number(limits[key] ?? 9999);
      const prevCurrent = Number(change.before.data()?.[key] ?? 0);
      if (current >= limit && prevCurrent < limit) {
        const token = userSnap.data()?.fcmToken;
        if (token) {
          await admin.messaging().send({
            token,
            notification: {
              title: "Limite journaliere atteinte",
              body: `Tu as atteint ta limite de ${label} aujourd'hui (${current.toFixed(1)} / ${limit})`,
            },
            data: {route: "/customer/nutrients"},
          });
        }
      }
    }
  });

async function getCompostQuota(entityId: string): Promise<CompostQuota> {
  const restDoc = await db.collection("restaurants").doc(entityId).get();
  if (restDoc.exists) {
    return quotaFrom(restDoc.data()?.compostQuota);
  }
  const hotelDoc = await db.collection("hotels").doc(entityId).get();
  return quotaFrom(hotelDoc.data()?.compostQuota);
}

function quotaFrom(data: FirebaseFirestore.DocumentData | undefined): CompostQuota {
  return {
    weeklyCompostGoalKg: Number(data?.weeklyCompostGoalKg ?? 40),
    weeklyWasteCapKg: Number(data?.weeklyWasteCapKg ?? 30),
  };
}

async function getEntityTokens(entityId: string): Promise<string[]> {
  const users = await db.collection("users").where("entityId", "==", entityId).get();
  const directUser = await db.collection("users").doc(entityId).get();
  const restaurantStaff = await db
    .collection("restaurants")
    .doc(entityId)
    .collection("staff")
    .get();
  const hotelStaff = await db
    .collection("hotels")
    .doc(entityId)
    .collection("staff")
    .get();
  const docs = [
    ...users.docs,
    ...(directUser.exists ? [directUser] : []),
    ...restaurantStaff.docs,
    ...hotelStaff.docs,
  ];
  return [
    ...new Set(
      docs
        .flatMap((d) => {
          const data = d.data() ?? {};
          return [data.fcmToken, data.token];
        })
        .map((token) => String(token ?? ""))
        .filter((token) => token.length > 0),
    ),
  ];
}

async function sendPush(
  tokens: string[],
  title: string,
  body: string,
): Promise<void> {
  if (tokens.length === 0) return;
  await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {title, body},
  });
}

async function writeAlert(
  entityId: string,
  type: string,
  severity: string,
  message: string,
): Promise<void> {
  const isRestaurant = (await db.collection("restaurants").doc(entityId).get()).exists;
  await db
    .collection(isRestaurant ? "restaurants" : "hotels")
    .doc(entityId)
    .collection("alerts")
    .add({
      type,
      severity,
      message,
      itemName: message,
      zone: "General",
      confidence: 100,
      resolved: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
}

async function sendWeeklySummaries(
  collection: "restaurants" | "hotels",
  isoWeek: string,
): Promise<void> {
  const entities = await db.collection(collection).get();
  await Promise.all(
    entities.docs.map(async (entity) => {
      const weeklySnap = await db
        .collection("compost_totals")
        .doc(entity.id)
        .collection("weekly")
        .doc(isoWeek)
        .get();
      const data = weeklySnap.data();
      if (!data) return;
      const compost = Number(data.compostable_kg ?? 0);
      const co2 = Number(data.co2_saved ?? 0);
      const quota = Number(entity.data().compostQuota?.weeklyCompostGoalKg ?? 40);
      const pct = Math.round((compost / Math.max(quota, 1)) * 100);
      const tokens = await getEntityTokens(entity.id);
      await sendPush(
        tokens,
        "Resume hebdomadaire FreshGuard",
        `${compost.toFixed(1)} kg compostes - ${pct}% de l'objectif - ${co2.toFixed(1)} kg CO2 evites`,
      );
    }),
  );
}

function getIsoWeek(d: Date): string {
  const date = new Date(d);
  date.setHours(0, 0, 0, 0);
  date.setDate(date.getDate() + 3 - ((date.getDay() + 6) % 7));
  const week1 = new Date(date.getFullYear(), 0, 4);
  const weekNum =
    1 +
    Math.round(
      ((date.getTime() - week1.getTime()) / 86400000 -
        3 +
        ((week1.getDay() + 6) % 7)) /
        7,
    );
  return `${date.getFullYear()}-W${String(weekNum).padStart(2, "0")}`;
}

function getPreviousIsoWeek(d: Date): string {
  const previous = new Date(d);
  previous.setDate(previous.getDate() - 7);
  return getIsoWeek(previous);
}
