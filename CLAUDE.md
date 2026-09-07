# Medical Store App

## Objective

Android application for a local pharmacy ("Sunil Medical Store"). Customers
browse/search medicines, upload prescriptions, book doctor appointments, and
manage orders, lab tests, addresses and payments. Admins get a separate
console. The backend is **live** (ASP.NET Core + MySQL, deployed to Azure) and
every feature talks to it over HTTP — see "Data & backend strategy".

## Tech Stack

- Flutter (Material 3), Dart 3.12
- Riverpod 3 (state management)
- GoRouter 17 (navigation)
- Firebase Authentication (phone/OTP) — **live**
- Firebase Messaging (push notifications — see "Push notifications" below;
  **fully live end-to-end** — client and backend send-side both verified
  against real devices)
- `fl_chart` (Statistics dashboard charts — see "Statistics" below)
- Firebase Storage (prescription image uploads — see "Prescriptions" below;
  `firebase_storage` package, **needs Storage enabled in the Firebase
  console** — not yet done, uploads currently fail with a 404 until it is)
- **ASP.NET Core + MySQL backend** — **live**, deployed to Azure App Service;
  this is the real data store
- No Firestore. See "Data & backend strategy".

## Coding Guidelines

- Use Material 3. Follow feature-first architecture. Use Riverpod.
- Keep widgets small. Prefer StatelessWidget. Separate UI and business logic.
- No mock data inside widgets — repositories/providers supply data.
- Write production-quality code. Avoid unnecessary packages.
- Always explain changed files.

## Architecture & folder layout

Feature-first. Each feature: `lib/features/<feature>/{domain,data,presentation/{screens,widgets,providers}}`.

- `lib/core/` — cross-cutting: `models/` (`AppUser`, `UserRole`), `routes/`
  (`app_router.dart`, `app_routes.dart`), `theme/` (`AppTheme`, `AppColors`,
  `AppConstants` design tokens, `AppTextTheme`), `utils/` (`week_range.dart`),
  `widgets/` (`scaffold_with_nav_bar.dart`, `placeholder_screen.dart`).
- `lib/app.dart` — `MyApp` (`ConsumerWidget`) → `MaterialApp.router` reading `routerProvider`.
- `lib/main.dart` — `Firebase.initializeApp` then `runApp(ProviderScope(MyApp))`.
- Features: `auth`, `splash`, `dashboard` (Pharmacy landing), `medicines`,
  `lab_tests`, `appointments`, `cart`, `profile`, `admin`.

**Conventions**
- Repositories: `domain/<x>_repository.dart` (interface) + `data/api_*.dart`
  (real implementation over Dio) exposed via a Riverpod `Provider`. No mock
  repositories remain — see "Data & backend strategy".
- Read data with `FutureProvider` + `AsyncValue.when` (loading/error/data).
- Mutations that need to refresh a list after writing go through an
  `AsyncNotifier`/`AsyncNotifierProvider` (e.g. addresses, payment methods)
  that calls the repository then re-fetches; purely local/derived state (e.g.
  cart quantities) uses a plain `Notifier`/`NotifierProvider`.
- "Coming soon" features show a SnackBar placeholder.
- Design tokens (spacing/radius) live in `AppConstants`; don't hard-code.

## Navigation (GoRouter)

`routerProvider` in `lib/core/routes/app_router.dart`. A single `redirect`
enforces the whole policy, driven by `authControllerProvider` via a
`refreshListenable`.

- Top-level routes (no bottom bar): `/` splash, `/login`, `/onboarding`.
- Customer area = `StatefulShellRoute.indexedStack` with 5 tabs (each keeps its
  own stack, in this order): **Pharmacy** `/pharmacy` (default), **Lab Tests**
  `/lab-tests`, **Appointments** `/appointments`, **Cart** `/cart`, **Profile**
  `/profile`. (Nav destination order must match branch order in the router.)
