#!/usr/bin/env bash
set -e
export DATABASE_URL="${DATABASE_URL:-postgresql+psycopg://laundry:laundry@localhost:5432/laundry}"
export JWT_SECRET="${JWT_SECRET:-change-this-secret}"
python3 -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
