importScripts(
  "https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js",
);
importScripts(
  "https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js",
);

firebase.initializeApp({
  apiKey: "AIzaSyA5OTjLIzW59glxE_q7bLiWG06OGRfWJq4",
  authDomain: "concious-living-app.firebaseapp.com",
  projectId: "concious-living-app",
  storageBucket: "concious-living-app.appspot.com",
  messagingSenderId: "50634132035",
  appId: "1:50634132035:web:90641a1d66c116a2b4a2f6",
});

const messaging = firebase.messaging();
messaging.onBackgroundMessage((payload) => {
  self.registration.showNotification(
    payload.notification?.title ?? "ORKA",
    {
      body: payload.notification?.body,
      icon: "/icons/Icon-192.png",
    },
  );
});
