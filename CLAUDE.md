# Medical Store App

## Objective

Android application for a local pharmacy ("Sunil Medical Store"). Customers
browse/search medicines, upload prescriptions, book doctor appointments, and
manage orders, lab tests, addresses and payments. Admins get a separate
console. Everything backend-facing is currently mocked in-app pending the
real backend.

## Tech Stack

- Flutter (Material 3), Dart 3.12
- Riverpod 3 (state management)
- GoRouter 17 (navigation)
- Firebase Authentication (phone/OTP) — **live**
- Firebase Messaging (planned)
- Azure Blob Storage (planned, for prescription/file uploads)
- **ASP.NET Core + MySQL backend (future)** — this is the real data store
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
- Repositories: `domain/<x>_repository.dart` (interface) + `data/mock_*.dart`
  (in-memory mock) exposed via a Riverpod `Provider`. Swap the provider's impl
  for the real backend later; UI is untouched.
- Read data with `FutureProvider` + `AsyncValue.when` (loading/error/data).
- Mutable in-memory state via `Notifier`/`NotifierProvider` (e.g. addresses, payments).
- "Coming soon" features show a SnackBar placeholder.
- Design tokens (spacing/radius) live in `AppConstants`; don't hard-code.

## Navigation (GoRouter)

`routerProvider` in `lib/core/routes/app_router.dart`. A single `redirect`
enforces the whole policy, driven by `authControllerProvider` via a
`refreshListenable`.

- Top-level routes (no bottom bar): `/` splash, `/login`, `/onboarding`, `/admin`.
- Customer area = `StatefulShellRoute.indexedStack` with 5 tabs (each keeps its
  own stack, in this order): **Pharmacy** `/pharmacy` (default), **Lab Tests**
  `/lab-tests`, **Appointments** `/appointments`, **Cart** `/cart`, **Profile**
  `/profile`. (Nav destination order must match branch order in the router.)
- Sub-pages nest under their tab so the bottom bar stays visible, e.g.
  `/pharmacy/medicines?category=<label>`, `/lab-tests/<testId>`,
  `/cart/checkout`, `/profile/account`, `/profile/orders`,
  `/profile/orders/detail` (order passed via `extra`), `/profile/addresses/add`, etc.
- The Cart tab icon shows a live item-count `Badge` (`ScaffoldWithNavBar` is a
  `ConsumerWidget` watching `cartItemCountProvider`).
- Redirect policy: `unknown`→splash; `unauthenticated`→login;
  `onboarding`→/onboarding; authenticated→role home (admin→/admin,
  customer→/pharmacy) and each role is kept out of the other's area.

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
- **Role** is read from the ID-token custom claim `role` (default `customer`;
  `admin` only if the claim says so). The app already reads it, so admins "just
  work" once the .NET backend sets the claim via the Admin SDK. `UserRole` enum
  in `core/models`.
- Phone numbers: UI takes 10 digits; controller sends E.164 `+91<digits>`.
  `AppUser.phoneNumber` stores the national 10-digit; `displayPhone` formats it.
- Widget test overrides `authRepositoryProvider` with an in-test fake so it
  never touches Firebase.

## Data & backend strategy (important decision)

**Firebase = Auth (+ Messaging later) only. No Firestore.** All app data —
users, orders, lab tests, addresses, payments, catalog — will live in **MySQL**
behind the **.NET Core** backend. The app will authenticate API calls by
sending the Firebase **ID token**, which the backend verifies with the Firebase
Admin SDK (and can set role custom claims). `cloud_firestore` was removed as
unused. Until the backend exists, every feature reads from **mock repositories**
that are the designated swap points.

## Features (current state)

- **Splash** — shown while the auth session resolves.
- **Pharmacy (dashboard)** — greeting; two buttons above search (**Search by
  image**, **Prescription** — placeholders); search bar (placeholder); promo
  banner; **Shop by category** grid (`homeCategoriesProvider`); **Suggested for
  you** horizontal products.
- **Medicines** — category-filtered product list from `?category=`; `Product`
  model + `MockProductRepository` + `medicine_providers`. "Add" → adds to cart.
- **Lab Tests** (tab) — bookable-test catalog like medicines
  (`features/lab_tests`, `LabTest` model + `MockLabTestRepository` +
  `labTestCatalogProvider`). List → detail (`/lab-tests/<testId>`) with sample
  type / report time / fasting / parameters → **Add to cart**. Note: distinct
  from **Profile → Lab Tests** (booked history); this tab is the storefront.
- **Appointments** — doctors available this week (`MockDoctorRepository`,
  `weeklyDoctorsProvider`); doctor cards with a Mon–Sun availability strip;
  **Book** = coming soon. Current-week math in `core/utils/week_range.dart`.
- **Cart** — functional, in-memory (`cartProvider` Notifier), holds **both
  medicines and lab tests**. `CartItem` stores neutral fields (`id`, `title`,
  `subtitle`, `price`, `kind` = `CartItemKind.medicine|labTest`) — a snapshot of
  the catalog item, so the cart isn't coupled to either catalog domain;
  `addProduct(Product)` / `addLabTest(LabTest)` map into it. Add-to-cart from
  medicines list + dashboard suggestions + lab test detail. Cart screen: line
  items with ± quantity steppers + remove; **promo code**
  (`MockPromoRepository`: `SAVE10` 10%, `FLAT50` ₹50>₹300, `NEW100` ₹100>₹500);
  price breakdown (subtotal, discount, delivery — free above ₹500 — total),
  derived via providers in `cart_providers.dart`. **Payment** → **Checkout**
  (`/cart/checkout`): default delivery address + change (bottom-sheet picker
  from `addressesProvider`); pay via UPI apps (Google Pay / PhonePe / BHIM /
  Other UPI with a custom UPI-id field) or **Cash on Delivery**; **Order Now** →
  success dialog → clears cart + promo → home. Payment is a selection UI + mock
  placement (no gateway/UPI deep-link); placed orders are **not** yet saved to
  Profile → Orders (that history is still mock, pending the backend).
- **Profile** — header + 6 menus + Sign Out:
  - **Account** — gender-based avatar, personal details, medical records (mock).
  - **Appointments** — past appointments + "Book Appointment" → Appointments tab.
  - **Orders** — history list → detail (items, total, "Download invoice" placeholder).
  - **Lab Tests** — history list → detail (parameters, "Download invoice" placeholder).
  - **Addresses** — list, **Set as default**, **Add address** (functional,
    in-memory `addressesProvider` Notifier).
  - **Payment Methods** — list, **Add UPI** dialog (functional, in-memory
    `paymentMethodsProvider`). Only UPI supported for now.
  - Read-only profile data (`MockProfileRepository`); name/phone shown around the
    app are the real auth values, but Account's extended fields are still mock.
- **Admin** — separate console screen, role-gated, no bottom tabs (dormant until
  a `role=admin` claim exists).

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
