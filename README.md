# مصاريفي (Masarifi)

**📲 تحميل التطبيق / Télécharger l'application:**
**https://merabetabdelkarim.github.io/masarifi/**

A personal-finance app for a **salaried person in Algeria**: set your monthly
salary and pay day, then the app tells you — every day — how much you may still
spend until the next salary.

- Flutter (Dart 3, Material 3). **Android is configured**; iOS needs
  `flutterfire configure --platforms=ios` first (see §2.1)
- Firebase Authentication (email/password + Google Sign-In), Cloud Firestore
  (offline persistence enabled by default), Crashlytics and App Check
- Riverpod, feature-first clean structure
- Full **Arabic RTL** UI with **French** as a second language
- Currency: Algerian Dinar, always stored as **integers in dinars**

---

## 1. Prerequisites

| Tool | Version |
| --- | --- |
| Flutter | 3.41+ (stable, Dart 3) |
| Dart | 3.11+ |
| FlutterFire CLI | latest |
| Firebase project | Blaze not required for Auth + Firestore |

```bash
dart pub global activate flutterfire_cli
```

## 2. Firebase setup

### 2.1 Configure the project

```bash
flutterfire configure            # add --platforms=android,ios to add iOS
```

`lib/firebase_options.dart` currently holds the **Android** app of project
`masarif-db` only; iOS and web throw a clear error until you run the command
above for them (it also adds `GoogleService-Info.plist`). Without any Firebase
configuration the app starts on a setup screen explaining what to run.

### 2.2 Enable the providers

In the Firebase console:

1. **Authentication → Sign-in method** → enable **Email/Password** and
   **Google**.
2. **Firestore Database** → create a database (production mode, pick the region
   closest to Algeria, e.g. `europe-west1`).

### 2.3 Deploy security rules and indexes

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

`firestore.rules` gives each user access to `users/{their-uid}` and its known
sub-collections only, and **validates every write**: positive integer amounts,
known enum values (`type`, `source`, `cycle`, …), pay day 1–31, `YYYY-MM`
budget months, goals never below zero. Optional fields are only checked when
present, so documents written by older versions stay editable.
`firestore.indexes.json` contains the composite indexes used by the queries.

The rules are tested on the emulator (Java 11+ and the Firebase CLI needed):

```bash
npm ci --prefix firestore-tests
firebase emulators:exec --only firestore --project demo-masarifi "npm --prefix firestore-tests test"
```

### 2.4 Crashlytics, App Check and the API key

- **Crashlytics** needs nothing more than the Gradle plugin already applied.
  Collection is off in debug builds; every error the app recovers from is
  still reported through `core/errors/error_reporter.dart`.
- **App Check**: in the console, register the Android app with
  **Play Integrity** (iOS: App Attest), run a debug build once and add the
  debug token it prints, then switch **enforcement** on for Firestore and
  Authentication.
- **API key**: in Google Cloud Console → Credentials, restrict the Android key
  to the package `dz.masarifi.masarifi` plus your SHA-1 fingerprints, and to
  the Firebase APIs. The key is public by design: the restriction, App Check
  and the rules are what protect the data.

### 2.5 Android

`android/app/build.gradle.kts` already sets:

```kotlin
minSdk = 23   // required by Firebase Auth / Firestore
```

For Google Sign-In, add the SHA-1 of your debug/release keystore to the
Firebase project settings (Android app):

```bash
cd android && ./gradlew signingReport
```

**Release signing.** Create an upload keystore and `android/key.properties`
(both git-ignored):

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

