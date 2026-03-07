const admin = require("firebase-admin");
const {onValueCreated} = require("firebase-functions/v2/database");

admin.initializeApp();

exports.pushColdStorageAlert = onValueCreated(
  {
    ref: "/alerts/{alertId}",
    region: "us-central1",
    instance: "foodtracking-2f928-default-rtdb",
  },
  async (event) => {
    const alert = event.data.val();
    if (!alert) {
      return;
    }

    const tokensSnapshot = await admin.database().ref("user_tokens").get();
    if (!tokensSnapshot.exists()) {
      return;
    }

    const tokens = [];
    const tokenTree = tokensSnapshot.val();
    Object.keys(tokenTree).forEach((uid) => {
      Object.keys(tokenTree[uid] || {}).forEach((token) => tokens.push(token));
    });

    if (tokens.length === 0) {
      return;
    }

    const message = {
      notification: {
        title: "Cold Storage Alert",
        body: alert.message || "Condition alert detected.",
      },
      data: {
        storageUnit: String(alert.storage_unit || ""),
        severity: String(alert.severity || "warning"),
        alertId: String(event.params.alertId),
      },
      tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    const invalidTokens = [];
    response.responses.forEach((r, index) => {
      if (!r.success) {
        invalidTokens.push(tokens[index]);
      }
    });

    if (invalidTokens.length > 0) {
      const updates = {};
      Object.keys(tokenTree).forEach((uid) => {
        invalidTokens.forEach((token) => {
          if (tokenTree[uid]?.[token]) {
            updates[`user_tokens/${uid}/${token}`] = null;
          }
        });
      });
      if (Object.keys(updates).length > 0) {
        await admin.database().ref().update(updates);
      }
    }
  },
);
