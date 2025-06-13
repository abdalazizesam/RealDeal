# 🎬 ReelDeal

> *Your personalized guide to movies and TV shows, tailored to your tastes and mood!*

![ReelDeal Banner](assets/reeldeal%20banner.png)

## ✨ What is ReelDeal?

ReelDeal is a modern Flutter application designed to simplify your entertainment choices. Gone are the days of endless scrolling! This app helps you discover your next favorite movie or TV show by combining your mood, genre preferences, and even learns from your viewing history to provide truly personalized recommendations. It's not just a discovery tool; it's a comprehensive library manager for all your cinematic and episodic adventures.

## 📱 App Showcase

<div align="center">
  <img src="assets/screenshots/reeldealscreenshots%20(1).png" width="25%"/>
  <img src="assets/screenshots/reeldealscreenshots%20(2).png" width="25%"/> 
  <img src="assets/screenshots/reeldealscreenshots%20(3).png" width="25%"/>
  <img src="assets/screenshots/reeldealscreenshots%20(4).png" width="25%"/>
  <img src="assets/screenshots/reeldealscreenshots%20(5).png" width="25%"/>
  <img src="assets/screenshots/reeldealscreenshots%20(6).png" width="25%"/>
  <img src="assets/screenshots/reeldealscreenshots%20(8).png" width="25%"/>
  <img src="assets/screenshots/reeldealscreenshots%20(9).png"  width="25%"/>
  <img src="assets/screenshots/reeldealscreenshots%20(10).png" width="25%" />
</div>
*Note: The images above are for illustrative purposes. Your app's appearance may vary based on your selected theme and content.*

## 🚀 Key Features

* **Personalized Discovery Engine:**
   * **Mood Matcher:** Find content that perfectly aligns with your current mood (Happy, Thrilled, Chill, Sad).
   * **Genre Filtering:** Refine your search with specific movie or TV show genres.
   * **"Because You Liked..." Recommendations:** Get suggestions based on the movies and TV shows you've highly rated in your library.
   * **Random Picks:** Can't decide? Let ReelDeal pick a random movie or TV show for you!

* **Comprehensive Library Management:**
   * **Status Tracking:** Organize your media with statuses like "Watching," "Want to Watch," "Completed," "On Hold," and "Dropped".
   * **Progress & Ratings:** Keep track of your progress on TV shows (episode by episode) or movies, and rate completed items. Add personal notes to your entries.
   * **Import/Export Library:** Easily back up and restore your entire library data.

* **In-Depth Media Information:**
   * Access rich details including overviews, release years, TMDB ratings, and durations.
   * **Watch Trailers:** Directly watch trailers for movies and TV shows (YouTube integration).
   * **Cast & Crew:** Explore detailed cast lists, character names, and key crew members (director, writers, creators).
   * **Actor Profiles:** Dive into actor biographies, filmographies, and "known for" roles with sorting options.
   * **Where to Watch:** Find out where content is available to stream, rent, or buy.

* **Stunning UI & Customization:**
   * Beautiful, modern Material 3 design crafted with Flutter.
   * **Dynamic Theming:** Choose from multiple vibrant color palettes.
   * **Light/Dark/System Themes:** Seamlessly switch between themes or follow your system settings.
   * **OLED Black Mode:** Optimized dark theme for OLED screens for deeper blacks and battery saving.
   * **Haptic Feedback:** Enjoy subtle tactile feedback for a more engaging user experience.

* **Seamless Experience:**
   * **Offline Handling:** Gracefully handles no internet connection, allowing access to cached data.
   * **Cached Images:** Fast and smooth image loading for posters and backdrops.

## 💻 Tech Stack

* **Flutter & Dart:** For building a beautiful, natively compiled cross-platform application.
* **TMDB API:** The Movie Database API for comprehensive movie and TV show data.
* **Provider:** A robust solution for state management within the app.
* **Shared Preferences:** Lightweight data storage for user preferences and library data.
* **CachedNetworkImage:** Efficiently loads and caches images from the network.
* **Connectivity Plus:** Checks and monitors network connectivity.
* **Shimmer:** Provides elegant shimmering loading effects for content.
* **URL Launcher:** For opening external links like watch provider websites and trailers.
* **Package Info Plus:** Retrieves application package information (e.g., version).
* **File Picker:** Allows users to pick files from their device for import/export.
* **Path Provider:** Provides access to file system locations.
* **Permission Handler:** Manages runtime permissions (e.g., storage access for import/export).
* **Flutter Animate:** Provides declarative animations for UI elements.
* **Intl:** Internationalization and localization utilities, particularly for date/number formatting.
* **Device Info Plus:** Provides device-specific information (e.g., Android SDK version for permissions).
* **http:** A simple, future-based HTTP client for making API requests.

## 📲 Download

<div align="center">
  <a href="https://github.com/abdalazizesam/RealDeal/releases/download/v2.0.0/ReelDealv2.0.0.apk">
    <img src="https://i.ibb.co/zVQDK09g/apk.png" alt="Download APK" />
  </a>
</div>

## 🏁 Quick Start

To get ReelDeal up and running on your local machine:

1.  **Clone the Repository:**
    ```bash
    git clone [https://github.com/abdalazizesam/RealDeal.git](https://github.com/abdalazizesam/RealDeal.git)
    cd ReelDeal
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Add Your TMDB API Key:**
   * Register for a free API key at [TMDB Developer](https://www.themoviedb.org/documentation/api).
   * Open `lib/services/tmdb_service.dart`.
   * Replace `'c77efa315e4a87ebcd95b283b83e7aad'` with your actual API key:
       ```dart
       final String apiKey = 'YOUR_API_KEY'; // Replace with your TMDB API Key
       ```

4.  **Run the App:**
    ```bash
    flutter run
    ```
    *(Ensure you have a device or emulator connected.)*

## 💖 Love ReelDeal?

If you enjoy using ReelDeal or find it helpful, please consider:
* Giving a ⭐ star to the repository!
* Sharing it with your friends and fellow movie/TV enthusiasts.
* Contributing to the project! All pull requests and suggestions are welcome.

---

<div align="center">
  <p>Created with Flutter, powered by TMDB, inspired by making entertainment easy</p>
  <p>© 2025 ReelDeal</p>
</div>