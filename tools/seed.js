/**
 * Development seed data.
 *
 * This script populates a Firestore database with a small, realistic sample
 * of providers, services, a customer and an order so you can explore the
 * application before real users exist. It is NOT part of the Flutter
 * application and is never bundled into the APK, so seed records can never
 * masquerade as permanent hardcoded content.
 *
 * Run it against an emulator or a development project only:
 *
 *   cd tools
 *   npm install firebase-admin
 *   # download a service account key from the Firebase console and save it
 *   # as service-account.json in this folder, then:
 *   node seed.js
 *
 * Every document created here carries seedData: true, so you can remove it
 * all again with:
 *
 *   node seed.js --clear
 */

const admin = require("firebase-admin");
const serviceAccount = require("./service-account.json");

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();
const now = admin.firestore.Timestamp.now();

const shouldClear = process.argv.includes("--clear");

async function clearSeedData() {
  const collections = ["users", "providers", "orders", "reviews", "notifications"];
  for (const name of collections) {
    const snapshot = await db.collection(name).where("seedData", "==", true).get();
    for (const doc of snapshot.docs) {
      await doc.ref.delete();
    }
    console.log(`Cleared ${snapshot.size} seed documents from ${name}`);
  }
}

async function seed() {
  // ---- Customer ----
  const customerId = "seed_customer_aisha";
  await db.collection("users").doc(customerId).set({
    uid: customerId,
    name: "Aisha Wanjiru",
    email: "aisha.customer@example.com",
    phone: "0712345678",
    role: "customer",
    profileImage: "",
    location: "Kilimani, Nairobi",
    seedData: true,
    createdAt: now,
    updatedAt: now,
    isActive: true,
  });

  // ---- Formal laundry provider ----
  const formalId = "seed_provider_sparkle";
  await db.collection("users").doc(formalId).set({
    uid: formalId,
    name: "Sparkle Laundry Limited",
    email: "sparkle@example.com",
    phone: "0720000001",
    role: "provider",
    location: "Westlands, Nairobi",
    seedData: true,
    createdAt: now,
    updatedAt: now,
    isActive: true,
  });
  await db.collection("providers").doc(formalId).set({
    ownerId: formalId,
    providerName: "Sparkle Laundry Limited",
    providerType: "formalLaundry",
    washingMethod: "machineWashing",
    ironingMethod: "electricIron",
    phone: "0720000001",
    email: "sparkle@example.com",
    description:
      "A registered laundry business offering same day machine washing, pressing and free delivery within Westlands.",
    location: "Westlands, Nairobi",
    latitude: -1.2676,
    longitude: 36.8108,
    profileImage: "",
    rating: 4.6,
    reviewCount: 18,
    capacity: 60,
    workingHours: { open: "07:00", close: "20:00" },
    availability: true,
    isVerified: true,
    isActive: true,
    startingPrice: 250,
    turnaroundHours: 24,
    seedData: true,
    createdAt: now,
    updatedAt: now,
  });

  const formalServices = [
    { name: "Washing", description: "Machine wash and tumble dry", price: 250, pricingUnit: "per load" },
    { name: "Washing And Ironing", description: "Full service wash and press", price: 400, pricingUnit: "per load" },
    { name: "Ironing", description: "Electric press only", price: 150, pricingUnit: "per load" },
    { name: "Delivery", description: "Doorstep delivery within Westlands", price: 100, pricingUnit: "per order" },
  ];
  for (const service of formalServices) {
    await db.collection("providers").doc(formalId).collection("services").add({
      providerId: formalId,
      ...service,
      isAvailable: true,
      seedData: true,
      createdAt: now,
      updatedAt: now,
    });
  }

  // ---- Mama Fua / Jua Kali provider ----
  const mamaFuaId = "seed_provider_mama_grace";
  await db.collection("users").doc(mamaFuaId).set({
    uid: mamaFuaId,
    name: "Grace Atieno",
    email: "grace.mamafua@example.com",
    phone: "0720000002",
    role: "provider",
    location: "Kibera, Nairobi",
    seedData: true,
    createdAt: now,
    updatedAt: now,
    isActive: true,
  });
  await db.collection("providers").doc(mamaFuaId).set({
    ownerId: mamaFuaId,
    providerName: "Mama Grace Laundry Services",
    providerType: "mamaFua",
    washingMethod: "manualHandWashing",
    ironingMethod: "traditionalCharcoalIron",
    phone: "0720000002",
    email: "grace.mamafua@example.com",
    description:
      "Careful hand washing and charcoal pressing, trusted by families in Kibera for over eight years. Delicate fabrics welcome.",
    location: "Kibera, Nairobi",
    latitude: -1.3133,
    longitude: 36.7819,
    profileImage: "",
    rating: 4.9,
    reviewCount: 34,
    capacity: 12,
    workingHours: { open: "06:30", close: "18:00" },
    availability: true,
    isVerified: true,
    isActive: true,
    startingPrice: 150,
    turnaroundHours: 12,
    seedData: true,
    createdAt: now,
    updatedAt: now,
  });

  const mamaFuaServices = [
    { name: "Hand Washing", description: "Careful hand wash, gentle on fabric", price: 150, pricingUnit: "per basket" },
    { name: "Washing And Ironing", description: "Hand wash with charcoal pressing", price: 250, pricingUnit: "per basket" },
    { name: "Ironing", description: "Charcoal iron pressing only", price: 100, pricingUnit: "per basket" },
    { name: "Duvet Washing", description: "Large items washed by hand and sun dried", price: 400, pricingUnit: "per piece" },
  ];
  for (const service of mamaFuaServices) {
    await db.collection("providers").doc(mamaFuaId).collection("services").add({
      providerId: mamaFuaId,
      ...service,
      isAvailable: true,
      seedData: true,
      createdAt: now,
      updatedAt: now,
    });
  }

  // ---- Example order ----
  const orderRef = db.collection("orders").doc();
  await orderRef.set({
    customerId,
    customerName: "Aisha Wanjiru",
    providerId: mamaFuaId,
    providerName: "Mama Grace Laundry Services",
    items: [
      {
        serviceId: "seed_service_hand_washing",
        serviceName: "Washing And Ironing",
        quantity: 2,
        pricingUnit: "per basket",
        unitPrice: 250,
      },
    ],
    washingMethod: "manualHandWashing",
    ironingMethod: "traditionalCharcoalIron",
    pickupRequested: true,
    deliveryRequested: true,
    pickupLocation: { label: "Kilimani, Nairobi", latitude: -1.2921, longitude: 36.7833 },
    deliveryLocation: { label: "Kilimani, Nairobi", latitude: -1.2921, longitude: 36.7833 },
    scheduledDate: now,
    scheduledTime: "10:00 AM",
    totalAmount: 500,
    paymentMethod: "cashOnDelivery",
    paymentStatus: "pending",
    orderStatus: "accepted",
    notes: "Please separate the white clothes",
    seedData: true,
    createdAt: now,
    updatedAt: now,
  });

  console.log("Seed data written successfully.");
  console.log("Create matching Firebase Authentication accounts for the seed");
  console.log("users if you want to sign in as them, using the same uid values.");
}

(shouldClear ? clearSeedData() : seed())
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
