/**
 * USSD gateway handler.
 *
 * This is the piece that makes the service usable from a feature phone with
 * no internet connection. It is a plain HTTPS endpoint, because a USSD
 * aggregator (Africa's Talking, or a Safaricom approved aggregator) posts to
 * a URL that you register with them. Firebase on its own is not a USSD
 * gateway; the aggregator owns the shortcode and relays each keypress here.
 *
 * Register this deployed URL with your aggregator as the callback URL:
 *   https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/ussd
 *
 * Africa's Talking posts the following form encoded fields on every step:
 *   sessionId, serviceCode, phoneNumber, text
 * where "text" accumulates every input the caller has typed, joined by "*".
 *
 * The response body must be plain text beginning with either:
 *   CON   the session continues and expects more input
 *   END   the session is finished and the message is the final screen
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

type ProviderDoc = {
  providerName: string;
  providerType: string;
  location: string;
  startingPrice: number;
  phone: string;
  isActive: boolean;
};

function con(message: string): string {
  return `CON ${message}`;
}

function end(message: string): string {
  return `END ${message}`;
}

/** Normalises a Kenyan phone number into the 2547XXXXXXXX form. */
function normalisePhone(raw: string): string {
  const digits = raw.replace(/\D/g, "");
  if (digits.startsWith("254")) return digits;
  if (digits.startsWith("0")) return `254${digits.substring(1)}`;
  return digits;
}

async function findUserByPhone(phone: string) {
  const snapshot = await db
    .collection("users")
    .where("phone", "==", phone)
    .limit(1)
    .get();
  return snapshot.empty ? null : { id: snapshot.docs[0].id, ...snapshot.docs[0].data() };
}

async function listProviders(limit = 5) {
  const snapshot = await db
    .collection("providers")
    .where("isActive", "==", true)
    .orderBy("rating", "desc")
    .limit(limit)
    .get();
  return snapshot.docs.map((doc) => ({ id: doc.id, ...(doc.data() as ProviderDoc) }));
}

async function listServices(providerId: string, limit = 5) {
  const snapshot = await db
    .collection("providers")
    .doc(providerId)
    .collection("services")
    .where("isAvailable", "==", true)
    .limit(limit)
    .get();
  return snapshot.docs.map((doc) => ({ id: doc.id, ...(doc.data() as any) }));
}

