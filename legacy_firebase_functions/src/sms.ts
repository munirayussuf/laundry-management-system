/**
 * SMS delivery.
 *
 * The Flutter application never holds an SMS gateway key. It calls this
 * callable function, which reads the credentials from the Firebase runtime
 * configuration and calls the gateway's REST API.
 *
 * Configure the credentials once, before deploying:
 *
 *   firebase functions:config:set \
 *     sms.username="YOUR_AFRICASTALKING_USERNAME" \
 *     sms.api_key="YOUR_AFRICASTALKING_API_KEY" \
 *     sms.sender_id="YOUR_APPROVED_SENDER_ID"
 *
 *   firebase deploy --only functions:sendSms
 *
 * If you use a different aggregator, change the endpoint and payload below;
 * the rest of the application is unaffected because it only ever speaks to
 * this function.
 */

import * as functions from "firebase-functions";
import axios from "axios";

const SMS_ENDPOINT = "https://api.africastalking.com/version1/messaging";

export const sendSms = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be signed in to send a message."
    );
  }

  const phone: string = data.phone;
  const message: string = data.message;

  if (!phone || !message) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "A phone number and a message are both required."
    );
  }

  const config = functions.config().sms;
  if (!config || !config.api_key || !config.username) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "The SMS gateway has not been configured yet."
    );
  }

  const recipient = phone.startsWith("+")
    ? phone
    : phone.startsWith("0")
    ? `+254${phone.substring(1)}`
    : `+${phone}`;

  try {
    const response = await axios.post(
      SMS_ENDPOINT,
      new URLSearchParams({
        username: config.username,
        to: recipient,
        message,
        ...(config.sender_id ? { from: config.sender_id } : {}),
      }).toString(),
      {
        headers: {
          apiKey: config.api_key,
          "Content-Type": "application/x-www-form-urlencoded",
          Accept: "application/json",
        },
      }
    );

    const recipients = response.data?.SMSMessageData?.Recipients ?? [];
    const delivered = recipients.length > 0 && recipients[0].statusCode < 200 + 200;

    return { success: delivered, detail: response.data?.SMSMessageData?.Message ?? "" };
  } catch (error) {
    functions.logger.error("SMS gateway call failed", error);
    throw new functions.https.HttpsError("internal", "The message could not be delivered.");
  }
});
