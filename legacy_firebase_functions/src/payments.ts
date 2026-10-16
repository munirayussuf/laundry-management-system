/**
 * Mobile money payments.
 *
 * Two functions work together:
 *
 *  initiateMobileMoneyPayment  called by the Flutter application, pushes a
 *                              payment prompt to the customer's handset.
 *  mpesaCallback               called by the payment provider once the
 *                              customer approves or declines. This is the
 *                              only place where a payment is ever marked
 *                              paid, which is why the application cannot
 *                              fake a successful payment.
 *
 * Configure the credentials before deploying:
 *
 *   firebase functions:config:set \
 *     mpesa.consumer_key="YOUR_CONSUMER_KEY" \
 *     mpesa.consumer_secret="YOUR_CONSUMER_SECRET" \
 *     mpesa.passkey="YOUR_PASSKEY" \
 *     mpesa.shortcode="YOUR_SHORTCODE" \
 *     mpesa.env="sandbox" \
 *     mpesa.callback_url="https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/mpesaCallback"
 *
 *   firebase deploy --only functions:initiateMobileMoneyPayment,functions:mpesaCallback
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

function baseUrl(): string {
  const env = functions.config().mpesa?.env ?? "sandbox";
  return env === "production"
    ? "https://api.safaricom.co.ke"
    : "https://sandbox.safaricom.co.ke";
}

async function fetchAccessToken(): Promise<string> {
  const config = functions.config().mpesa;
  const credentials = Buffer.from(
    `${config.consumer_key}:${config.consumer_secret}`
  ).toString("base64");

  const response = await axios.get(
    `${baseUrl()}/oauth/v1/generate?grant_type=client_credentials`,
    { headers: { Authorization: `Basic ${credentials}` } }
  );
  return response.data.access_token;
}

function timestamp(): string {
  const now = new Date();
  const pad = (n: number) => String(n).padStart(2, "0");
  return (
    String(now.getFullYear()) +
    pad(now.getMonth() + 1) +
    pad(now.getDate()) +
    pad(now.getHours()) +
    pad(now.getMinutes()) +
    pad(now.getSeconds())
  );
}

export const initiateMobileMoneyPayment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "You must be signed in to pay.");
  }

  const config = functions.config().mpesa;
  if (!config || !config.consumer_key || !config.shortcode) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "The mobile money gateway has not been configured yet."
    );
  }

  const { paymentId, phone, amount } = data;
  if (!paymentId || !phone || !amount) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "A payment reference, phone number and amount are required."
    );
  }

  const normalisedPhone = phone.startsWith("0") ? `254${phone.substring(1)}` : phone.replace("+", "");
  const stamp = timestamp();
  const password = Buffer.from(`${config.shortcode}${config.passkey}${stamp}`).toString("base64");

  try {
    const token = await fetchAccessToken();
    const response = await axios.post(
      `${baseUrl()}/mpesa/stkpush/v1/processrequest`,
      {
        BusinessShortCode: config.shortcode,
        Password: password,
        Timestamp: stamp,
        TransactionType: "CustomerPayBillOnline",
        Amount: Math.round(Number(amount)),
        PartyA: normalisedPhone,
        PartyB: config.shortcode,
        PhoneNumber: normalisedPhone,
        CallBackURL: config.callback_url,
        AccountReference: paymentId.substring(0, 12),
        TransactionDesc: "Laundry service payment",
      },
      { headers: { Authorization: `Bearer ${token}` } }
    );

    // Store the gateway's checkout id so the callback can find this payment.
    await db.collection("payments").doc(paymentId).update({
      providerReference: response.data.CheckoutRequestID ?? null,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    return { success: true, checkoutRequestId: response.data.CheckoutRequestID };
  } catch (error) {
    functions.logger.error("Mobile money initiation failed", error);
    await db.collection("payments").doc(paymentId).update({
      status: "failed",
      failureReason: "The payment could not be started. Please try again.",
      updatedAt: admin.firestore.Timestamp.now(),
    });
    throw new functions.https.HttpsError("internal", "The payment could not be started.");
  }
});

export const mpesaCallback = functions.https.onRequest(async (req, res) => {
  try {
    const callback = req.body?.Body?.stkCallback;
    if (!callback) {
      res.status(400).send({ ResultCode: 1, ResultDesc: "Malformed callback" });
      return;
    }

    const checkoutRequestId = callback.CheckoutRequestID;
    const resultCode = Number(callback.ResultCode);

    const snapshot = await db
      .collection("payments")
      .where("providerReference", "==", checkoutRequestId)
      .limit(1)
      .get();

    if (snapshot.empty) {
      functions.logger.warn("No payment found for checkout id", checkoutRequestId);
      res.status(200).send({ ResultCode: 0, ResultDesc: "Accepted" });
      return;
    }

    const paymentDoc = snapshot.docs[0];
    const payment = paymentDoc.data();
    const now = admin.firestore.Timestamp.now();

    if (resultCode === 0) {
      await paymentDoc.ref.update({ status: "paid", updatedAt: now });
      await db.collection("orders").doc(payment.orderId).update({
        paymentStatus: "paid",
        updatedAt: now,
      });
      await db.collection("notifications").add({
        userId: payment.customerId,
        title: "Payment Confirmed",
        body: `Your payment of KES ${payment.amount} has been received.`,
        type: "paymentConfirmation",
        relatedOrderId: payment.orderId,
        isRead: false,
        createdAt: now,
      });
    } else {
      await paymentDoc.ref.update({
        status: "failed",
        failureReason: callback.ResultDesc ?? "The payment was not completed.",
        updatedAt: now,
      });
      await db.collection("orders").doc(payment.orderId).update({
        paymentStatus: "failed",
        updatedAt: now,
      });
    }

    res.status(200).send({ ResultCode: 0, ResultDesc: "Accepted" });
  } catch (error) {
    functions.logger.error("Payment callback failed", error);
    res.status(200).send({ ResultCode: 0, ResultDesc: "Accepted" });
  }
});
