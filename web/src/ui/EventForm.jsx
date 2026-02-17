import React, { useMemo, useState } from "react";
import TypePicker from "./TypePicker";

function toLocalInputValue(date) {
  // date: JS Date -> "YYYY-MM-DDTHH:mm"
  const pad = (n) => String(n).padStart(2, "0");
  const y = date.getFullYear();
  const m = pad(date.getMonth() + 1);
  const d = pad(date.getDate());
  const hh = pad(date.getHours());
  const mm = pad(date.getMinutes());
  return `${y}-${m}-${d}T${hh}:${mm}`;
}

export default function EventForm({ initial, types, onSubmit, onDelete }) {
  const init = useMemo(() => {
    const now = new Date();
    const start = initial?.start ? new Date(initial.start) : now;
    const end = initial?.end ? new Date(initial.end) : new Date(start.getTime() + 60 * 60 * 1000);

    return {
      title: initial?.title ?? "",
      notes: initial?.notes ?? "",
      typeId: initial?.typeId ?? null,
      allDay: !!initial?.allDay,
      startLocal: toLocalInputValue(start),
      endLocal: toLocalInputValue(end),
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

    if (!form.title.trim()) return setErr("Tytuł jest wymagany.");
    const start = new Date(form.startLocal);
    const end = new Date(form.endLocal);
    if (!(start < end)) return setErr("Koniec musi być po początku.");

    await onSubmit({
      title: form.title.trim(),
      notes: form.notes,
      typeId: form.typeId,
      allDay: form.allDay,
      // wysyłamy ISO UTC
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

      <label className="checkbox">
        <input type="checkbox" checked={form.allDay} onChange={(e) => set("allDay", e.target.checked)} />
        Cały dzień
      </label>

      <label className="label">Notatki</label>
      <textarea className="input" rows={3} value={form.notes} onChange={(e) => set("notes", e.target.value)} />

      <div className="row" style={{ justifyContent: "space-between" }}>
        {onDelete ? <button type="button" className="btn danger" onClick={onDelete}>Usuń</button> : <span />}
        <button className="btn primary" type="submit">Zapisz</button>
      </div>
    </form>
  );
}
