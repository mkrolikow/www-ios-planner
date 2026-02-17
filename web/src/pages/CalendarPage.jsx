import React, { useEffect, useMemo, useRef, useState } from "react";
import FullCalendar from "@fullcalendar/react";
import dayGridPlugin from "@fullcalendar/daygrid";
import timeGridPlugin from "@fullcalendar/timegrid";
import interactionPlugin from "@fullcalendar/interaction";
import api from "../api/client";
import Modal from "../ui/Modal";
import EventForm from "../ui/EventForm";
import { useAuth } from "../auth/AuthContext";

function ymd(date) {
  const pad = (n) => String(n).padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

export default function CalendarPage() {
  const auth = useAuth();
  const calRef = useRef(null);

  const [types, setTypes] = useState([]);
  const [events, setEvents] = useState([]);
  const [range, setRange] = useState({ from: null, to: null });

  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState(null); // { id?, start, end, title, notes, typeId, allDay }

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

  const fcEvents = useMemo(() => {
    return events.map((e) => ({
      id: String(e.id),
      title: e.title,
      start: e.startAt,
      end: e.endAt,
      extendedProps: {
        notes: e.notes,
        typeId: e.typeId,
        allDay: e.allDay,
      },
      allDay: !!e.allDay,
      backgroundColor: e.type?.colorHex || "#007AFF",
      borderColor: e.type?.colorHex || "#007AFF",
    }));
  }, [events]);

  function openCreate(date) {
    setEditing({
      start: date,
      end: new Date(date.getTime() + 60 * 60 * 1000),
      title: "",
      notes: "",
      typeId: null,
      allDay: false,
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
    if (!editing?.id) {
      await api.post("/api/events", payload);
    } else {
      await api.put(`/api/events/${editing.id}`, payload);
    }
    // reload
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

  return (
    <div className="page">
      <div className="topbar">
        <div className="brand">Planer</div>
        <div className="spacer" />
        <button className="btn" onClick={() => { auth.logout(); window.location.href = "/login"; }}>
          Wyloguj
        </button>
      </div>

      <div className="card wide">
        <FullCalendar
          ref={calRef}
          plugins={[dayGridPlugin, timeGridPlugin, interactionPlugin]}
          initialView="dayGridMonth"
          headerToolbar={{
            left: "prev,next today",
            center: "title",
            right: "dayGridMonth,timeGridWeek,timeGridDay",
          }}
          height="auto"
          nowIndicator={true}
          selectable={true}
          editable={true}
          weekNumbers={false}
          dayMaxEvents={true}
          slotMinTime="06:00:00"
          slotMaxTime="22:00:00"
          scrollTime="08:00:00"
          events={fcEvents}
          datesSet={(arg) => {
            // FullCalendar daje start/end widoku (end jest exclusive)
            const from = new Date(arg.start);
            const to = new Date(arg.end);
            to.setDate(to.getDate() - 1);
            setRange({ from, to });
          }}
          dateClick={(info) => openCreate(info.date)}
          eventClick={(info) => openEdit(info.event)}
          eventDrop={(info) => updateFromDragOrResize(info.event)}
          eventResize={(info) => updateFromDragOrResize(info.event)}
        />
      </div>

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
    </div>
  );
}
