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
| 5 | GET | `/v1/catalog/products?category={label}&search={q}` | ✔ | Product list (both filters optional; `search` proposed) |
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
| 35 | GET | `/v1/admin/doctors` | ✔ admin | All doctors |
| 36 | GET | `/v1/admin/doctors/{id}` | ✔ admin | Single doctor for edit |
| 37 | POST | `/v1/admin/doctors` | ✔ admin | Create doctor → 201 |
| 38 | PUT | `/v1/admin/doctors/{id}` | ✔ admin | Update doctor → 200 |
| 39 | DELETE | `/v1/admin/doctors/{id}` | ✔ admin | Delete doctor → 204 |
| 40 | GET | `/v1/admin/appointments?…filters` | ✔ admin | All appointments across users |
| 41 | GET | `/v1/admin/appointments/{id}` | ✔ admin | Single appointment |
| 42 | POST | `/v1/admin/appointments` | ✔ admin | Book on behalf of user → 201 |
| 43 | PUT | `/v1/admin/appointments/{id}` | ✔ admin | Reschedule and/or change status |
| 44 | GET | `/v1/admin/users?search={q}` | ✔ admin | Directory of all users |
| 45 | PUT | `/v1/orders/{id}/cancel` | ✔ | Customer cancels their own order → 200 |
| 46 | GET | `/v1/admin/orders?…filters` | ✔ admin | All orders across all users |
| 47 | GET | `/v1/admin/orders/{id}` | ✔ admin | Single order |
| 48 | PUT | `/v1/admin/orders/{id}` | ✔ admin | Change order status (incl. cancel) |
| 49 | GET | `/v1/admin/promo-codes` | ✔ admin | All promo codes |
| 50 | GET | `/v1/admin/promo-codes/{id}` | ✔ admin | Single promo code for edit |
| 51 | POST | `/v1/admin/promo-codes` | ✔ admin | Create promo code → 201 |
| 52 | PUT | `/v1/admin/promo-codes/{id}` | ✔ admin | Update promo code → 200 |
| 53 | DELETE | `/v1/admin/promo-codes/{id}` | ✔ admin | Delete promo code → 204 |
| 54 | POST | `/v1/prescriptions` | ✔ | Save an uploaded prescription's metadata → 201 |
| 55 | GET | `/v1/prescriptions` | ✔ | Caller's prescriptions |
| 56 | GET | `/v1/prescriptions/{id}` | ✔ | Single prescription |
| 57 | GET | `/v1/admin/prescriptions?status=` | ✔ admin | All prescriptions across users |
| 58 | GET | `/v1/admin/prescriptions/{id}` | ✔ admin | Single prescription for review |
| 59 | PUT | `/v1/admin/prescriptions/{id}` | ✔ admin | Approve/reject → 200 |
| 60 | PUT | `/v1/users/me/fcm-token` | ✔ | Register this device for push notifications |

