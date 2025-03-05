const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotification = functions.https.onRequest(async (req, res) => {
  const { name, phone, date, service, doctor, time } = req.body;

  const message = {
    notification: {
      title: 'Appointment Booked',
      body: `Hello ${name}, your appointment for ${service} with ${doctor} on ${date} at ${time} has been booked successfully.`,
    },
    token: phone, // Use FCM token here
  };

  try {
    await admin.messaging().send(message);
    res.status(200).send('Notification sent successfully');
  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).send('Error sending notification');
  }
});