- Admin area = **parallel** `StatefulShellRoute.indexedStack` with 5 tabs:
  **Inventory** `/admin/inventory` (default), **Appointments**
  `/admin/appointments`, **Orders** `/admin/orders`, **Discounts**
  `/admin/discounts`, **More** `/admin/more` (a menu screen, not a direct
  feature — see below). Admin nested routes live under the parent tab, e.g.
  `/admin/inventory/new`, `/admin/inventory/edit/<productId>`. Every
  *tab-root* admin screen includes an `AdminSignOutButton` app-bar action (no
  Profile tab to sign out from); nested/detail screens don't repeat it.
  **More** (`AdminMoreScreen`) is a plain `ListTile` menu — not a feature
  itself — for admin destinations that don't warrant their own bottom-nav
  slot: currently **Statistics** (`/admin/more/statistics`, moved here from
  its own tab) and **Users** (`/admin/more/users`); future admin-only
  screens append the same way instead of growing the bottom nav further.
- Sub-pages nest under their tab so the bottom bar stays visible, e.g.
  `/pharmacy/medicines?category=<label>`, `/pharmacy/medicine/<productId>`,
  `/lab-tests/<testId>`, `/cart/checkout`, `/profile/account`, `/profile/orders`,
  `/profile/orders/detail` (order passed via `extra`), `/profile/addresses/add`, etc.
- The Cart tab icon shows a live item-count `Badge` (`ScaffoldWithNavBar` is a
  `ConsumerWidget` watching `cartItemCountProvider`).
- Redirect policy: `unknown`→splash; `unauthenticated`→login;
  `onboarding`→/onboarding; authenticated→role home
  (admin→`/admin/inventory`, customer→`/pharmacy`); admins blocked from
  everything outside `/admin/**` and customers blocked from `/admin/**` via
  a `startsWith(AppRoutes.admin)` prefix check.

## Authentication (Firebase Phone Auth — live & verified)

Real Firebase phone/OTP auth, verified end-to-end on the emulator.

- `AuthRepository` (`features/auth/domain`) — stream-based:
  `authStateChanges()` (source of truth, gives session persistence across
  restarts), `sendOtp`, `verifyOtp`, `completeProfile`, `signOut`.
  `FirebaseAuthRepository` implements it (`features/auth/data`).
- `AuthController` (`Notifier<AuthState>`) subscribes to `authStateChanges()`.
  `AuthStatus`: `unknown | authenticated | onboarding | unauthenticated`.
- Flow: login (phone → `sendOtp`) → OTP step (`verifyOtp` → `signInWithCredential`)
  → if the Firebase user has no `displayName` → **onboarding** screen (collect
  name → `updateDisplayName`) → dashboard.
- **Name** is stored on the Firebase user's `displayName` (no profile DB).
- **Role** is admin if **either**: (a) the ID token's `role` custom claim is
  `admin` (set by the backend via the Admin SDK), **or** (b) the signed-in
  phone number is in `FirebaseAuthRepository._adminPhoneNumbers` — a
  hard-coded 10-digit set. Currently only `9124833215` (`+91 91248 33215`).
  The hard-coded fallback lets the admin console be demoed with no backend
  infrastructure; add new admins by extending the set. `UserRole` enum in
  `core/models`.
- Phone numbers: UI takes 10 digits; controller sends E.164 `+91<digits>`.
  `AppUser.phoneNumber` stores the national 10-digit; `displayPhone` formats it.
- Widget test overrides `authRepositoryProvider` with an in-test fake so it
  never touches Firebase.

## Data & backend strategy (important decision)

**Firebase = Auth (+ Messaging later) only. No Firestore.** All app data —
users, orders, lab tests, addresses, payments, catalog — lives in **MySQL**
behind the **.NET Core** backend (see the sibling repo `SunilMedicalStore` for
the backend source and `docs/API_ENDPOINTS.md` for the full contract). Every
API call sends the Firebase **ID token**, which the backend verifies with the
Firebase Admin SDK (and can set role custom claims). `cloud_firestore` was
removed as unused. Every repository is now backed by a real `Api*Repository`
over Dio — no mock repositories remain.

- **API base URL** (`lib/core/network/api_config.dart`): defaults to the
  hosted Azure backend —
  `https://sunilmedical-bxg0bheub8aqdjfk.southindia-01.azurewebsites.net/v1`
  (DB: Aiven-hosted MySQL, free tier). Override for local dev with
  `flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:5260/v1`
  (`10.0.2.2` is how the Android emulator reaches the host machine's
  `localhost`).
