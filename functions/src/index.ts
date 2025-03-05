/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import * as functions from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import * as nodemailer from 'nodemailer';

admin.initializeApp();

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASSWORD,
  },
});

export const sendAppointmentEmail = functions.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { to, subject, appointmentDetails } = request.data;

  const mailOptions = {
    from: '"Health Connect" <wanyonyip148@gmail.com>',
    to: to,
    subject: subject,
    html: `
      <h2>Appointment Confirmation</h2>
      <p>Dear ${appointmentDetails.patientName},</p>
      <p>Your appointment has been successfully scheduled:</p>
      <ul>
        <li><strong>Date:</strong> ${appointmentDetails.date}</li>
        <li><strong>Time:</strong> ${appointmentDetails.time}</li>
        <li><strong>Session:</strong> ${appointmentDetails.session}</li>
        <li><strong>Doctor:</strong> ${appointmentDetails.doctor}</li>
        <li><strong>Service:</strong> ${appointmentDetails.service}</li>
        <li><strong>Location:</strong> Health Connect Clinic</li>
      </ul>
      <p>If you need to reschedule or cancel your appointment, please contact us.</p>
      <p>Thank you for choosing Health Connect!</p>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    return { success: true };
  } catch (error) {
    console.error('Error sending email:', error);
    throw new functions.HttpsError('internal', 'Error sending email');
  }
});
