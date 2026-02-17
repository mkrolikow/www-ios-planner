import React, { useEffect, useMemo, useState } from "react";
import FullCalendar from "@fullcalendar/react";
import dayGridPlugin from "@fullcalendar/daygrid";
import timeGridPlugin from "@fullcalendar/timegrid";
import listPlugin from "@fullcalendar/list";
import interactionPlugin from "@fullcalendar/interaction";
import api from "../api/client";
import Modal from "../ui/Modal";
import EventForm from "../ui/EventForm";
import TypesManager from "../ui/TypesManager";
import { useAuth } from "../auth/AuthContext";

function pad(n) { return String(n).padStart(2, "0"); }
function ymd(date) {
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

export default function CalendarPage() {
  const auth = useAuth();

  const [types, setTypes] = useState([]);
  const [events, setEvents] = useState([]);
  const [range, setRange] = useState({ from: null, to: null });

  const [typesOpen, setTypesOpen] = useState(false);

  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState(null);

  // filtrowanie po typach: Set(id)
  const [filterTypeIds, setFilterTypeIds] = useState(new Set());

  async function loadTypes() {
    const res = await api.get("/api/types");
    setTypes(res.data);
  }

  async function loadEvents(fromDate, toDate) {
    const res = await api.get("/api/events", { params: { from: ymd(fromDate), to: ymd(toDate) } });
    setEvents(res.data);
  }

  useEffect(() => {
    if (!auth.isAuthed) window.location.href = "/login";
    loadTypes();
  }, []);

  useEffect(() => {
    if (range.from && range.to) loadEvents(range.from, range.to);
  }, [range.from, range.to]);

  const typeById = useMemo(() => {
    const m = new Map();
    types.forEach((t) => m.set(Number(t.id), t));
    return m;
  }, [types]);

  const filteredEvents = useMemo(() => {
    if (!filterTypeIds || filterTypeIds.size === 0) return events;
    return events.filter((e) => e.typeId && filterTypeIds.has(Number(e.typeId)));
  }, [events, filterTypeIds]);

  const fcEvents = useMemo(() => {
    return filteredEvents.map((e) => ({
      id: String(e.id),
      title: e.title,
      start: e.startAt,
      end: e.endAt,
      allDay: !!e.allDay,
      extendedProps: {
        notes: e.notes,
        typeId: e.typeId,
      },
      backgroundColor: e.type?.colorHex || "#007AFF",
      borderColor: e.type?.colorHex || "#007AFF",
    }));
  }, [filteredEvents]);

  function openCreateFromSelection(sel) {
    setEditing({
      start: sel.start,
      end: sel.end,
      title: "",
      notes: "",
      typeId: null,
      allDay: !!sel.allDay,
    });
    setModalOpen(true);
  }

  function openEdit(fcEvent) {
    setEditing({
      id: Number(fcEvent.id),
      start: fcEvent.start,
      end: fcEvent.end || new Date(fcEvent.start.getTime() + 60 * 60 * 1000),
      title: fcEvent.title,
      notes: fcEvent.extendedProps?.notes ?? "",
      typeId: fcEvent.extendedProps?.typeId ?? null,
      allDay: !!fcEvent.allDay,
    });
    setModalOpen(true);
  }

  async function createOrUpdate(payload) {
    if (!editing?.id) await api.post("/api/events", payload);
    else await api.put(`/api/events/${editing.id}`, payload);

    if (range.from && range.to) await loadEvents(range.from, range.to);
    setModalOpen(false);
    setEditing(null);
  }

  async function deleteEvent() {
    if (!editing?.id) return;
    await api.delete(`/api/events/${editing.id}`);
    if (range.from && range.to) await loadEvents(range.from, range.to);
    setModalOpen(false);
    setEditing(null);
  }

  async function updateFromDragOrResize(fcEvent) {
    const payload = {
      title: fcEvent.title,
      startAt: fcEvent.start.toISOString(),
      endAt: (fcEvent.end || new Date(fcEvent.start.getTime() + 60 * 60 * 1000)).toISOString(),
      allDay: !!fcEvent.allDay,
      typeId: fcEvent.extendedProps?.typeId ?? null,
      notes: fcEvent.extendedProps?.notes ?? "",
    };
    await api.put(`/api/events/${Number(fcEvent.id)}`, payload);
    if (range.from && range.to) await loadEvents(range.from, range.to);
  }

  // typy CRUD (userowe) przez API
  async function createType(payload) {
    await api.post("/api/types", payload);
    await loadTypes();
  }
  async function updateType(id, payload) {
    await api.put(`/api/types/${id}`, payload);
    await loadTypes();
  }
  async function deleteType(id) {
    await api.delete(`/api/types/${id}`);
    await loadTypes();
    // jeśli filtr zawierał usunięty typ -> usuń z filtra
    setFilterTypeIds((prev) => {
      const n = new Set(prev);
      n.delete(Number(id));
      return n;
    });
  }

  function toggleFilterType(id) {
    setFilterTypeIds((prev) => {
      const n = new Set(prev);
      if (n.has(id)) n.delete(id);
      else n.add(id);
      return n;
    });
  }

  return (
    <div className="page">
      <div className="topbar">
        <div className="brand">Planer</div>

        <div className="spacer" />

        <button className="btn" onClick={() => setTypesOpen(true)}>Typy</button>
        <button className="btn" onClick={() => { auth.logout(); window.location.href = "/login"; }}>
          Wyloguj
        </button>
      </div>

      {/* FILTRY typów */}
      <div className="card wide" style={{ marginBottom: 12 }}>
        <div className="row" style={{ flexWrap: "wrap", alignItems: "center" }}>
          <div className="muted" style={{ marginRight: 10 }}>Filtry:</div>

          <button
            className="btn"
            onClick={() => setFilterTypeIds(new Set())}
            title="Pokaż wszystkie"
          >
            Wszystkie
          </button>

          {types.map((t) => {
            const id = Number(t.id);
            const active = filterTypeIds.size > 0 && filterTypeIds.has(id);
            return (
              <button
                key={t.id}
                className={"chip " + (active ? "chipActive" : "")}
                onClick={() => toggleFilterType(id)}
                title={t.name}
              >
                <span className="swatch" style={{ background: t.color_hex }} />
                {t.name}
              </button>
            );
          })}

          {filterTypeIds.size > 0 ? (
            <span className="muted small" style={{ marginLeft: 8 }}>
              Aktywne: {filterTypeIds.size}
            </span>
          ) : null}
        </div>
      </div>

      <div className="card wide">
        <FullCalendar
          plugins={[dayGridPlugin, timeGridPlugin, listPlugin, interactionPlugin]}
          initialView="dayGridMonth"
          headerToolbar={{
            left: "prev,next today",
            center: "title",
            right: "dayGridMonth,timeGridWeek,timeGridDay,listDay",
          }}
          height="auto"
          nowIndicator={true}
          selectable={true}
          selectMirror={true}
          editable={true}
          dayMaxEvents={true}
          slotMinTime="06:00:00"
          slotMaxTime="22:00:00"
          scrollTime="08:00:00"
          events={fcEvents}
          datesSet={(arg) => {
            // end jest exclusive -> cofamy 1 dzień do pobrania zakresu
            const from = new Date(arg.start);
            const to = new Date(arg.end);
            to.setDate(to.getDate() - 1);
            setRange({ from, to });
          }}
          // klik w dzień -> szybkie dodanie (1h)
          dateClick={(info) => {
            openCreateFromSelection({
              start: info.date,
              end: new Date(info.date.getTime() + 60 * 60 * 1000),
              allDay: info.allDay,
            });
          }}
          // zaznaczanie (drag na siatce) -> tworzenie eventu
          select={(sel) => openCreateFromSelection(sel)}
          eventClick={(info) => openEdit(info.event)}
          eventDrop={(info) => updateFromDragOrResize(info.event)}
          eventResize={(info) => updateFromDragOrResize(info.event)}
        />
      </div>

      {/* MODAL eventu */}
      <Modal
        open={modalOpen}
        title={editing?.id ? "Edytuj wydarzenie" : "Dodaj wydarzenie"}
        onClose={() => { setModalOpen(false); setEditing(null); }}
      >
        <EventForm
          initial={editing}
          types={types}
          onSubmit={createOrUpdate}
          onDelete={editing?.id ? deleteEvent : null}
        />
      </Modal>

      {/* MODAL typów */}
      <TypesManager
        open={typesOpen}
        onClose={() => setTypesOpen(false)}
        types={types}
        onCreate={createType}
        onUpdate={updateType}
        onDelete={deleteType}
      />
    </div>
  );
}