- `lib/core/network/api_client.dart` (`dioProvider`) attaches the bearer token
  and, in debug builds, logs every request/response via `LogInterceptor`
  (visible in `adb logcat`, tag `flutter`) — the go-to tool for diagnosing
  401/500/timeout issues against either backend.

## Features (current state)

- **Splash** — shown while the auth session resolves.
- **Pharmacy (dashboard)** — greeting; two buttons above search (**Search by
  image** — placeholder; **Prescription** — real, opens `/pharmacy/prescriptions`);
  search bar → real, opens `/pharmacy/search` (`SearchScreen`); promo banner;
  **Shop by category** grid (`homeCategoriesProvider`); **Suggested for you**
  horizontal products.
- **Search** (`SearchScreen`, `lib/features/medicines/presentation/screens/search_screen.dart`)
  — plain text field in the app bar (`onSubmitted`, matching the search-on-submit
  convention used by every admin list screen), results as `ProductCard`s
  reusing the Medicines list styling. Backed by `ProductRepository.searchProducts`
  → `GET /catalog/products?search=`. **Live** — backend now does real
  case-insensitive substring filtering (searching "para" correctly returns
  only Paracetamol 500mg Tablets); previously it silently ignored the
  `search` param and returned the full catalog, since fixed.
- **Prescriptions** (`lib/features/prescriptions/`) — upload flow reachable
  from the dashboard "Prescription" button and from checkout. `PrescriptionsScreen`:
  list of the caller's uploads with a `StatusChip` (pending/approved/rejected
  + rejection note) and an "Upload prescription" FAB → bottom sheet
  (camera/gallery via `image_picker`) → uploads straight to **Firebase
  Storage** (`prescriptions/{uid}/{uuid}.{ext}`) → sends the resulting
  download URL to `POST /v1/prescriptions` (backend never sees raw file
  bytes). Backed by `PrescriptionRepository` (`domain`) +
  `ApiPrescriptionRepository` (`data`). **Backend endpoints 54–59 are live**
  against Azure (`GET /prescriptions` verified). **Still blocked on one
  manual step**: Firebase Storage isn't enabled for this project yet
  (Console → Storage → Get started) — until then, the upload itself fails
  with a Firebase `object-not-found`/404 before the backend is ever called
  (verified live on the emulator; surfaces as a clean snackbar, doesn't
  crash). The full checkout-gating and admin-review paths are built but not
  yet exercised end-to-end because of this.
- **Push notifications** (`lib/core/notifications/`) — customer gets
  notified on order status → shipped/delivered/cancelled (not `processing`)
  and same-day appointment/lab-test reminders (daily job, 8 AM IST); admin
  gets notified on order placed/delivered and new appointment/lab-test
  bookings. `NotificationService` (`notification_service.dart`) is
  initialized from `AuthController` on every authenticated transition
  (alongside the profile bootstrap call): requests `POST_NOTIFICATIONS`
  permission, fetches the FCM token, PUTs it to `/v1/users/me/fcm-token`
  (re-sent on `onTokenRefresh`). `FirebaseMessaging.onMessage` (foreground)
  shows an in-app banner (`in_app_notification_banner.dart`, an `Overlay`
  entry inserted via `rootNavigatorKey` from `app_router.dart` — no
  `BuildContext` needed, works from anywhere); background/terminated is
  handled automatically by Android's system tray for a `notification` +
  `data` payload. Tapping (foreground banner, `onMessageOpenedApp`, or
  `getInitialMessage()` on cold start) parses the `data` payload
  (`NotificationPayload`, `type: order|appointment|labTest` + `id`) and
  deep-links via `GoRouter` — customer order taps use a new fetch-by-id path
  (`ProfileRepository.orderById` → `OrderDetailByIdScreen`, since a
  notification only carries an id, not the full `Order` the in-list route
  normally gets via `extra`); admin order/appointment taps reuse the
  existing `getById` providers. Admin lab-test-booking notifications have
  nowhere dedicated to deep-link to yet (no admin lab-test screen exists) —
  they land on Admin → Orders as the closest related surface. On receipt of
  an `order`-type payload (both the foreground path and the tap/deep-link
  path), `NotificationService` also invalidates `pastOrdersProvider` and
  `orderByIdProvider(id)` so an already-open Orders list or Order Detail
  screen reflects an admin-made status change live, without a manual
  pull-to-refresh — `OrderDetailScreen` itself uses `ref.listen` on
  `orderByIdProvider` for this (it's seeded from a static `extra`-passed
  `Order`, so without this it would never notice a change made elsewhere).
  **Fully live end-to-end, verified with real devices** — placed and
  cancelled a real order and watched both the admin "order placed" push and
  the customer "order cancelled" push arrive as in-app banners with the
  exact spec'd wording. Background/terminated tray delivery and the daily
  8 AM reminder job haven't been separately exercised yet (the foreground
  banner path covers the same code either way). Full contract — message
  shape, every event trigger, the daily job's schedule — is in
  `docs/API_ENDPOINTS.md` §Push notifications.
