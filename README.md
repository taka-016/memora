# memora

**A Flutter application for recording and sharing events within groups such as families**

## Overview

Memora is a mobile application that allows groups such as families and friends to record and share past and future events in a timeline format.

### Key Features

- **Event Management**: Display and manage personal and group events in timeline format
- **Travel Records**: Manage travel information and routes on maps
- **Member Management**: Manage member information within groups
- **Authentication**: Secure account management with Firebase Authentication
- **Map Features**: Location management integrated with Google Maps

## Documentation

Please refer to the following for detailed design documentation:

- [Application Specification](./doc/app_spec.md) - Functional requirements and UI structure
- [ER Diagram](./doc/er_diagram.md) - Database design
- [Use Case Diagram](./doc/usecase_diagram.md) - System usage scenarios
- [TODO List](./doc/todo_list.md) - Development progress status

## Development Environment

### Google Cloud Platform API Configuration

Enable the following APIs in your Google Cloud Console and configure the corresponding API keys:
- **Maps SDK for Android** - Required for map functionality on Android devices. Set the API key in `android/local.properties` as `MAPS_API_KEY`
- **Places API** - Required for location search functionality. Set the API key in `.env` as `GOOGLE_PLACES_API_KEY`

### Firebase Configuration

This application uses Firebase/Firestore and requires the following APIs to be enabled:
- **Identity Toolkit API** - Required for Firebase Authentication
- **Token Service API** - Required for secure token management
- `firebase_options.dart` - Generated Firebase configuration
- `firebase.json` - Firebase project configuration

### Setup

1. Clone the project
2. Create environment variable file:
   ```bash
   cp .env.example .env
   # Edit .env file to set required environment variables
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Generate configuration from environment variables:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. Remove the .env file (contains sensitive information):
   ```bash
   rm .env
   ```

6. Configure Android local properties:
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

## License

This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0).  
See the [LICENSE](./LICENSE) file for details.
