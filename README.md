# Souqna Sneakers — Flutter

A modern sneaker store app connected to the Souqna platform API (store `emans`).
The whole app is in **English** (LTR).

## Visual identity
- **Ink** `#111014` — buttons and hero cards
- **Bone** `#F4F1EB` — background
- **Ember** `#FF5A1F` — accents: totals, badges, current status
- Font: **Readex Pro**

## Sneaker photography
`lib/core/sneaker_images.dart` — 28 product shots, 8 wide banner heroes and 4 lifestyle
shots from Unsplash (free commercial licence), each reviewed by hand — sneakers only.
- `forceDemoPhotos = false` (default) → the app shows the photos uploaded in the dashboard
  (all 7 products, 6 categories and 4 banners now carry pro sneaker photos). Curated photos are the fallback.
- Set it to `true` to always show the curated photos.

## Store content (dashboard)
- Categories: Luxury Sneakers · High-Tops · Running · Basketball · Leather Classics · Limited Editions
- Banners link to a product or category (`link_type` / `link_id`) and open it on "Shop now".
- The store type is "Clothing", so the dashboard only accepts clothing sizes; the app ignores
  those and shows EU shoe sizes 36–45.

## Banners (ads)
`lib/widgets/stacked_banners.dart` — three stacked cards; tap / swipe to deal the next one,
"Shop now" (or long-press) opens the linked product/category. Auto-advances every 5 s.
- **Every banner has a photo**: the dashboard image, or a distinct editorial hero per banner.
- The front banner photo has a slow "Ken Burns" zoom.
- Four default banners are shown if the dashboard has none.

## Motion
`lib/widgets/motion.dart`
- **Home app bar**: logo + greeting drop in on launch, the logo has a slowly spinning ember ring,
  and a compact frosted app bar slides in once you scroll down.
- **Inner app bars** (Checkout, My orders, Order details): title drops in with a growing ember
  underline; the back button slides in.
- Cart badges "pop" when the count changes; bottom-nav icons pop when selected.

## Run

```bash
cd souqna_app
flutter create . --org com.souqna --platforms android,ios   # generates platform folders only
flutter pub get
flutter run
```

> Android: make sure `android/app/src/main/AndroidManifest.xml` contains
> `<uses-permission android:name="android.permission.INTERNET"/>`

## Screens

| Screen | API |
|---|---|
| Splash + onboarding | `GET /stores/emans` |
| Home (stacked banners, categories, trending, picks, new arrivals) | `GET /home` |
| Categories | `GET /categories` |
| Product list + search + filter/sort + paging | `GET /products` |
| Product details (gallery, EU sizes + size guide, colors, reviews, related) | `GET /products/{id}`, `/reviews` |
| Bag + coupon | `/cart`, `/cart/items`, `/cart/coupon` |
| Checkout | `POST /checkout` |
| My orders + tracking + cancel | `/orders`, `/orders/{id}`, `/cancel` |
| Wishlist | `/favorites` |
| Sign in / sign up / profile / sign out | `/auth/*` |
| About the store & contact | `GET /stores/emans` |

## Structure
```
lib/
  core/      api_client.dart (requests + token) · theme.dart · sneaker_images.dart
  models/    models.dart (lenient field parsing)
  state/     app_state.dart (Provider: account, cart, favorites)
  widgets/   stacked_banners · product_card · motion · common
  screens/   all screens
```

## Customise
- Colors: `lib/core/theme.dart` → `AppColors`
- Photos: `lib/core/sneaker_images.dart`
- Store: `lib/core/api_client.dart` → `ApiConfig.storeSlug`
- Default currency `₪` (replaced automatically if the API sends one).
