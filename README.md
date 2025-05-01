📱 Flutter Chat App
An end-to-end real-time chat application built with Flutter. This app includes full authentication features like Sign Up, Sign In, and Sign Out, along with real-time messaging, user status updates, and a clean UI powered by Flutter.

🚀 Features
🔐 User Authentication (Email & Password)

Sign Up

Sign In

Sign Out

💬 Real-Time Chat

Send & receive messages instantly

User presence/status updates (online/offline)

🧑‍🤝‍🧑 Contact List

View all registered users

Start 1-on-1 chats

📲 Responsive UI

Smooth experience on both Android and iOS

🛠️ Tech Stack
Frontend: Flutter (Dart)

Backend: Firebase (Authentication, Firestore, Realtime Database or Cloud Functions)

State Management: Provider / Riverpod / Bloc (choose based on your implementation)

Push Notifications: Firebase Cloud Messaging (optional)

📦 Getting Started
1. Clone the repository

git clone https://github.com/your-username/flutter-chat-app.git
cd flutter-chat-app
2. Install dependencies

flutter pub get
3. Set up Firebase
Go to Firebase Console

Create a new project.

Add Android/iOS app to the project.

Download google-services.json (for Android) or GoogleService-Info.plist (for iOS) and place them in respective directories.

Enable Email/Password authentication.

Set up Cloud Firestore for real-time messaging.

4. Run the app

flutter run
📸 Screenshots
Sign In	Chat Screen	Contact List

📁 Project Structure
arduino
lib/
├── main.dart
├── models/
├── screens/
│   ├── auth/
│   ├── chat/
│   └── home/
├── services/
├── widgets/
└── utils/
✅ TODOs
 Group chats

 Push notifications

 Message read receipts

 User profile customization

📄 License
This project is licensed under the MIT License.