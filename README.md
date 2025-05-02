# 📱 Flutter Chat App


<<<<<<< main
An end-to-end real-time chat application built with Flutter. This app includes full authentication features like **Sign Up**, **Sign In**, and **Sign Out**, along with **real-time messaging**, **user status updates**, and a clean UI powered by Flutter.
=======
A new Flutter project.
##Documentation
for detail documentation and project overview, visit
**[Chewat Documentation on Deepwiki**]https://deepwiki.com/biniam0/Chewata
>>>>>>> master

An end-to-end real-time chat application built with Flutter. This app includes full authentication features like **Sign Up**, **Sign In**, and **Sign Out**, along with **real-time messaging**, **user status updates**, and a clean UI powered by Flutter.

---

## 🚀 Features

### 🔐 User Authentication (Email & Password)
- Sign Up  
- Sign In  
- Sign Out  

### 💬 Real-Time Chat
- Send & receive messages instantly  
- User presence/status updates (online/offline)

### 🧑‍🤝‍🧑 Contact List
- View all registered users  
- Start 1-on-1 chats  

### 📲 Responsive UI
- Smooth experience on both Android and iOS  

---

## 🛠️ Tech Stack

- **Frontend:** Flutter (Dart)  
- **Backend:** Firebase (Authentication, Firestore, Realtime Database or Cloud Functions)  
- **State Management:** Provider / Riverpod / Bloc *(choose based on your implementation)*  
- **Push Notifications:** Firebase Cloud Messaging *(optional)*  

---

## 📦 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/your-username/flutter-chat-app.git
cd flutter-chat-app
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Set up Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Add Android/iOS app to the project
4. Download `google-services.json` *(for Android)* or `GoogleService-Info.plist` *(for iOS)* and place them in the appropriate directories
5. Enable **Email/Password** authentication
6. Set up **Cloud Firestore** for real-time messaging

### 4. Run the app

```bash
flutter run
```

---

## 📸 Screenshots

| Sign In | Chat Screen | Contact List |
|--------|-------------|--------------|
| ![Sign In](screenshots/signin.png) | ![Chat](screenshots/chat.png) | ![Contacts](screenshots/contacts.png) |

---

## ✅ TODOs

- [ ] Group chats  
- [ ] Push notifications  
- [ ] Message read receipts  
- [ ] User profile customization  

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