- **Medicines** — category-filtered product list from `?category=`; `Product`
  model + `medicine_providers`. "Add" → adds to cart.
  Tapping a product name/card (list, suggested row, or similar-products row)
  opens **medicine detail** (`/pharmacy/medicine/<productId>`): image
  placeholder, price/discount, description, composition, dosage, ingredients
  (chips), a **Similar products** row (same category, recursively tappable),
  and a sticky **Add to cart**. `Product` carries the extra fields
  (`description`/`composition`/`dosage`/`ingredients`), all optional since
  non-medicine categories (e.g. Devices) don't populate them.
  Also carries `stock: int` — when `0`, `Product.isOutOfStock` is true and
  the catalog UIs (ProductCard, SuggestedProductCard, MedicineDetailScreen)
  grey out the card + disable Add + show an "Out of stock" badge. Cart's
  `addProduct` no-ops on out-of-stock as a defensive backstop.
- **Lab Tests** (tab) — bookable-test catalog like medicines
  (`features/lab_tests`, `LabTest` model + `ApiLabTestRepository` +
  `labTestCatalogProvider`), backed by `GET /catalog/lab-tests` /
  `GET /catalog/lab-tests/{id}`. List → detail (`/lab-tests/<testId>`) with
  sample type / report time / fasting / parameters → **Add to cart**. Note:
  distinct from **Profile → Lab Tests** (booked history); this tab is the
  storefront.
- **Appointments** — doctors available this week, real via
  `ApiDoctorRepository` (`GET /doctors`, `weeklyDoctorsProvider`); doctor
  cards with a Mon–Sun availability strip; **Book** is real —
  `ApiAppointmentRepository.book()` (`POST /appointments`), confirmed live
  with a booking confirmation snackbar. Current-week math in
  `core/utils/week_range.dart`.
- **Cart** — functional, in-memory (`cartProvider` Notifier), holds **both
  medicines and lab tests**. `CartItem` stores neutral fields (`id`, `title`,
  `subtitle`, `price`, `kind` = `CartItemKind.medicine|labTest`) — a snapshot of
  the catalog item, so the cart isn't coupled to either catalog domain;
  `addProduct(Product)` / `addLabTest(LabTest)` map into it. Add-to-cart from
  medicines list + dashboard suggestions + lab test detail. Cart screen: line
  items with ± quantity steppers + remove; **promo code** — real via
  `ApiPromoRepository.validate()` (`POST /promo-codes/validate`), codes are
  whatever's live in Admin → Discounts (no client-hardcoded codes); price
  breakdown (subtotal, discount, delivery — free above ₹500 — total),
  derived via providers in `cart_providers.dart`. **Payment** → **Checkout**
  (`/cart/checkout`): default delivery address + change (bottom-sheet picker
  from `addressesProvider`); pay via UPI apps (Google Pay / PhonePe / BHIM /
  Other UPI with a custom UPI-id field) or **Cash on Delivery**. When the cart
  holds an Rx-flagged item (`CartItem.requiresPrescription`, set from
  `Product.requiresPrescription` in `addProduct`;
  `cartRequiresPrescriptionProvider` derives the cart-wide flag), a
  **"Prescription required"** card gates **Order Now** — pick an existing
  non-rejected upload or take/upload a new one inline (reuses the
  Prescriptions upload flow); the chosen id is sent as `prescriptionId`.
  **Order Now** → real `POST /orders` (`ApiOrderRepository`) → success dialog
  → clears cart + promo → home. Payment is a selection UI only (no
  gateway/UPI deep-link) — the order itself is real and shows up immediately
  in Profile → Orders.
  Profile → Orders → detail has a **Cancel order** action while
  `status.isCustomerCancellable` (`created`/`processing` — hidden once
  shipped); calls `OrderRepository.cancelOrder` (`PUT /orders/{id}/cancel`).
