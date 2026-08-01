# Sunil Medical Store — Backend API Reference (implemented)

The **actual, implemented** HTTP contract of the ASP.NET Core backend, for wiring
the Flutter (Android) client. This documents what the server really returns today
(derived from the controllers + DTOs), not a proposal. For the original product
brief see [`API_SPEC.md`](API_SPEC.md); for backend internals see [`claude.md`](claude.md).

---

## 1. Basics

- **Base URL**: local dev `http://localhost:5260`; all routes are prefixed **`/v1`**
  (e.g. `http://localhost:5260/v1/catalog/products`). Azure URL to follow — read it
  from Flutter build config.
- **Content type**: `application/json` for every request and response.
- **Auth**: send `Authorization: Bearer <Firebase ID token>` on **every** endpoint
  except the one marked _Public_. The server verifies the token as an OIDC JWT
  (Firebase project `sunil-medical-store`). No token / invalid token → **401**
  (empty body).
- **Success**: the resource is returned **directly** (object or array) — no `data`
  wrapper. `201` for creates, `204` for deletes, `200` otherwise.
- **Money**: integers, whole rupees (never decimals).
- **IDs**: strings.
- **Dates**: `date` = `yyyy-MM-dd` (e.g. `1994-03-18`); `date-time` = ISO-8601 UTC
  with trailing `Z` (e.g. `2026-07-27T14:32:00Z`).
- **Enums**: lowerCamelCase strings (e.g. `googlePay`, `labTest`) — see §5.
- **Errors**: envelope with a matching HTTP status (§4).

### dio wiring notes (client side)
- Base URL + `/v1` from build config.
- Interceptor: attach the current Firebase ID token as `Authorization: Bearer …`
  on every request (the `firebase_auth` SDK keeps it fresh).
- After onboarding (and ideally every login) call **`PUT /v1/users/me`** once to
  create the MySQL user row — other authed endpoints assume it exists.
- Map error responses (§4) to typed exceptions (e.g. `PromoException` uses
  `error.message` directly in the UI).

---

## 2. Endpoint summary

| # | Method | Path | Auth | Purpose |
|---|---|---|---|---|
| 1 | GET | `/v1/users/me` | ✔ | Signed-in user's unified profile |
| 2 | PUT | `/v1/users/me` | ✔ | Upsert profile (onboarding bootstrap) |
| 3 | GET | `/v1/users/me/medical-records` | ✔ | Medical records only |
| 4 | GET | `/v1/catalog/categories` | **Public** | Home categories |
| 5 | GET | `/v1/catalog/products?category={label}` | ✔ | Product list (filter optional) |
| 6 | GET | `/v1/catalog/products/suggested` | ✔ | "Suggested for you" (6) |
| 7 | GET | `/v1/catalog/products/{id}` | ✔ | Product detail |
| 8 | GET | `/v1/catalog/products/{id}/similar` | ✔ | Same-category products |
| 9 | GET | `/v1/catalog/lab-tests` | ✔ | Lab-test catalog |
| 10 | GET | `/v1/catalog/lab-tests/{id}` | ✔ | Lab-test detail |
| 11 | GET | `/v1/doctors` | ✔ | Doctors + weekly availability |
| 12 | POST | `/v1/appointments` | ✔ | Book appointment → 201 |
| 13 | GET | `/v1/appointments/me` | ✔ | Caller's appointments |
| 14 | POST | `/v1/promo-codes/validate` | ✔ | Validate promo vs. subtotal |
| 15 | POST | `/v1/orders` | ✔ | Place order → 201 |
| 16 | GET | `/v1/orders` | ✔ | Order history |
| 17 | GET | `/v1/orders/{id}` | ✔ | Order detail |
| 18 | GET | `/v1/orders/{id}/invoice` | ✔ | `{ invoiceUrl }` |
| 19 | GET | `/v1/lab-test-bookings` | ✔ | Booked-test history |
| 20 | GET | `/v1/lab-test-bookings/{id}` | ✔ | Booking detail |
| 21 | GET | `/v1/lab-test-bookings/{id}/invoice` | ✔ | `{ invoiceUrl }` |
| 22 | GET | `/v1/addresses` | ✔ | List addresses |
| 23 | POST | `/v1/addresses` | ✔ | Add address → 201 |
| 24 | PUT | `/v1/addresses/{id}/default` | ✔ | Make default |
| 25 | DELETE | `/v1/addresses/{id}` | ✔ | Remove → 204 |
| 26 | GET | `/v1/payment-methods` | ✔ | List UPI methods |
| 27 | POST | `/v1/payment-methods` | ✔ | Add UPI method → 201 |
| 28 | PUT | `/v1/payment-methods/{id}/default` | ✔ | Make default |
| 29 | DELETE | `/v1/payment-methods/{id}` | ✔ | Remove → 204 |
| 30 | GET | `/v1/admin/products?category={label}` | ✔ admin | Full inventory list (includes out-of-stock) |
| 31 | GET | `/v1/admin/products/{id}` | ✔ admin | Single product for edit |
| 32 | POST | `/v1/admin/products` | ✔ admin | Create product → 201 |
| 33 | PUT | `/v1/admin/products/{id}` | ✔ admin | Update product → 200 |
| 34 | DELETE | `/v1/admin/products/{id}` | ✔ admin | Delete product → 204 |