export const ussd = functions.https.onRequest(async (req, res) => {
  res.set("Content-Type", "text/plain");

  try {
    const phoneNumber = normalisePhone(String(req.body.phoneNumber ?? ""));
    const sessionId = String(req.body.sessionId ?? "");
    const text = String(req.body.text ?? "");
    const steps = text === "" ? [] : text.split("*");

    // Keep a record of every session so support staff and the admin console
    // can trace what a caller did.
    await db.collection("ussd_sessions").doc(sessionId).set(
      {
        sessionId,
        phoneNumber,
        lastInput: text,
        updatedAt: admin.firestore.Timestamp.now(),
      },
      { merge: true }
    );

    const user = await findUserByPhone(phoneNumber);

    // ---- Root menu ----
    if (steps.length === 0) {
      const greeting = user ? `Welcome back ${String((user as any).name).split(" ")[0]}` : "Welcome to Laundry Service";
      return res.send(
        con(
          `${greeting}\n1. Find Laundry\n2. Book Service\n3. My Orders\n4. Check Order Status\n5. Register\n6. Help`
        )
      );
    }

    const choice = steps[0];

    // ---- 1. Find Laundry ----
    if (choice === "1") {
      const providers = await listProviders();
      if (providers.length === 0) {
        return res.send(end("No laundry providers are available right now. Please try again later."));
      }
      if (steps.length === 1) {
        const lines = providers
          .map((p, i) => `${i + 1}. ${p.providerName} from KES ${p.startingPrice}`)
          .join("\n");
        return res.send(con(`Providers near you\n${lines}`));
      }
      const selected = providers[Number(steps[1]) - 1];
      if (!selected) return res.send(end("Invalid selection. Please dial again."));
      const typeLabel = selected.providerType === "mamaFua" ? "Mama Fua / Jua Kali" : "Formal Laundry";
      return res.send(
        end(
          `${selected.providerName}\nType: ${typeLabel}\nLocation: ${selected.location}\nFrom KES ${selected.startingPrice}\nCall ${selected.phone} or dial again to book.`
        )
      );
    }

    // ---- 2. Book Service ----
    if (choice === "2") {
      if (!user) {
        return res.send(end("You need an account first. Dial again and choose option 5 to Register."));
      }

      const providers = await listProviders();
      if (providers.length === 0) {
        return res.send(end("No laundry providers are available right now. Please try again later."));
      }

      if (steps.length === 1) {
        const lines = providers.map((p, i) => `${i + 1}. ${p.providerName}`).join("\n");
        return res.send(con(`Choose a provider\n${lines}`));
      }

      const provider = providers[Number(steps[1]) - 1];
      if (!provider) return res.send(end("Invalid provider selection. Please dial again."));

      const services = await listServices(provider.id);
      if (services.length === 0) {
        return res.send(end(`${provider.providerName} has not listed any services yet.`));
      }

      if (steps.length === 2) {
        const lines = services
          .map((s: any, i: number) => `${i + 1}. ${s.name} KES ${s.price} ${s.pricingUnit}`)
          .join("\n");
        return res.send(con(`Choose a service\n${lines}`));
      }

      const service = services[Number(steps[2]) - 1];
      if (!service) return res.send(end("Invalid service selection. Please dial again."));

      if (steps.length === 3) {
        return res.send(con(`Enter quantity in ${service.pricingUnit}`));
      }

      const quantity = Number(steps[3]);
      if (!Number.isFinite(quantity) || quantity <= 0) {
        return res.send(end("Invalid quantity. Please dial again."));
      }

      if (steps.length === 4) {
        return res.send(con("Enter your pickup location"));
      }

      const pickupLocation = steps[4];

      if (steps.length === 5) {
        return res.send(con("Payment method\n1. Mobile Money\n2. Cash On Delivery"));
      }

      const paymentMethod = steps[5] === "1" ? "mobileMoney" : "cashOnDelivery";
      const totalAmount = quantity * Number(service.price);
      const orderRef = db.collection("orders").doc();
      const now = admin.firestore.Timestamp.now();

      await orderRef.set({
        customerId: (user as any).id,
        customerName: (user as any).name ?? "USSD Customer",
        providerId: provider.id,
        providerName: provider.providerName,
        items: [
          {
            serviceId: service.id,
            serviceName: service.name,
            quantity,
            pricingUnit: service.pricingUnit,
            unitPrice: Number(service.price),
          },
        ],
        washingMethod: "machineWashing",
        ironingMethod: "electricIron",
        pickupRequested: true,
        deliveryRequested: true,
        pickupLocation: { label: pickupLocation, latitude: 0, longitude: 0 },
        deliveryLocation: { label: pickupLocation, latitude: 0, longitude: 0 },
        scheduledDate: now,
        scheduledTime: "As soon as possible",
        totalAmount,
        paymentMethod,
        paymentStatus: "pending",
        orderStatus: "pending",
        notes: "Order placed through USSD",
        channel: "ussd",
        createdAt: now,
        updatedAt: now,
      });

      await db.collection("notifications").add({
        userId: provider.id,
        title: "New Order Received",
        body: `A USSD order worth KES ${totalAmount} was placed.`,
        type: "newOrder",
        relatedOrderId: orderRef.id,
        isRead: false,
        createdAt: now,
      });

      return res.send(
        end(
          `Order confirmed.\nProvider: ${provider.providerName}\nService: ${service.name}\nTotal: KES ${totalAmount}\nReference: ${orderRef.id.substring(0, 8).toUpperCase()}\nYou will receive an SMS shortly.`
        )
      );
    }

    // ---- 3. My Orders ----
    if (choice === "3") {
      if (!user) return res.send(end("No account found for this number."));
      const snapshot = await db
        .collection("orders")
        .where("customerId", "==", (user as any).id)
        .orderBy("createdAt", "desc")
        .limit(5)
        .get();
      if (snapshot.empty) return res.send(end("You have no orders yet."));
      const lines = snapshot.docs
        .map((doc, i) => {
          const data = doc.data();
          return `${i + 1}. ${data.providerName} KES ${data.totalAmount} ${data.orderStatus}`;
        })
        .join("\n");
      return res.send(end(`Your recent orders\n${lines}`));
    }

    // ---- 4. Check Order Status ----
    if (choice === "4") {
      if (steps.length === 1) {
        return res.send(con("Enter your order reference"));
      }
      const reference = steps[1].toLowerCase();
      const snapshot = await db.collection("orders").get();
      const match = snapshot.docs.find((doc) => doc.id.toLowerCase().startsWith(reference));
      if (!match) return res.send(end("Order not found. Please check your reference."));
      const data = match.data();
      return res.send(
        end(`Order ${reference.toUpperCase()}\nProvider: ${data.providerName}\nStatus: ${data.orderStatus}\nAmount: KES ${data.totalAmount}`)
      );
    }

    // ---- 5. Register ----
    if (choice === "5") {
      if (user) return res.send(end("This number is already registered."));
      if (steps.length === 1) return res.send(con("Enter your full name"));
      if (steps.length === 2) return res.send(con("Enter your location"));

      const now = admin.firestore.Timestamp.now();
      const userRef = db.collection("users").doc();
      await userRef.set({
        uid: userRef.id,
        name: steps[1],
        email: "",
        phone: phoneNumber,
        role: "customer",
        profileImage: "",
        location: steps[2],
        channel: "ussd",
        createdAt: now,
        updatedAt: now,
        isActive: true,
      });
      return res.send(end(`Welcome ${steps[1]}. Your account has been created. Dial again to book a service.`));
    }

    // ---- 6. Help ----
    if (choice === "6") {
      return res.send(
        end("Laundry Service Help\nDial this code to find providers, book laundry and check your order status.\nFor assistance call 0700000000.")
      );
    }

    return res.send(end("Invalid choice. Please dial again."));
  } catch (error) {
    functions.logger.error("USSD handler failed", error);
    return res.send(end("The service is temporarily unavailable. Please try again shortly."));
  }
});
