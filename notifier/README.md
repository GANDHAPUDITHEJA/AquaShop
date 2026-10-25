# AquaShop notifier

This process watches Firestore and sends:

- FCM notifications to administrators for new orders/service requests.
- FCM notifications to the customer or dealer when an order is approved/rejected.
- Email to the customer or dealer when an order is approved/rejected.

Keep `serviceAccountKey.json` and SMTP credentials outside source control.

## Configure email

PowerShell example:

```powershell
$env:SMTP_HOST = "smtp.gmail.com"
$env:SMTP_PORT = "587"
$env:SMTP_USER = "your-sender@gmail.com"
$env:SMTP_PASS = "your-app-password"
$env:MAIL_FROM = "AquaShop <your-sender@gmail.com>"
node index.js
```

For Gmail, use an App Password, not the normal account password. The notifier
must remain running to receive Firestore order status changes.
