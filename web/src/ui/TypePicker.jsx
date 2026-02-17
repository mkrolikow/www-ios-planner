import React from "react";

export default function TypePicker({ types, value, onChange }) {
  return (
    <select className="input" value={value ?? ""} onChange={(e) => onChange(e.target.value ? Number(e.target.value) : null)}>
      <option value="">(Brak typu)</option>
      {types.map((t) => (
        <option key={t.id} value={t.id}>
          {t.name} {t.color_hex ? `(${t.color_hex})` : ""}
        </option>
      ))}
    </select>
  );
}
