// Watches Firestore and sends FCM pushes. Free: runs locally with a service-account key.
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
admin.initializeApp({ credential: admin.credential.cert(require('./serviceAccountKey.json')) });
const db = admin.firestore();

const smtpHost = process.env.SMTP_HOST;
const smtpPort = Number(process.env.SMTP_PORT || 587);
const smtpUser = process.env.SMTP_USER;
const smtpPass = process.env.SMTP_PASS;
const mailFrom = process.env.MAIL_FROM || smtpUser;
const mailer = smtpHost && smtpUser && smtpPass
  ? nodemailer.createTransport({
      host: smtpHost,
      port: smtpPort,
      secure: smtpPort === 465,
      auth: { user: smtpUser, pass: smtpPass },
    })
  : null;

async function sendTo(token, title, body) {
  try { await admin.messaging().send({ token, notification: { title, body } }); console.log('sent:', title); }
  catch (e) { console.log('send failed:', e.code || e.message); }
}
async function emailUser(userId, subject, text, fallbackTo) {
  const user = (await db.collection('users').doc(userId).get()).data() || {};
  const to = user.email || fallbackTo;
  if (!to) {
    console.log('no email for user', userId);
    return;
  }
  if (!mailer) {
    console.error('email not configured: set SMTP_HOST, SMTP_USER, SMTP_PASS');
    return;
  }
  try {
    await mailer.sendMail({ from: mailFrom, to, subject, text });
    console.log('email sent:', to, subject);
  } catch (e) {
    console.error('email failed:', to, e.code || e.message);
  }
}
async function push(userId, title, body) {
  const t = (await db.collection('users').doc(userId).get()).data()?.fcmToken;
  t ? await sendTo(t, title, body) : console.log('no token for', userId);
}
async function notifyAdmins(title, body) {
  const admins = await db.collection('users').where('role', '==', 'admin').get();
  for (const a of admins.docs) if (a.data().fcmToken) await sendTo(a.data().fcmToken, title, body);
}

function watch(col, onAdded, onModified) {
  const last = new Map(); let ready = false;
  db.collection(col).onSnapshot(snap => {
    snap.docChanges().forEach(c => {
      const d = c.doc.data();
      if (ready && c.type === 'added') onAdded(c.doc.id, d);
      if (ready && c.type === 'modified') onModified(c.doc.id, d, last.get(c.doc.id));
      last.set(c.doc.id, d);
    });
    ready = true; // first snapshot = existing data, ignore it
  }, e => console.error(col, e.message));
}

watch('orders',
  (id, d) => notifyAdmins('New order', `${d.userEmail} • ₹${Math.round(d.total)}`),
  (id, d, prev) => {
    if (prev && prev.status !== d.status) {
      const text = `Your order #${id.slice(0, 6)} was ${d.status}.`;
      push(d.userId, `Order ${d.status}`, text);
      if (d.status === 'approved' || d.status === 'rejected')
        emailUser(d.userId, `AquaShop order ${d.status}`, text, d.userEmail);
    }
  });

watch('serviceRequests',
  (id, d) => notifyAdmins('New service request', `${d.type} from ${d.userEmail}`),
  (id, d, prev) => {
    if (prev && (prev.status !== d.status || prev.adminNote !== d.adminNote))
      push(d.userId, `Service request ${d.status.replace('_', ' ')}`, d.adminNote || `${d.type} request updated.`);
  });

console.log('Notifier running. Leave this window open.');
