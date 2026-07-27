# Sunil Medical Store — Android Client API Specification

**Purpose of this document:** a self-contained brief for the session building the
**ASP.NET Core + MySQL backend**. It lists every API endpoint the Flutter
(Android) client needs, with exact request/response payloads derived directly
from the app's current domain models — not guessed. Everything in the app is
currently mocked client-side (in-memory repositories); this doc is the contract
to replace those mocks with real HTTP calls.

If you're starting a fresh session with this document, you have everything you
need below — you don't need the Flutter source to build the backend. Section 12
lists the Flutter source files for cross-checking if you do have repo access.

---

## 1. Project context

- **App**: "Sunil Medical Store" — Flutter Android app for a local pharmacy.
  Customers browse/order medicines & lab tests, book doctor appointments,
  manage addresses/payment methods/orders. Admins get a separate console
  (currently just a role-gated placeholder screen — out of scope for this API
  pass).
- **Client stack**: Flutter (Material 3), Riverpod, GoRouter. `dio` is already
  a dependency in `pubspec.yaml` but is **not wired to anything yet** — no
  network client, no base URL, no interceptors exist today. That setup is part
  of the work this API unlocks.
- **Auth**: Firebase Phone Authentication is **already live** in the app —
  phone + OTP sign-in, session persistence, and role read from a Firebase ID
  token custom claim. The backend's job is to **verify** that token, not to
  issue it. See §3.
- **Backend**: ASP.NET Core + MySQL (per project decision). Firebase is used
  for Auth (+ Messaging later) only — **no Firestore**. All product/order/user
  data lives in MySQL behind this API.
- **File uploads** (prescriptions) will eventually go to Azure Blob Storage —
  out of scope for this pass except where noted in §11.

---

## 2. Conventions

- **Base URL**: not yet decided — placeholder `https://api.sunilmedicalstore.com/v1`.
  Pick something and the client will read it from build config.
- **Auth header**: every endpoint below requires `Authorization: Bearer <Firebase ID token>`
  unless explicitly marked **Public**. The client already holds a live
  Firebase ID token at all times post-login (refresh handled by the
  `firebase_auth` SDK) — no extra work needed client-side to obtain it.
- **Content type**: `application/json` for all requests/responses (file
  upload endpoints in §11 are the only exception, `multipart/form-data`).
- **Money**: all prices are **integers, in rupees, no decimals, no currency
  code** — matches the app's convention throughout (`int price`, never a
  float). Do not switch to paise/decimals without telling the client team.
- **IDs**: strings everywhere. Backend internal representation (int, GUID,
  whatever) doesn't matter as long as it serializes as a string and is stable.
- **Dates/times**: ISO-8601. Use full `date-time` (`2026-07-27T10:30:00Z`) for
  anything with a time component (order placed, appointment slot); use
  `date`-only (`2026-07-27`) for date-of-birth.
- **Enums**: sent as **lowerCamelCase strings** matching the Dart enum member
  names 1:1 (see §7 for the canonical list). This keeps client-side
  `enum.values.byName(json)` deserialization trivial — please don't use
  UPPER_SNAKE_CASE or integers on the wire.
- **Errors**: recommend a consistent envelope:
  ```json
  { "error": { "code": "invalid_promo_code", "message": "Add ₹40 more to use this code." } }
  ```
  with a matching HTTP status (400 for validation, 401/403 for auth, 404, 409
  for conflicts, 500). `message` should be **user-presentable** — several
  screens (promo code, OTP-adjacent flows) show the backend's message string
  directly in the UI today (see the mock `PromoException`/`AuthException`
  pattern in §12), so keep messages short and friendly.
- **Success envelope**: return the resource directly (object or array), not
  wrapped in a `data` key — simplest mapping to the client's `FutureProvider`
  pattern. Lists don't need pagination for MVP (current catalogs are 18
  products / 7 lab tests / 5 doctors) — but consider optional
  `?page=&pageSize=` query params so you're not boxed in later.

---

## 3. Auth strategy (already live client-side)

**Flutter → Firebase is done and working.** Phone number + OTP sign-in, via
`FirebaseAuth.verifyPhoneNumber` / `signInWithCredential`, with session
persistence via `authStateChanges()`. The backend does **not** participate in
OTP/phone verification at all.

What the backend needs to do:

1. **Verify the ID token** on every request using the **Firebase Admin SDK**
   (`FirebaseAdmin` NuGet package for .NET). Extract the Firebase `uid` — that
   is the stable user identifier; use it as (or map it to) your MySQL user
   primary key.
