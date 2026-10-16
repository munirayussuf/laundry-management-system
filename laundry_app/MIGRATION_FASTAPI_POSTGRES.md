# Firebase → PostgreSQL + FastAPI migration

## New architecture
Flutter app → FastAPI → PostgreSQL. Firebase Auth/Firestore/Cloud Functions are no longer required by the Flutter application.

## Run locally
1. Install Docker Desktop.
2. `docker compose up --build`
3. API docs: `http://localhost:8000/docs`
4. Android emulator API URL: `http://10.0.2.2:8000` (the Flutter default).
5. Physical phone: replace `API_BASE_URL` with your computer LAN address, e.g. `http://192.168.1.20:8000`.

## Existing Firebase data
Export Firestore collections into `firebase_export/` as JSON files named `users.json`, `providers.json`, `services.json`, `orders.json`, `payments.json`, `notifications.json`, and `reviews.json`, then run:
`DATABASE_URL=postgresql+psycopg://laundry:laundry@localhost:5432/laundry python tools/firebase_to_postgres.py firebase_export`

Firebase Authentication passwords cannot be recovered from Firestore. Imported users are therefore marked `MIGRATED_PASSWORD_RESET_REQUIRED`; implement your production password-reset email flow before switching existing users.

## Production secrets
Set `DATABASE_URL`, a strong random `JWT_SECRET`, and SMS/M-Pesa gateway credentials in the hosting provider's secret manager. Never commit them.

## API coverage
Authentication, profiles, providers, services, orders, notifications, reviews, payments, provider status, and SMS gateway hooks are represented as FastAPI routes. The client polls these routes every 3 seconds where the old app used Firestore streams.

## Deployment
Deploy the `backend/` directory to a Python host with PostgreSQL (Render, Railway, Fly.io, or another FastAPI-compatible host), then build the Flutter Android app with `--dart-define=API_BASE_URL=https://YOUR-API-DOMAIN`.
