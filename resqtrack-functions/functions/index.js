// Import the necessary Firebase modules
const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize the Firebase Admin SDK
admin.initializeApp();

/**
 * Cloud Function that triggers when a new document is created in the 'alerts' collection.
 * It sends a push notification to all users.
 */
exports.sendAlertNotification = functions.firestore
  .document("alerts/{alertId}")
  .onCreate(async (snapshot, context) => {
    // 1. Get the data from the newly created alert document
    const alertData = snapshot.data();
    const alertTitle = alertData.title;
    const alertDescription = alertData.description;

    console.log(`New alert created: "${alertTitle}". Preparing to send notifications.`);

    // 2. Prepare the notification payload
    const payload = {
      notification: {
        title: `🚨 Emergency Alert: ${alertTitle}`,
        body: alertDescription,
        sound: "default", // Use the default notification sound on the device
      },
      // You can also send additional data to the app
      data: {
        alertId: context.params.alertId,
        click_action: "FLUTTER_NOTIFICATION_CLICK", // Important for Flutter
      },
    };

    // 3. Get all documents from the 'users' collection
    const usersSnapshot = await admin.firestore().collection("users").get();

    // 4. Extract the FCM tokens from each user document
    const tokens = [];
    usersSnapshot.forEach((doc) => {
      const user = doc.data();
      // Add the token only if it exists and is not empty
      if (user.fcmToken && user.fcmToken.length > 0) {
        tokens.push(user.fcmToken);
      }
    });

    // 5. Check if there are any tokens to send to
    if (tokens.length === 0) {
      console.log("No user tokens found. No notifications were sent.");
      return null;
    }

    console.log(`Found ${tokens.length} tokens. Sending notifications...`);

    try {
      // 6. Send the notification to all collected tokens
      const response = await admin.messaging().sendToDevice(tokens, payload);
      console.log("Successfully sent notifications:", response);

      // Optional: Clean up invalid tokens
      response.results.forEach((result, index) => {
        const error = result.error;
        if (error) {
          console.error("Failure sending notification to", tokens[index], error);
          // If a token is invalid, you might want to remove it from the user's document
          if (
            error.code === "messaging/invalid-registration-token" ||
            error.code === "messaging/registration-token-not-registered"
          ) {
            // Here you could write code to find the user with this token and remove it
          }
        }
      });

      return response;
    } catch (error) {
      console.error("Error sending notifications:", error);
      return null;
    }
  });
