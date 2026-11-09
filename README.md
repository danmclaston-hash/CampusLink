# CampusLink

One place for every Cavendish University student to find help, stay informed and connect.

Built with **Flutter – one code base** for Android, iOS, Web (installable PWA), Windows, macOS and Linux.

**Live web app:** https://danmclaston-hash.github.io/CampusLink/

## Features

| # | Feature | Where in the app |
|---|---------|------------------|
| 1 | Announcements (faculty, finance, events, urgent) | Home → Announcements |
| 2 | Help directory – every office, what it does, where it is, when it opens | Where? → Directory |
| 3 | Help requests with tracked status (open → in progress → resolved) | Requests |
| 4 | Tutor and study‑group matching | Home → Study |
| 5 | Campus Pulse – quick anonymous polls | Home → Pulse |
| 6 | First‑year Buddy – pair new students with mentors | Home → Buddy |
| 7 | Smart "Where do I go?" search across offices, events, clubs, groups | Where? |
| 8 | Engagement – anonymous feedback, events, clubs, campus map, offline | Home → Engage |
| + | Timetable import from Excel / CSV / Word / PDF text, matched to your course | Timetable |

## How it works

```
Flutter app (Android, iOS, Web/PWA, Windows, macOS, Linux)
        │
        ├── Demo mode  → data saved on the device (no account needed)
        └── Live mode  → Supabase (Postgres + Auth + Row Level Security)
```

Every platform talks to the **same Supabase database**, so a request opened on the web shows up on the phone.

Without Supabase keys the app runs in **demo mode** with seeded Cavendish data, so it always opens.

## Run it

```bash
flutter pub get
flutter run                      # demo mode
flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxx   # live mode
```

Build for any target: `flutter build apk`, `flutter build web`, `flutter build windows`, etc.

## Set up the database (once)

1. Create a Supabase project.
2. In the SQL editor run `supabase/migrations/0001_campuslink_schema.sql`, then `supabase/seed.sql`.
3. Copy the project URL and publishable (anon) key.
4. In GitHub → Settings → Secrets and variables → Actions, add `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

To make someone staff (can post announcements, answer requests), set `role = 'staff'` on their row in `profiles`.

## Deploy

Every push to `main` runs `.github/workflows/deploy-pages.yml`, which builds the web app and publishes it to GitHub Pages. Nothing to do by hand.

## Project layout

```
lib/
  core/        config, theme
  data/        models, repository interface, local + Supabase implementations, smart search
  features/    one folder per screen
  widgets/     shared UI
supabase/      schema migration + seed data
web/           PWA shell (manifest, icons, splash)
```

## Licence

MIT