- **Profile** — header + 6 menus + Sign Out:
  - **Account** — gender-based avatar, personal details, medical records
    (real backend data, read-only — see the Account note below).
  - **Appointments** — past appointments + "Book Appointment" → Appointments tab.
  - **Orders** — history list → detail (items, total, **Download invoice**).
  - **Lab Tests** — history list → detail (parameters, **Download invoice**).
  - **Invoice download** (Orders + Lab Tests detail) — real: fetches
    `{ invoiceUrl }` from `GET /orders/{id}/invoice` /
    `GET /lab-test-bookings/{id}/invoice` via `ProfileRepository`, opens it
    with `url_launcher` (`LaunchMode.externalApplication`). Verified live —
    Chrome opens with the exact URL the backend returns. The backend's
    `invoiceUrl` is currently a placeholder domain (`api.sunilmedicalstore.com`,
    doesn't resolve — no real PDF generation yet), so the page itself won't
    load; that's expected per `docs/API_ENDPOINTS.md`, not a client bug.
  - **Addresses** — list, **Set as default**, **Add address** — real via
    `ApiAddressRepository` (`GET/POST /addresses`,
    `PUT /addresses/{id}/default`, `DELETE /addresses/{id}`), wrapped in an
    `AsyncNotifierProvider` (`addressesProvider`) that re-fetches after each
    mutation.
  - **Payment Methods** — list, **Add UPI** dialog — real via
    `ApiPaymentMethodRepository` (`GET/POST /payment-methods`,
    `PUT /payment-methods/{id}/default`, `DELETE /payment-methods/{id}`),
    same `AsyncNotifierProvider` pattern (`paymentMethodsProvider`). Only UPI
    supported for now.
  - **Account** data — real via `ApiProfileRepository.customerProfile()`
    (`customerProfileProvider`), which self-heals a missing backend user row
    on first sign-in. Name/phone shown around the app are the real auth
    values; Account's extended fields (gender, DOB, email, medical records)
    now come from the backend too, not mock data — there's just no edit UI
    for them yet (`upsertProfile()` exists on the repository but nothing
    calls it).
- **Admin console** (`lib/features/admin/`) — role-gated, mirrors the
  customer's 5-tab shell (`AdminScaffoldWithNavBar` in `core/widgets`). Tabs:
  - **Inventory** — full CRUD over the product catalog against
    `/v1/admin/products`. `InventoryRepository` (`domain`) +
    `ApiInventoryRepository` (`data`) exposed via
    `inventoryRepositoryProvider`; `adminInventoryListProvider(category)`
    and `adminProductByIdProvider(id)` back the screens. **List** with
    category filter chips (from `homeCategoriesProvider` — same categories
    as the customer dashboard) + an "In stock only" toggle; each row shows a
    `StockBadge` (In stock N / Low: N / Out of stock) and the Rx flag. Tap a
    row → **Edit form**; FAB → **Add form**. The form supports both modes
    (`productId == null` means Add), captures all `Product` fields
    (mandatory: Name, Brand, Category, Price, Quantity, Composition, Rx;
    optional: MRP, Description, Dosage, Ingredients as comma-separated
    string, Image URL), and has a delete-with-confirm action on Edit.
  - **Appointments** — a `DefaultTabController` shell with **two sub-tabs**:
    - _Appointments sub-tab_ (`AdminAppointmentsListScreen`) — every
      appointment across every user. Search bar (name or doctor) +
      filter bottom sheet (`AppointmentFilterSheet`) with status chips,
      doctor dropdown, date range, day-of-week. Applied filters live in
      `adminAppointmentFiltersProvider` (Notifier); the list is a
      `FutureProvider` that re-fetches when filters change. Tap a row →
      `EditAppointmentScreen` (change status and/or reschedule date; doctor
      and user stay the same). FAB → `CreateAppointmentScreen` (pick user
      via `PickUserSheet` → pick doctor from dropdown → pick date with
      selectable-days constrained to the doctor's weekly schedule → book
      via `POST /admin/appointments`). `_pickDate` walks forward from
      today/the current selection to the first day matching the doctor's
      `availableWeekdays` before opening `showDatePicker` — its
      `initialDate` must already satisfy `selectableDayPredicate` or the
      picker throws (hit this for real: today, Fri, wasn't one of the
      selected doctor's working days). All backed by
      `AdminAppointmentRepository` (`domain`) +
      `ApiAdminAppointmentRepository` (`data`) against
      `/v1/admin/appointments`, plus `AdminUsersRepository` for the picker.
    - _Doctors sub-tab_ (`AdminDoctorsListScreen`) — full CRUD via
      `DoctorAdminRepository` on `/v1/admin/doctors`. Tap a row →
      `AddOrEditDoctorScreen` (all `Doctor` fields; weekday multi-select
      via shared `WeekdaySelector`; free-text consulting hours; delete-with-
      confirm on edit). Reuses the customer `Doctor` domain model.
  - **Orders** — a `DefaultTabController` shell with **two sub-tabs**
    (mirrors the Appointments/Doctors pattern):
    - _Orders sub-tab_ (`AdminOrdersListScreen`) — search by order
      #/user/phone + filter sheet: status, date range → tap a row →
      `AdminOrderDetailScreen` (read-only user/items/total, status
      `ChoiceChip`s covering the full lifecycle —
      `created → processing → shipped → delivered`, plus `cancelled` —
      Save applies via a single status-change PUT). Backed by
      `AdminOrderRepository` (`domain`) + `ApiAdminOrderRepository`
      (`data`) against `/v1/admin/orders`. This also widens `OrderStatus`
      (`core/models/order.dart`) from `processing | delivered | cancelled`
      to `created | processing | shipped | delivered | cancelled`. **Live**
      against Azure as of this writing.
    - _Prescriptions sub-tab_ (`AdminPrescriptionsListScreen`) — Rx review
      queue, status filter chips (defaults to **Pending review**) → tap a
      row → `AdminPrescriptionDetailScreen` (full-size image +
      Approve/Reject; Reject prompts for an optional note shown to the
      customer). Backed by `AdminPrescriptionRepository` (`domain`) +
      `ApiAdminPrescriptionRepository` (`data`) against
      `/v1/admin/prescriptions`.
    **Orders backend is live**; **Prescriptions (54–59) endpoints in
    `docs/API_ENDPOINTS.md` are implemented server-side but prescription
    uploads still fail** — see the Prescriptions feature note below (Firebase
    Storage isn't enabled for this project yet, a separate manual step from
    the backend deploy).
  - **Discounts** — full CRUD over promo codes, mirroring the Inventory
    pattern. `DiscountsListScreen` (code, label, value, active/expired/
    exhausted status badge) → tap a row → `AddOrEditPromoCodeScreen`
    (mandatory: code, label, type — percentage/flat —, value, active;
    optional: min order, expiry date, max total uses, max uses/user;
    delete-with-confirm on edit). Backed by `DiscountRepository` (`domain`)
    + `ApiDiscountRepository` (`data`) against `/v1/admin/promo-codes`.
    **Live** against Azure — full CRUD verified. Reuses the customer
    `PromoType` enum (`features/cart/domain/promo_code.dart`). **Note**: the
    backend keys promo codes by `code` itself — there's no separate `id` in
    the wire shape, and `PUT` silently keeps the original `code` even if the
    request body sends a different one (renames aren't supported). The
    client's `_fromJson` falls back to `code` when `id` is absent, and the
    Code field is locked (not editable) once a promo code exists.
  - **More** (`AdminMoreScreen`, `lib/features/admin/more/`) — a plain
    `ListTile` menu, not a feature of its own, for admin destinations that
    don't need their own bottom-nav slot. Currently two entries:
    - **Statistics** (`/admin/more/statistics`) — one dashboard, one
      aggregate call per range change (`GET /v1/admin/stats?range=`, not
      one endpoint per widget). `StatsRange` selector
      (`today | 7d | 30d | all`) as `ChoiceChip`s at the top, backed by
      `statsRangeProvider`. Below: revenue + order-count `StatTile`s, a
      `RevenueLineChart` (`fl_chart`) trend — bucket labels
      (hourly/daily/monthly) are pre-formatted server-side, the client just
      renders them; an order-status `StatusBarChart` (also `fl_chart`, one
      semantically-colored bar per `OrderStatus`); a top-10 best-sellers
      list; a low-stock list reusing Inventory's `StockBadge`; and the same
      stat-tile + status-bar-chart pattern repeated for appointments and lab
      tests. Backed by `StatsRepository` (`domain`) + `ApiStatsRepository`
      (`data`) against endpoint 61 in `docs/API_ENDPOINTS.md`. **Live** —
      verified against real data on the emulator: revenue/order totals, the
      revenue trend line, and the order-status bar chart all correctly
      reflected a real cancelled ₹70 test order; low-stock, appointments,
      and lab-tests sections all rendered correctly too (including a
      correctly empty lab-tests chart with zero bookings). No longer a
      tab root, so its app bar dropped the `AdminSignOutButton`.
    - **Users** (`/admin/more/users`, `lib/features/admin/users/`) — full
      CRUD directory over customer records, mirroring the Inventory/
      Discounts pattern. `AdminUsersListScreen`: search bar (name or phone)
      + `AdminUserTile` rows; FAB → **Add user**. Tap a row → **Edit user**
      (full name + email editable; phone number locked — it's the account's
      Firebase login identity, same lock reasoning as Discounts' `code`
      field — plus delete-with-confirm). Backed by `AdminUsersRepository`
      (`domain`) + `ApiAdminUsersRepository` (`data`) against
      `/v1/admin/users` (endpoints 44, 62–65 in `docs/API_ENDPOINTS.md`);
      the same repository also backs the "book on behalf" `PickUserSheet`
      in Admin → Appointments. **"Add user" pre-registers a walk-in/phone
      customer** who hasn't signed into the app yet — the backend must key
      this by phone number and reconcile it with that person's real Firebase
      account on their first real login (see the doc's reconciliation
      note), otherwise they'd end up with two separate history-splitting
      records. **Delete is blocked server-side** (not just client-side) if
      the user has any order/appointment/lab-test history, surfaced as a
      plain error message. **Live** — full CRUD verified end-to-end on the
      emulator against the real admin account: created a walk-in user,
      edited their email, deleted them, each step confirmed by the app's
      own success message and the list correctly re-fetching afterward.

## Backlog (prioritized, not started)

The single tracked list — every open item lives here, ranked by intended
pickup order. The user confirms which one to start explicitly; this table
is a plan, not a queue being worked automatically. Update it (status,
ranking, new items) as items are picked up, finished, or reprioritized.

| # | Item | Type | Status | Notes |
|---|------|------|--------|-------|
| 1 | Order status doesn't refresh immediately for the customer after an admin changes it | Bug | **Done** | Root cause: `NotificationService` never invalidated `pastOrdersProvider`/`orderByIdProvider` on push receipt, and `OrderDetailScreen` held a static `extra`-passed `Order` with no live provider binding at all. Fixed both; verified live — changed a real order `created→shipped` via a direct API call while the customer sat on both the Orders list and the Order Detail screen, both updated with no manual refresh |
| 2 | Bottom nav "Appointments" label wraps to 2 lines on some device widths | UI bug | Not started | Make the customer/admin `NavigationBar` responsive |
| 3 | Lab-test booking notifications show `{date}` only, no time-of-day | Minor bug | Not started | Backend-flagged (`LabTestBooking.BookedOn` is date-only); fix if it matters — no decision yet |
| 4 | Enable Firebase Storage (Blaze plan) to unblock Prescriptions | Blocked — user action | Waiting on you | Prescriptions is fully built client + backend (endpoints 54–59 live); blocked on this one manual Firebase Console step (Console → Storage → Get started, then Blaze plan) |
| 5 | Cancel appointment | New feature | Not started | Customer-facing cancel action, mirrors the existing order-cancel pattern (`PUT` to a cancel endpoint, hidden once not cancellable) |
| 6 | Doctor ratings from customers | New feature | Not started | Suggested earlier, not yet scoped |
| 7 | Statistics date filters: `6 months` / `1 year` + custom year/month picker | Improvement | Not started | Add range pills + a "more filters" icon opening a year/month selector |
| 8 | Admin order-status flow: swipe-to-advance + separate cancel; Orders gains 3 tabs (Pharmacy / Prescriptions / Pathology) | New feature | Not started | Replaces the free-choice `ChoiceChip` status picker with a linear swipe ("Process Order" → processing → shipped → delivered) + a standalone red Cancel button (disabled once already cancelled) |
| 9 | Lab test / appointment status flow: `Scheduled → InSession → Completed`, `Cancelled` | New feature | Not started | Same swipe-to-advance + separate cancel pattern as #8. Depends on #8's swipe UI being built first |
| 10 | Order ID format standardization — `PHSMS-<mmyy>-<seq>` / `PLSMS-<mmyy>-<seq>` / `DASMS-<mmyy>-<seq>` | New feature | Not started | Backend-heavy (per-type sequence generation). **Decided**: new orders only, existing `SMS-<seq>` orders keep their numbers, no backfill |
| 11 | Location integration — capture address location, derive read-only area/pincode, home-screen area display, admin-configurable order-radius gating | New feature | Not started | Pharmacy orders blocked outside the radius; lab tests/appointments always allowed. **Decided**: device-only `Geocoder` + Haversine distance, no Maps API billing |
| 12 | Dynamic delivery & platform fees, admin-configurable under new More menu | New feature | Not started | Distance-tiered delivery fee + single platform fee, both with a "mark as free" strike-through toggle. Pharmacy orders only. Depends on #11's distance calc |
| 13 | Inventory bulk import (Excel upload and/or barcode scan) | New feature | Needs discussion | Scope not yet defined — discuss format/flow before estimating |
| 14 | UI beautification — full app redesign, modern/minimal style, new logo, redesigned in-app notifications | New feature | Needs discussion | **Decided**: user supplies the logo asset; scheduled last, after items 1–13 stabilize, so screens don't get restyled twice |
| 15 | Image search | New feature | Backlogged | Explicitly deprioritized earlier — don't start unless asked |

## Android / build notes

- Firebase project: **sunil-medical-store**. `google-services.json` present.
- `applicationId = com.example.sunil_medical_store` (the installed package —
  SHA fingerprints go on this Firebase app); `namespace = com.sunilmedical.store`.
  `MainActivity.kt` lives at `android/app/src/main/kotlin/com/sunilmedical/store/`.
- `INTERNET` permission is in the main manifest (needed for release auth).
- **Windows build fix:** `kotlin.incremental=false` in `android/gradle.properties`
  (the Kotlin Build Tools API incremental cache fails to close on Windows —
  "Could not close incremental caches"). Also `android.newDsl=false`.
- Known harmless warning: `firebase_storage` applies its own Kotlin Gradle
  Plugin (KGP deprecation notice) — build still succeeds.

## Running & testing on the emulator

- Emulator `emulator-5554` (Android 16). adb at
  `C:/Users/abipa/AppData/Local/Android/Sdk/platform-tools/adb.exe`.
- `flutter build apk --debug` then `adb install -r`, `am start -n
  com.example.sunil_medical_store/com.sunilmedical.store.MainActivity`.
  Cold start is slow (~8–15s) before the first Flutter frame.
- adb `input text` drops characters here — type via `input keyevent KEYCODE_*`.
  Tap coords: screenshots display at 900×2000 but the device is 1080×2400
  (multiply by 1.2).
- **Firebase test numbers** (Console → Auth → Sign-in method → Phone → Phone
  numbers for testing) work on the emulator with **no** SHA/Blaze/real SMS.
  Current test number: `+917438013279`, code `775184`.
  **Firebase → Auth → Settings → SMS region policy must allow India (+91)** or
  sends fail with error `17006`.
- For **real** devices/SMS later: add SHA-1/SHA-256 fingerprints in Firebase and
  switch the project to the **Blaze** plan.

## Verification workflow

Always: `flutter analyze` (expect no issues) + `flutter test` (splash→login
redirect test), then build + drive the real app on the emulator with
screenshots to confirm a change actually works.
