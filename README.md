# Laundry Service Management System

A Flutter and FastAPI/PostgreSQL laundry marketplace built for Kenya, supporting formal laundry businesses and Mama Fua / Jua Kali operators. Smartphone customers use the Android application; feature-phone customers use the USSD callback at `/ussd`, which is served by the active FastAPI backend. The older Firebase implementation remains under `legacy_firebase_functions/` and is not used by the current app.

---

## Contents

1. [What is built](#what-is-built)
2. [Technology stack](#technology-stack)
3. [Architecture](#architecture)
4. [Folder structure](#folder-structure)
5. [Database design](#database-design)
6. [Installation](#installation)
7. [API and administrator setup](#api-and-administrator-setup)
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
Splash and onboarding, account creation, login, password reset, a dashboard fed by the API, provider discovery with filters, search and GPS-based nearby sorting, full provider profiles with services and reviews, a complete booking flow with dynamically calculated totals and exact pickup/delivery coordinates, live order tracking, order cancellation, and written reviews after completion. Profile editing includes a photo and GPS location. The help form sends messages to the admin support inbox.

**Provider experience, including Mama Fua / Jua Kali**
Provider registration capturing provider type, washing method, ironing method, pricing, turnaround and daily capacity. A dashboard with counts of pending, active and today's jobs plus revenue from completed orders. An availability switch writes to the API. Order acceptance, rejection and status advancement update the customer order. Full create, edit and delete service management.

**Administrator console**
Live platform metrics including a separate count of Mama Fua providers and formal laundry providers, user management with activate, deactivate and delete, provider management with verify, activate, deactivate and delete, and order management with filtering and deletion.

**Backend**
An active USSD state machine that registers feature-phone customers, lists providers, takes bookings and reports order status. Africa's Talking SMS and Safaricom Daraja STK Push adapters are implemented server-side and become active when configured with valid provider credentials.

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

Notable dependencies: `equatable` for value comparison in models, `uuid` for order and service identifiers, `intl` for date formatting, `flutter_rating_bar` for the review sheet, and `shared_preferences` for onboarding and access-token state.

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
  /ussd           ◄── USSD aggregator ◄── feature phone
  sendSms         ──► SMS gateway     ──► customer handset
  initiateMobileMoneyPayment ──► mobile money API
  mpesaCallback   ◄── mobile money API
```

The USSD aggregator owns the shortcode and posts each keypress to the FastAPI `/ussd` endpoint. The mobile app communicates with FastAPI; external SMS and payment gateway credentials must remain server-side.

Layering inside the Flutter application: screens depend on Riverpod providers, providers expose repositories and services, repositories communicate with FastAPI, and models own serialization.

---

## Folder structure

```
lib/
  core/
    constants/      app_enums.dart
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
  main.dart

backend/app/main.py FastAPI routes, PostgreSQL models and USSD callback
legacy_firebase_functions/  previous Firebase Functions implementation
firestore/          legacy Firebase rules
tools/              legacy Firebase seed and migration scripts
android/            AndroidManifest.xml, build.gradle
```

---

## Database design

**users** — uid, name, email, password_hash, phone, role, profileImage, location, latitude, longitude, createdAt, updatedAt, isActive

**providers** — id, ownerId, providerName, providerType, washingMethod, ironingMethod, phone, email, description, location, latitude, longitude, profileImage, rating, reviewCount, capacity, workingHours, availability, isVerified, isActive, startingPrice, turnaroundHours, createdAt, updatedAt

The provider id equals the owner's uid.

**services** — id, providerId, name, description, price, pricingUnit, isAvailable, createdAt, updatedAt

**orders** — id, customerId, customerName, providerId, providerName, items (JSON array of service lines), washingMethod, ironingMethod, pickupRequested, deliveryRequested, pickupLocation, deliveryLocation (including GPS coordinates), scheduledDate, scheduledTime, totalAmount, paymentMethod, paymentStatus, orderStatus, notes, createdAt, updatedAt

**payments** — id, orderId, customerId, providerId, amount, method, status, providerReference, failureReason, createdAt, updatedAt

**notifications** — id, userId, title, body, type, relatedOrderId, isRead, createdAt

**reviews** — id, orderId, customerId, customerName, providerId, rating, comment, createdAt

**support_messages** — id, userId, name, email, subject, message, status, createdAt

**ussd_sessions** — sessionId, phoneNumber, lastInput, updatedAt

PostgreSQL stores timestamps with timezone information, numeric amounts and booleans in their native column types. The order lifecycle includes pending, accepted, scheduled, picked up, washing, ironing, ready, out for delivery, completed and cancelled.

---

## Installation

```bash
flutter --version          # confirm Flutter 3.19 or newer
git clone <your repository>
cd laundry_service_app
flutter pub get
```

---

## API and administrator setup

The active app uses FastAPI and PostgreSQL; Firebase is not required. Start the API and database with `docker compose up --build`. SQLAlchemy creates missing tables when the API starts. For production, set a strong `JWT_SECRET` and a private PostgreSQL `DATABASE_URL`.

Public registration does not allow administrator accounts to be self-created. After registering the intended admin account, connect to PostgreSQL and assign its role:

```sql
UPDATE users SET role = 'admin' WHERE email = 'admin@example.com';
```

The admin account can then review messages in the Support Inbox.

---

## USSD setup

The USSD state machine is served at `POST /ussd` and follows Africa's Talking's form-encoded `sessionId`, `serviceCode`, `phoneNumber`, and accumulated `text` protocol. Configure the aggregator to post to `https://YOUR-API-HOST/ussd?token=YOUR_USSD_CALLBACK_TOKEN`; set the same high-entropy `USSD_CALLBACK_TOKEN` in the backend environment. The callback implements the menus, but telecom/aggregator provisioning of a shortcode and registration of this callback URL are external requirements; this repository cannot provision a shortcode.

The menu supports provider discovery, registration, booking, recent orders and order-status lookup. USSD mobile-money bookings start an STK Push to the caller's phone and remain unpaid until Daraja confirms payment.

To display the provisioned shortcode in the app's help screen, pass it when building the Android release:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-API-HOST --dart-define=USSD_SHORTCODE=*384*1234#
```

## SMS setup

The FastAPI backend sends SMS through Africa's Talking. Set these server-side environment variables (Render's deploy configuration or the local `.env` file):

| Variable | Required | Description |
|---|---|---|
| `AT_USERNAME` | Yes | Africa's Talking account username (`sandbox` for sandbox) |
| `AT_API_KEY` | Yes | API key from the Africa's Talking dashboard |
| `AT_SENDER_ID` | No | Approved sender ID; omit to use the account's default |
| `AT_SMS_URL` | No | Override the default Africa's Talking messaging endpoint |

For local development, copy `.env.example` to `.env` and add sandbox credentials before `docker compose up --build`. SMS requests are sent only to the authenticated user's own registered Kenyan phone number (admins may send to another number). The API returns HTTP 503 when the gateway is unconfigured or unavailable; a successful response means the provider accepted or queued the SMS, not that the handset has received it. Check the Africa's Talking delivery reports for final delivery status.

## Payment setup

Mobile-money checkout uses Safaricom Daraja STK Push. The customer is prompted on their handset, and an order is marked paid only after the authenticated Daraja callback confirms the payment and the amount matches the order. The app cannot set a payment to paid. Cash-on-delivery is recorded by the assigned provider when cash is collected.

Configure these backend environment variables:

| Variable | Required | Description |
|---|---|---|
| `MPESA_ENV` | Yes | `sandbox` for testing, `production` for live payments |
| `MPESA_CONSUMER_KEY`, `MPESA_CONSUMER_SECRET` | Yes | Daraja app credentials |
| `MPESA_SHORTCODE`, `MPESA_PASSKEY` | Yes | Provisioned Paybill/Till shortcode and STK passkey |
| `MPESA_CALLBACK_URL` | Yes | Public HTTPS URL ending in `/api/payments/mpesa/callback` |
| `MPESA_CALLBACK_TOKEN` | Yes | Long random secret; the backend appends it to the callback URL and verifies it |
| `MPESA_TRANSACTION_TYPE` | Yes | `CustomerPayBillOnline` (default) or `CustomerBuyGoodsOnline` |
| `MPESA_PARTY_B` | No | Till/Paybill destination; defaults to `MPESA_SHORTCODE` |

Safaricom must provision the shortcode and Daraja app for the selected environment. The callback URL must be publicly reachable over HTTPS; for sandbox testing use a temporary HTTPS tunnel to the local API and configure that exact URL in `.env`. Use real production credentials and the live shortcode only after completing Safaricom's approval process. Never put gateway secrets in the Flutter app or commit them. The administrator-only `GET /api/integrations/status` endpoint reports whether the backend has the required SMS and payment settings without exposing credential values.

Copy `.env.example` to `.env` for local Compose runs. Render's deployment configuration prompts for gateway credentials. Configure these values in the hosting provider's secret manager, not in source control.

For an Android release build, point the app to the deployed HTTPS backend, for example `flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-API-HOST`. Android Internet permission is included. Debug builds allow cleartext HTTP for the local emulator backend at `10.0.2.2:8000`; release builds should use HTTPS.

---

## Security

The API uses bearer JWTs for authenticated routes and checks roles for administrator operations such as support inbox access. Configure a strong `JWT_SECRET`, serve the API over HTTPS and restrict database access in production. Review API route permissions before exposing a deployment to real customers.

---

## Legacy Firebase seed data

```bash
cd tools
npm install firebase-admin
# save a service account key as tools/service-account.json
node seed.js            # write the sample data
node seed.js --clear    # remove it again
```

This script seeds the previous Firebase implementation only. It does not seed the active PostgreSQL database.

---

## Running the application

Start the API and PostgreSQL:

```bash
docker compose up --build
```

In a second terminal, run the Flutter app in Chrome:

```bash
flutter pub get
flutter run -d chrome --web-port 8080 --dart-define=API_BASE_URL=http://localhost:8000
```

### Deploying the API on Render for Android APKs

The `render.yaml` Blueprint creates the FastAPI service and PostgreSQL database. In Render, choose **New → Blueprint**, connect the GitHub repository containing this project, and deploy the Blueprint. Copy the API service's public `https://...onrender.com` URL after its `/api/health` endpoint reports `{"status":"ok","database":"postgresql"}`.

Build an APK configured to use that deployed API:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-API.onrender.com
```

Share `build/app/outputs/flutter-apk/app-release.apk` with Android users (for example, through Google Drive). They can download and install the APK; they do not install the Render API URL.

The Blueprint uses Render's free plans, which are suitable for trying the app with friends but have limits: free web services can sleep when idle, and free PostgreSQL databases expire after 30 days. Upgrade the database to a paid plan before relying on it for persistent data.

---

## Testing checklist

Test with the API and PostgreSQL running: customer/provider registration and login, provider discovery and filters, GPS permission and nearby sorting, GPS pickup/delivery coordinates, booking and order tracking, provider order/service management, notifications, reviews, profile edits/photo updates, Help and Support submission and admin triage, role separation, USSD simulator menu/booking/status flows, and finally `flutter build apk --release`.

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

**Implemented in the current FastAPI app:** authentication and role routing, provider registration/discovery, GPS capture and nearby sorting, booking with GPS pickup/delivery coordinates, order status and cancellation, service management, notifications, reviews, provider/admin dashboards, profile edits and photo updates, and admin support-message triage. The active FastAPI USSD state machine is at `/ussd`.

**Requires external configuration:** a shortcode and aggregator callback registration, Africa's Talking credentials/sender ID approval, and Safaricom Daraja credentials plus a provisioned shortcode. The SMS and payment adapters are implemented, but live delivery and charges cannot be activated without those third-party accounts and configuration. The app stores compressed profile photos in PostgreSQL as data URIs and should move to object storage for production-scale usage. Provider-to-customer chat and admin reports are not included.

The legacy Firebase implementation remains in the repository but is not used by the active app.