**45–59 are live** (verified against Azure) — widened the `order status`
enum (see §5) from `processing | delivered | cancelled` to
`created | processing | shipped | delivered | cancelled`, a freshly placed
order (#15) now comes back with `status: "created"` instead of
`"processing"`.

**⚠ 60 (and the push-notification send-side described after §3) is not yet
implemented on the backend** — proposed by the Flutter client, which is
already built against this contract (permission request, token
registration, foreground/background message handling, tap deep-linking all
verified live — the token PUT currently 404s and is swallowed silently, as
designed, until the backend has the endpoint).

49–53 additionally mean **#14 `POST /v1/promo-codes/validate` gains new
rejection rules** — reject (still `400 invalid_promo_code`, just a different
`message`) when the code is `active: false`, past `expiresAt`, at
`maxRedemptions`, or the caller has already redeemed it `perUserLimit`
times. The client doesn't branch on error code for promo validation, only
displays `message` — so no new error codes are required here, just accurate
messages (e.g. `"This code has expired."`, `"This code is no longer
active."`, `"You've already used this code."`).

**54–59 (prescriptions) — important architecture note:** the client uploads
the image directly to **Firebase Storage** (path `prescriptions/{uid}/{uuid}.{ext}`,
requires Storage security rules letting a signed-in user write under their
own uid — not yet configured in the Firebase console, separately from this
backend work) and only sends the backend the resulting download URL. The
backend **never receives multipart/raw file bytes** for this — #54 is a
plain JSON call. This also means **#15 `POST /v1/orders` gains an optional
`prescriptionId` field** — validate server-side (don't just trust the
client-side gate) that when any ordered item's product has
`requiresPrescription: true`, a `prescriptionId` was sent and belongs to
the caller; reject with `400 prescription_required` or
`404 prescription_not_found` otherwise.

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

#### 5. `GET /v1/catalog/products?category={label}&search={q}` → `200` — `Product[]`
`category` and `search` are both optional and combinable; omit both for the
full catalog. **`search` (proposed, not yet implemented) — free-text match
against `name` and `brand`**, case-insensitive substring (e.g. `search=para`
matches "Paracetamol 500mg Tablets"). Powers the dashboard search bar
(`SearchScreen`), which sends only `search` (no category). **Product
object:**
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
  "paymentMethod": "googlePay",
  "prescriptionId": "rx-1"
}
```
- `items[].kind`: `medicine | labTest`. Send `productId` for medicines, `testId` for lab tests.
- `promoCode`: optional (`null`/omit for none).
- `prescriptionId`: optional/omit unless the cart has an Rx item (see §54–59
  below) — required and server-validated in that case.
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

#### 45. `PUT /v1/orders/{id}/cancel` → `200` — updated `Order` — **proposed, not yet built**
No body. The customer cancelling their own order.
- Only valid while `status` is `created` or `processing` — reject with
  `409 order_not_cancellable` once `shipped`/`delivered`/already `cancelled`.
- `404 order_not_found` if missing or not the caller's order.

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

### Admin — Doctors

Full CRUD over the doctor catalog. Reads mirror the customer `Doctor` shape
(§11) — same fields, so the client shares its `Doctor` domain model.

#### 35. `GET /v1/admin/doctors` → `200` — `Doctor[]`
All doctors, including any inactive/hidden ones the customer catalog might
filter out. `403 forbidden_admin_only` if not admin.

#### 36. `GET /v1/admin/doctors/{id}` → `200` — `Doctor`
Single doctor for the edit form. `404 doctor_not_found` if missing.

#### 37. `POST /v1/admin/doctors` → `201` — created `Doctor`
Request:
```json
{
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
- Client-mandatory: `name`, `specialization`, `qualification`,
  `experienceYears`, `rating` (0–5), `consultationFee`, `availableWeekdays`
  (non-empty; ISO Mon=1..Sun=7), `availableTime`.
- Optional: `photoUrl`.
- Errors: `400 validation_error`, `403 forbidden_admin_only`.

#### 38. `PUT /v1/admin/doctors/{id}` → `200` — updated `Doctor`
Same request shape as #37 (full replace). `404 doctor_not_found` if missing.

#### 39. `DELETE /v1/admin/doctors/{id}` → `204`
The client warns that existing appointments will be preserved. If the backend
soft-deletes instead, that's fine — just ensure the customer `/doctors` list
stops returning them. `404 doctor_not_found` if missing; `409 doctor_in_use`
if the backend refuses to delete a doctor with upcoming appointments.

---

### Admin — Appointments

Admin's read + write surface for every appointment across every user. Note
the DTO here is **richer** than the customer's `PastAppointment` (§13) —
it also carries `userId`/`userName`/`userPhone` so admin lists don't need a
separate user fetch.

#### 40. `GET /v1/admin/appointments?…filters` → `200` — `AdminAppointment[]`
Newest first. All query parameters are optional; combine as needed.

Filter query params:
- `search` — free-text match against user name **and** doctor name.
- `status` — `upcoming | completed | cancelled` (single value).
- `doctorId` — filter to one doctor.
- `dateFrom`, `dateTo` — `yyyy-MM-dd`, inclusive range on the appointment
  date (server compares against `dateTime`'s date component).
- `weekday` — ISO 1..7 (Mon..Sun).

**AdminAppointment object:**
```json
{
  "id": "a1",
  "userId": "LESzBD8zGdTww6U0HhFsEIGK5Y32",
  "userName": "Rahul Kumar",
  "userPhone": "8123456789",
  "doctorId": "doc-1",
  "doctorName": "Dr. Ananya Sharma",
  "specialization": "General Physician",
  "dateTime": "2026-07-10T11:00:00Z",
  "status": "upcoming",
  "fee": 400
}
```

#### 41. `GET /v1/admin/appointments/{id}` → `200` — `AdminAppointment`
`404 appointment_not_found` if missing.

#### 42. `POST /v1/admin/appointments` → `201` — created `AdminAppointment`
Book on a user's behalf. Same shape as the customer's `POST /appointments`
(§12) plus a `userId`. `timeSlot` should match the doctor's advertised
consulting hours (client sends `Doctor.availableTime` verbatim).

Request:
```json
{
  "userId": "LESzBD8zGdTww6U0HhFsEIGK5Y32",
  "doctorId": "doc-1",
  "date": "2026-08-03",
  "timeSlot": "10:00 AM – 1:00 PM"
}
```
Errors: `404 user_not_found`, `404 doctor_not_found`,
`409 slot_unavailable` (doctor already booked for that date — one-per-day
model), `403 forbidden_admin_only`.

#### 43. `PUT /v1/admin/appointments/{id}` → `200` — updated `AdminAppointment`
Change status and/or reschedule to a new date. Any field omitted stays as-is;
the client sends only what actually changed.

Request:
```json
{ "status": "completed", "date": "2026-08-05" }
```
- `status` — `upcoming | completed | cancelled`.
- `date` — `yyyy-MM-dd`. If sent, server keeps the doctor's `timeSlot` and
  updates `dateTime` accordingly.
- Doctor cannot be reassigned via this endpoint (delete + recreate if
  needed).
- Errors: `404 appointment_not_found`, `409 slot_unavailable` (rescheduling
  to a date the doctor is already booked on).

---

### Admin — Users (directory)

#### 44. `GET /v1/admin/users?search={q}` → `200` — `AdminUser[]`
Directory used today by the "book on behalf" user picker; the Statistics
tab will reuse it. `search` matches against name and phone (server-side).
Client currently doesn't paginate — if the backend needs pagination,
introduce `page`/`pageSize` later.

**AdminUser object:**
```json
{
  "id": "LESzBD8zGdTww6U0HhFsEIGK5Y32",
  "fullName": "Rahul Kumar",
  "phoneNumber": "8123456789",
  "email": "rahul.kumar@example.com"
}
```
- `email` may be `null`. `phoneNumber` is the national 10-digit form.
- `403 forbidden_admin_only` if not admin.

---

### Admin — Orders — **proposed, not yet built**

Admin's read + write surface for every order across every user. Note the
DTO here is **richer** than the customer's `Order` (§15) — it also carries
`userId`/`userName`/`userPhone`, same pattern as `AdminAppointment` (§40).

#### 46. `GET /v1/admin/orders?…filters` → `200` — `AdminOrder[]`
Newest first. All query parameters are optional; combine as needed.

Filter query params:
- `search` — free-text match against order number, user name **and** phone.
- `status` — `created | processing | shipped | delivered | cancelled` (single value).
- `dateFrom`, `dateTo` — `yyyy-MM-dd`, inclusive range on `placedOn`'s date.

**AdminOrder object:**
```json
{
  "id": "o10",
  "orderNumber": "SMS-100238",
  "userId": "LESzBD8zGdTww6U0HhFsEIGK5Y32",
  "userName": "Rahul Kumar",
  "userPhone": "8123456789",
  "placedOn": "2026-07-27T14:32:00Z",
  "status": "processing",
  "items": [
    { "name": "Paracetamol 500mg Tablets", "quantity": 2, "price": 30 }
  ],
  "subtotal": 510,
  "discount": 51,
  "delivery": 0,
  "total": 459,
  "paymentMethod": "googlePay",
  "addressId": "addr-0"
}
```

#### 47. `GET /v1/admin/orders/{id}` → `200` — `AdminOrder`
`404 order_not_found` if missing.

#### 48. `PUT /v1/admin/orders/{id}` → `200` — updated `AdminOrder`
Change the order's status — advance the fulfilment lifecycle or cancel.
Unlike the customer's self-cancel (#45), admin may set **any** status,
including `cancelled`, regardless of the pre-shipment window.

Request:
```json
{ "status": "shipped" }
```
- `status` — `created | processing | shipped | delivered | cancelled`.
- Errors: `404 order_not_found`, `403 forbidden_admin_only`.

---

### Admin — Discounts (promo codes) — **proposed, not yet built**

Full CRUD over promo codes, admin-only. #14 `POST /v1/promo-codes/validate`
is the customer-facing read-only validation surface; these are the admin
mutation surface (mirrors the Inventory split).

#### 49. `GET /v1/admin/promo-codes` → `200` — `AdminPromoCode[]`
All promo codes, newest first. `403 forbidden_admin_only` if not admin.

**AdminPromoCode object:**
```json
{
  "id": "promo-1",
  "code": "SAVE10",
  "label": "10% off your order",
  "type": "percentage",
  "value": 10,
  "minOrder": 0,
  "active": true,
  "expiresAt": null,
  "maxRedemptions": null,
  "perUserLimit": 1,
  "redemptionCount": 37
}
```
- `type`: `percentage | flat` (same wire values as #14).
- `expiresAt`: `yyyy-MM-dd` date, or `null` for no expiry.
- `maxRedemptions`, `perUserLimit`: `null` = unlimited.
- `redemptionCount`: server-computed, read-only — how many times the code
  has been successfully used (across all users) so far.

#### 50. `GET /v1/admin/promo-codes/{id}` → `200` — `AdminPromoCode`
Single code for the edit form. `404 not_found` if missing.

#### 51. `POST /v1/admin/promo-codes` → `201` — created `AdminPromoCode`
Request:
```json
{
  "code": "SAVE10",
  "label": "10% off your order",
  "type": "percentage",
  "value": 10,
  "minOrder": 0,
  "active": true,
  "expiresAt": null,
  "maxRedemptions": null,
  "perUserLimit": 1
}
```
- Mandatory: `code`, `label`, `type`, `value`, `active`.
- Optional (omit or `null`): `minOrder` (default `0`), `expiresAt`,
  `maxRedemptions`, `perUserLimit`.
- `code` should be unique (case-insensitive) — reject duplicates with
  `409 promo_code_exists`.
- Server starts `redemptionCount` at `0`.
- Errors: `400 validation_error`, `409 promo_code_exists`, `403 forbidden_admin_only`.

#### 52. `PUT /v1/admin/promo-codes/{id}` → `200` — updated `AdminPromoCode`
Same request shape as #51 (full replace). `redemptionCount` is untouched by
this call — it only ever changes as a side effect of successful order
placement. `404 not_found` if missing.

#### 53. `DELETE /v1/admin/promo-codes/{id}` → `204`
Hard delete. `404 not_found` if missing. No "in use" guard needed —
deleting a code doesn't affect orders that already redeemed it (their
`discount` was already computed and stored at order time).

---

### Prescriptions — **proposed, not yet built**

Customers upload a photo of a prescription (from the Pharmacy tab's
"Prescription" button, or at checkout when the cart holds an Rx-flagged
item); admin reviews it. See the architecture note above §2 — the backend
only ever sees a Firebase Storage download URL, never raw image bytes.

#### 54. `POST /v1/prescriptions` → `201` — created `Prescription`
Request:
```json
{ "imageUrl": "https://firebasestorage.googleapis.com/v0/b/…/prescriptions%2Fuid%2Fabc.jpg?alt=media&token=…" }
```
Response:
```json
{
  "id": "rx-1",
  "imageUrl": "https://firebasestorage.googleapis.com/…",
  "uploadedOn": "2026-08-28T10:00:00Z",
  "status": "pending",
  "note": null
}
```
- Server sets `status: "pending"` and `uploadedOn: now` — not client-supplied.
- `imageUrl` isn't validated for reachability; the app trusts Firebase Storage.

#### 55. `GET /v1/prescriptions` → `200` — `Prescription[]` (caller's own, newest first)
#### 56. `GET /v1/prescriptions/{id}` → `200` — `Prescription` — `404 prescription_not_found`

---

### Admin — Prescriptions — **proposed, not yet built**

Admin's review queue. Presented as a sub-tab of Admin → Orders in the
client (mirrors the Appointments/Doctors sub-tab split) since Rx approval
is part of order fulfilment, but it's its own resource here.

#### 57. `GET /v1/admin/prescriptions?status=` → `200` — `AdminPrescription[]`
Newest first. `status` optional — `pending | approved | rejected`; omit for all.

**AdminPrescription object:**
```json
{
  "id": "rx-1",
  "userId": "LESzBD8zGdTww6U0HhFsEIGK5Y32",
  "userName": "Rahul Kumar",
  "userPhone": "8123456789",
  "imageUrl": "https://firebasestorage.googleapis.com/…",
  "uploadedOn": "2026-08-28T10:00:00Z",
  "status": "pending",
  "note": null
}
```

#### 58. `GET /v1/admin/prescriptions/{id}` → `200` — `AdminPrescription`
`404 prescription_not_found` if missing.

#### 59. `PUT /v1/admin/prescriptions/{id}` → `200` — updated `AdminPrescription`
Request:
```json
{ "status": "rejected", "note": "Image is blurry, please re-upload." }
```
- `status` — `approved | rejected` (never sent back to `pending`).
- `note` — optional either way; typically the rejection reason, shown to
  the customer.
- Errors: `404 prescription_not_found`, `403 forbidden_admin_only`.

---

### Push notifications — **proposed, endpoint 60 + send-side not yet built**

The client side is fully wired (`firebase_messaging`): requests
`POST_NOTIFICATIONS` permission on sign-in, fetches the FCM token, PUTs it
to #60 (and again on every `onTokenRefresh`), shows an in-app banner for
foreground messages (`FirebaseMessaging.onMessage` — Android never shows
its own tray notification while the app is foregrounded), and deep-links on
tap (`onMessageOpenedApp` / `getInitialMessage()`) using the `data` payload
below. All verified live against Azure except the parts that need the
backend: #60 currently 404s (swallowed silently, retried on next app open
or token refresh — not surfaced to the user), and no push has actually been
sent yet since nothing server-side triggers one.

#### 60. `PUT /v1/users/me/fcm-token` → `200`
Request:
```json
{ "token": "dIHXf2kG6fUSNAkWNdZTdK:APA91bH…", "platform": "android" }
```
- `platform` — `android | ios` (this app is Android-only today; the client
  always sends `android`, kept generic for whenever iOS is added).
- A user can have multiple devices — store per `(userId, token)`, don't
  overwrite; upsert on `token` so re-registering the same device is a no-op.
- No response body needed beyond `200`; the client ignores it.

#### Message contract (what the backend sends via the Firebase Admin SDK)
Every push must include **both** blocks — `notification` so Android shows
its own tray notification automatically when the app is backgrounded/
terminated (no work needed in the client for that path), and `data` so the
client can build its in-app banner (foregrounded) and resolve a tap to a
route:
```json
{
  "token": "<recipient's registered FCM token>",
  "notification": { "title": "Order shipped", "body": "Your order is out for delivery." },
  "data": { "type": "order", "id": "o10" }
}
```
- `data.type` — `order | appointment | labTest` (matches
  `NotificationEntityType` in the client 1:1 — lowerCamelCase, same
  convention as every other enum in this app).
- `data.id` — the order id / appointment id / lab-test-booking id, used by
  the client to route the tap:
  - `order` → customer: `GET /v1/orders/{id}` then Profile → Orders detail;
    admin: `GET /v1/admin/orders/{id}` then the admin order detail/edit screen.
  - `appointment` → customer: Profile → Appointments list (no per-item
    detail route exists client-side yet); admin: the admin appointment
    edit screen via `GET /v1/admin/appointments/{id}`.
  - `labTest` → customer: Profile → Lab Tests list; admin: **no dedicated
    admin lab-test-booking screen exists yet**, so this currently just
    opens the Admin → Orders tab as the closest related surface. Worth
    building a real one if lab-test admin notifications turn out to matter
    in practice.
- Send to **one token at a time** (loop over a user's registered devices
  server-side) — the client always expects a single-recipient message, no
  multicast/topic assumptions on its end.

#### Event triggers (server-side, none built yet)
| Event | Recipient(s) | `data` | Message |
|---|---|---|---|
| `POST /orders` succeeds | All admins | `{type: "order", id}` | `"{userName} placed an order {orderNumber} for ₹{total}"` |
| Order status → `shipped` | The customer | `{type: "order", id}` | `"Your order is out for delivery."` |
| Order status → `delivered` | The customer | `{type: "order", id}` | `"Your order has been delivered."` |
| Order status → `delivered` | All admins | `{type: "order", id}` | `"{orderNumber} was delivered at {time}"` |
| Order status → `cancelled` | The customer | `{type: "order", id}` | `"Your order has been cancelled."` |
| `POST /appointments` succeeds (customer books) | All admins | `{type: "appointment", id}` | `"{userName} scheduled an appointment with Dr. {doctorName} on {date time}"` |
| Lab-test booking created (via `POST /orders` with a `labTest` item) | All admins | `{type: "labTest", id}` | `"{userName} scheduled a lab test for {testName} on {date time}"` |

Per the product decision, order `processing` does **not** notify the
customer (only `shipped`/`delivered`/`cancelled` do) — admin already sees
every order via the console, so no `created`/`processing` admin pushes are
needed either beyond the "placed" one above. `POST /admin/appointments`
(admin booking on a user's behalf) does **not** trigger the "scheduled an
appointment" admin push — that message names the customer as the actor, so
it only fires for customer-initiated bookings.

#### Daily reminder job (server-side, not built yet)
A timer-triggered job, **once daily at 8:00 AM IST**, that:
- Finds appointments with `status: "upcoming"` and a `dateTime` falling
  today → push the customer `{type: "appointment", id}` /
  `"Your appointment is scheduled today at {time}"`.
- Finds lab-test bookings with `status: "scheduled"` and a date falling
  today → push the customer `{type: "labTest", id}` /
  `"Your lab test is due today at {time}"`.

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
`invalid_category`, `product_in_use`, `doctor_in_use`, `appointment_not_found`,
`slot_unavailable`, `order_not_cancellable` (proposed, with #45),
`promo_code_exists` (proposed, with #51), `prescription_required` (proposed,
with #15), `prescription_not_found` (proposed, with #54–59).

---

## 5. Enum wire values

| Field | Values |
|---|---|
| `role` | `customer`, `admin` |
| `gender` | `male`, `female`, `other` |
| address `type` | `home`, `work`, `other` |
| order `status` | `created`, `processing`, `shipped`, `delivered`, `cancelled` |
| lab-booking `status` | `completed`, `scheduled`, `cancelled` |
| appointment `status` | `completed`, `cancelled`, `upcoming` |
| order item `kind` | `medicine`, `labTest` |
| promo `type` | `percentage`, `flat` |
| `paymentMethod` | `googlePay`, `phonePe`, `bhim`, `upi`, `cod` |
| prescription `status` | `pending`, `approved`, `rejected` |
| push `platform` | `android`, `ios` (proposed, with #60) |
| push `data.type` | `order`, `appointment`, `labTest` (proposed, with #60) |

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
