// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Send push notification
exports.sendPushNotification = functions.firestore
    .document("user_notifications/{userId}/notifications/{notificationId}")
    .onCreate(async (snap, context) => {
      const notification = snap.data();
      const userId = context.params.userId;

      try {
        // Get user settings
        const settingsDoc = await admin.firestore()
            .collection("user_settings")
            .doc(userId)
            .get();

        const settings = settingsDoc.data();

        // Check if push notifications are enabled
        if (!settings || !settings.pushNotifications) {
          console.log(
              `Push notifications disabled for user ${userId}`,
          );
          return null;
        }

        // Get FCM token
        const tokenDoc = await admin.firestore()
            .collection("user_tokens")
            .doc(userId)
            .get();

        const tokenData = tokenDoc.data();
        const fcmToken = tokenData && tokenData.fcmToken;

        if (!fcmToken) {
          console.log(`No FCM token found for user ${userId}`);
          return null;
        }

        // Prepare notification message
        const message = {
          notification: {
            title: notification.title || "FitWise",
            body: notification.body || "",
          },
          data: {
            type: notification.type || "general",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          token: fcmToken,
        };

        // Send notification
        await admin.messaging().send(message);
        console.log(`Push notification sent to user ${userId}`);

        return null;
      } catch (error) {
        console.error("Error sending push notification:", error);
        return null;
      }
    });
