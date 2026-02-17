import React, { useState } from "react";
import Modal from "./Modal";
import TypeForm from "./TypeForm";

export default function TypesManager({ open, onClose, types, onCreate, onUpdate, onDelete }) {
  const [editing, setEditing] = useState(null);

  function closeAll() {
    setEditing(null);
    onClose();
  }

  return (
    <Modal open={open} title="Typy wydarzeń (kolory)" onClose={closeAll}>
      <div className="stack">
        <div className="row" style={{ justifyContent: "space-between", alignItems: "center" }}>
          <div className="muted">
            Typy globalne (admin) oraz Twoje (user). W WEB edytujesz swoje; globalne edytuje admin w CI4.
          </div>
          <button className="btn primary" onClick={() => setEditing({ mode: "create" })}>
            + Dodaj
          </button>
        </div>

        <div className="typeList">
          {types.map((t) => (
            <div key={t.id} className="typeRow">
              <div className="typeLeft">
                <span className="swatch" style={{ background: t.color_hex }} />
                <div>
                  <div className="typeName">{t.name}</div>
                  <div className="muted small">{t.color_hex}</div>
                </div>
              </div>
              <div className="row">
                <button className="btn" onClick={() => setEditing({ mode: "edit", type: t })}>
                  Edytuj
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      <Modal
        open={!!editing}
        title={editing?.mode === "create" ? "Dodaj typ" : "Edytuj typ"}
        onClose={() => setEditing(null)}
      >
        <TypeForm
          initial={editing?.type}
          onSubmit={async (payload) => {
            if (editing?.mode === "create") await onCreate(payload);
            else await onUpdate(editing.type.id, payload);
            setEditing(null);
          }}
          onDelete={
            editing?.mode === "edit"
              ? async () => {
                  await onDelete(editing.type.id);
                  setEditing(null);
                }
              : null
          }
        />
      </Modal>
    </Modal>
  );
}
