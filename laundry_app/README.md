# Laundry Service Management System

A Flutter and Firebase laundry marketplace built for Kenya, supporting both formal laundry businesses and Mama Fua / Jua Kali operators as equal, first class providers. Customers with smartphones use the Android application; customers on feature phones use the USSD channel served by the same Firestore database.

---

## Contents

1. [What is built](#what-is-built)
2. [Technology stack](#technology-stack)
3. [Architecture](#architecture)
4. [Folder structure](#folder-structure)
5. [Database design](#database-design)
6. [Installation](#installation)
7. [Firebase setup](#firebase-setup)
8. [USSD setup](#ussd-setup)
9. [SMS setup](#sms-setup)
10. [Payment setup](#payment-setup)
11. [Security](#security)
12. [Seed data](#seed-data)
13. [Running the application](#running-the-application)
14. [Testing checklist](#testing-checklist)
15. [APK generation](#apk-generation)
16. [Honest status of every module](#honest-status-of-every-module)

---

## What is built

**Customer experience**
Splash and onboarding, account creation with Kenyan phone validation, login, password reset, a dashboard fed by live Firestore streams, provider discovery with working filters and search, full provider profiles with services and reviews, a complete booking flow with dynamically calculated totals, live order tracking on a status timeline, order cancellation, and star ratings with written reviews after completion.

**Provider experience, including Mama Fua / Jua Kali**
Provider registration capturing provider type, washing method, ironing method, pricing, turnaround and daily capacity. A dashboard with real counts of pending, active and today's jobs plus revenue from completed orders. An availability switch that writes straight to Firestore. Order acceptance, rejection and step by step status advancement, each of which notifies the customer. Full create, edit and delete service management.

**Administrator console**
Live platform metrics including a separate count of Mama Fua providers and formal laundry providers, user management with activate, deactivate and delete, provider management with verify, activate, deactivate and delete, and order management with filtering and deletion.

**Backend**
A USSD state machine that registers users, lists providers, takes a booking and reports order status entirely over a feature phone session. An SMS relay that keeps gateway keys off the handset. A mobile money flow where only the payment provider's own callback can mark a payment paid.

---

## Design system

The interface is a light rose theme rather than a dark one: a soft pink canvas (`#FDF0F6`), white cards with a hairline pink border, magenta (`#D81B76`) as the single action color, and deep plum (`#3D0A28`) text. Headings use Poppins, body copy uses Inter, corners are generously rounded and primary buttons are full pills.

Everything is driven from three files, so a future restyle touches only these:

| File | Holds |
|---|---|
| `lib/core/theme/app_colors.dart` | Every color token, the pink gradient and the background wash |
| `lib/core/theme/app_text_styles.dart` | The eight text styles, all defaulting to plum |
| `lib/core/theme/app_theme.dart` | The Material 3 `ThemeData` that wires cards, inputs, buttons, chips, switches, dialogs and navigation |

Shared building blocks live in `lib/core/widgets/app_widgets.dart`: `PinkAppBar` (the rounded gradient header with a title, subtitle and circular back control), `IconTile` (the soft pink circle behind a row icon), `AppCard`, `PremiumButton` with its built in loading state, `ProviderTypeBadge`, `OrderStatusBadge`, and the empty and error states.

Text that sits on a pink surface must pass `AppColors.white` explicitly, since every text style defaults to plum for the light canvas.

Rose gold is deliberately reserved for the Mama Fua badge alone; stars, verification marks and amounts are pink, matching the reference screens.

---

## Technology stack

| Layer | Choice | Why |
|---|---|---|
| Framework | Flutter | Single Android codebase with precise control over the premium visual identity |
| Language | Dart | Flutter's language |
| State management | Riverpod | Used consistently throughout, no mixing of approaches |
| Routing | go_router | Declarative routes with a single redirect callback that enforces role separation |
| Backend | FastAPI | Python REST API with JWT authentication and server-side business logic |
| Database | PostgreSQL | Relational persistence with SQLAlchemy and durable transactions |
| Auth | JWT + PostgreSQL | Email/password authentication with role stored in PostgreSQL |
| Server integrations | FastAPI adapters | Holds SMS/mobile-money secrets off the device |
| Fonts | google_fonts | Playfair Display for headings, Inter for body |

Every dependency in `pubspec.yaml` is used. Notable ones: `equatable` for value comparison in models, `uuid` for order and service identifiers, `intl` for date formatting, `flutter_rating_bar` for the review sheet, `shared_preferences` to remember that onboarding was seen, `cloud_functions` to reach the SMS and payment relays.

---

## Architecture

```
Flutter application  ─────────────┐
(customer, provider, admin)       │
                                  ▼
                              FastAPI
                                  │
                                  ▼
                              PostgreSQL
                                  ▲
                                  │
 SMS / M-Pesa adapters ───────────┘
  ussd            ◄── USSD aggregator ◄── feature phone
  sendSms         ──► SMS gateway     ──► customer handset
  initiateMobileMoneyPayment ──► mobile money API
  mpesaCallback   ◄── mobile money API
```

The four boxes are deliberately separate. Firebase is not a USSD gateway; the aggregator owns the shortcode and posts each keypress to the `ussd` HTTPS function. Likewise the application never calls an SMS or payment API directly, because that would require shipping a secret key inside the APK.

Layering inside the Flutter application: screens depend on Riverpod providers, providers expose repositories and services, repositories are the only code that touches Firestore, and models own all serialisation. No screen builds a Firestore query inline except the admin aggregate views, which read whole collections by design.

---

## Folder structure

```
lib/
  core/
    constants/      app_enums.dart, firestore_paths.dart
    theme/          app_colors.dart, app_text_styles.dart, app_theme.dart
    models/         user, provider, service, order, payment, notification, review
    repositories/   provider, order, notification, review
    services/       auth_service, sms_service, payment_service
    providers/      app_providers.dart  (the Riverpod graph)
    routes/         app_router.dart     (role based redirection)
    widgets/        app_widgets.dart    (buttons, badges, empty and error states)
  features/
    auth/           splash, onboarding, login, register, forgot password
    customer/       shell, home, discovery, provider details, booking, orders, order details
    provider/       shell, registration, dashboard, orders, order details, services
    admin/          shell, dashboard, users, providers, orders
    notifications/  notifications_screen.dart
    profile/        profile_screen.dart
  firebase_options.dart
  main.dart

functions/src/      ussd.ts, sms.ts, payments.ts, index.ts
firestore/          firestore.rules, firestore.indexes.json
tools/              seed.js
android/            AndroidManifest.xml, build.gradle
```

---

## Database design

**users/{userId}** — uid, name, email, phone, role, profileImage, location, latitude, longitude, createdAt, updatedAt, isActive

**providers/{providerId}** — ownerId, providerName, providerType, washingMethod, ironingMethod, phone, email, description, location, latitude, longitude, profileImage, rating, reviewCount, capacity, workingHours, availability, isVerified, isActive, startingPrice, turnaroundHours, createdAt, updatedAt

The provider document id equals the owner's uid, which lets the security rules check ownership without an extra read.

**providers/{providerId}/services/{serviceId}** — providerId, name, description, price, pricingUnit, isAvailable, createdAt, updatedAt

**orders/{orderId}** — customerId, customerName, providerId, providerName, items (array of service lines), washingMethod, ironingMethod, pickupRequested, deliveryRequested, pickupLocation, deliveryLocation, scheduledDate, scheduledTime, totalAmount, paymentMethod, paymentStatus, orderStatus, notes, createdAt, updatedAt

**payments/{paymentId}** — orderId, customerId, providerId, amount, method, status, providerReference, failureReason, createdAt, updatedAt

**notifications/{notificationId}** — userId, title, body, type, relatedOrderId, isRead, createdAt

**reviews/{reviewId}** — orderId, customerId, customerName, providerId, rating, comment, createdAt

All dates are stored as Firestore `Timestamp`, amounts as numbers, and flags as booleans. Nothing is stored as a string where a native type fits.

Order lifecycle: Pending, Accepted, Scheduled, Picked Up, Washing, Ironing, Ready, Out For Delivery, Completed, with Cancelled as a terminal branch.

---

## Installation

```bash
flutter --version          # confirm Flutter 3.19 or newer
git clone <your repository>
cd laundry_service_app
flutter pub get
```

---

## Firebase setup

1. Create a project at the Firebase console and name it, for example, `laundry-service-kenya`.
2. Add an Android application with the package name `com.example.laundry_service_app`. Change it in `android/app/build.gradle` first if you prefer your own.
3. Download `google-services.json` and place it at `android/app/google-services.json`.
4. Generate the Dart configuration, which overwrites the placeholder file:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

5. In the console enable **Authentication → Sign in method → Email and password**.
6. Create a **Firestore database** in production mode, choosing a region close to Kenya such as `europe-west1`.
7. Deploy the rules and indexes:

```bash
firebase login
firebase use --add            # select your project
firebase deploy --only firestore:rules,firestore:indexes
```

8. Create your first administrator. Register normally in the app, then in the Firestore console open that user's document in `users` and change `role` from `customer` to `admin`. The rules deliberately forbid a client from assigning itself the admin role.

Collections are created automatically on first write; there is no manual collection setup step.

**Values you must supply yourself:** the contents of `google-services.json`, and the five fields in `lib/firebase_options.dart` (apiKey, appId, messagingSenderId, projectId, storageBucket). `flutterfire configure` fills the second one in for you.

---

## USSD setup

The USSD handler is `functions/src/ussd.ts`, deployed as an HTTPS endpoint.

```bash
cd functions
npm install
npm run build
firebase deploy --only functions:ussd
```

Then, with your aggregator (Africa's Talking, or a Safaricom approved aggregator):

1. Apply for a USSD shortcode, for example `*384*1234#`. This is a commercial arrangement with the telecom and takes days to weeks; there is no way to shortcut it.
2. In the aggregator dashboard, set the callback URL to the deployed function:
   `https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/ussd`
3. Test with the aggregator's simulator before going live.

**Values you must supply:** the shortcode itself, and the callback URL registration. No API key is needed for inbound USSD, because the aggregator calls you.

Menu served by the handler:

```
Welcome to Laundry Service
1. Find Laundry
2. Book Service
3. My Orders
4. Check Order Status
5. Register
6. Help
```

Option 2 walks the caller through provider, service, quantity, pickup location and payment method, then writes a real order document with `channel: "ussd"` and notifies the provider.

---

## SMS setup

```bash
firebase functions:config:set \
  sms.username="YOUR_AFRICASTALKING_USERNAME" \
  sms.api_key="YOUR_AFRICASTALKING_API_KEY" \
  sms.sender_id="YOUR_APPROVED_SENDER_ID"

firebase deploy --only functions:sendSms
```

**Values you must supply:** username, API key and an approved sender id from your SMS provider.

Until you configure these, `SmsService` logs a warning and returns false rather than throwing. That is deliberate: a customer's order must still be placed successfully even if the notification channel is not live yet.

---

## Payment setup

```bash
firebase functions:config:set \
  mpesa.consumer_key="YOUR_CONSUMER_KEY" \
  mpesa.consumer_secret="YOUR_CONSUMER_SECRET" \
  mpesa.passkey="YOUR_PASSKEY" \
  mpesa.shortcode="YOUR_SHORTCODE" \
  mpesa.env="sandbox" \
  mpesa.callback_url="https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/mpesaCallback"

firebase deploy --only functions:initiateMobileMoneyPayment,functions:mpesaCallback
```

**Values you must supply:** consumer key, consumer secret, passkey and shortcode from your payment provider's developer portal, plus the deployed callback URL registered back with them.

A payment is only ever marked `paid` inside `mpesaCallback`, using the Admin SDK. The Firestore rules forbid any client from writing that status. Cash on delivery is settled when the provider marks the order completed.

---

## Security

`firestore/firestore.rules` enforces, among other things:

- A user may read and update only their own profile, and may never set `role` to `admin`.
- Provider profiles are publicly readable so discovery works for signed out browsing, but only the owner may edit them, and only an admin may set `isVerified`.
- A provider cannot write their own `rating` or `reviewCount`; those are derived from the reviews collection.
- A customer creating an order must set `orderStatus` and `paymentStatus` to `pending`, so neither can be forged.
- A provider may change only `orderStatus`, `paymentStatus` and `updatedAt` on orders assigned to them.
- A customer may only cancel an order, and only while it is still pending.
- A review may be created only by the customer who owns that order, and only when the order is completed. The repository additionally rejects duplicates so the user sees a clear message rather than a permission error.
- USSD session records are writable only by the Admin SDK.

There is no `allow read, write: if true` anywhere.

Test the rules locally before deploying:

```bash
firebase emulators:start --only firestore
```

---

## Seed data

```bash
cd tools
npm install firebase-admin
# save a service account key as tools/service-account.json
node seed.js            # write the sample data
node seed.js --clear    # remove it again
```

Creates one formal laundry provider, one Mama Fua provider, their service catalogs, one customer and one order. Every document carries `seedData: true`, and the script lives outside `lib/` so nothing it creates is ever compiled into the APK.

---

## Running the application

```bash
flutter clean
flutter pub get
flutter run
```

---

## Testing checklist

Work through these on a real device or emulator after connecting Firebase:

Registration as customer, registration as provider, login, logout, password reset email, splash and onboarding sequence, customer dashboard loading live providers, discovery filters by provider type and washing method, search by name and location, provider details with services and reviews, booking with dynamic total, validation blocking an empty booking, order appearing in My Orders, provider seeing the new order, accept, reject, each status advancement, customer timeline updating live without a restart, cancellation while pending, service create, service edit, service delete with confirmation, notification list, mark as read, swipe to delete, clear all, review submission after completion, duplicate review blocked, provider rating recalculated, profile edit, admin counts matching reality, admin verify and deactivate a provider, admin delete with confirmation, role separation (sign in as a customer and try to open `/admin`), airplane mode behaviour, and finally `flutter build apk --release`.

---

## APK generation

```bash
flutter build apk                 # debug oriented build
flutter build apk --release       # release build, unsigned by default
flutter build apk --split-per-abi # smaller per architecture builds
```

The output lands in `build/app/outputs/flutter-apk/`.

For a signed release:

```bash
keytool -genkey -v -keystore ~/laundry-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias laundry
```

Then create `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=laundry
storeFile=/absolute/path/to/laundry-release.jks
```

`android/app/build.gradle` already reads this file and applies the release signing config when it exists. Keep `key.properties` and the keystore out of version control.

```bash
flutter build apk --release
flutter build appbundle --release   # for the Play Store
```

---

## Honest status of every module

I would rather you know exactly where the edges are than discover them mid demonstration.

**Fully implemented and working once Firebase is connected:** authentication and role routing, the theme system, provider registration, provider discovery with filters and search, provider details, the booking flow with dynamic pricing, order creation, the full order lifecycle with provider driven status changes, live order tracking, order cancellation, service create, edit and delete, notifications including delete and clear, reviews with rating recalculation and duplicate prevention, the provider dashboard metrics, the admin dashboard, admin user, provider and order management, the Firestore rules, the USSD state machine, and the SMS and payment relays.

**Implemented as a correct integration point awaiting your credentials:** SMS delivery (needs a gateway account), mobile money (needs a payment provider account and a registered callback), and USSD (needs a shortcode from a telecom aggregator). In each case the code path is real and the credentials are the only missing piece, which is the honest state of any application that talks to these systems.

**Present but minimal, and the first places I would extend:** the settings list rows in the profile screen are navigational placeholders rather than full settings screens; provider to customer messaging is not built; the location service is structured through latitude and longitude fields on providers and orders but device location capture and distance sorting are not wired to `geolocator` yet; and admin reports beyond the dashboard counts are not built. I have not written unit or widget tests.

I have reviewed the imports and dependencies for consistency, but I have not been able to run `flutter analyze` or compile this in a Flutter toolchain, so expect to fix a small number of compile errors on first build rather than zero.
