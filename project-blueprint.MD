1) Backend: CodeIgniter 4 (API + Panel Admin)
Pakiety i podejście

Auth: polecam CodeIgniter Shield (oficjalny) + JWT (access/refresh)

DB: MySQL/MariaDB lub PostgreSQL (CI4 wspiera oba)

API: /api/... (JSON)

Admin: klasyczny panel w CI4 (Blade/Views) albo “admin” w React (wolisz jedno UI).

Struktura (proponowana)

```
app/
  Controllers/
    Api/AuthController.php
    Api/EventsController.php
    Api/TypesController.php
    Admin/DashboardController.php
    Admin/UsersController.php
    Admin/EventsController.php
    Admin/TypesController.php
  Models/
    EventModel.php
    EventTypeModel.php
  Entities/
    EventEntity.php
  Filters/
    JwtAuthFilter.php
  Database/Migrations/
    2026-..._CreateEventTypes.php
    2026-..._CreateEvents.php
public/
writable/
```

2) Baza danych (migracje)
event_types

id (PK)

user_id (nullable jeśli typ globalny admina)

name

color_hex (np. #FF3B30)

created_at, updated_at

events

id (PK)

user_id

type_id

title

notes (nullable)

start_at (datetime UTC)

end_at (datetime UTC)

all_day (tinyint/bool)

created_at, updated_at

Dzięki type_id łatwo kolorujesz eventy w web i iOS.

3) API endpointy (gotowy kontrakt)
Auth

POST /api/auth/login → {accessToken, refreshToken, user}

POST /api/auth/refresh → {accessToken}

POST /api/auth/logout

Typy wydarzeń

GET /api/types

POST /api/types

PUT /api/types/{id}

DELETE /api/types/{id}

Wydarzenia

GET /api/events?from=2026-02-01&to=2026-02-28

POST /api/events

PUT /api/events/{id}

DELETE /api/events/{id}

Format eventu (JSON)

```
{
  "id": 123,
  "title": "Dentysta",
  "notes": "Karta + RTG",
  "typeId": 5,
  "startAt": "2026-02-17T10:00:00Z",
  "endAt": "2026-02-17T11:00:00Z",
  "allDay": false,
  "type": { "id": 5, "name": "Zdrowie", "colorHex": "#34C759" }
}
```

4) Panel administracyjny (CI4)

W adminie robimy:

Użytkownicy: lista + blokada/rola (admin/user)

Typy: CRUD + color picker (hex)

Wydarzenia: podgląd, filtrowanie (data/użytkownik/typ), edycja

Dostęp:

/admin tylko dla roli admin (Shield/Filter)

5) Web (React): kalendarz miesiąc/tydzień/dzień

Najlepszy zestaw:

FullCalendar (dayGridMonth, timeGridWeek, timeGridDay)

Kolory po type.colorHex

Siatka i scroll w timeGrid “z pudełka”

Modal do dodawania/edycji

W web robimy też “/admin” jako React albo zostawiamy admina w CI4 (ja bym zostawił admina w CI4, a web jako planer dla usera — mniej roboty i szybciej dowieziesz).

6) iOS 16+ (SwiftUI + UICalendarView)
Widoki

Month: UICalendarView (wrapper do SwiftUI)

Day/Week: time-grid w SwiftUI (ScrollView + linie siatki)

Formularz eventu: title, typ (kolor), start/end, allDay, notes

Notyfikacje 15 min przed (lokalne)

Przy zapisie/edycji: planujesz lokalne powiadomienie

Przy usunięciu: kasujesz request po eventId

Najważniejsza zasada:

identifier notyfikacji = "event-\(eventId)"
wtedy update to: cancel + schedule (bez duplikatów)