**Admin endpoints (30–34)**: require the caller's role to be `admin` — either
via the `role=admin` custom claim on the Firebase ID token, or (for
early-development convenience) via a hard-coded phone-number allowlist enforced
client-side. Non-admins hitting these should get **403** with
`code: "forbidden_admin_only"`.

---

## 3. Endpoints in detail

### Users / Profile

#### 1. `GET /v1/users/me` → `200`
```json
{
  "id": "LESzBD8zGdTww6U0HhFsEIGK5Y32",
  "fullName": "Rahul Kumar",
  "phoneNumber": "8123456789",
  "email": "rahul.kumar@example.com",
  "gender": "male",
  "dateOfBirth": "1994-03-18",
  "role": "customer",
  "medicalRecords": [
    { "id": "mr1", "title": "Penicillin allergy", "type": "Allergy", "date": "2021-06-12" }
  ]
}
```
- `email`, `gender`, `dateOfBirth` may be `null`. `medicalRecords` may be `[]`.
- `404 user_not_found` if the profile has not been bootstrapped yet (call PUT first).

#### 2. `PUT /v1/users/me` → `200` (same shape as #1)
Request (all fields optional; `fullName` required on first-ever create):
```json
{ "fullName": "Rahul Kumar", "email": "rahul.kumar@example.com", "gender": "male", "dateOfBirth": "1994-03-18" }
```
- Idempotent upsert. `phoneNumber`/`role` come from the verified token, not the body.
- `400 full_name_required` if creating without a `fullName`.

#### 3. `GET /v1/users/me/medical-records` → `200`
```json
[ { "id": "mr1", "title": "Penicillin allergy", "type": "Allergy", "date": "2021-06-12" } ]
```

---

### Catalog — Medicines

#### 4. `GET /v1/catalog/categories` → `200` — **Public (no token)**
```json
[
  { "label": "Medicines", "icon": "medication_outlined" },
  { "label": "Wellness", "icon": "spa_outlined" },
  { "label": "Personal Care", "icon": "face_retouching_natural" },
  { "label": "Devices", "icon": "monitor_heart_outlined" },
  { "label": "Baby Care", "icon": "child_friendly_outlined" },
  { "label": "Ayurveda", "icon": "eco_outlined" }
]
```

#### 5. `GET /v1/catalog/products?category={label}` → `200` — `Product[]`
`category` is optional; omit for the full catalog. **Product object:**
```json
{
  "id": "p1",
  "name": "Paracetamol 500mg Tablets",
  "brand": "Micro Labs",
  "category": "Medicines",
  "price": 30,
  "mrp": 35,
  "requiresPrescription": false,
  "description": "Relieves mild to moderate pain and reduces fever.",
  "composition": "Paracetamol 500mg",
  "dosage": "1 tablet every 6 hours, as needed (max 4/day)",
  "ingredients": ["Paracetamol", "Starch", "Povidone", "Magnesium stearate"],
  "imageUrl": null,
  "stock": 42
}
```
- `mrp`, `composition`, `dosage`, `imageUrl` may be `null`; `ingredients` may be `[]`
  (e.g. Devices). Client computes discount% from `mrp`/`price`; `imageUrl` falls back
  to a placeholder icon when `null`.
