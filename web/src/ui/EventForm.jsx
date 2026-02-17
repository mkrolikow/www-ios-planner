import React, { useMemo, useState } from "react";
import TypePicker from "./TypePicker";

function pad(n) { return String(n).padStart(2, "0"); }

function toLocalDateInput(date) {
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

function toLocalDateTimeInput(date) {
  return `${toLocalDateInput(date)}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

function fromLocalDate(dateStr) {
  // "YYYY-MM-DD" -> local Date at 00:00
  const [y, m, d] = dateStr.split("-").map(Number);
  return new Date(y, m - 1, d, 0, 0, 0, 0);
}

export default function EventForm({ initial, types, onSubmit, onDelete }) {
  const init = useMemo(() => {
    const now = new Date();
    const start = initial?.start ? new Date(initial.start) : now;
    const end = initial?.end ? new Date(initial.end) : new Date(start.getTime() + 60 * 60 * 1000);

    const allDay = !!initial?.allDay;

    return {
      title: initial?.title ?? "",
      notes: initial?.notes ?? "",
      typeId: initial?.typeId ?? null,
      allDay,
      startDate: toLocalDateInput(start),
      endDate: toLocalDateInput(end),
      startLocal: toLocalDateTimeInput(start),
      endLocal: toLocalDateTimeInput(end),
    };
  }, [initial]);

  const [form, setForm] = useState(init);
  const [err, setErr] = useState("");

  function set(key, val) {
    setForm((p) => ({ ...p, [key]: val }));
  }

  async function submit(e) {
    e.preventDefault();
    setErr("");

    const title = form.title.trim();
    if (!title) return setErr("Tytuł jest wymagany.");

    let start, end, allDay = !!form.allDay;

    if (allDay) {
      // FullCalendar najlepiej działa gdy end jest EXCLUSIVE (następny dzień 00:00)
      start = fromLocalDate(form.startDate);
      const endStart = fromLocalDate(form.endDate);
      // end = dzień końca + 1 dzień (exclusive)
      end = new Date(endStart.getTime() + 24 * 60 * 60 * 1000);
    } else {
      start = new Date(form.startLocal);
      end = new Date(form.endLocal);
    }

    if (!(start < end)) return setErr("Koniec musi być po początku.");

    await onSubmit({
      title,
      notes: form.notes,
      typeId: form.typeId,
      allDay,
      startAt: start.toISOString(),
      endAt: end.toISOString(),
    });
  }

  return (
    <form onSubmit={submit} className="stack">
      {err ? <div className="error">{err}</div> : null}

      <label className="label">Tytuł</label>
      <input className="input" value={form.title} onChange={(e) => set("title", e.target.value)} />

      <label className="label">Typ (kolor)</label>
      <TypePicker types={types} value={form.typeId} onChange={(v) => set("typeId", v)} />

      <label className="checkbox">
        <input type="checkbox" checked={form.allDay} onChange={(e) => set("allDay", e.target.checked)} />
        Cały dzień
      </label>

      {form.allDay ? (
        <div className="row">
          <div className="col">
            <label className="label">Start (data)</label>
            <input className="input" type="date" value={form.startDate} onChange={(e) => set("startDate", e.target.value)} />
          </div>
          <div className="col">
            <label className="label">Koniec (data)</label>
            <input className="input" type="date" value={form.endDate} onChange={(e) => set("endDate", e.target.value)} />
          </div>
        </div>
      ) : (
        <div className="row">
          <div className="col">
            <label className="label">Start</label>
            <input className="input" type="datetime-local" value={form.startLocal} onChange={(e) => set("startLocal", e.target.value)} />
          </div>
          <div className="col">
            <label className="label">Koniec</label>
            <input className="input" type="datetime-local" value={form.endLocal} onChange={(e) => set("endLocal", e.target.value)} />
          </div>
        </div>
      )}

      <label className="label">Notatki</label>
      <textarea className="input" rows={3} value={form.notes} onChange={(e) => set("notes", e.target.value)} />

      <div className="row" style={{ justifyContent: "space-between" }}>
        {onDelete ? <button type="button" className="btn danger" onClick={onDelete}>Usuń</button> : <span />}
        <button className="btn primary" type="submit">Zapisz</button>
      </div>
    </form>
  );
}
