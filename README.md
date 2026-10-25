# AquaShop

AquaShop is a Flutter e-commerce application for water purifiers, filters,
pumps, dispensers, accessories, and spare parts.

The application has three user roles:

- **Customer**: browse products, place orders, choose Razorpay or Cash on
  Delivery, and submit service requests.
- **Dealer**: browse products with dealer pricing and place bulk orders.
- **Admin**: manage products, import products from CSV, approve or reject
  orders, and manage service requests.

## How the application works

### Customer and dealer flow

1. A user creates an account or signs in with Firebase Authentication.
2. The user's role is stored in the Firestore `users` collection.
3. Products are loaded from the Firestore `products` collection.
4. The user adds products to the cart.
5. At checkout, the user selects an address on an OpenStreetMap map.
6. The order is saved in the Firestore `orders` collection.
7. The user can pay using:
   - Razorpay: payment must succeed before the order is created.
   - Cash on Delivery: the order is created with payment status `pending`.
8. The admin approves or rejects the order.
9. The user can view the order status in order history.

After a successful order submission, the cart is cleared immediately.

### Service request flow

1. The user opens the Service section.
2. The user selects a service type and describes the problem.
3. The user selects the service address on the OpenStreetMap picker.
4. The request is saved in the Firestore `serviceRequests` collection.
5. The admin can change the request status and add a reply.

### Product management

An admin can:

- Load the built-in sample catalog.
- Import products from a CSV file.
- Update an existing product when the CSV contains its `id`.
- Create a new product when the CSV `id` is blank.

CSV columns:

```csv
id,name,category,price,stock,description,imageUrl
p001,AquaPure RO,Purifiers,12999,10,RO purifier,https://example.com/ro.jpg
,Replacement Filter,Filters,499,25,Filter cartridge,https://example.com/filter.jpg
```

The `id` column is optional. The other columns are required.

## Technology used

- Flutter and Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- Razorpay
- OpenStreetMap and Nominatim reverse geocoding
- Flutter Map
- Vercel for Flutter web hosting
- Optional Node.js notifier for FCM and SMTP email

## Requirements

Install these tools:

1. Flutter stable
2. Dart SDK (included with Flutter)
3. Android Studio and Android SDK for Android builds
4. Node.js and npm for the optional notifier
5. Git
6. A Firebase project
7. A Vercel account only if deploying the web app

Check the Flutter installation:

```powershell
flutter doctor
```

The Android SDK must include API 36 because the Android project compiles
against API 36.

## First-time Flutter setup

Open PowerShell in the project directory:

```powershell
cd C:\Users\gandh\Downloads\E-commerce\aquashop
flutter pub get
flutter devices
```

Run the application on a connected device or emulator:

```powershell
flutter run
```

Run it on a specific device:

```powershell
flutter run -d <device-id>
```

## Firebase setup

The app is configured for the Firebase project represented by
[`firebase_options.dart`](./lib/firebase_options.dart). If you use a different
Firebase project, generate new FlutterFire configuration instead of copying
credentials from another project.

Required Firebase products:

1. **Authentication**
   - Enable Email/Password sign-in.
2. **Cloud Firestore**
   - Create a database.
   - Deploy [`firestore.rules`](./firestore.rules).
3. **Cloud Messaging**
   - Configure push notifications for Android/iOS if needed.

Deploy Firestore rules with the Firebase CLI:

```powershell
firebase login
firebase use <your-firebase-project-id>
firebase deploy --only firestore:rules
```

The first registered customer or dealer cannot become an admin from the app.
To create an admin, update that user's role in Firestore to:

```text
admin
```

Do this only from a trusted administrator account.

## Razorpay setup

The Razorpay key is configured in [`config.dart`](./lib/config.dart).

For development, use a Razorpay test key. For production:

- Use a production key only when the app is ready for real payments.
- Do not commit Razorpay secret keys.
- Never put a Razorpay secret key in Flutter code.
- Payment verification should be implemented on a trusted backend before
  accepting real production payments.

Cash on Delivery does not require Razorpay and stores:

