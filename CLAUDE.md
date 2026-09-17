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
- `google_fonts` (Manrope type family for the redesign — see backlog #14;
  fetched over the network on first use and cached, not bundled as an asset)
- `geolocator` + `geocoding` (device GPS capture + on-device reverse
  geocoding for the Add Address "Use current location" flow and the admin
  Delivery Settings store-location capture — see "Location integration"
  under Addresses/Cart/Admin > More below; deliberately no Maps API/billing)
- Firebase Storage (prescription image uploads — see "Prescriptions" below;
  `firebase_storage` package, **needs Storage enabled in the Firebase
  console** — not yet done, uploads currently fail with a 404 until it is)
- `flutter_secure_storage` (already a dependency; first real use **2026-09-15**
  — persists the dark-mode preference, see Profile > Settings below)
- **ASP.NET Core + MySQL backend** — **live**, deployed to Azure App Service;
  this is the real data store
- No Firestore. See "Data & backend strategy".

## Coding Guidelines

- Use Material 3. Follow feature-first architecture. Use Riverpod.
- Keep widgets small. Prefer StatelessWidget. Separate UI and business logic.
- No mock data inside widgets — repositories/providers supply data.
- **Every button/action that triggers an API call must show a loading
  state** (disable the control + swap its label for a small spinner, the
  `_saving`/`_cancelling`/`_settingDefault`-style local bool pattern used
  throughout) — **user rule, 2026-09-13**: a tap that silently does nothing
  for a moment reads as broken/unresponsive, even if it's actually working.
  Caught first on Addresses/Payment Methods' "Set as default" buttons; check
  for this whenever adding a new mutation-triggering control.
- Write production-quality code. Avoid unnecessary packages.
- Always explain changed files.

## Architecture & folder layout

Feature-first. Each feature: `lib/features/<feature>/{domain,data,presentation/{screens,widgets,providers}}`.

