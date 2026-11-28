# Zaatra — Project Architecture & Technical Overview

**Zaatra** is a multi-role transportation, stay, and event-hall booking platform consisting of a cross-platform mobile/web frontend (**Flutter / Dart**) and a REST + real-time WebSocket backend (**Node.js / Express / MongoDB**).

---

## 1. Platform Roles & Modules

The application serves **three primary user roles** from a single codebase:

1. **Customer (`customer/`)**
   - **Ride**: Intercity & local ride search, driver/vehicle selection, live ride tracking, trip booking confirmation, chat, and ride rating.
   - **Stay**: Hotel/villa/apartment search, property detail view, room selection, guest details, 50% advance payment summary, booking confirmation, request changes, and stay rating.
   - **Event Halls (`customer-event/`)**: Banquet/convention hall search, results filtering, venue detail with slots & catering plate pricing, multi-hall selector, organizer details, booking summary, confirmation, and voucher details.
   - **Common**: Unified 4-tab Wishlist (`All`, `Stays`, `Event halls`, `Rider`), City Guides, Booking History, Notifications, Profile, and Support.
2. **Driver (`driver/`)**
   - Driver dashboard, online/offline toggle, publishing/managing rides, viewing ride requests, pre-trip & ride-start navigation flow, OTP verification, earnings, and notifications.
3. **Host (`host_updated/`)**
   - Host dashboard, multi-step property & event venue onboarding wizard (Stays & Event Halls), availability calendar & slot timings, date blocking, venue rate overrides, offline bookings, payment collection, OTP check-in, customer reviews, and host-guest messaging.

---

## 2. Frontend Stack (`zaatra_app`)

- **Framework**: Flutter (Material Design)
- **Language**: Dart (`sdk: >=3.0.0 <4.0.0`)
- **Configuration**: `flutter_dotenv` (`.env`) wrapped by `lib/core/config/app_env.dart` for safe defaults and web/mobile URL normalization.
- **Key Packages (`pubspec.yaml`)**:
  - **Networking**: `http` (`^1.2.0`) via centralized `ApiService` (`lib/services/api_service.dart`) and domain services (`AuthService`, `RideService`, `DriverService`, `HostApiService`, `BookingService`, `HeritageService`, etc.).
  - **State & Storage**: `provider` (`^6.1.1`) and `shared_preferences` (`^2.2.2`) for JWT token persistence and 30-day role/session state.
  - **Location & Maps**: `geolocator` (`^14.0.2`) and `GoogleMapsService` (Google Maps Places & Directions APIs).
  - **Payments**: `razorpay_flutter` (`^1.3.7`) + web payment service (`razorpay_web_service.dart`).
  - **Media & Utilities**: `google_fonts`, `image_picker`, `file_picker`, `url_launcher`, `webview_flutter`.

---

## 3. Backend Stack (`zaatra-backend`)

- **Runtime & Language**: **Node.js** using **JavaScript** (CommonJS modules, entry point `src/server.js` / `src/app.js`).
- **Web Framework**: **Express.js** (`^4.19.2`).
- **Real-Time Communication**: **Socket.IO** (`^4.7.5`, configured in `src/sockets/socket.js`) for live updates (ride tracking, booking/status events, notifications).
- **Authentication & Security**:
  - **JWT** (`jsonwebtoken ^9.0.2`) for stateless Bearer token authentication (`auth.middleware.js`).
  - **Role-Based Access Control** (`role.middleware.js`) separating Customer, Driver, Host, and Admin permissions.
  - **Password Hashing**: `bcryptjs` (`^2.4.3`).
  - **Validation**: `joi` (`^17.13.3`) for request payload validation.
- **File Uploads & Scheduling**:
  - `multer` (`^1.4.5-lts.1`) for property/profile/document image uploads (`upload.middleware.js`).
  - `node-cron` (`^3.0.3`) for scheduled background reminder jobs (`src/jobs/reminder.job.js`).
  - `cors` and `morgan` for cross-origin access and HTTP request logging.

---

## 4. Database Architecture

- **Database**: **MongoDB** (configured via `MONGODB_URL` / `zaatra_db` in `src/config/db.js`).
- **ODM (Object Data Modeling)**: **Mongoose** (`^8.5.1`).
- **Core Collections / Models (`src/models/`)**:
  - `User.model.js` — Accounts, credentials, roles (customer/driver/host/admin), and profile metadata.
  - `Property.model.js` — Stays, hotels, villas, and event/banquet halls, amenities, rates, and photos.
  - `Ride.model.js` — Driver-published rides, routes, seats, timings, and ride status.
  - `Booking.model.js` — Stay, event hall, and ride bookings, 50% advance / balance tracking, and OTPs.
  - `Transaction.model.js` — Payment records and Razorpay transaction logs.
  - `Review.model.js` — Ratings and reviews for stays, rides, and customers.
  - `Coupon.model.js` — Promo codes and discount rules.
  - `Notification.model.js` — In-app alerts for bookings, rides, and host updates.
  - `SupportTicket.model.js` — Help & customer/host support tickets.

---

## 5. APIs Used

### A. Internal Backend REST APIs (`/api/...`)
All backend routes are mounted in `src/routes/` and consumed by `ApiService` over HTTP+JSON:
- `/api/auth` (`auth.routes.js`) — OTP login, registration, role selection, session validation.
- `/api/users` (`user.routes.js`) — User profile updates, saved preferences.
- `/api/rides` (`ride.routes.js`) — Ride search, seat booking, ride lifecycle.
- `/api/driver` (`driver.routes.js`) — Driver dashboard, ride publishing, ride start/complete, earnings.
- `/api/host` (`host.routes.js`) — Host dashboard, property wizard steps, availability calendar, block/unblock dates, rate overrides, offline bookings, conversations.
- `/api/properties` (`property.routes.js`) — Property listings, metadata, photo uploads.
- `/api/bookings` (`booking.routes.js`) — Booking creation, history, details, cancellation, OTP verification.
- `/api/payments` (`payment.routes.js`) — Payment initiation, verification, and transaction history.
- `/api/promotions` (`promotion.routes.js`) — Coupon validation and promo offers.
- `/api/reviews` (`review.routes.js`) — Submitting and fetching ratings.
- `/api/notifications` (`notification.routes.js`) — Unread counts and notification feeds.
- `/api/support` (`support.routes.js`) — Support ticket submission.
- `/api/admin` (`admin.routes.js`) — Administrative oversight routes.

### B. External / Third-Party APIs
- **Google Maps Platform**: Places Autocomplete, Geocoding, and Directions API (`GoogleMapsService` using `GOOGLE_MAPS_API_KEY`).
- **Razorpay Payment Gateway**: Native (`razorpay_flutter`) and Web (`razorpay_web_service.dart`) checkout integration (`RAZORPAY_KEY_ID`).