```text
paymentMethod: cod
paymentStatus: pending
```

## Notifications

The Flutter app creates notification jobs in Firestore:

- `mail`: email jobs for the Firebase Trigger Email extension.
- `messages`: SMS jobs for a Twilio-compatible Firebase extension.
- FCM tokens are stored in the user's document for push notifications.

The optional Node.js notifier watches Firestore and sends:

- FCM notifications to admins for new orders and service requests.
- FCM notifications to customers/dealers when order status changes.
- SMTP email when an order is approved or rejected.

### Install the notifier

The notifier is in the sibling directory:

```powershell
cd C:\Users\gandh\Downloads\E-commerce\notifier
npm install
```

The notifier requires a Firebase Admin service-account key. Keep that key
outside Git and outside any public hosting environment.

Configure SMTP in the same PowerShell window where the notifier is started:

```powershell
$env:SMTP_HOST = "smtp.gmail.com"
$env:SMTP_PORT = "587"
$env:SMTP_USER = "your-college-email@example.edu"
$env:SMTP_PASS = "your-gmail-app-password"
$env:MAIL_FROM = "AquaShop <your-college-email@example.edu>"
node index.js
```

For a college Google Workspace account:

1. Enable two-step verification.
2. Create a Google App Password if your college administrator permits it.
3. Use the App Password, not the normal Gmail password.
4. If **App passwords** is unavailable, ask the college IT administrator
   whether SMTP access is allowed.

The notifier must stay running to detect order status changes. For production,
use a secured server or Firebase Cloud Functions rather than a personal
computer.

## Run the notifier safely

The notifier's service-account key must not be committed:

```text
serviceAccountKey.json
```

If this key was ever uploaded to GitHub, sent to someone, or exposed in a
public folder, revoke it in Google Cloud/Firebase and create a new key.

## Deploy the web application to Vercel

Flutter must build the web files before Vercel can host them:

```powershell
cd C:\Users\gandh\Downloads\E-commerce\aquashop
flutter build web --release --base-href /
vercel deploy build/web --prod
```

The included script performs both commands:

```powershell
.\deploy-vercel.ps1
```

For Vercel dashboard deployment:

- Root Directory: `build/web`
- Framework Preset: `Other`
- Build Command: empty
- Output Directory: `.`
- Install Command: empty

The generated `build/` directory is intentionally ignored by Git. Build it
again whenever the Flutter source changes.

## Run checks before pushing

Format Dart files:

```powershell
dart format lib
```

Analyze the Flutter code:

```powershell
flutter analyze
```

Build Android:

```powershell
flutter build apk --debug
```

Build web:

```powershell
flutter build web --release --base-href /
```

Check the notifier:

```powershell
cd ..\notifier
node --check index.js
npm install
```

## What must not be pushed to Git

Never commit:

- `serviceAccountKey.json`
- Firebase Admin private keys
- SMTP passwords or Gmail App Passwords
- `.env` and `.env.*` files containing real values
- Vercel tokens and `.vercel/`
- Private signing keys, keystores, and certificates
- Production API secrets
- Passwords, access tokens, and private credentials
- Local build output and generated caches

The following are normally safe to commit:

- Flutter source code
- `pubspec.yaml` and `pubspec.lock`
- `package.json` and `package-lock.json`
- Firestore rules
- Firebase client configuration files generated for the app

Client Firebase configuration is not a replacement for Firestore security
rules. Always deploy and review [`firestore.rules`](./firestore.rules).

## Git commands

From the AquaShop directory:

```powershell
git init
git add .
git status
git commit -m "Initial AquaShop application"
git branch -M main
git remote add origin https://github.com/<username>/<repository>.git
git push -u origin main
```

Before committing, inspect:

```powershell
git status --ignored
git diff --cached
```

If a secret was already staged, remove it from Git tracking before pushing:

```powershell
git rm --cached path\to\secret-file
```

Removing a file from the latest commit does not remove it from old Git
history. Revoke exposed credentials and rewrite history if necessary.
