# COMAT: AI-Visual Powered Comrade Marketplace 🎓🚀

[](https://flutter.dev)
[](https://firebase.google.com)
[](https://ai.google.dev/)
[](https://opensource.org/licenses/MIT)

> **"Stop scrolling, start selling."** \> COMAT is a specialized C2C marketplace designed to solve the inefficiencies of informal university trade. By integrating **Gemini Pro Vision AI**, COMAT eliminates the "Brain Fatigue" and "Manual Entry Friction" found in traditional campus WhatsApp/Telegram groups.

-----

## 🧠 The Engineering Challenge

Current campus resale relies on disorganized chat histories, leading to **Information Overload** and **Decision Fatigue** (Cognitive Load Theory). COMAT acts as a centralized "Guaranteed Buyer" pool—providing an AI-searchable marketplace that ensures sellers get fair value and buyers find essentials without the mental exhaustion of combing through messages.

## ✨ Key Features

  * **🤖 AI-Driven Listing (Gemini Pro Vision):** Simply snap a photo. The AI identifies the item, suggests a category, and generates a draft price in Ksh, reducing listing time by **\~70%**.
  * **💬 Seamless WhatsApp Bridge:** One-tap negotiation. Connects buyers and sellers directly through their preferred communication channel without losing context.
  * **📍 Secure Campus Logistics:** Integrated location-aware features for standardized, safe meetup points within the university geography.
  * **🛡️ Academic Trust:** Secure Google Authentication restricted to university-affiliated accounts to ensure a vetted community.

-----

## 🛠️ Tech Stack

  * **Frontend:** Flutter (Dart) - Cross-platform performance.
  * **Backend:** Firebase (Firestore NoSQL, Cloud Storage).
  * **AI Engine:** Google Generative AI (Gemini 1.5 Flash).
  * **State Management:** Provider/Clean Architecture.

-----

## ⚙️ Installation & Setup

To protect project integrity, sensitive configurations (`.env` and `google-services.json`) have been scrubbed. Follow these steps to deploy your own instance:

### 1\. Clone & Clean

```bash
git clone git@github.com:fskamau/comat.git
cd comat
flutter pub get
```

### 2\. Environment Variables

Rename the `.env.example` file to `.env` and insert your API key:

```text
GEMINI_API_KEY=your_key_here
```

### 3\. Firebase Connection

  * Create a project on the [Firebase Console](https://console.firebase.google.com/).
  * Add an Android/iOS app.
  * Download `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) and place them in the correct directories:
      * `android/app/google-services.json`
      * `ios/Runner/GoogleService-Info.plist`

### 4\. Firestore Rules

Ensure your Firestore rules allow authenticated read/writes for the `products` and `users` collections.

-----

## 📂 Project Structure

```text
lib/
├── core/          # Theme, Constants, & Shared Utils
├── data/          # Models, API Services (Gemini/Firebase)
├── presentation/  # UI Components (Auth, Listings, Profile)
└── main.dart      # App Entry & .env Initialization
```

## 🤝 Contributing

Found a bug or want to add a feature (like AI-based price trending)? Open a PR\!

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](https://www.google.com/search?q=LICENSE) file for details.