- `stock` (integer, ≥ 0). When `0`, the client greys the card out, shows an
  "Out of stock" badge, and disables Add-to-cart. The customer catalog
  endpoints (5–8) return out-of-stock products so users can still discover
  them; only the admin `/admin/products` endpoints allow mutation.

#### 6. `GET /v1/catalog/products/suggested` → `200` — `Product[]` (6 items)
#### 7. `GET /v1/catalog/products/{id}` → `200` — `Product` — `404 not_found` if missing
#### 8. `GET /v1/catalog/products/{id}/similar` → `200` — `Product[]` (same category, excludes self, ≤10)

---

### Catalog — Lab Tests

#### 9. `GET /v1/catalog/lab-tests` → `200` — `LabTest[]`
```json
{
  "id": "lt1",
  "name": "Complete Blood Count (CBC)",
  "description": "Screens overall blood health and helps detect infections and anemia.",
  "labName": "Sunil Diagnostics",
  "price": 450,
  "mrp": 600,
  "sampleType": "Blood",
  "reportTime": "Within 24 hours",
  "fastingRequired": false,
  "parameters": ["Hemoglobin", "WBC count", "RBC count", "Platelet count", "Hematocrit"]
}
```
- `mrp` may be `null`.

#### 10. `GET /v1/catalog/lab-tests/{id}` → `200` — `LabTest` — `404 not_found` if missing

---

### Appointments — Doctors

#### 11. `GET /v1/doctors` → `200` — `Doctor[]`
```json
{
  "id": "doc-1",
  "name": "Dr. Ananya Sharma",
  "specialization": "General Physician",
  "qualification": "MBBS, MD (Internal Medicine)",
  "experienceYears": 12,
  "rating": 4.8,
  "consultationFee": 400,
  "availableWeekdays": [1, 3, 5],
  "availableTime": "10:00 AM – 1:00 PM",
  "photoUrl": null
}
```
- `availableWeekdays`: ISO **1 (Mon) – 7 (Sun)**. `photoUrl` may be `null` (fall back to initials).

