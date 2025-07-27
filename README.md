# memora

A Flutter application for recording and sharing events within groups such as families

## Overview

Memora is a Flutter mobile application designed for groups such as families and friends to record, organize, and share memories through an interactive timeline interface. The application provides a comprehensive platform for managing personal and group events, travel experiences, and life milestones in chronological order.

### Key Features

- **Timeline Visualization**: Interactive timeline displaying events, travels, and life events across past, present, and future years with adjustable row heights and year-based column organization
- **Group & Member Management**: Create and manage multiple groups with flexible member assignment, allowing members to belong to multiple groups simultaneously
- **Event Management**: Create, edit, and delete personal and group events with validation for required fields (name, date) and chronological organization
- **Travel Management**: Comprehensive travel planning with start/end date validation, location pinning, visit scheduling, and itinerary ordering through drag-and-drop interface
- **Interactive Maps**: Google Maps integration with location search, manual pin placement, travel route visualization, and historical visit tracking for frequently visited places
- **Life Event Automation**: Automatic calculation and display of future life events (Shichi-Go-San ceremony, school milestones, coming of age) based on member birthdays

## Documentation

Please refer to the following for detailed design documentation:

- [Application Specification](./doc/app_spec.md) - Functional requirements and UI structure
- [User Stories](./doc/user_stories.md) - User scenarios and acceptance criteria
- [ER Diagram](./doc/er_diagram.md) - Database design
- [Use Case Diagram](./doc/usecase_diagram.md) - System usage scenarios
- [TODO List](./doc/todo.md) - Development progress status

## Development Environment

### Google Cloud Platform API Configuration

Enable the following APIs in your Google Cloud Console and configure the corresponding API keys:

- **Maps SDK for Android** - Required for map functionality on Android devices. Set the API key in `android/local.properties` as `MAPS_API_KEY`
- **Places API** - Required for location search functionality. Set the API key in `.env` as `GOOGLE_PLACES_API_KEY`

#### Environment Setup Instructions

1. Create environment variable file:

   ```bash
   cp .env.example .env
   # Edit .env file to set required environment variables
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Generate configuration from environment variables:

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Remove the .env file (contains sensitive information):

   ```bash
   rm .env
   ```

5. Configure Android local properties:

   ```bash
   # Create android/local.properties with the following content:
   sdk.dir=/path/to/your/android/sdk
   flutter.sdk=/path/to/your/flutter/sdk
   flutter.buildMode=debug
   flutter.versionName=1.0.0
   flutter.versionCode=1
   
   # Google Maps API key
   MAPS_API_KEY=your_maps_api_key_here
   ```

### Firebase Configuration

This application uses Firebase/Firestore for data persistence and Firebase Authentication for user management. The following APIs must be enabled in your Firebase Console:

- **Identity Toolkit API** - Required for Firebase Authentication
- **Token Service API** - Required for secure token management

#### Required Configuration Files

- `firebase_options.dart` - Generated Firebase configuration file
- `firebase.json` - Firebase project configuration file

#### Firebase Setup Instructions

1. Create Firebase Project:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or select existing project
   - Enable Authentication and Firestore Database

2. Configure Flutter App:

   ```bash
   # Install Firebase CLI (if not already installed)
   npm install -g firebase-tools
   
   # Login to Firebase
   firebase login
   
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase for your Flutter app
   flutterfire configure
   ```

3. Enable Required Services:
   - In Firebase Console, enable Authentication (Google and Email/Password providers)
   - Enable Firestore Database in production mode
   - Configure Firestore security rules as needed

4. Verify Configuration:
   - Ensure `firebase_options.dart` is generated in `/lib/`
   - Ensure `firebase.json` exists in project root

## License

This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0).  
See the [LICENSE](./LICENSE) file for details.
