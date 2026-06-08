# Business Dashboard — Flutter App

A clean 2-screen business overview dashboard built with Flutter for the **Techwise Solutions** developer assessment.

## Screens

| Screen | Description |
|--------|-------------|
| **Dashboard** | Welcome header, 4 KPI summary cards, weekly sales bar chart (fl_chart), recent activity feed |
| **Transactions** | Filterable transaction list with status badges, credit/debit indicators, and summary strip |

## Tech Stack

- **Flutter 3.44.1** (stable)
- **fl_chart ^0.68.0** — weekly sales bar chart
- **intl ^0.19.0** — number/date formatting
- **Material 3** design system

## Project Structure

```
lib/
├── main.dart                  # App entry point + BottomNavigationBar shell
├── models/
│   ├── summary_card_model.dart
│   ├── activity_model.dart
│   └── transaction_model.dart
├── data/
│   └── mock_data.dart         # All static mock data
├── screens/
│   ├── dashboard_screen.dart  # Screen 1: Main Dashboard
│   └── transactions_screen.dart # Screen 2: Transactions
└── widgets/
    ├── summary_card.dart      # KPI card widget
    ├── sales_chart.dart       # Bar chart widget
    ├── activity_tile.dart     # Activity feed row
    └── transaction_tile.dart  # Transaction list item
```

## Running Locally

```bash
# Install dependencies
flutter pub get

# Run on connected Android device
flutter run

# Run on Chrome (web preview)
flutter run -d chrome

# Build release APK
flutter build apk --release
# APK → build/app/outputs/flutter-apk/app-release.apk
```

## Build with Docker

```bash
# Build the Docker image (builds the APK inside)
docker build -t business-dashboard-apk .

# Extract the APK to ./output/
mkdir output
docker run --rm -v "%cd%/output":/output business-dashboard-apk
```

The APK will be at `output/app-release.apk` — install on any Android device.

## Installing on Android Device

1. Copy `app-release.apk` to your device
2. Enable **Install from unknown sources** in device settings
3. Open the APK file to install

---

*Built for Techwise Solutions Junior Mobile/Frontend Developer Assessment — June 2026*