#### 12. `POST /v1/appointments` → `201`
Request:
```json
{ "doctorId": "doc-1", "date": "2026-08-03", "timeSlot": "10:00 AM – 1:00 PM" }
```
Response (an `Appointment`, see #13) with `status: "upcoming"`.
- `404 doctor_not_found` if the doctor id is unknown.

#### 13. `GET /v1/appointments/me` → `200` — `Appointment[]`
```json
{
  "id": "a1",
  "doctorName": "Dr. Ananya Sharma",
  "specialization": "General Physician",
  "dateTime": "2026-07-10T11:00:00Z",
  "status": "completed",
  "fee": 400
}
```
- `status`: `completed | cancelled | upcoming`.

---

### Cart / Checkout

#### 14. `POST /v1/promo-codes/validate` → `200`
Request:
```json
{ "code": "SAVE10", "subtotal": 310 }
```
Response:
```json
{ "code": "SAVE10", "label": "10% off your order", "type": "percentage", "value": 10, "minOrder": 0 }
```
- `type`: `percentage | flat`. `value` = percent (0–100) for `percentage`, else rupees.
- `400 invalid_promo_code` for an unknown code, or subtotal below `minOrder`
  (message like `"Add ₹40 more to use this code."` — show it directly).

#### 15. `POST /v1/orders` → `201`
Prices are **not** sent — the server prices authoritatively from the catalog.
Request:
```json
{
  "items": [
    { "kind": "medicine", "productId": "p1", "quantity": 2 },
    { "kind": "labTest", "testId": "lt1", "quantity": 1 }
  ],
  "addressId": "addr-0",
  "promoCode": "SAVE10",
  "paymentMethod": "googlePay"
}
```
- `items[].kind`: `medicine | labTest`. Send `productId` for medicines, `testId` for lab tests.
- `promoCode`: optional (`null`/omit for none).
- `paymentMethod`: `googlePay | phonePe | bhim | upi | cod`. For `upi`, also send `upiId`:
  ```json
  { "paymentMethod": "upi", "upiId": "rahul@okaxis" }
  ```
Response:
```json
{
  "id": "o10",
  "orderNumber": "SMS-100238",
  "placedOn": "2026-07-27T14:32:00Z",
  "status": "processing",
  "items": [
    { "name": "Paracetamol 500mg Tablets", "quantity": 2, "price": 30 },
    { "name": "Complete Blood Count (CBC)", "quantity": 1, "price": 450 }
  ],
  "subtotal": 510,
  "discount": 51,
  "delivery": 0,
  "total": 459,
  "paymentMethod": "googlePay",
  "addressId": "addr-0"
}
```
- Pricing: `delivery` = ₹40, waived (→ 0) when `subtotal ≥ 500`. Discount: `percentage →
  subtotal*value/100` (integer division), `flat → value`, clamped to subtotal.
- Placing an order with a `labTest` item also creates a **Lab Test Booking** (#19).
- Errors: `400 empty_cart`, `400 address_required`, `404 address_not_found`,
  `404 product_not_found` / `404 lab_test_not_found`, `400 invalid_quantity`,
  `400 invalid_upi_id`, `400 invalid_promo_code`.

#### 16. `GET /v1/orders` → `200` — `Order[]` (same shape as #15, newest first)
#### 17. `GET /v1/orders/{id}` → `200` — `Order` — `404 order_not_found`
#### 18. `GET /v1/orders/{id}/invoice` → `200`
```json
{ "invoiceUrl": "https://api.sunilmedicalstore.com/v1/orders/o10/invoice.pdf" }
```
- Placeholder URL (no PDF generated yet); client just opens the URL.

---

### Profile history

#### 19. `GET /v1/lab-test-bookings` → `200` — `LabTestBooking[]`
```json
{
  "id": "l1",
  "name": "Complete Blood Count (CBC)",
  "labName": "Sunil Diagnostics",
  "bookedOn": "2026-07-12",
  "status": "completed",
  "amount": 450,
  "parameters": ["Hemoglobin", "WBC count", "Platelet count", "RBC count"]
}
```
- `status`: `completed | scheduled | cancelled`. Freshly created bookings are `scheduled`.

#### 20. `GET /v1/lab-test-bookings/{id}` → `200` — `LabTestBooking` — `404 lab_test_booking_not_found`
#### 21. `GET /v1/lab-test-bookings/{id}/invoice` → `200` — `{ "invoiceUrl": "…" }` (placeholder)

#### 22. `GET /v1/addresses` → `200` — `Address[]` (default first)
```json
{
  "id": "addr-0",
  "type": "home",
  "line1": "12, Green Park Colony",
  "line2": "Near City Hospital",
  "city": "Bhubaneswar",
  "state": "Odisha",
  "pincode": "751001",
  "isDefault": true
}
```
- `type`: `home | work | other`. `line2` may be `null`.

#### 23. `POST /v1/addresses` → `201` — created `Address`
Request:
```json
{ "type": "work", "line1": "Tower B, Tech Park", "line2": null, "city": "Bhubaneswar", "state": "Odisha", "pincode": "751024", "makeDefault": false }
```
- The **first** address a user adds is always default (regardless of `makeDefault`).
- Errors: `400 line1_required | city_required | state_required | pincode_required`.

#### 24. `PUT /v1/addresses/{id}/default` → `200` — updated `Address` (clears others' default). No body.
#### 25. `DELETE /v1/addresses/{id}` → `204`. `404 address_not_found` if not the caller's.

#### 26. `GET /v1/payment-methods` → `200` — `PaymentMethod[]` (default first)
```json
{ "id": "pm-0", "upiId": "rahul@okaxis", "isDefault": true }
```

#### 27. `POST /v1/payment-methods` → `201` — created `PaymentMethod`
Request: `{ "upiId": "rahul@okaxis" }`
- Validated server-side against `^[\w.\-]{2,}@[a-zA-Z]{2,}$`. First one added is default.
- `400 invalid_upi_id` on a bad UPI id.

#### 28. `PUT /v1/payment-methods/{id}/default` → `200` — updated `PaymentMethod`. No body.
#### 29. `DELETE /v1/payment-methods/{id}` → `204`. `404 payment_method_not_found`.

---

### Admin — Inventory (products)

Full CRUD over the product catalog, admin-only. The customer catalog
endpoints (5–8) are the read-only public surface; these are the admin
mutation surface. Wire values for `category` match the seed strings in §6
(`Medicines`, `Wellness`, etc.).

#### 30. `GET /v1/admin/products?category={label}` → `200` — `Product[]`
Full inventory, out-of-stock items included. `category` optional; omit for
the entire catalog. Response objects match the customer `Product` shape
above (including the new `stock` field). `403 forbidden_admin_only` if the
caller isn't admin.

#### 31. `GET /v1/admin/products/{id}` → `200` — `Product`
Single product for the edit form. `404 product_not_found` if missing.

#### 32. `POST /v1/admin/products` → `201` — created `Product`
Request:
```json
{
  "name": "Paracetamol 500mg Tablets",
  "brand": "Micro Labs",
  "category": "Medicines",
  "price": 30,
  "stock": 100,
  "requiresPrescription": false,
  "composition": "Paracetamol 500mg",
  "mrp": 35,
  "description": "Relieves mild to moderate pain and reduces fever.",
  "dosage": "1 tablet every 6 hours, as needed (max 4/day)",
  "ingredients": ["Paracetamol", "Starch", "Povidone"],
  "imageUrl": null
}
```
- Mandatory (client validates): `name`, `brand`, `category`, `price`,
  `stock`, `requiresPrescription`, `composition`.
- Optional (omit or `null`): `mrp`, `description` (may be `""`), `dosage`,
  `ingredients` (may be `[]`), `imageUrl`.
- Server assigns the id.
- Errors: `400 validation_error` (missing mandatory field or bad type),
  `400 invalid_category` (unknown category label),
  `403 forbidden_admin_only`.

#### 33. `PUT /v1/admin/products/{id}` → `200` — updated `Product`
Same request/response shape as #32. Full replace (client currently sends the
complete object). `404 product_not_found` if missing.

#### 34. `DELETE /v1/admin/products/{id}` → `204`
Hard delete. `404 product_not_found` if missing. Backend may want to prevent
deletion if the product is referenced by unfulfilled orders — flag with
`409 product_in_use` if so; the client will surface the message.

---

## 4. Error envelope

Every 4xx/5xx (except the bare `401` auth challenge) returns:
```json
{ "error": { "code": "invalid_promo_code", "message": "Add ₹40 more to use this code." } }
```
`message` is user-presentable — safe to show directly. Statuses used: `400` (validation /
promo), `401` (missing/invalid token), `404` (not found), `500` (`internal_error`).

Common codes: `validation_error`, `invalid_promo_code`, `invalid_upi_id`, `empty_cart`,
`address_required`, `not_found`, `user_not_found`, `product_not_found`, `lab_test_not_found`,
`order_not_found`, `lab_test_booking_not_found`, `address_not_found`, `payment_method_not_found`,
`doctor_not_found`, `full_name_required`, `internal_error`, `forbidden_admin_only`,
`invalid_category`, `product_in_use`.

---

## 5. Enum wire values

| Field | Values |
|---|---|
| `role` | `customer`, `admin` |
| `gender` | `male`, `female`, `other` |
| address `type` | `home`, `work`, `other` |
| order `status` | `processing`, `delivered`, `cancelled` |
| lab-booking `status` | `completed`, `scheduled`, `cancelled` |
| appointment `status` | `completed`, `cancelled`, `upcoming` |
| order item `kind` | `medicine`, `labTest` |
| promo `type` | `percentage`, `flat` |
| `paymentMethod` | `googlePay`, `phonePe`, `bhim`, `upi`, `cod` |

Deserialize with Dart's `Enum.values.byName(json)` — values match member names 1:1.

---

## 6. Seed data (for local testing)

The dev DB is seeded with stable ids you can use directly:

- **Categories**: `Medicines`, `Wellness`, `Personal Care`, `Devices`, `Baby Care`, `Ayurveda`.
- **Products**: `p1`–`p12` (`p1` = Paracetamol; `p9`/`p10` = Devices with `null`
  composition/dosage and empty `ingredients`).
- **Lab tests**: `lt1`–`lt7` (`lt1` = CBC).
- **Doctors**: `doc-1`–`doc-5`.
- **Promo codes**: `SAVE10` (10% off, no min), `FLAT50` (₹50 off, min ₹300),
  `NEW100` (₹100 off, min ₹500).

### Testing without a Firebase token
Set `DevAuth:Enabled = true` in `appsettings.Development.json` (backend), then send an
`X-Debug-Uid: <any-id>` header instead of a bearer token; add `X-Debug-Role: admin` for
admin. See [`SunilMedicalStore_API/SunilMedicalStore_API.http`](SunilMedicalStore_API/SunilMedicalStore_API.http)
for a runnable request set.