```properties
storeFile=/absolute/path/to/upload-keystore.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

Without that file a release build falls back to the debug key: fine for
`flutter run --release`, refused by the Play Store.

### 2.6 iOS

Add `REVERSED_CLIENT_ID` from `GoogleService-Info.plist` to
`ios/Runner/Info.plist` under `CFBundleURLTypes` (FlutterFire does this for you
when it configures the project).

## 3. Run

```bash
flutter pub get
flutter run
```

### App icon & logo

The logo is a wallet with a gold clasp on the app green. Its sources are the
SVGs in `assets/brand/`; the in-app version is drawn by
`core/widgets/app_logo.dart` with the same geometry. After changing the art,
export the SVGs to the PNGs next to them (1024×1024) and regenerate:

```bash
dart run flutter_launcher_icons
git checkout -- ios/Runner.xcodeproj/project.pbxproj   # the tool corrupts one Xcode setting
```

The adaptive foreground is drawn larger than the safe zone on purpose: the
tool adds a 16 % inset around it.

## 4. Tests

```bash
flutter analyze   # no issues
flutter test      # 167 tests
```

CI (`.github/workflows/ci.yml`) runs format, analyze, the Flutter tests and
the Firestore rules tests on every push to `main` and every pull request.
`.github/workflows/pages.yml` publishes `landing page/` to GitHub Pages
whenever it changes on `main`.

Repository tests (`test/data/`, in-memory Firestore via `fake_cloud_firestore`):

- every money action keeps ledger, wallets and the linked document consistent,
  and deleting the operation undoes all of it (debt payments, subscription due
  dates, dawra contributions and rounds),
- `addToBalance` debts move the wallet back on delete or amount change,
- account and category deletion guards, system-category back-fill,
- JSON backup content and "delete everything" (only that user's data).

Covered by unit tests:

- pay-period calculation (clamping pay day 31 to short months, period
  boundaries, previous period),
- daily allowance (including the negative-budget warning and the
  no-double-counting rule for a recorded salary),
- debt remaining / partial payments / old-debt detection,
- amount formatting (standard `12,500 دج` and the Algerian `1.25 مليون`),
- subscription cycles (weekly/monthly/yearly with month-end clamping),
- the reminder planner (pay day, subscriptions, unpaid debts, past times),
- budget levels (80 % warning / 100 % exceeded) and month-key arithmetic,
- the monthly report builder (income/expense sums, transfers excluded,
  per-category grouping),
- the dawra rotation (receiver order, paid/unpaid members, finished state),
- seasonal planning (upcoming Algerian events, months left, monthly set-aside,
  Ramadan extrapolated beyond the table, the two Ramadans of 2030),
- dashboard: goals set aside and dawra flows,
- PDF generation in Arabic and French.

---

## 5. Folder structure

```
lib/
├── main.dart                     # Firebase init + ProviderScope
├── app.dart                      # theme, locale, AuthGate, setup screen
├── firebase_options.dart         # generated by `flutterfire configure`
├── core/
│   ├── constants/                # app constants + seed data (defaults)
│   ├── domain/                   # pure logic: pay_period, debt_calculator
│   ├── errors/                   # AppFailure, auth error mapping, Crashlytics reporter
│   ├── localization/             # S (ar/fr strings) + context extension
│   ├── notifications/            # local-reminder plugin wrapper
│   ├── providers/                # core + locale providers
│   ├── theme/                    # Material 3 light & dark themes
│   ├── utils/                    # formatters (DZD) + validators (localized)
│   └── widgets/                  # async/empty/error views, dialogs, fields
├── features/
│   ├── auth/        data · providers · presentation (sign in/up, auth gate)
│   ├── settings/    models · data · providers · presentation (salary, payday, backup, delete account)
│   ├── accounts/    models · data · providers · presentation (wallets, transfer)
│   ├── categories/  models · data · providers · presentation
│   ├── transactions/ models · data · providers · presentation (fast add)
│   ├── subscriptions/ domain · models · data · providers · presentation
│   ├── debts/       models · data · providers · presentation (both sides)
│   ├── notifications/ domain (reminder planner) · providers
│   ├── budgets/     domain (status) · models · data · providers · presentation
│   ├── goals/       models · data · providers · presentation (envelopes)
│   ├── dart/        models · data · providers · presentation (dawra groups)
│   ├── seasonal/    domain (Algerian events) · presentation
│   ├── reports/     domain (monthly report) · data (Excel/PDF export) · presentation
│   ├── dashboard/   domain · providers · presentation (+ widgets)
│   └── shell/       presentation (bottom navigation)
└── features/<name>/
    ├── models/        immutable models + toMap/fromDoc
    ├── data/          Firestore repositories (all writes batched)
    ├── providers/     Riverpod StreamProviders
    └── presentation/  screens, sheets and widgets
