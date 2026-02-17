import React from "react";

export default function Modal({ open, title, onClose, children }) {
  if (!open) return null;
  return (
    <div className="modalOverlay" onMouseDown={onClose}>
      <div className="modalCard" onMouseDown={(e) => e.stopPropagation()}>
        <div className="modalHeader">
          <div className="modalTitle">{title}</div>
          <button className="btn" onClick={onClose}>✕</button>
        </div>
        <div className="modalBody">{children}</div>
      </div>
    </div>
  );
}