- `lib/core/` — cross-cutting: `models/` (`AppUser`, `UserRole`), `routes/`
  (`app_router.dart`, `app_routes.dart`), `theme/` (`AppTheme`, `AppColors`,
  `AppConstants` design tokens, `AppTextTheme`), `utils/` (`week_range.dart`),
  `widgets/` (`scaffold_with_nav_bar.dart`, `admin_scaffold_with_nav_bar.dart`,
  `app_bottom_nav_bar.dart`, `placeholder_screen.dart`).
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
- Both bottom nav bars (`ScaffoldWithNavBar`, `AdminScaffoldWithNavBar`) render
  via a shared `AppBottomNavBar` (`core/widgets/app_bottom_nav_bar.dart`) — a
  from-scratch Material 3 lookalike, not Flutter's built-in `NavigationBar`.
  `NavigationDestination.label` is a plain `String` with no `maxLines`/
  `overflow` control, so a longer label ("Appointments") wraps to 2 lines on
  narrower devices with no way to fix it through the public API.
  `AppBottomNavBar` measures every destination's label up front and applies
  **one shared shrink factor** (the minimum needed by the longest label,
  via `LayoutBuilder` + `TextPainter`) across all of them, so labels never
  wrap and are always the same size as each other — an earlier version
  wrapped each label in its own independent `FittedBox`, which stopped the
  wrapping but let each tab shrink to fit *its own* text, so "Appointments"
  rendered visibly smaller than "Cart" on the same bar. Below a legibility
  floor (`_kMinLegibleLabelScale`), labels are dropped entirely and the bar
  falls back to icon-only rather than keep shrinking text. Same M3 token
  values (pill indicator, colors, 80dp height) as `NavigationBar`'s
  defaults, just reimplemented for control over the label.
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
- **Pharmacy (dashboard)** — greeting; a **"Delivering to {area}"** line
  (falls back to city, or hidden entirely with no default address/no
  location captured on it) read from the default `Address`; a search bar
  (real, opens `/pharmacy/search` → `SearchScreen`) with a compact
  `IconButton.filledTonal` **Prescription** shortcut beside it (real, opens
  `/pharmacy/prescriptions`) — **decided 2026-09-13**: dropped the
  "Search by image" placeholder button entirely (was never real) and moved
  Prescription off its own full-width button row onto the search bar's row,
  which naturally shortens the search bar too; a **cycling promo banner**
  (`HomeBannerCarousel`, `lib/features/dashboard/presentation/widgets/`) —
  see Admin > More > Home Banners below for the admin side; **Shop by
  category** grid + **Suggested for you** horizontal products.
  **Category taxonomy expanded 6→22, 2026-09-16** — see "Category taxonomy"
  under Medicines below for the full write-up; the dashboard grid now shows
  8 curated `homeFeaturedCategories` (`ProductCategory`,
  `lib/features/medicines/domain/product_category.dart`) plus a
  **"Show All Categories"** button (`AppRoutes.categories`,
  `/pharmacy/categories`) opening a new `AllCategoriesScreen` listing all
  22 — each tile routes into the existing Medicines list
  (`?category=<label>`), same as before.
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
  **Card layout, 2026-09-15**: `ProductCard`/`SuggestedProductCard` gained a
  `packSize` line under the brand (e.g. "10 tablets", "125ml", "1 piece") —
  new optional `Product.packSize` field, admin-editable on the Inventory
  Add/Edit form, **built ahead of the backend** (`docs/API_ENDPOINTS.md`
  §5/§32), so it stays hidden until the backend returns it. Also added an
  "estimated delivery" line (e.g. "Get by Fri, 18th Sept",
  `core/utils/delivery_estimate.dart`) — purely client-computed (today + a
  fixed number of days), no backend involved, cosmetic only. `ProductCard`
  (the full-width list row) was restructured so **Add is bottom-right
  aligned** instead of vertically centered beside the thumbnail, now that
  the info column can run to 4–5 lines; `SuggestedProductCard` already had
  Add at the bottom of its column. Verified live on the emulator (Medicines
  list): delivery line renders correctly, Add button sits at the
  bottom-right of each card; `packSize` has no seed data yet so its line
  correctly stays hidden pending the backend field.
  **`SuggestedProductCard` Add-button fix, 2026-09-17**: once real
  `packSize` data started showing (via the category work below), the
  "already had Add at the bottom" claim above turned out false in the
  horizontal "Suggested for you"/"Similar products" row specifically — user
  caught this live with a screenshot showing two Add buttons at different
  heights. Root cause: that row wraps every card in a `SizedBox(height:
  250)` (`suggested_products.dart`), which forces a **tight** height on
  each `SuggestedProductCard`'s `Column`, but the column had no flex
  spacer — a card without a `packSize` line simply had shorter content and
  left blank space *below* Add instead of Add sitting at the bottom. Fixed
  by inserting `const Spacer()` right before the trailing
  `SizedBox(height: spacingSm)` + Add button, so the flexible gap absorbs
  the height difference and Add always lands flush at the card's bottom
  regardless of which optional lines (packSize, discount, delivery
  estimate) are present. `ProductCard` (the full-width row) was never
  affected — it isn't height-constrained by a sibling, so its Add button
  was already correctly self-positioned. Verified live: a card without
  `packSize` ("Bio HFG Forye") and one with it ("Mecofol D — 10 tablets")
  now show their Add buttons at the exact same height in the same row.
  **Category taxonomy expanded 6→22, 2026-09-16**: replaced the old
  backend-driven 6-category list (`GET /catalog/categories`, no longer
  called by the client) with a **fixed client-side catalog** —
  `ProductCategory` (`lib/features/medicines/domain/product_category.dart`,
  22 values: Vitamins & Supplements, Monitoring Devices, Protein
  Supplements, Sexual Wellness, Ayurvedic Wellness, Food & Nutrition, Skin
  Care, Men Care, Women Care, Elderly Care, Pain Relief, Supports & Braces,
  Gut Care, Diabetes, Hair Care, Oral Care, Cold/Cough & Fever, First Aid,
  Baby Care, Respiratory Care, Eye Care, Prescription Drugs) — same "fixed
  catalog, not admin-extensible" decision already made for `BannerId`.
  Also added `ProductType` (`product_type.dart`: Tablet Drug, Liquid Drug,
  Injection, Non Oral Drug, Others), a new nullable `Product.type` field,
  **built ahead of the backend** (`docs/API_ENDPOINTS.md`, which also
  flags the **breaking data-migration** existing products need — none of
  their current category labels exist in the new 22, so category-filtered
  views won't show them until an admin re-categorizes, though unfiltered
  views are unaffected). New colorful `CategoryIllustration`
  (`core/illustrations/`) — a pastel rounded-square card + vivid icon badge
  + sparkle accents per category, one parameterized `CustomPainter` (no
  external assets/photos — see backlog #17 for why) — replaces the old
  plain `CircleAvatar`+`Icon` category tiles everywhere (dashboard grid,
  new All Categories screen, admin inventory filter screen).
  **Two follow-up bugs fixed, 2026-09-17** (both caught live by the user
  with phone screenshots): (1) `_CategoryTile`'s `Column` used
  `mainAxisAlignment: MainAxisAlignment.center` around a variable-height
  label (`Text(..., maxLines: 2)`) — a 2-line label made that tile's total
  content taller than a neighboring 1-line-label tile in the *same* grid
  row, so centering shifted the illustration up/down tile by tile instead
  of keeping every icon at the same y — clearly visible across a row where
  label lengths differ. Fixed by wrapping the label in a `SizedBox` whose
  height is always exactly 2 lines (computed from
  `labelMedium.fontSize`/`.height`, not hardcoded), so every tile has
  identical content height regardless of whether its label actually wraps
  to 1 or 2 lines — the illustration now lines up across every row.
  (2) `ProductCategory.prescriptionDrugs`'s `cardColor` (`0xFFE1F0EC`) was
  far more desaturated than its neighbors (e.g. `vitaminsSupplements`'s
  `0xFFFFF3D6`), so it read as washed-out/faint next to them — bumped to
  `0xFFC9ECE0`, a more saturated mint that matches the badge's teal hue
  while staying pastel like the rest of the set.
- **Lab Tests** (tab) — bookable-test catalog like medicines
  (`features/lab_tests`, `LabTest` model + `ApiLabTestRepository` +
  `labTestCatalogProvider`), backed by `GET /catalog/lab-tests` /
  `GET /catalog/lab-tests/{id}`. List → detail (`/lab-tests/<testId>`) with
  sample type / report time / fasting / parameters → **Add to cart** opens
  `ScheduleLabTestSheet` (`presentation/widgets/`) first — a bottom sheet to
  pick a sample-collection date (today onwards, `showDatePicker`) and a
  preferred time window (`kLabTestTimeSlots`, `domain/lab_test_slots.dart`:
  4 fixed ranges e.g. `7:00 AM – 10:00 AM`) — before the item is actually
  added; both are stored on the `CartItem` and shown on its cart-screen line
  (`"10 Sep • 1:00 PM – 4:00 PM"`). **Built ahead of the backend** — sent as
  `scheduledDate`/`timeSlot` on `labTest` items in `POST /orders` (endpoint
  #15 in `docs/API_ENDPOINTS.md`), verified live that the existing endpoint
  accepts them without error (order placement still succeeds), but the
  backend doesn't store/return them yet, so Profile → Lab Tests shows no
  time slot for now — degrades cleanly, no crash. Note: distinct from
  **Profile → Lab Tests** (booked history); this tab is the storefront.
- **Appointments** — doctors available this week, real via
  `ApiDoctorRepository` (`GET /doctors`, `weeklyDoctorsProvider`); doctor
  cards with a Mon–Sun availability strip; **Book** is real —
  `ApiAppointmentRepository.book()` (`POST /appointments`), confirmed live
  with a booking confirmation snackbar. Current-week math in
  `core/utils/week_range.dart`. The rating chip shows `doctor.rating`
  (`"4.8 (23)"` with `ratingCount`) once customers have rated the doctor
  (see Profile → Appointments), or **"New"** while `ratingCount == 0` —
  verified live showing "New" for both seed doctors, since neither has any
  ratings yet against the real backend.
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
  from `addressesProvider`); a **"Saved UPI"** section (only shown when
  non-empty) lists the customer's saved payment methods from
  `paymentMethodsProvider` (Profile → Payment Methods) as selectable tiles —
  **fixed 2026-09-13**: previously Checkout never read that provider at all,
  so anything saved there was invisible/unusable during payment, a real gap
  since adding one is the whole point of saving it. Selecting a saved method
  sends `paymentMethod: 'upi'` + its `upiId` straight through, same as typing
  one manually. Below that, pay via UPI apps (Google Pay / PhonePe / BHIM /
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
  **Order Now** also runs a client-side delivery-radius check
  (`core/utils/distance.dart`'s Haversine calc) whenever the cart has a
  `CartItemKind.medicine` item — lab tests/appointments are never gated.
  Blocks with a clear message if the selected address's captured
  coordinates put it outside the admin-configured radius (`deliverySettingsProvider`,
  `features/admin/delivery/`); fails open (no block) if the address has no
  captured coordinates or delivery settings aren't configured/deployed yet.
  **Delivery and platform fee are dynamic for pharmacy carts** (backlog
  #12): `cartDeliveryFeeLineProvider`/`cartPlatformFeeLineProvider`
  (`cart_providers.dart`) compute a distance-tiered delivery fee + flat
  platform fee from the same store-distance calc, admin-configured via
  `DeliverySettings.deliveryFeeTiers`/`platformFee`; either can be marked
  free independently by the admin, shown struck through on
  `PriceBreakdown` rather than just omitted. A cart with **no** medicine
  item (lab-test-only) is unaffected — keeps the legacy flat ₹40/
  free-over-₹500 rule and never gets a platform fee. The address checkout
  prices/gates against (`selectedAddressProvider`) is shared with the Cart
  screen's pre-checkout estimate, so both show the same numbers before an
  address is ever explicitly changed.
- **Profile** — header + 8 menus + Sign Out:
  - **Account** — gender-based avatar, personal details, medical records
    (real backend data, read-only — see the Account note below).
  - **Appointments** — past appointments + "Book Appointment" → Appointments
    tab. Each `upcoming` appointment shows a **Cancel** action
    (`AppointmentStatus.isCustomerCancellable`) → confirm dialog →
    `AppointmentRepository.cancel(id)` (`PUT /appointments/{id}/cancel`,
    endpoint #66) → `pastAppointmentsProvider` invalidated to refresh the
    list. **Live** — backend deployed 2026-09-07 (client-side was already
    verified before that: correct cancellable-only gating, correct
    confirm-dialog copy, clean error against the missing endpoint; a full
    live re-pass against the now-deployed endpoint is intentionally
    deferred). Each `completed` appointment instead shows either **Rate
    doctor** (a `StarRating` picker dialog, `presentation/widgets/`) if not
    yet rated, or the given rating read-only ("Your rating: ★★★★☆") if it
    is — `AppointmentRepository.rate(id, stars)` → `POST
    /appointments/{id}/rating` (endpoint #67), one rating per appointment,
    1–5 stars only (no written review). **Built ahead of the backend** —
    `PastAppointment.myRating` parses nullable so an unrated/not-yet-updated
    backend degrades cleanly. The rate-doctor trigger itself hasn't been
    exercised live yet (no completed appointment in the test account) but
    is code-identical in structure to the proven Cancel flow.
    **Layout fix, 2026-09-15**: putting Cancel on the same row as the
    date/time (done 2026-09-13) left the date/time text starting flush
    under the doctor avatar instead of aligned under the name/specialization
    column. Fixed with a leading spacer matching the avatar's width +
    spacing, and simplified Cancel from a labelled `TextButton.icon` to an
    icon-only pill (`_CancelIconButton`, a small circular `IconButton` in
    the error-container color) to free up the row — matches the user's own
    suggested fix. Verified live: the date now lines up correctly under the
    doctor name, Cancel renders as a compact red circular ✕ button.
  - **Orders** — history list → detail (items, total, **Download invoice**).
  - **Lab Tests** — history list → detail (parameters, **Download invoice**).
    `LabTest.bookedOn` is the customer-chosen scheduled collection date (not
    the date the order was placed — see the Lab Tests tab note above and
    `docs/API_ENDPOINTS.md` §19); list/detail show it as "Scheduled for
    {date} • {timeSlot}" when `timeSlot` is present, date-only otherwise
    (`null` until the backend lands the new fields).
  - **Invoice download** (Orders + Lab Tests detail) — real: fetches
    `{ invoiceUrl }` from `GET /orders/{id}/invoice` /
    `GET /lab-test-bookings/{id}/invoice` via `ProfileRepository`, opens it
    with `url_launcher` (`LaunchMode.externalApplication`). Verified live —
    Chrome opens with the exact URL the backend returns. The backend's
    `invoiceUrl` is currently a placeholder domain (`api.sunilmedicalstore.com`,
    doesn't resolve — no real PDF generation yet), so the page itself won't
    load; that's expected per `docs/API_ENDPOINTS.md`, not a client bug.
  - **Addresses** — list, **Set as default**, **Add address**, and now
    **Edit**/**Delete** (**added 2026-09-15**) — real via
    `ApiAddressRepository` (`GET/POST /addresses`,
    `PUT /addresses/{id}/default`, `DELETE /addresses/{id}`, and a new
    `PUT /addresses/{id}` for edit, **built ahead of the backend** —
    endpoint #76 in `docs/API_ENDPOINTS.md`), wrapped in an
    `AsyncNotifierProvider` (`addressesProvider`) that re-fetches after each
    mutation. `AddAddressScreen` now doubles as the edit form (`existing:
    Address?` param — seeds every field including captured lat/lng, swaps
    "Save address"/"Add address" copy for "Save changes"/"Edit address",
    hides the "Set as default" checkbox in edit mode since editing
    shouldn't silently change default status) — reached via a new pencil
    icon per card (`/profile/addresses/edit/<id>`, address passed via
    `extra`); delete is a trash icon with a confirm dialog, reusing the
    controller's pre-existing (and already-live) `remove()`. Verified live:
    Edit opens correctly pre-seeded; saving cleanly surfaces "Something
    went wrong" since #76 isn't deployed yet (same fail-open pattern as
    every other build-ahead-of-backend mutation), no crash. Add Address has
    a **"Use current location"** button
    (`core/location/`: `geolocator` GPS fix + `geocoding` on-device
    reverse-geocode, no Maps API billing) that fills `area`/city/state/
    pincode read-only from the device's location; falls back to editable
    manual entry if capture fails, with an "Edit manually" override even
    after a successful capture. **Built ahead of the backend** — `area`/
    `latitude`/`longitude` are new nullable `Address` fields; existing
    addresses (and any manually-entered one) simply have `null` coordinates,
    which the checkout radius check (see Cart below) treats as "can't
    verify, don't block". **Set as default** shows a per-card loading state
    while its `PUT` is in flight (each address row is its own
    `ConsumerStatefulWidget`, `_AddressCard` — button disables + swaps its
    label for a small spinner) — **fixed 2026-09-13**, the button previously
    gave no feedback during the round-trip and looked unresponsive.
  - **Payment Methods** — list, **Add UPI** dialog, and now **Edit**/
    **Delete** (**added 2026-09-15**) — real via `ApiPaymentMethodRepository`
    (`GET/POST /payment-methods`, `PUT /payment-methods/{id}/default`,
    `DELETE /payment-methods/{id}`, and a new `PUT /payment-methods/{id}`
    for edit, **built ahead of the backend** — endpoint #77), same
    `AsyncNotifierProvider` pattern (`paymentMethodsProvider`). Only UPI
    supported for now. The former `_AddUpiDialog` became `_AddOrEditUpiDialog`
    (`existing: PaymentMethod?`) — tapping a card opens it pre-filled and
    calls `updateUpi()` instead of `addUpi()`; delete is a trash icon with a
    confirm dialog, reusing the already-live `remove()`. **Set default** got
    the same per-row loading-state fix as Addresses above
    (`_PaymentMethodCard`), same day, same reason. Verified live: tapping a
    saved UPI method opens "Edit UPI" pre-filled with its id; delete icon
    renders correctly next to the Default chip.
  - **Account** data — real via `ApiProfileRepository.customerProfile()`
    (`customerProfileProvider`), which self-heals a missing backend user row
    on first sign-in. Name/phone shown around the app are the real auth
    values; Account's extended fields (gender, DOB, email) are now
    **editable** (**built 2026-09-13**) — Full Name, Gender, Date of birth,
    and Email ID are real form fields on `AccountScreen`
    (`ConsumerStatefulWidget`, seeded once from the loaded `CustomerProfile`
    the same way `AdminDeliverySettingsScreen` seeds itself) with a single
    **Save changes** button calling the repository's pre-existing
    `upsertProfile()` (finally wired up — it previously existed but nothing
    called it) and a loading spinner on the button per the "every API call
    needs a loader" rule above. Validation: Full Name requires 2+ characters
    including a letter; Email, if non-empty, must match a standard
    `name@domain.tld` pattern (both optional fields — `null`/empty stays
    "not set", matching the domain model); Date of birth opens
    `showDatePicker` (same pattern as `ScheduleLabTestSheet`/admin's date
    pickers) and can't be in the future; **Gender is a dropdown** — Male /
    Female / **Others** (`Gender.other.label` changed from "Other" to
    "Others" per explicit wording ask) / "Not set". **Phone number stays
    read-only** (locked icon) — it's the Firebase sign-in identity, same
    locking rationale as Discounts' `code` field and Users' phone field.
    Medical records remain read-only (no ask to edit those). Verified live
    end-to-end: selected Female (avatar icon updated live to match), picked
    a DOB via the date picker, tried an invalid email (rejected inline,
    "Profile updated" not shown), then a valid one — saved successfully
    against the real backend, and reloading the screen confirmed the new
    values persisted server-side.
    **Restyled 2026-09-15**: the Phone number row used to be a plain
    unstyled `Row` (label + text + lock icon) that didn't match the other
    fields' `TextFormField` look. Swapped for a disabled `TextFormField`
    (`enabled: false`, lock icon as `suffixIcon`) — same filled-box/
    floating-label chrome as Full Name/Gender/etc., just visibly greyed out
    and non-interactive. Verified live.
  - **Settings** (`/profile/settings`, **new 2026-09-15**) — currently just
    a dark-mode toggle (`SwitchListTile`), backed by a new
    `themeModeProvider` (`Notifier<ThemeMode>`,
    `features/profile/presentation/providers/theme_controller.dart`)
    persisted via `flutter_secure_storage`. **The app now defaults to light
    mode** regardless of the device's system setting — previously
    `MaterialApp.router` didn't set `themeMode` at all, so it silently
    followed `ThemeMode.system`; `app.dart` now watches `themeModeProvider`
    explicitly. Verified live: app launches in light mode, the Settings
    toggle switches the whole app to dark instantly and the choice would
    persist across restarts (secure-storage write confirmed, not
    separately verified across a real process restart).
  - **Help & Support** (`/profile/help-support`, **new 2026-09-15**) — a
    "Chat with us on WhatsApp" tile deep-linking to `wa.me/<number>` via
    `url_launcher` (same `LaunchMode.externalApplication` pattern as
    invoice download), plus a static FAQ list (`ExpansionTile`s). **The
    WhatsApp number is a placeholder** (`HelpSupportScreen._whatsAppNumber`)
    — needs the store's real WhatsApp Business number before go-live. FAQ
    copy is placeholder/dummy content, as asked. Verified live.
    **Border fix, 2026-09-17**: `ExpansionTile` draws its own top/bottom
    border by default when expanded, which clashed visibly with the parent
    `Card`'s rounded corners on the first/last FAQ (a square-cornered line
    poking past the card's curve) — user caught this live on a real phone.
    Fixed by setting `shape`/`collapsedShape` to `const Border()` (no
    border) on every `ExpansionTile` and drawing explicit `Divider(height:
    1)` separators between items instead, so the card's own rounded edge
    stays clean regardless of which FAQs are expanded. Verified live,
    including expanding the first and last FAQ specifically.
- **Admin console** (`lib/features/admin/`) — role-gated, mirrors the
  customer's 5-tab shell (`AdminScaffoldWithNavBar` in `core/widgets`). Tabs:
  - **Inventory** — full CRUD over the product catalog against
    `/v1/admin/products`. `InventoryRepository` (`domain`) +
    `ApiInventoryRepository` (`data`) exposed via
    `inventoryRepositoryProvider`; `adminInventoryListProvider` and
    `adminProductByIdProvider(id)` back the screens. **List/filter bar
    redesigned 2026-09-16**: the top bar now shows an "All" chip + the
    first 5 of the 22 categories (`adminTopBarCategories`) in a horizontally
    scrolling `Row`, with a fixed filter `IconButton` (`Icons.tune`, badge
    dot when any filter is active) at the row's right end — same layout
    pattern as Statistics' "more filters" row. Tapping it opens a new
    dedicated `AdminInventoryFilterScreen` (`/admin/inventory/filter`, a
    full page per the ask, not a bottom sheet) with a **category** picker
    (all 22, `Wrap` of `ChoiceChip`s), a **product type** picker (5 values,
    same widget), and a **search** field matching Name/Category/Type/
    Composition/Ingredient — Apply writes an `AdminInventoryFilters` value
    (`admin/inventory/domain/inventory_filters.dart`) into a new
    `adminInventoryFiltersProvider` Notifier. Only `category` is sent to
    the backend (`GET /admin/products?category=`, unchanged endpoint); type
    and the multi-field search are matched **client-side** against the
    category-scoped list already in memory (`InventoryListScreen`) — no new
    endpoint needed, works today regardless of backend support (see
    `docs/API_ENDPOINTS.md`'s Admin — Inventory note). Still has an
    "In stock only" toggle below the bar; each row shows a `StockBadge`
    (In stock N / Low: N / Out of stock) and the Rx flag. Tap a row →
    **Edit form**; FAB → **Add form**. The form supports both modes
    (`productId == null` means Add), captures all `Product` fields
    (mandatory: Name, Brand, Category, **Product type — new 2026-09-16**,
    Price, Quantity, Composition, Rx; optional: MRP, Description, Dosage,
    Ingredients as comma-separated string, Image URL, Pack size — e.g. "10
    tablets", feeds the catalog cards' pack-size line, see Medicines
    above), and has a delete-with-confirm action on Edit. Category and Type
    are both required dropdowns sourced from the fixed `ProductCategory`/
    `ProductType` enums (no more network category fetch on this screen
    either).
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
      `AddOrEditDoctorScreen` (all `Doctor` fields *except* rating; weekday
      multi-select via shared `WeekdaySelector`; free-text consulting hours;
      delete-with-confirm on edit). Reuses the customer `Doctor` domain
      model. **Rating is no longer admin-editable** (since customer ratings
      landed, see Profile → Appointments) — the form's manual "Rating"
      input was removed and replaced with a read-only info tile on Edit
      showing `"{rating} ({ratingCount})"` or "No ratings yet"; `DoctorInput`
      (create/update payload) no longer carries a `rating` field at all.
  - **Orders** — a `DefaultTabController` shell with **three sub-tabs**
    (mirrors the Appointments/Doctors pattern):
    - _Pharmacy sub-tab_ (`AdminOrdersListScreen`, renamed from "Orders")
      — search by order #/user/phone + filter sheet: status, date range →
      tap a row → `AdminOrderDetailScreen`: read-only user/items/total,
      then a **status swipe bar** (`StatusSwipeBar`,
      `admin/presentation/widgets/` — shared with Pathology below, and
      built for future reuse by Appointments too) that advances one linear
      step at a time (`created → processing → shipped → delivered`) with a
      per-step label ("Process Order" / "Mark as Shipped" / "Mark as
      Delivered"), applying immediately on drag-confirm — no separate Save
      step, no free-choice status jumping. A standalone red **"Cancel
      order"** button sits below, always enabled unless already
      `cancelled` (admin's explicit call — unlike the customer's
      pre-shipment-only self-cancel). Backed by `AdminOrderRepository`
      (`domain`) + `ApiAdminOrderRepository` (`data`) against
      `/v1/admin/orders` — same endpoint as before, just a different client
      access pattern (`OrderStatus.next`/`.advanceLabel` in
      `core/models/order.dart` drive the linear sequence). **Live** —
      swiped a real order all the way `created→processing→shipped→
      delivered` against Azure, confirmed by the real "Order delivered"
      push notification firing correctly too.
    - _Prescriptions sub-tab_ (`AdminPrescriptionsListScreen`) — Rx review
      queue, status filter chips (defaults to **Pending review**) → tap a
      row → `AdminPrescriptionDetailScreen` (full-size image +
      Approve/Reject; Reject prompts for an optional note shown to the
      customer). Backed by `AdminPrescriptionRepository` (`domain`) +
      `ApiAdminPrescriptionRepository` (`data`) against
      `/v1/admin/prescriptions`.
    - _Pathology sub-tab_ (`AdminLabTestBookingsListScreen`,
      `admin/pathology/`, brand new) — lab-test-booking management, since
      none existed before. File-for-file mirror of the Pharmacy sub-tab:
      search/filter list → `AdminLabTestBookingDetailScreen` with the same
      `StatusSwipeBar` pattern advancing `scheduled → inSession →
      completed` (`LabTestStatus` gained `inSession`, between `scheduled`
      and `completed`) plus a standalone "Cancel booking" button. Backed by
      `AdminLabTestRepository` (`domain`) + `ApiAdminLabTestRepository`
      (`data`) against new endpoints `/v1/admin/lab-test-bookings`
      (#68–70). **Built ahead of the backend** — verified live that it
      degrades cleanly (`GET .../lab-test-bookings` 404s → "Something went
      wrong" + Retry, no crash) since the backend doesn't have these
      endpoints yet.
    **Orders (Pharmacy) backend is live**; **Prescriptions (54–59)
    endpoints in `docs/API_ENDPOINTS.md` are implemented server-side but
    prescription uploads still fail** — see the Prescriptions feature note
    below (Firebase Storage isn't enabled for this project yet, a separate
    manual step from the backend deploy). **Pathology (68–70) not yet
    implemented server-side.**
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
      aggregate call per filter change (`GET /v1/admin/stats?range=`, not
      one endpoint per widget). `StatsRange` pills
      (`today | 7d | 30d | 6m | 1y | all`) as `ChoiceChip`s at the top,
      horizontally scrollable, with a **"More filters"** icon (`Icons.tune`)
      fixed at the row's right end *outside* the scroll area (`Row` +
      `Expanded(SingleChildScrollView(...))` + a sibling `IconButton`) so
      it's always visible without scrolling — opens `StatsPeriodSheet` to
      pick a specific year, optionally narrowed to one month — sent as
      `range=custom&year=&month=`. The active selection is
      `StatsFilter` (`domain/stats_filter.dart`, a sealed
      `StatsRangeFilter | StatsPeriodFilter`), backed by
      `statsFilterProvider`; a custom period shows as its own `InputChip`
      (e.g. "Mar 2026") with a delete action reverting to the 7-day default.
      `6m`/`1y` and `range=custom` extend the already-live endpoint #61 —
      **backend deployed and user-confirmed working live** (e.g. a "Jan
      2026" custom period), see backlog #7. Below: revenue + order-count
      `StatTile`s, a
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
    - **Delivery Settings** (`/admin/more/delivery-settings`,
      `lib/features/admin/delivery/`) — captures the store's own lat/lng via
      the same device-GPS flow as the customer's Add Address "Use current
      location" (no reverse-geocode needed, just raw coordinates), plus a
      delivery radius (km); "Save" calls `PUT /v1/admin/delivery-settings`.
      Backs the checkout radius gate (see Cart above). Also an editable
      **delivery fee tier list** (add/remove rows, each an "up to N km → ₹Y"
      band) and a flat **platform fee**, each with its own **independent**
      "mark as free" switch — waived delivery doesn't force-waive the
      platform fee or vice versa. **Built ahead of the backend** —
      endpoints #71/#72 aren't deployed yet.
    - **Home Banners** (`/admin/more/banners`, `lib/features/admin/banners/`,
      **built 2026-09-14**) — a **fixed 12-slot catalog** of dashboard promo
      banners (`BannerId` enum: 3 general-discount slots, 6 festival slots —
      Kali Puja/Diwali, Durga Puja, New Year, Holi, Independence Day, Ganesh
      Puja — and 3 doctor-promo slots); admin edits `title`/`description`/
      `isActive` per slot (list screen: inline `Switch` to toggle active
      with a per-row loader, tap to open `EditBannerScreen` for the text
      fields). **Illustrations are fixed per slot, not admin-configurable**
      — a new slot needs a developer to map an illustration, so the catalog
      itself isn't admin-extensible (no add/delete). Two new parameterized
      `CustomPainter` illustrations added to `core/illustrations/` and
      reused across all 12 slots rather than one bespoke painter each:
      `PersonBadgeIllustration` (character + icon badge — the three
      discount slots and, with a white coat, the three doctor slots) and
      `FestivalIllustration` (`FestivalMotif`: diya for Kali/Durga Puja,
      confetti for New Year, colored powder splashes for Holi, a tricolor
      flag for Independence Day, a modak sweet for Ganesh Puja — all
      deliberately secular/symbolic motifs, none depict a religious figure).
      On the customer side, `HomeBannerCarousel`
      (`features/dashboard/presentation/widgets/`) reads only the *active*
      banners and — when more than one is active — cycles them with a
      `PageView` + 5-second auto-advance timer + dot indicators; a single
      active banner renders statically with no carousel chrome. **Built
      ahead of the backend** — endpoints #73–75 aren't deployed yet;
      verified live that the dashboard fails open cleanly (confirmed via
      logcat that `GET /v1/banners` 404s against the real Azure backend,
      and the carousel falls back to a single hardcoded banner matching the
      `generalDiscount1` seed copy, matching the original static banner
      exactly — no blank gap, no crash). The 10 non-default illustrations
      were visually spot-checked live via a temporary debug harness (not
      shipped) cycling through all 12 slots — caught and fixed one real bug
      this way (the diya's lamp base was a thick stroked arc that read as a
      smile/mouth; redrawn as a filled lens/boat shape). The admin
      list/edit screens themselves weren't re-verified live — same
      hardcoded-admin-OTP blocker noted elsewhere in this doc. **Seed data
      note**: every festival banner's seed description uses the literal
      "5th to 10th Nov" text as given, even though most of these festivals
      don't fall in November — flagged in `docs/API_ENDPOINTS.md` for the
      user to correct per-festival before go-live, not silently changed
      since the exact wording was an explicit ask.

## Backlog (prioritized, not started)

The single tracked list — every open item lives here, ranked by intended
pickup order. The user confirms which one to start explicitly; this table
is a plan, not a queue being worked automatically. Update it (status,
ranking, new items) as items are picked up, finished, or reprioritized.

| # | Item | Type | Status | Notes |
|---|------|------|--------|-------|
| 1 | Order status doesn't refresh immediately for the customer after an admin changes it | Bug | **Done** | Root cause: `NotificationService` never invalidated `pastOrdersProvider`/`orderByIdProvider` on push receipt, and `OrderDetailScreen` held a static `extra`-passed `Order` with no live provider binding at all. Fixed both; verified live — changed a real order `created→shipped` via a direct API call while the customer sat on both the Orders list and the Order Detail screen, both updated with no manual refresh |
| 2 | Bottom nav "Appointments" label wraps to 2 lines on some device widths | UI bug | **Done** | Root cause: `NavigationDestination.label` is a plain `String` — Flutter renders it as `Text(label, style: textStyle)` with no `maxLines`/`overflow` (confirmed in the Flutter SDK source), so it wraps whenever a destination's column is too narrow. No public hook to fix this through `NavigationBar` itself. Replaced with a custom `AppBottomNavBar` (`core/widgets/app_bottom_nav_bar.dart`). **First attempt had a follow-up bug**, caught by the user 2026-09-12: wrapping each label in its own independent `FittedBox` stopped the wrapping but let each tab shrink to fit *only its own* text, so "Appointments" (the longest label) rendered visibly smaller than "Cart" or "Orders" on the same bar — inconsistent sizing, not just a wrapping fix. **Fixed properly**: `AppBottomNavBar` now measures every label up front (`LayoutBuilder` + `TextPainter`) and applies one shared shrink factor — the minimum needed by the longest label — uniformly across every tab, so they're always the same size; below a legibility floor, labels are dropped entirely and the bar falls back to icon-only instead of shrinking text further (the user's explicit ask). Verified live at three simulated widths (normal, mid-narrow shrink, icon-only fallback) via the customer scaffold; the admin scaffold renders through the same shared component with no per-caller branching |
| 3 | Lab-test booking notifications show `{date}` only, no time-of-day | Minor bug | **Done** | Turned out bigger than a copy fix: no part of the system ever captured a lab-test time at all (`bookedOn` being date-only was a symptom, not the cause) — decided to add real time-slot selection rather than just drop the claim. Customer picks a date + fixed time-range slot (`kLabTestTimeSlots`) via a new `ScheduleLabTestSheet` bottom sheet on "Add to cart"; threaded through `CartItem`/`OrderRequestItem` to `POST /orders`' `labTest` items as `scheduledDate`/`timeSlot`, landing on the Lab Test Booking as `bookedOn`/`timeSlot` (`bookedOn`'s *meaning* changed — see `docs/API_ENDPOINTS.md` §19). **Fully re-verified live 2026-09-13**: booked "Fasting Blood Sugar" for 13 Sep, 1:00 PM – 4:00 PM, placed the order (`PLSMS-0926-0001`), and Profile → Lab Tests correctly showed "13 Sep 2026 • 1:00 PM – 4:00 PM" — the real time slot round-tripped through the backend exactly as designed, no crash |
| 4 | Enable Firebase Storage (Blaze plan) to unblock Prescriptions | Blocked — user action | Waiting on you | Prescriptions is fully built client + backend (endpoints 54–59 live); blocked on this one manual Firebase Console step (Console → Storage → Get started, then Blaze plan) |
| 5 | Cancel appointment | New feature | **Done** | Inline **Cancel** action on each upcoming appointment card in Profile → Appointments (`AppointmentStatus.isCustomerCancellable`, true only while `upcoming`), mirroring the order-cancel pattern: confirm dialog → `AppointmentRepository.cancel(id)` → `PUT /appointments/{id}/cancel` → invalidate `pastOrdersProvider`. **Fully re-verified live 2026-09-13**: booked a fresh appointment with Dr. Ananya Sharma (`DASMS-0926-0001`), cancelled it from Profile → Appointments — confirm dialog, "Appointment cancelled" snackbar, status flipped to `Cancelled` against the real backend, no crash. (Note: `pastAppointmentsProvider` isn't auto-invalidated after booking from the Appointments tab — a newly-booked appointment needs a pull-to-refresh on Profile → Appointments before it appears there; not a bug in the cancel flow itself, just a cross-feature refresh gap worth fixing if it comes up again) |
| 6 | Doctor ratings from customers | New feature | **Done (client)** | Customer can rate a doctor 1–5 stars after a `completed` appointment (`AppointmentRepository.rate(id, stars)` → `POST /appointments/{id}/rating`, endpoint #67), once per appointment, via a "Rate doctor" button + star-picker dialog on Profile → Appointments; already-rated appointments show "Your rating: ★★★★☆" read-only. `Doctor.rating` becomes a server-computed average with a new `ratingCount` field — admin's manual "Rating" input is removed from the doctor form (now a read-only info tile), and `DoctorCard` shows "New" instead of a fabricated number when `ratingCount == 0`. **Decided**: server-computed average replaces the admin field; one rating per completed appointment. Verified live: doctor cards correctly show "New" (0 ratings from real backend data); hit and fixed a real bug during testing — `PastAppointment` briefly had a non-nullable `doctorId` field that broke the *entire* appointments list against the current backend (crashed on missing field) — removed it since it turned out unused (the rating endpoint takes the appointment id, not the doctor's). The "Rate doctor" trigger itself wasn't exercised live (no completed appointment in the test account, and getting one needs admin access) — code-reviewed and pattern-matches the already-proven Cancel button exactly, so verification is deferred, not skipped for cause |
| 7 | Statistics date filters: `6 months` / `1 year` + custom year/month picker | Improvement | **Done** | Added `sixMonths`/`oneYear` to the `StatsRange` pills, plus a "More filters" icon (fixed at the row's right end, doesn't scroll off) opening `StatsPeriodSheet` (year dropdown, required + month dropdown, optional — "whole year" when omitted). New sealed `StatsFilter` (`StatsRangeFilter \| StatsPeriodFilter`) replaces the old bare `StatsRange` as the provider's state shape; custom periods send `range=custom&year=&month=`. Backend deployed and **user-confirmed working live** (e.g. "Jan 2026" custom period) |
| 8 | Admin order-status flow: swipe-to-advance + separate cancel; Orders gains 3 tabs (Pharmacy / Prescriptions / Pathology) | New feature | **Done** | New shared `StatusSwipeBar` (`admin/presentation/widgets/`) replaces the free-choice `ChoiceChip` picker on Order detail — drag-to-confirm one linear step at a time (`created→processing→shipped→delivered`, label changes per step: "Process Order" / "Mark as Shipped" / "Mark as Delivered"), plus a standalone red "Cancel order" button (always enabled unless already cancelled — admin's explicit call, unlike the customer's pre-shipment-only self-cancel). Orders tab renamed **Pharmacy**, gained a 3rd **Pathology** sub-tab — a brand-new admin lab-test-booking management surface (list + detail, same swipe pattern, `scheduled→inSession→completed`), built from scratch since no admin lab-test screen existed before (`admin/pathology/`, mirrors `admin/orders/` file-for-file). `LabTestStatus` gained `inSession`. **Verified fully live** — swiped a real order through `created→processing→shipped→delivered` against the real backend, each step updating in place with no navigation between steps, confirmed by the real "Order delivered" push notification firing correctly too (proves the swipe flow uses the same trigger path as before). Pathology confirmed cleanly degrading (`GET /admin/lab-test-bookings` 404s, shows "Something went wrong" + Retry, no crash) since its 3 new endpoints (#68–70) weren't deployed at the time. **Update 2026-09-13**: incidentally observed the Pathology tab now loads real booking data from the backend (e.g. "Fasting Blood Sugar — PLSMS-0926-0001 — Scheduled") — endpoints #68–70 appear deployed, but the swipe-to-advance/cancel actions on this tab haven't been re-exercised live yet to confirm the full round-trip |
| 9 | Appointment status flow: `Upcoming → InSession → Completed`, `Cancelled` | New feature | **Done** | Same `StatusSwipeBar` pattern as #8: `AppointmentStatus` gains `inSession` (between `upcoming` and `completed`) with `.next`/`.advanceLabel`; `EditAppointmentScreen` rewritten to apply reschedule/advance/cancel immediately in place (no more shared Save button). **Fully re-verified live 2026-09-13** (user signed into the admin account on the emulator directly): swiped a real appointment (Ayush Bhanja / Dr. Vikram Rao) through the full lifecycle — "Start Session" → `In Session` ("Appointment marked In Session" snackbar), then "Mark Completed" → `Completed` ("Appointment marked Completed" snackbar), swipe bar correctly disappearing once terminal. Reschedule/Cancel were already confirmed live earlier |
| 10 | Order ID format standardization — `PHSMS-<mmyy>-<seq>` / `PLSMS-<mmyy>-<seq>` / `DASMS-<mmyy>-<seq>` | New feature | **Done** | Turned out mostly backend-only for Pharmacy: `Order.orderNumber` was already an opaque, displayed-verbatim string with zero client-side format assumptions, so the `PHSMS-<mmyy>-<seq>` swap needed **no client change at all** — purely a backend sequence-generator change. Lab-test bookings and appointments never had a human-readable number before, so those two got genuinely new work: added a nullable `bookingNumber`/`appointmentNumber` field to `LabTest`, `AdminLabTestBooking`, `PastAppointment`, `AdminAppointment`, parsed it, and displayed it on every card/detail screen those entities already have (customer Lab Tests list/detail, customer Profile → Appointments, admin Pathology tile/detail, admin Appointments tile/edit screen). **Decided**: new records only, no backfill — same policy as the original Order decision, extended to all three types for consistency. **Fully re-verified live 2026-09-13** — all three prefixes confirmed against the real backend in the same session: placing a pharmacy order returned `PHSMS-0926-0001`/`PHSMS-0926-0002`, booking a lab test returned `PLSMS-0926-0001`, booking an appointment returned `DASMS-0926-0001`. All rendered correctly on their respective history screens |
| 11 | Location integration — capture address location, derive read-only area/pincode, home-screen area display, admin-configurable order-radius gating | New feature | **Done** | `Address` gains optional `area`/`latitude`/`longitude`. Add Address gets a "Use current location" button (`geolocator` GPS fix + `geocoding` on-device reverse-geocode, no Maps API billing) that fills area/city/state/pincode read-only; falls back to editable manual entry if capture fails (permission denied, services off, or no geocoder result), with an "Edit manually" override even after a successful capture. **Decided** (asked the user): GPS-first with manual fallback, not GPS-only. Dashboard shows "Delivering to {area}" from the default address (falls back to city when `area` is `null`). New Admin → More → **Delivery Settings** screen captures the store's own location the same way (**decided**: GPS capture, not manual lat/lng entry) plus a radius (km); backed by endpoints #71 (any signed-in user, for the client-side radius check) / #72 (admin write). Checkout blocks **pharmacy-only** carts (never lab tests/appointments) outside that radius via a client-side Haversine calculation (`core/utils/distance.dart`) — fails open whenever it can't verify: no coordinates on the address (manual entry, or pre-existing data — no backfill) or no delivery settings configured/deployed yet. Also bumped `compileSdk` to 36 project-wide (forced on every library subproject via `android/build.gradle.kts`, not just `:app`) — `geocoding_android`'s own hardcoded compileSdk 33 conflicted with its own transitive androidx deps otherwise. **Fully re-verified live 2026-09-13** (backend deployed): Admin → More → Delivery Settings loaded real configured data from `GET /delivery-settings` (store location `20.29610, 85.82450`, radius `10.0`km) — confirms #71/#72 are live. Earlier live pass covered the customer side: permission dialog, GPS fix, and the reverse-geocode-failure fallback (this emulator image has no working native Geocoder backend) all worked correctly with no crash; saved a new address end-to-end; dashboard's "Delivering to" line confirmed live, including the city-fallback case |
| 12 | Dynamic delivery & platform fees, admin-configurable under new More menu | New feature | **Done** | Extends #11's `DeliverySettings`/admin screen rather than adding a separate one: `deliveryFeeTiers` (distance-banded list), `deliveryFeeWaived`, `platformFee`, `platformFeeWaived` on the same `GET /delivery-settings` / `PUT /admin/delivery-settings` endpoints. Admin screen gains an editable tier list (add/remove rows) + two **independent** "mark as free" switches — **decided** (asked the user): delivery and platform fee waived separately, not one combined toggle. **Decided**: a lab-test-only cart (no medicine item) is entirely unaffected — keeps the pre-#12 flat ₹40/free-over-₹500 rule and never gets a platform fee, matching #11's radius-gate precedent (gated/priced by presence of a medicine item, not proportionally split). Checkout/Cart pricing (`cart_providers.dart`) computes the tiered fee from the selected address's distance to the store (reusing #11's Haversine calc); refactored checkout's local address-selection state into shared `selectedAddressIdProvider`/`selectedAddressProvider` so the Cart screen's pre-checkout estimate and Checkout's actual selection price against the same address. `PriceBreakdown` gained a Platform Fee row and a strikethrough "waived" treatment (mirrors the existing MRP-vs-price pattern). Same fail-open philosophy as #11 throughout: no tiers configured, delivery settings not deployed, or address has no coordinates all fall back to the legacy flat rule. **Fully re-verified live 2026-09-13** (backend deployed): admin's configured tiers (3/5/7/10km → ₹0/50/70/100), platform fee (₹12), and "mark platform fee as free" toggle all loaded correctly from the backend and saved cleanly via `PUT`. Customer-side: added a pharmacy item — Cart and Checkout both correctly showed "Platform fee: ~~₹12~~ FREE" (struck through, matching the admin's waived toggle), Delivery still the legacy flat ₹40 (this test address has no captured coordinates, correctly falling back). Placed the order (`PHSMS-0926-0003`, ₹70) — server-authoritative total matched the client estimate exactly, confirming the backend now applies the same waived/fallback logic. Distance-tiered delivery pricing itself (as opposed to the legacy fallback) still isn't exercisable on this emulator, since its non-functional Geocoder means no test address can ever get real coordinates |
| 13 | Inventory bulk import (Excel upload and/or barcode scan) | New feature | Needs discussion | Scope not yet defined — discuss format/flow before estimating |
| 14 | UI beautification — full app redesign, modern/minimal style, new logo, redesigned in-app notifications | New feature | In progress | **Decided**: "calm clinical minimal" direction — deep teal/emerald palette (replacing stock Material blue), `google_fonts` Manrope type family, flat tonal Material 3 cards (no drop shadow, hairline border, bumped-up radii) instead of elevated/shadowed cards, pill-shaped buttons, a top-to-bottom gradient app background (replacing the flat scaffold color) applied once in `MyApp`'s `builder` rather than per-screen, and simple hand-drawn flat-style 2D character illustrations (`core/illustrations/`, `CustomPainter`-based — no external asset/SVG package, since no illustration set or logo exists yet) wherever a friendly visual helps, starting with the dashboard discount banner. User supplies the real logo asset later (placeholder branding until then); scheduled last after items 1–13 stabilize, rolled out **incrementally** feature-by-feature rather than big-bang. **Foundation pass done** (`AppColors`, `AppConstants` radii, `AppTheme`, `app.dart` gradient, `in_app_notification_banner.dart` restyle, `HappyDiscountIllustration` wired into `PromoBanner`) — verified live on the emulator in both light and dark mode across the Pharmacy dashboard, empty Cart, and Profile screens: gradient, new palette, Manrope font, tonal cards, pill buttons, and the illustration all render correctly, `flutter analyze`/`flutter test` clean. Icon style (outlined vs filled) isn't theme-enforceable in Flutter (`Icons.*` glyphs are separate constants per style) — being normalized screen-by-screen during the incremental rollout instead. **Medicines/Search pass done**: most of `ProductCard`/`SuggestedProductCard`/category grid already inherited the new look for free from the global theme (tonal cards, radii, pill "Add" buttons); on top of that, normalized `Icons.medication`/`Icons.add_shopping_cart` to their outlined variants, replaced `MedicineDetailScreen`'s heavy `Material(elevation: 8)` bottom action bar with a flat tonal surface + hairline top border matching the notification banner's language, and added a second illustration (`core/illustrations/search_empty_illustration.dart` — a cute sleepy/curious magnifying glass) wired into three empty states: Search's pre-query prompt, Search's "no results for X", and Medicines' empty-category state. Verified live: browsed Medicines (tonal cards, Rx/out-of-stock badges, pill Add buttons), opened a product detail (flat bottom bar, pill "Add to cart", outlined chips), and exercised Search end-to-end (empty-state illustration, typed "para", got the filtered "Paracetamol 500mg Tablets" result). `flutter analyze`/`flutter test` clean. **Cart/Checkout pass done**: flattened the two remaining heavy `Material(elevation: 8)` bottom bars (Cart's payment bar, Checkout's Order Now bar) to the same flat tonal + hairline-border treatment as everywhere else; normalized `Icons.medication`/`Icons.biotech` to outlined variants in `CartItemTile`; gave `PaymentOptionTile` a colored border (`primary` when selected, faded `outlineVariant` otherwise) instead of relying on a background tint alone, for clearer selected-state feedback on the new flat surfaces; and added a third illustration (`core/illustrations/order_success_illustration.dart` — a checkmark badge with scattered confetti) replacing the plain check icon on the "Order placed!" success dialog. Verified live end-to-end: added an item to cart, saw the flat payment bar and waived-platform-fee breakdown, went to Checkout, selected Cash on Delivery (confirmed the new selected-border treatment), and placed a real order (`PHSMS-0926-0005`, ₹65) — both the confetti success dialog and the restyled in-app "New order" notification banner rendered correctly together. `flutter analyze`/`flutter test` clean. **Appointments/Lab Tests pass done**: most of `DoctorCard`/`WeeklyAvailability`/`LabTestCard` already inherited the new look for free. On top of that: added a `chipTheme` to `AppTheme` (a foundation-pass gap noticed here — `Chip`/`ChoiceChip` had no shared styling yet) making every `Chip`/`ChoiceChip` app-wide pill-shaped and tonal, which immediately fixed `ScheduleLabTestSheet`'s time-slot picker for free; bumped the shared `StatusChip` (used by Orders/Appointments/Lab Tests status pills) from `radiusSm` to a full pill (`radiusFull`) for consistency with the button/chip language; flattened `LabTestCatalogDetailScreen`'s last heavy `Material(elevation: 8)` bottom bar; normalized `Icons.biotech`/`Icons.add_shopping_cart` to outlined variants; and reused the existing magnifying-glass illustration for two more "nothing here" empty states (Profile → Appointments' "No past appointments", Profile → Lab Tests' "No lab tests yet") rather than building new ones, keeping the illustration set small and consistent. Verified live: Appointments tab (doctor cards, weekly availability), Lab Tests catalog → detail → schedule sheet (chip theme confirmed on the time-slot picker), and Profile → Appointments/Lab Tests/Orders all showing the new pill-shaped status chips (Orders' benefited for free from the same shared widget, ahead of its own dedicated pass). `flutter analyze`/`flutter test` clean. **Admin console pass done — theme/colors only, deliberately no illustrations** (explicit user call: admin is a working tool, not a marketing surface). Audited every admin screen/widget (inventory, appointments, orders, prescriptions, pathology, discounts, users, statistics, delivery settings) — it was already written cleanly against `theme.colorScheme`/`Card`/`StatusChip`/`AppBottomNavBar` throughout, so nearly everything inherited the new palette, fonts, tonal cards, pill buttons and chip theme for free with **zero admin-specific changes**. Found and fixed only a handful of small consistency gaps: `Icons.medication`/`Icons.event` → outlined variants (`inventory_item_tile.dart`, `edit_appointment_screen.dart`, `create_appointment_screen.dart`); bumped `StockBadge` (inventory low/out-of-stock pill) and `AdminPrescriptionTile`'s thumbnail corner radius to match the pill/radius language used everywhere else. Left the Statistics status-bar-chart colors (`Colors.indigo`/`amber`/`green`/`red` per status) untouched — semantic/functional, not brand chrome, and need to stay mutually distinct regardless of theme. **Live verification note**: signing into the hardcoded admin number (`9124833215`) requires a real OTP — this project's only known Firebase test number is the customer one (`+917438013279`/`775184`), same blocker hit in an earlier session for item #9 — so the admin console's live rendering wasn't visually re-confirmed on-device this pass; confidence instead comes from the thorough source read (every screen already theme-driven) plus `flutter analyze`/`flutter test` passing clean. The customer-facing **login/OTP screens themselves** were confirmed live during this pass (reached while switching test accounts) and correctly show the new gradient background, palette, and pill-shaped fields/buttons. If the user signs into the admin account themselves, a live visual pass of the admin console would be a good follow-up. **Dashboard polish 2026-09-13**: removed the "Search by image" placeholder button entirely, moved **Prescription** to a compact `IconButton.filledTonal` beside the search bar (which shortens the search bar as a side effect), and deepened the app background gradient (`AppColors.gradientLightTop/Bottom`, `gradientDarkTop/Bottom`) — the original foundation-pass values were a near-solid tint that didn't read as a gradient at a glance; strengthened to a clearly-visible teal-to-white (light) / teal-black-to-dark (dark) fade, verified live in both themes. **Button-height fix 2026-09-13**: the global `elevatedButtonTheme`/`filledButtonTheme`/`outlinedButtonTheme` vertical padding was `AppConstants.spacingMd` (16px) — reasonable on its own, but Checkout's "Order Now" and Cart's "Payment" buttons *also* wrapped their label in an extra local `Padding(vertical: spacingSm)`, doubling up to a visibly oversized button; Lab Tests' "Add to cart" had no such local override and still read as too large purely from the 16px theme default. Fixed both causes: dropped the global vertical padding to `spacingSm` (8px, app-wide — every filled/elevated/outlined button is slightly more compact now, not just these two) and removed the redundant local `Padding` wrappers on Order Now/Payment. Verified live across Lab Tests detail, Cart, and Checkout — all three read as proportionate now. **Appointment card layout fix 2026-09-13**: `ProfileAppointmentsScreen`'s Cancel button used to sit on its own row below the date, with a visible gap that read as floating too low. Moved the date/time and Cancel onto the same row (date `Expanded` on the left, a `visualDensity: compact` Cancel button right-aligned), immediately below the header row — now reads as directly attached to the status pill above it instead of adrift lower in the card. Remaining for #14 overall: more illustrations at other customer-facing empty-state moments. **Real logo/branding done, 2026-09-15**: the user supplied two logo PNGs — a full app-icon artwork and a lighter in-app variant with an "Estd. 2001 / Chhaka Bazar, Kamarda" tagline. The launcher icon (`assets/branding/app_icon_source.png`, kept out of the Flutter asset bundle — used only as the resize source) replaced `android/app/src/main/res/mipmap-*/ic_launcher.png` at all 5 densities (48/72/96/144/192px) via a one-off Python/Pillow resize script (no `flutter_launcher_icons` dependency added, since it's a one-time asset swap, not an ongoing generation need); the source already carried a real anti-aliased alpha channel for its rounded-square shape, so no further processing was needed there. The in-app logo (`assets/branding/logo.png`, declared in `pubspec.yaml`'s `flutter.assets`) needed a fix first — **the PNG the user saved had lost its real transparency**: what displayed as a checkerboard "transparent" preview in chat was actually baked into the pixels as literal alternating gray squares (confirmed via Pillow: the file was `RGB` mode with no alpha channel at all). Reconstructed real transparency with a Python/Pillow script that detects the checkerboard's near-neutral gray pixels (low R/G/B variance, value bands ~105–216) and sets them fully transparent, verified by compositing the result against the app's actual teal gradient before committing to it — no artifacts, no holes in the real logo art. Wired into `SplashScreen` and `LoginScreen` via `Image.asset('assets/branding/logo.png', ...)`, replacing the placeholder `Icons.local_pharmacy_rounded` + `Text(AppConstants.appName)` (the logo image already has "SUNIL MEDICAL STORE" baked in, so the separate text label was dropped as redundant). **Real bug hit and fixed**: on the login screen, the logo initially rendered stretched to the full screen width instead of its specified `width: 160` — root cause: the parent `Column` uses `crossAxisAlignment: CrossAxisAlignment.stretch` (needed for the form fields below), which gives `Image` a tight width constraint that silently overrides its own `width` parameter (this doesn't happen to `Icon`, which sizes its glyph independently of its box) — fixed by wrapping the logo in `Center(child: Image.asset(...))` so it receives loose constraints instead. Verified live on the emulator: launcher icon shows correctly on the home screen (Android's own circular mask applied automatically) and during cold-start; splash and login screens both render the destickered logo cleanly against the gradient background at the correct size, `flutter analyze`/`flutter test` clean. **Order-success illustration redesigned, 2026-09-16**: the user reported the checkmark badge on the "Order placed!" dialog looked "very out of place" on a real device (photo shared). Root cause was the confetti in `OrderSuccessIllustration`: the 5 pieces were positioned at fixed box-corner-ish coordinates independent of the badge's own size/position, at irregular angles, colored from the theme's `tertiary`/`secondary`/dimmed-`primary` — all teal-family hues in this app's seeded scheme, so they read as faint, disconnected smudges rather than confetti, especially in dark mode where the halo blob (`primary` at 12% alpha) was nearly invisible too. Redesigned: 6 confetti pieces (alternating small rounded rects and dots) now sit at fixed, evenly-spaced angles on a ring at `1.55×` the badge radius — close enough to read as one cohesive burst — in three fixed, non-theme celebratory colors (gold `#FFC94D`, coral pink `#FF6F91`, mint `#57C08C`) that stay vivid regardless of theme; halo alpha bumped slightly (12%→16%). Verified via a temporary side-by-side debug harness on the login screen (both `AppTheme.light`/`AppTheme.dark` rendered at once, not shipped — reverted immediately after, confirmed via `git diff` showing no residual changes to `login_screen.dart`/`splash_screen.dart`): the new version reads clearly as a checkmark with a celebratory ring around it in both themes, `flutter analyze`/`flutter test` clean |
| 15 | Image search | New feature | Backlogged | Explicitly deprioritized earlier — don't start unless asked |
| 16 | Admin-configurable home banners (12 fixed slots: 3 general discount, 6 festival, 3 doctor promo), cycling display when multiple active | New feature | **Done (client)** | See Admin > More > Home Banners and Pharmacy (dashboard) above for the full write-up. `BannerId` enum, two parameterized illustration painters (`PersonBadgeIllustration`, `FestivalIllustration`) reused across all 12 slots, admin list (inline active toggle + edit) + edit screen, customer `HomeBannerCarousel` (auto-cycling `PageView`, fails open to a single static banner). **Built ahead of the backend** — endpoints #73–75 documented in `docs/API_ENDPOINTS.md` (and synced to the cross-repo copy) but not yet deployed. Verified live: dashboard fail-open confirmed via logcat (`GET /v1/banners` 404s cleanly, static fallback renders correctly, no crash); all 12 illustrations spot-checked via a temporary (unshipped) debug harness, catching and fixing one real bug (the diya read as a smile until redrawn as a filled shape). Admin screens not live-verified — same hardcoded-admin-OTP blocker as other admin-only work in this backlog. **Flagged, not fixed**: every festival banner's seed description uses the identical literal "5th to 10th Nov" text as given, though most of these festivals don't actually fall in November — worth revisiting per-festival before go-live |
| 17 | Expand category taxonomy to 22 categories; admin product-type field + filter/search redesign; colorful category illustrations | New feature | **Done (client)** | See "Category taxonomy" under Medicines, Pharmacy (dashboard), and Admin > Inventory above for the full write-up. `ProductCategory` (22, fixed client-side catalog, replaces the old backend-driven 6) + `ProductType` (5, new nullable `Product.type` field) — both **built ahead of the backend**, `docs/API_ENDPOINTS.md` flags a **breaking data-migration** existing products need (old category labels don't exist in the new 22, so category-filtered views won't surface them until an admin re-categorizes — unfiltered views are unaffected). Dashboard shows 8 featured categories + a new "Show All Categories" button → `AllCategoriesScreen` (all 22). Admin Inventory's filter bar redesigned (first-5-categories + fixed filter icon, mirroring Statistics' "more filters" row) with a new dedicated `AdminInventoryFilterScreen` (category, type, and a Name/Category/Type/Composition/Ingredient search — type and search are client-side, only category hits the network). New `CategoryIllustration` (`core/illustrations/`) — colorful pastel card + icon badge per category, `CustomPainter`-based like the rest of this app's illustrations; **decided with the user**: vector illustrations rather than real product photography (no image-generation/licensed-stock tool available, and bundling scraped photos would carry copyright/consistency risk) — asked via `AskUserQuestion`, user picked the vector option. `flutter analyze`/`flutter test` clean. **Not done this pass**: the user's item 7 ("exciting life-like illustrations to the [home] banners") — scope wasn't specific enough to act on safely alongside this already-large batch; flagged for a follow-up session rather than guessed at. **4 live-verification bugs found and fixed, 2026-09-17** (user tested on a real phone and reported all four with annotated screenshots): FAQ `ExpansionTile` border clashing with the parent card's rounded corners (see Help & Support above), `SuggestedProductCard`'s Add button misaligning across a row when `packSize` was only present on some products (see the packSize card-layout note under Medicines above), category-tile illustrations shifting up/down within a row whenever a neighboring label wrapped to a different line count, and `prescriptionDrugs`' card color reading as too faint next to its more saturated neighbors (both under "Category taxonomy" → "Two follow-up bugs fixed" above). All four verified live on the emulator after the fix. |

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
- **compileSdk fix:** `android/build.gradle.kts` forces `compileSdk = 36` on
  every Android library subproject (`afterEvaluate`, guarded against
  `evaluationDependsOn(":app")` already having evaluated some subprojects by
  that point — see the inline comment). Needed because `geocoding_android`
  hardcodes its own `compileSdk 33`, which conflicts with its own transitive
  androidx deps (`androidx.core:1.13.1` etc. need 34+) — bumping only
  `:app`'s `compileSdk` doesn't fix this, since each library module's
  `compileSdk` is independent.

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
