import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

exports.sendStepCountNotificationTest = functions.firestore
  .document("userID_tokens/{totalSteps}")
  .onUpdate(async (change, context) => {
    const newValue = change.after.data();
    const previousValue = change.before.data();
    if (Math.abs(newValue.totalSteps - previousValue.totalSteps) === 100) {
      var payload = {
        notification: {
          title: "Step Count Milestone!",
          body:
            "You have reached a new milestone" +
            newValue.totalSteps +
            " steps!",
          sound: "default",
          channel_id: "step_milestone_channel",
          android_channel_id: "step_milestone_channel",
          priority: "high",
        },
      };
      try {
        const response = await admin
          .messaging()
          .sendToDevice(newValue.FCMtoken, payload);
        console.log("Notification sent successfully:", response);
      } catch (error) {
        console.log("Error sending notification:", error);
      }
    }
  });