2. **Role via custom claims.** The client already reads `role` from the ID
   token's custom claims (`claims['role'] == 'admin'` → admin, else
   customer — see `FirebaseAuthRepository._accountFor`). The backend sets
   this claim using the Admin SDK's `SetCustomUserClaimsAsync(uid, new {
   role = "admin" })`, typically via an internal/admin action — **not** a
   claim the app itself ever sets. No claim present = customer (the default).
   There is currently no "list users to promote to admin" UI anywhere in the
   app; that's an admin-console feature not yet built.
3. **First-login bootstrap.** The client's onboarding screen currently only
   calls Firebase's `updateDisplayName` — it does **not** call any backend
   endpoint today. For real integration, the client will need to call
   `PUT /users/me` (§4) after onboarding completes (and ideally as an
   idempotent upsert on every login) so a MySQL user row exists with phone
   number + name. **This is a client-side change the other session's backend
   work will need paired with a small Flutter change** — flagging it now so
   it's not a surprise.
4. **Phone number format.** Firebase gives E.164 (`+919812345678`). The app
   normalizes to a bare 10-digit national number everywhere internally
   (`AppUser.phoneNumber`, `_nationalNumber()` in `FirebaseAuthRepository`).
   Recommend the backend also store/return the bare 10-digit form so the
   client doesn't need to re-strip a country code — see the `User` schema in
   §4.

---

## 4. Users / Profile

### `GET /users/me`
Returns the signed-in user's full profile — merges the lightweight auth
identity (name/phone/role) with the extended Account-screen fields (gender,
DOB, email, medical records). Today these are two separate mock sources
client-side (`AppUser` from Firebase, `CustomerProfile` from
`MockProfileRepository`) that get merged in `customerProfileProvider`; the
real API should just return one unified object.

**Response `200`:**
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
    { "id": "mr1", "title": "Penicillin allergy", "type": "Allergy", "date": "2021-06-12" },
    { "id": "mr2", "title": "Type 2 Diabetes", "type": "Condition", "date": "2022-01-05" }
  ]
}
```
- `gender`: `"male" | "female" | "other"`.
- `medicalRecords[].type`: free-text label today (`Allergy`, `Condition`,
  `Report` are the mock examples) — not a closed enum in the client, so don't
  over-constrain it server-side either.
- `medicalRecords[].id`: the current Dart `MedicalRecord` model has **no id**
  (display-only). Add one anyway since it's good REST practice and the client
  can just ignore it until records become editable.

### `PUT /users/me`
Upsert the profile. Used for (a) onboarding bootstrap, (b) any future
edit-profile screen (not built yet — Account screen is currently read-only).

**Request:**
```json
{
  "fullName": "Rahul Kumar",
  "email": "rahul.kumar@example.com",
  "gender": "male",
  "dateOfBirth": "1994-03-18"
}
```
All fields optional/nullable except `fullName` on first creation. Returns the
same shape as `GET /users/me`.

### `GET /users/me/medical-records`
Returns `medicalRecords` alone (array, same shape as above) — convenience
endpoint if you'd rather not always inline it in the profile payload. Not
strictly required if `GET /users/me` already includes it.

---

## 5. Catalog — Medicines

Categories are currently a **static hardcoded list** client-side
(`homeCategoriesProvider`), not fetched from anywhere:
`Medicines`, `Wellness`, `Personal Care`, `Devices`, `Baby Care`, `Ayurveda`.
Recommend exposing them via an endpoint anyway so the backend owns the source
of truth going forward:

### `GET /catalog/categories`  — *(Public — no auth required, but fine to require it too)*
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
`icon` is a Material-icon-name string the client already has a fixed local
mapping for — safe to ignore this field server-side if you don't want to own
icon choices; the client can keep its local mapping keyed by `label` instead.

### `GET /catalog/products?category={label}`
Category-filtered product list (used by the Medicines tab / dashboard
category taps). Omit `category` to get the full catalog.

