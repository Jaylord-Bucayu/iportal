importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: "AIzaSyDdGS3fMbLnElKYGi3rO_2zeH_vlAPCuyQ",
    authDomain: "manifest-emblem-451812-h1.firebaseapp.com",
    projectId: "manifest-emblem-451812-h1",
    storageBucket: "manifest-emblem-451812-h1.firebasestorage.app",
    messagingSenderId: "910193430774",
    appId: "1:910193430774:web:69eb4a15e3970632861cd7",
    measurementId: "G-507PVY7XEW"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log("Background message received:", payload);

  const notificationTitle = payload.notification?.title || "New Notification";
  const notificationOptions = {
    body: payload.notification?.body || "",
    icon: "/icons/Icon-192.png",
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});