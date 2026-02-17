import React, { useState } from "react";

export default function TypeForm({ initial, onSubmit, onDelete }) {
  const [name, setName] = useState(initial?.name ?? "");
  const [colorHex, setColorHex] = useState(initial?.color_hex ?? "#007AFF");
  const [err, setErr] = useState("");

  async function submit(e) {
    e.preventDefault();
    setErr("");

    const n = name.trim();
    const c = (colorHex || "").toUpperCase().trim();

    if (!n) return setErr("Nazwa jest wymagana.");
    if (!/^#[0-9A-F]{6}$/.test(c)) return setErr("Kolor musi mieć format #RRGGBB.");

    await onSubmit({ name: n, colorHex: c });
  }

  return (
    <form onSubmit={submit} className="stack">
      {err ? <div className="error">{err}</div> : null}

      <label className="label">Nazwa</label>
      <input className="input" value={name} onChange={(e) => setName(e.target.value)} />

      <label className="label">Kolor</label>
      <div className="row">
        <input
          className="input"
          style={{ flex: 1 }}
          value={colorHex}
          onChange={(e) => setColorHex(e.target.value)}
          placeholder="#RRGGBB"
        />
        <input
          className="input"
          style={{ width: 56, padding: 0 }}
          type="color"
          value={colorHex}
          onChange={(e) => setColorHex(e.target.value)}
          aria-label="color"
        />
      </div>

      <div className="row" style={{ justifyContent: "space-between" }}>
        {onDelete ? (
          <button type="button" className="btn danger" onClick={onDelete}>
            Usuń
          </button>
        ) : (
          <span />
        )}
        <button className="btn primary" type="submit">
          Zapisz
        </button>
      </div>
    </form>
  );
}