**Product object** (full shape — every field the client's `Product` model has):
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
  "imageUrl": null
}
```
- `mrp`: nullable; when present and `> price`, the client computes and shows
  a discount badge (`(mrp - price) / mrp`, rounded) — **the client computes
  this itself**, no need to send a precomputed `discountPercent`.
- `composition` / `dosage`: nullable strings — `null` for categories that
  don't have them today (e.g. **Devices** — thermometers, BP monitors have
  neither in the current mock data).
- `ingredients`: array, can be empty (Devices have `[]`).
- `imageUrl`: **new field, not in the current Dart model** — the app
  currently shows a placeholder icon everywhere (no real product images
  exist yet). Add this now so the client can start rendering real images
  without another contract change; client falls back to its placeholder icon
  when `null`.

**Response `200`:** `Product[]`.

### `GET /catalog/products/suggested`
The "Suggested for you" horizontal row on the dashboard. Currently a
hand-picked static subset (6 of 18 mock products) — no personalization logic
exists client- or server-side yet. Same `Product[]` shape as above. Fine to
start as "any 6 products" server-side; personalize later without a contract
change.

### `GET /catalog/products/{productId}`
Single product for the detail screen. Same `Product` shape as above.

### `GET /catalog/products/{productId}/similar`
"Similar products" row on the detail screen. Today the client fetches the
**entire catalog** and filters client-side (`same category, id != self`) —
inefficient once the catalog is large. Recommend the backend do this
filtering instead:

**Response `200`:** `Product[]` (same category, excluding `productId`,
suggest limiting to ~10).

---

## 6. Catalog — Lab Tests

Distinct from *booked* lab tests (§9) — this is the storefront catalog.

### `GET /catalog/lab-tests`
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
**Response `200`:** array of the above.
- `sampleType`: free text today (`Blood`, `Urine`, `Blood & Urine` are the
  mock examples) — not a closed enum.
- `mrp` behaves identically to Product's `mrp` (nullable, client computes
  discount%).

### `GET /catalog/lab-tests/{testId}`
Single test, same shape.

---

## 7. Appointments — Doctors

### `GET /doctors`
Returns doctors with a **recurring weekly availability pattern** (not
date-specific bookings) — this matches how the client already renders it: it
computes "this week" locally (`WeekRange.of(DateTime.now())` in
`core/utils/week_range.dart`) and highlights whichever weekdays a doctor is
available on. Recommend keeping availability as a **recurring weekday set**
server-side too (simplest — no per-week schedule management needed yet).

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
- `availableWeekdays`: integers **1 (Monday) – 7 (Sunday)**, matching Dart's
  `DateTime.monday..DateTime.sunday` constants exactly — this is the
  convention the client already uses, please don't switch to 0-indexed.
- `availableTime`: free-text display string today, not structured start/end
  times. Fine to keep as-is for now.
- `photoUrl`: new field (not in current model) for the same reason as
  `Product.imageUrl` — client currently shows initials in a colored circle
  as a placeholder avatar (`Doctor.initials` getter, computed client-side
  from `name`). Nullable; client falls back to initials when `null`.

The endpoint name is intentionally just `/doctors`, not
`/doctors/available-this-week` — "this week" is a client-side display
concern (which weekday cells to highlight), not a filter the server needs to
apply, since availability is a recurring pattern, not per-date bookings.

### `POST /appointments` — *(not yet wired client-side — see below)*
Book an appointment. **The "Book appointment" button currently just shows a
"coming soon" SnackBar** — there is no real booking flow in the app yet. This
endpoint is specified so the backend can be built ahead of the client catching
up, not because the client calls it today.

**Request:**
```json
{ "doctorId": "doc-1", "date": "2026-08-03", "timeSlot": "10:00 AM – 1:00 PM" }
```
**Response `201`:** an appointment object shaped like §9's `PastAppointment`
(below) with `status: "upcoming"` — note §9's current client model only has
`completed | cancelled`, so this is a new status value the client's
`AppointmentStatus` enum will need a 3rd case for when this ships.

### `GET /appointments/me`
List the caller's appointments (past + upcoming). Same shape as
`PastAppointment` in §9 — see that section, since today this data comes from
`ProfileRepository.pastAppointments()` and is what backs **Profile →
Appointments**.

---

## 8. Cart — recommend keeping client-side (read before building)

**Current state: the cart is 100% client-side, in-memory, and lost on app
restart or device switch.** `CartController` (a Riverpod `Notifier`) holds
`List<CartItem>` with no persistence at all — not even local disk storage,
let alone a server sync. There is **no existing cart endpoint need** driving
this doc.

**Recommendation:** don't build cart-sync endpoints for this pass unless
multi-device cart continuity is a product requirement right now. It adds
real complexity (merge conflicts between local/server cart, guest-cart
handling) for a feature the client doesn't currently support anyway. Cart
state is rebuilt fresh every session by the user adding items; only the
**order placed at checkout** needs to hit the server (§9).

If/when you do want server-side cart sync later, the shape to mirror is:
```json
{ "id": "medicine-p1", "title": "Paracetamol 500mg Tablets", "subtitle": "Micro Labs", "price": 30, "kind": "medicine", "quantity": 2 }
```
(`kind`: `"medicine" | "labTest"` — see §7's note on `CartItemKind`.) Treat
this as reference only, not a spec to implement now.

---

## 9. Orders (checkout)

This is the one flow that **must** move from mock to real backend for
checkout to mean anything. Today "Order Now" just shows a local success
dialog and clears the in-memory cart — nothing is persisted anywhere.

**Important design correction vs. the current client:** today `CartItem`
carries a **client-set price** (captured at add-to-cart time). For a real
order, **the server must price authoritatively** from its own catalog data —
never trust a client-supplied price. The request below sends item
*references* (kind + catalog id + quantity), not prices; the response
returns the priced breakdown.

### `POST /promo-codes/validate`
Called when the user taps "Apply" on a promo code in the cart, **before**
checkout. Matches `PromoRepository.validate(code, subtotal)` exactly.

**Request:**
```json
{ "code": "SAVE10", "subtotal": 310 }
```
**Response `200`:**
```json
{ "code": "SAVE10", "label": "10% off your order", "type": "percentage", "value": 10, "minOrder": 0 }
```
**Response `400`** (invalid code, or subtotal below `minOrder`):
```json
{ "error": { "code": "invalid_promo_code", "message": "Add ₹40 more to use this code." } }
```
- `type`: `"percentage" | "flat"`.
- `value`: percent (0-100) when `type=percentage`, else rupees.
- The 3 demo codes today (for reference/parity, not required to keep):
  `SAVE10` (10% off, no minimum), `FLAT50` (₹50 off, min ₹300 subtotal),
  `NEW100` (₹100 off, min ₹500 subtotal).
- Discount math (so the backend's `POST /orders` response matches exactly
  what the client would have shown): `percentage` → `subtotal * value / 100`
  (integer division); `flat` → `value`; either way, **clamped to at most the
  subtotal** (never a negative total).

### `POST /orders`
Places the order. This is the "Order Now" button on the Checkout screen.

**Request:**
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
- `items[].kind`: `"medicine" | "labTest"`. Send `productId` for medicines,
  `testId` for lab tests (matching whichever catalog the item came from) —
  mirrors `CartController.addProduct` / `.addLabTest`.
- `promoCode`: nullable — omit or `null` if none applied.
- `paymentMethod`: one of `"googlePay" | "phonePe" | "bhim" | "upi" | "cod"`.
  When `"upi"`, include `upiId` (the custom UPI id the user typed into the
  "Other UPI" field, validated client-side against `^[\w.\-]{2,}@[a-zA-Z]{2,}$`
  before submit — validate again server-side, don't trust the client):
  ```json
  { "paymentMethod": "upi", "upiId": "rahul@okaxis" }
  ```
  These 5 values come from the **UI-only** `_PaymentChoice` enum in
  `checkout_screen.dart` today — there is no domain-level `PaymentMethod`
  enum in Dart yet (don't confuse this with the *saved* `PaymentMethod` model
  in §10, which only ever stores a UPI id — the payment-method **selector**
  at checkout is broader: it includes named UPI apps and COD too).
- **No real payment gateway integration exists today.** Selecting Google
  Pay/PhonePe/BHIM is a UI choice only — no deep link, no gateway callback,
  no payment confirmation webhook. `POST /orders` should treat all payment
  methods identically for now (record the choice, mark the order placed) —
  don't build gateway integration as part of this pass unless separately
  scoped.

**Response `201`:**
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
- `status`: `"processing" | "delivered" | "cancelled"` (see §7's Dart
  `OrderStatus` enum — a freshly placed order should be `"processing"`).
- **Delivery fee logic** (so server math matches client expectations exactly):
  flat **₹40**, waived (→ `0`) when `subtotal >= ₹500`. (`_deliveryFee` /
  `_freeDeliveryThreshold` constants in `cart_providers.dart`.)
- `subtotal`/`discount`/`delivery`/`total` are **new fields vs. the current
  Dart `Order` model**, which today only stores `items[]` and *derives*
  `total` client-side by summing line totals (no discount/delivery
  breakdown persisted at all, because no real order has ever been placed).
  The backend response should include the full breakdown; the Android client
  will need a small model update to store it when this ships.
- `items[]` here intentionally drops quantity×price to just the display
  fields the Order Detail screen needs (name/quantity/price) — same shape as
  the existing mock `OrderItem`.

### `GET /orders`
List the caller's past orders — backs **Profile → Orders**.

**Response `200`:** array shaped like the `POST /orders` response above
(minus needing to resend `paymentMethod`/`addressId` if you'd rather keep the
list response lighter — Order Detail can be the fuller payload; see below).

### `GET /orders/{orderId}`
Single order detail — backs the Order Detail screen (line items + total +
"Download invoice"). Same shape as `POST /orders`'s response.

### `GET /orders/{orderId}/invoice`
"Download invoice" is currently a placeholder button (shows a "coming soon"
SnackBar) on both Order Detail and Lab Test Detail. Recommend returning
either:
- `{ "invoiceUrl": "https://.../invoices/o10.pdf" }` (simplest — client opens
  the URL), or
- streaming the PDF bytes directly with `Content-Type: application/pdf`.

Either is fine; flag which one you pick since the client-side download code
differs slightly.

---

## 10. Booked Lab Tests, Addresses, Payment Methods, Appointments (Profile history)

These four all back **Profile** menu sections. Three are currently read-only
mocks; two (Addresses, Payment Methods) are already fully interactive
client-side (in-memory `Notifier` controllers) and just need real endpoints
swapped in — the UI logic won't change.

### 10.1 Booked lab tests — `GET /lab-test-bookings`
Backs **Profile → Lab Tests** (booking *history* — distinct from the §6
storefront catalog).

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
- `status`: `"completed" | "scheduled" | "cancelled"`.

`GET /lab-test-bookings/{id}` → single record, same shape.
`GET /lab-test-bookings/{id}/invoice` → same pattern as §9's order invoice.

**⚠️ Open design question, flagging rather than deciding for you:** lab
tests are added to the **same cart** as medicines and go through the **same**
`POST /orders` checkout (see §8's `kind: "labTest"` items). That means an
order can contain lab tests, medicines, or both. Right now the mock data
treats "Orders" (§9) and "Booked Lab Tests" (here) as two **entirely separate
histories** with no linkage — an order containing a lab test wouldn't
currently show up in this list at all in the mock. Decide one of:
  - (a) `POST /orders` also creates a `LabTestBooking` row per `labTest`
    line item in the same transaction, keeping these as parallel views over
    related data (recommended — matches the two-tabs-in-Profile UI best), or
  - (b) collapse this into a filtered view of Orders
    (`GET /orders?kind=labTest`) and drop this as a separate resource.
  This wasn't decided when the mock was built — the client currently just
  shows disconnected fake data for each screen — so it's a genuinely open
  call for the backend design, not a client requirement to preserve exactly.

### 10.2 Past appointments — `GET /appointments/me`
Already specified in §7. Backs **Profile → Appointments**.
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
`status`: `"completed" | "cancelled"` today (mock); add `"upcoming"` once
real booking (§7) ships.

### 10.3 Addresses — already fully interactive client-side
Backs **Profile → Addresses**. The Riverpod `AddressController` already
supports add / set-default / remove with optimistic local state — these
endpoints are a straight swap-in, no UI changes needed.

**`GET /addresses`**
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
- `type`: `"home" | "work" | "other"`.
- `line2`: nullable.

**`POST /addresses`** — request body is the same shape minus `id`/`isDefault`,
plus an optional `makeDefault` flag:
```json
{
  "type": "work",
  "line1": "Tower B, Tech Park",
  "line2": null,
  "city": "Bhubaneswar",
  "state": "Odisha",
  "pincode": "751024",
  "makeDefault": false
}
```
Business rule to preserve: **the first address a user ever adds always
becomes default**, regardless of `makeDefault` (see `AddressController.add`:
`becomesDefault = makeDefault || state.isEmpty`). Response `201`: the created
`Address` (with `id`, `isDefault` resolved).

**`PUT /addresses/{id}/default`** — sets this address default, unsets all
others for the user (atomic — exactly one default at a time). No body.
Response `200`: the updated address, or the full list.

**`DELETE /addresses/{id}`** — the client controller supports `remove()`
though no screen currently exposes a delete button — build it anyway for
parity.

### 10.4 Payment methods — UPI only, already fully interactive client-side
Backs **Profile → Payment Methods**. Same pattern as Addresses.

**`GET /payment-methods`**
```json
{ "id": "pm-0", "upiId": "rahul@okaxis", "isDefault": true }
```
**`POST /payment-methods`** — request `{ "upiId": "rahul@okaxis" }`. Validate
server-side with the same pattern the client uses:
`^[\w.\-]{2,}@[a-zA-Z]{2,}$`. Same "first one added is default" rule as
addresses. Response `201`: created `PaymentMethod`.

**`PUT /payment-methods/{id}/default`** — same semantics as addresses.
**`DELETE /payment-methods/{id}`** — same as addresses (supported client-side, no UI button yet).

Only UPI is supported anywhere in the app today — no card storage, no
wallets-as-saved-methods. Don't build card/wallet storage speculatively.

---

## 11. Explicitly out of scope for this pass

Don't build these yet — they're UI placeholders with no wired logic client-side,
listed here only so you know *why* there's no endpoint for them:

- **Search** — the dashboard search bar is decorative (`HomeSearchBar`,
  shows a "coming soon" SnackBar on tap). No search query flow exists.
- **Image search** ("Search by image" button) — placeholder only.
- **Prescription upload** — placeholder only. When built, this will need a
  file-upload endpoint backed by **Azure Blob Storage** (per the project's
  planned stack) — e.g. `POST /prescriptions` (`multipart/form-data`) →
  returns a blob URL/reference. Worth designing alongside the medicines
  `requiresPrescription` flag (§5) once scoped, but not needed now.
- **Real appointment booking / payment gateway / SMS** — see notes inline in
  §7 and §9. Firebase already handles all SMS/OTP (§3); no SMS endpoint is
  ever needed here.
- **Admin console** — role-gated placeholder screen only
  ("Catalog, orders, and inventory management will be implemented here").
  No admin endpoints scoped yet.

---

## 12. Enum reference (canonical wire values)

| Dart enum | Wire values | Used by |
|---|---|---|
| `UserRole` | `customer`, `admin` | §3, §4 |
| `Gender` | `male`, `female`, `other` | §4 |
| `AddressType` | `home`, `work`, `other` | §10.3 |
| `OrderStatus` | `processing`, `delivered`, `cancelled` | §9 |
| `LabTestStatus` (booked) | `completed`, `scheduled`, `cancelled` | §10.1 |
| `AppointmentStatus` | `completed`, `cancelled` (+ future `upcoming`) | §7, §10.2 |
| `CartItemKind` | `medicine`, `labTest` | §8, §9 |
| `PromoType` | `percentage`, `flat` | §9 |
| Payment method (checkout, UI-only today) | `googlePay`, `phonePe`, `bhim`, `upi`, `cod` | §9 |

---

## 13. Flutter source files for cross-reference

If this session has access to the app repo, these are the exact files the
schemas above were read from (all under `lib/`):

- `core/models/app_user.dart`, `core/models/user_role.dart`
- `features/auth/domain/{auth_account,auth_repository}.dart`,
  `features/auth/data/firebase_auth_repository.dart`
- `features/medicines/domain/{product,product_repository}.dart`,
  `features/medicines/data/mock_product_repository.dart`
- `features/lab_tests/domain/{lab_test,lab_test_repository}.dart`
- `features/appointments/domain/{doctor,doctor_repository}.dart`,
  `core/utils/week_range.dart`
- `features/cart/domain/{cart_item,promo_code,promo_repository}.dart`,
  `features/cart/presentation/providers/cart_providers.dart`,
  `features/cart/presentation/screens/checkout_screen.dart`
- `features/profile/domain/{customer_profile,past_appointment,order,lab_test,address,payment_method}.dart`,
  `features/profile/domain/profile_repository.dart`,
  `features/profile/presentation/providers/{address_controller,payment_controller}.dart`
- `features/dashboard/presentation/providers/dashboard_providers.dart`
- Project-level context: `CLAUDE.md` at the repo root (architecture,
  conventions, current feature state, Firebase project details).

---

## 14. Suggested next steps for the backend session

1. Confirm base URL / environment strategy (dev vs. prod) and hand it back so
   the Flutter side can wire up `dio` (currently an unused dependency) with a
   base URL + an interceptor that attaches the Firebase ID token to every
   request and maps error responses to the app's existing
   `AuthException`/`PromoException`-style typed exceptions.
2. Stand up `GET/PUT /users/me` first — every other authenticated endpoint
   assumes a MySQL user row exists, created via this bootstrap.
3. Catalog endpoints (§5, §6) are pure reads — good next target, no auth
   edge cases.
4. Orders (§9) is the highest-value integration (turns checkout from a fake
   local dialog into a real persisted order) but depends on catalog +
   addresses + payment methods existing first.
5. Resolve the Orders-vs-LabTestBookings open question (§10.1) before
   building either.
