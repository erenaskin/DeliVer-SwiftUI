# DeliVer-SwiftUI
  
  ### Multi-Service Delivery Platform
  
  [![Swift Version](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)
  [![iOS Version](https://img.shields.io/badge/iOS-18.5+-blue.svg)](https://www.apple.com/ios)
  [![SwiftUI](https://img.shields.io/badge/SwiftUI-Latest-green.svg)](https://developer.apple.com/xcode/swiftui/)
  
</div>

## 📱 About

DeliVer is a comprehensive multi-service delivery application built with SwiftUI. The app offers 6 different service categories including food delivery, grocery shopping, pet supplies, water delivery, pharmacy services, and tech support - all in one platform.

## ✨ Key Features

- 🍔 **Food Delivery**: Browse restaurants and order meals
- 🛒 **Grocery Shopping**: Order fresh produce and household items
- 🐾 **Pet Supplies**: Pet food and accessories delivery
- 💧 **Water Delivery**: Schedule water bottle deliveries
- 💊 **Pharmacy Services**: Order medications and health products
- 🔧 **Tech Support**: Device repair and technical services

## 🛠 Tech Stack

- **SwiftUI**: Modern declarative UI framework
- **MVVM Architecture**: Clean separation of concerns
- **Combine**: Reactive programming for data flow
- **Swift Concurrency**: Async/await for asynchronous operations
- **REST API**: Backend communication with JWT authentication
- **URLSession**: Native networking layer

## 🏗 Project Structure

```
DeliVer/
├── App/                    # Application entry point
├── Core/                   
│   ├── Components/        # Reusable UI components
│   └── Networking/        # API services & repositories
└── Features/              
    ├── Auth/              # Login, registration, verification
    ├── Home/              # Main dashboard
    ├── Services/          # Service-specific views
    ├── Cart/              # Shopping cart management
    └── Order/             # Order tracking & history
```

## 🚀 Getting Started

### Prerequisites

- macOS 13.0+
- Xcode 16.4+
- iOS 18.5+ device or simulator

### Installation

1. Clone the repository:
```bash
git clone https://github.com/erenaskin/DeliVer-SwiftUI.git
cd DeliVer-SwiftUI
```

2. Open the project:
```bash
open DeliVer.xcodeproj
```

3. Configure API endpoint in `APIService.swift`:
```swift
private let baseURL = URL(string: "http://YOUR_API_URL:8080/api")!
```

4. Build and run the project (⌘ + R)

## 🔑 Main Features

### Authentication
- Email & password registration
- Email verification with code
- Secure JWT token management
- Persistent login sessions

### Shopping Experience
- Browse products by categories
- Search and filter products
- Add products to cart with custom options
- Real-time price calculations

### Order Management
- Create and track orders
- View order history
- Real-time order status updates
- Order cancellation support

### User Interface
- Dark mode support
- Smooth animations
- Responsive design
- Clean and modern UI

## 📡 API Integration

The app communicates with a REST API backend:

- **Authentication**: `/api/auth/*`
- **Services**: `/api/services/*`
- **Products**: `/api/products/*`
- **Orders**: `/api/orders/*`
- **Cart**: `/api/cart/*`