test/
├── pay_period_test.dart
├── daily_allowance_test.dart
├── debt_calculator_test.dart
├── formatters_test.dart
├── subscription_calculator_test.dart
├── reminder_planner_test.dart
├── budget_status_test.dart
├── monthly_report_test.dart
├── dart_rounds_test.dart
├── seasonal_events_test.dart
├── pdf_export_test.dart
└── data/                         # repositories on fake Firestore
assets/fonts/                     # Amiri (Arabic PDF) + OFL licence
assets/brand/                     # logo sources (SVG) and the PNGs the app icons are made from
firestore-tests/                  # security-rules tests (emulator)
.github/workflows/ci.yml
firestore.rules
firestore.indexes.json
firebase.json
```

---

## 6. Data model (Firestore)

```
users/{uid}                       profile + settings
users/{uid}/accounts/{id}         wallet
users/{uid}/categories/{id}       category
users/{uid}/transactions/{id}     income / expense / transfer
users/{uid}/subscriptions/{id}    recurring bills
users/{uid}/debts/{id}            iOwe | owedToMe
users/{uid}/budgets/{id}          category budget        (id: YYYY-MM_catId)
users/{uid}/goals/{id}            savings goal           (deposit envelope)
users/{uid}/dart/{id}             rotating savings group (dawra)
```

### `users/{uid}` — profile & settings

| field | type | notes |
| --- | --- | --- |
| `displayName`, `email` | string | |
| `salary` | **int** | monthly net salary in dinars |
| `payday` | int | 1–31, clamped to the last day of shorter months |
| `locale` | string | `ar` (default, RTL) or `fr` |
| `currencyDisplay` | string | `dzd` → `45,000 دج` · `millions` → `4.5 مليون` |
| `themeMode` | string | `system` / `light` / `dark` |
| `setupCompleted` | bool | onboarding finished |
| `createdAt`, `updatedAt` | Timestamp | server timestamps |

### `accounts/{id}`

`name`, `type` (`cash` | `ccp` | `card` | `other`), `balance` (**int**),
`colorValue` (int ARGB). Balances are updated with `FieldValue.increment`
inside the **same batch** as the related transaction.

### `categories/{id}`

`nameAr`, `nameFr`, `iconCode` (Material icon code point), `colorValue`,
`kind` (`both` | `expense` | `income`), `isDefault`.
Seeded on first sign-in: food, transport, coffee, shopping, bills, health,
family, leisure, subscriptions, other + a `salary` income category, plus
`cat_debts` and `cat_dawra` (back-filled for existing users at sign-in).
The **system categories** `cat_other`, `cat_salary`, `cat_debts` and
`cat_dawra` are written to automatically, so they can be renamed but never
deleted; a category still used by operations, budgets or subscriptions cannot
be deleted either.

### `transactions/{id}`

| field | notes |
| --- | --- |
| `type` | `income` \| `expense` \| `transfer` |
| `amount` | **int dinars, always positive** — the sign comes from `type` |
| `categoryId` | income/expense only |
| `accountId` | target account; transfers also carry `fromAccountId`/`toAccountId` |
| `date` | `Timestamp` |
| `source` | `manual` \| `subscription` \| `debt` \| `salary` \| `dawra` |
| `note` | optional |
| `linkedId` | debt / subscription / dawra that produced the operation |
| `linkedPaymentId` | payment entry inside that debt or dawra |
| `linkedRound` | dawra round |
| `previousDueDate` | subscriptions: due date before this payment |

**Linked operations.** An operation created by a debt payment, a bill payment
or a dawra action carries `linkedId`. Its amount and type cannot be edited
from the history (only note, date, category and account), and **deleting it
undoes the side effect** in the same batch: the debt payment disappears, the
bill's due date goes back (unless a later payment moved it again), the dawra
contribution or round is undone.

**Design decision:** the salary itself lives in settings; the *dashboard*
formula is `salary + extra income − expenses − due subscriptions − due debts`,
so a salary recorded as a transaction (`source = 'salary'`) is excluded from
"extra income" and is never counted twice. The **"تسجيل الراتب"** button on the
dashboard records it into an account so wallet balances stay correct.

### `debts/{id}`

`type` (`iOwe` | `owedToMe`), `person`, `phone`, `amount` (int), `date`,
`dueDate?`, `note`, `payments[] {id, amount, date, note}`, `addToBalance`,
`balanceAccountId?`.
Remaining = `amount − Σ payments`. A payment is written in **one batch**:
payment entry + matching income/expense transaction + account balance.

Both sides live on their own tab of the **الديون** screen. A debt unpaid for
more than 60 days gets a "دين قديم" badge; `addToBalance` moves the borrowed
or lent money on the wallet at creation time; that wallet is stored in
`balanceAccountId`, so deleting the debt (or changing its amount) moves the
money back. Payment operations use the `cat_debts` category.

### `subscriptions/{id}`

`name`, `amount` (int), `cycle` (`weekly` | `monthly` | `yearly`),
`nextDueDate`, `categoryId?`, `accountId?`, `isActive`, `note`,
`lastPaidAt?`.

**"تم الدفع"** writes one batch: an expense operation tagged
`source = subscription`, the account balance decremented, and
`nextDueDate` advanced **at least one cycle**, even when the bill is paid
early (clamped the same way the pay day is).
Paused bills (`isActive = false`) never count towards the dashboard and never
remind.

### `budgets/{id}`

`month` (`YYYY-MM`), `categoryId`, `limit` (int). The document id is
`<month>_<categoryId>` so re-saving a category simply updates its ceiling.
Spent per category is computed from that month's expense transactions;
levels are pure logic (`budget_status.dart`): **warning ≥ 80 %**,
**exceeded ≥ 100 %** of the limit.

### `goals/{id}` — savings envelopes

`name`, `targetAmount`, `savedAmount`, `deadline?`, `kind`
(`saving` | `seasonal`), `eventId?`, `entries[] {amount, date, note, withdraw}`.
A deposit moves money from a wallet **into** the envelope; a withdrawal moves
it back — both in one batch and **without** creating a ledger transaction.
The dashboard subtracts the period's net deposits ("مُدّخر في الأهداف") from
the remaining amount: that money is no longer available to spend.

### `dart/{id}` — rotating savings group (دَّارة)

`name`, `contributionAmount`, `memberNames[]`, `meName`, `currentRound`
(1-based), `startDate`, `payments[] {id, memberName, round, date}`.
Every member pays the same monthly contribution; the whole pot goes to one
member each round (`receiverOf(round) = members[(round-1) % n]`). Recording a
contribution writes an expense; receiving the pot writes an income
(or an expense when I hand the cash to someone else) and advances
`currentRound` — always in one batch. These operations use
`source = dawra` and the `cat_dawra` category: the dashboard keeps them out
of income, expenses and the category chart (it is savings, not consumption)
but adds their net to the remaining cash ("صافي الدَّارة").

### Seasonal planning

Not a collection: a pure table of Algerian events
(`features/seasonal/domain/algerian_events.dart`) — Ramadan starts (Maghrib
announcements 2025–2030, then extrapolated with the mean lunar year, ±2 days;
2030 has two), Aïd el-Fitr, school year (1 September), summer
vacation, 1 November, New Year. Each event can spawn a `kind = seasonal` goal
linked by `eventId`; the screen shows the progress and the **monthly set-aside**
needed to reach the target before the event.

### Reports & export

The monthly report (`features/reports/domain/monthly_report.dart`) sums
incomes/expenses of a calendar month (transfers excluded) and groups expenses
by category. The reports screen exports it two ways:

- **Excel** (`excel` package): Arabic/French labels, full transactions table +
  per-category summary, shared via `share_plus`;
- **PDF** (`pdf` + `printing` package): in the app language. Arabic is laid
  out right-to-left with the embedded **Amiri** font (`assets/fonts/`, SIL
  OFL); same tables, shared as a file.

### Backup & account deletion

Settings → **بياناتي**: export every document as one JSON file
(`masarifi-backup-YYYY-MM-DD.json`), or delete the account permanently
(re-authentication, then all Firestore data in batches, then the Firebase
Auth user), as Google Play and the App Store require.

---

## 7. The pay period

- The period runs from **the last pay day** to **the next one** (exclusive).
- A new period starts exactly on the pay day.
- Pay day 31 becomes 28/29 February, 30 April, etc.
- **Days left** = whole days from today until the next pay day (the pay day
  itself is not counted: the salary arrives then). "Today" rolls over at
  midnight and whenever the app returns to the foreground on another day.
- **Daily allowance** = `remaining ÷ days left`; if `remaining < 0` the card
  turns red and shows an explicit warning.
- Unpaid subscriptions and debts **due before the next pay day** are subtracted
  from the remaining amount, and so is the money put into goals this period;
  the dawra net is added.

---

## 8. Local reminders

Switch **الإشعارات → تذكيرات الاستحقاقات** on in settings (the OS permission
is requested the first time). The app then schedules local notifications and
re-schedules them whenever the data changes:

| reminder | when |
| --- | --- |
| each **active** subscription | 09:00 the day before, and 09:00 on the due day |
| each **unpaid** debt with a due date | 09:00 the day before, and 09:00 on the due day |
| **pay day** | 19:00 the evening before, and 09:00 on the pay day |

Everything is planned by a pure function
(`features/notifications/domain/reminder_planner.dart`) so it is unit tested;
the plugin wrapper lives in `core/notifications/notifications_service.dart`.
On Android the scheduled alarms survive a reboot through the receivers
declared in `AndroidManifest.xml` (`RECEIVE_BOOT_COMPLETED`,
`POST_NOTIFICATIONS`).

---

## 9. Localization & formatting

- Arabic is the default language and forces RTL; French is available in
  settings and switches to LTR automatically.
- Every string lives in `lib/core/localization/s.dart` — no screen hard-codes
  text, including validation and `FirebaseAuth` error messages.
- Amounts are **never** stored or computed as `double`; formatting uses integer
  grouping (`1,234,567`) with Western digits, as used in Algeria.
- The optional "Algerian way" mode expresses amounts in **millions of
  centimes**: `10,000 DA = 1 مليون`, `1,000 DA = 100 ألف`.

---

## 10. Roadmap

| Phase | Scope | Status |
| --- | --- | --- |
| **1** | auth, settings (salary + payday), accounts, transactions, dashboard | ✅ delivered |
| **2** | subscriptions, both debt types with partial payments, local reminders | ✅ delivered |
| **3** | budgets, goals, dart, seasonal planning, reports + Excel/PDF export | ✅ delivered |
| **4** | data integrity, validated rules, Crashlytics/App Check, Arabic PDF, JSON backup, account deletion, CI | ✅ delivered |
| **5** | restore from backup, onboarding polish, widgets, multi-currency trip mode | ideas |
