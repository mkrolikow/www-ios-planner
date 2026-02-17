# www-ios-planner

1) Architektura (1 backend, 2 klienty)

Backend (API + Admin)

REST API: logowanie, wydarzenia, typy wydarzeń (kolory), użytkownicy/role

Baza: PostgreSQL (lub SQLite na start)

Auth: JWT (access + refresh)

Web

React + FullCalendar (widoki: month/week/day, siatka, scroll, drag&drop)

Panel admina: ta sama aplikacja React (np. /admin) lub osobny UI

iOS

SwiftUI (widoki listy + kalendarz)

Synchronizacja z API

Lokalne cache: SQLite (GRDB) albo CoreData

Powiadomienia: UNUserNotificationCenter (lokalne) 15 min przed startem wydarzenia

Dlaczego lokalne powiadomienia? Są najpewniejsze i nie wymagają serwera push. Jeśli chcesz “gwarantowane” na wielu urządzeniach i przy zmianach na serwerze, wtedy dorzucamy push (APNs) jako etap 2.

2) Model danych (prosty, praktyczny)

EventType

id

name (np. “Praca”, “Dom”, “Trening”)

colorHex (np. #FF3B30)

userId (albo globalne typy w adminie)

Event

id

title

notes (opcjonalnie)

startAt (UTC ISO)

endAt (UTC ISO)

allDay (bool)

typeId

userId

createdAt, updatedAt

3) API (endpointy)

Auth

POST /api/auth/login

POST /api/auth/refresh

POST /api/auth/logout

Typy

GET /api/types

POST /api/types (admin lub user)

PUT /api/types/:id

DELETE /api/types/:id

Wydarzenia

GET /api/events?from=2026-02-01&to=2026-02-28

POST /api/events

PUT /api/events/:id

DELETE /api/events/:id

4) Web (React) – kalendarz miesiąc/tydzień/dzień + kolory + siatka

Najprościej: FullCalendar.

Instalacja

@fullcalendar/react

@fullcalendar/daygrid (miesiąc)

@fullcalendar/timegrid (dzień/tydzień)

@fullcalendar/interaction (klik, drag)

Mapowanie kolorów typów

FullCalendar przyjmuje backgroundColor, borderColor, textColor.

Najważniejsze rzeczy, które dostaniesz “z pudełka”

Widoki month/week/day

Linie siatki i przewijanie w timeGrid

Klikanie i dodawanie eventów

Drag & drop + resize
