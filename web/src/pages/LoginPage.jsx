import React, { useState } from "react";
import { useAuth } from "../auth/AuthContext";

export default function LoginPage() {
  const auth = useAuth();
  const [email, setEmail] = useState("admin@planer.local");
  const [password, setPassword] = useState("Admin123!");
  const [err, setErr] = useState("");

  async function submit(e) {
    e.preventDefault();
    setErr("");
    try {
      await auth.login(email, password);
      window.location.href = "/";
    } catch (e2) {
      setErr("Błędny email lub hasło.");
    }
  }

  return (
    <div className="page">
      <div className="card">
        <h2>Logowanie</h2>
        {err ? <div className="error">{err}</div> : null}
        <form onSubmit={submit} className="stack">
          <input className="input" placeholder="Email" value={email} onChange={(e) => setEmail(e.target.value)} />
          <input className="input" placeholder="Hasło" type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
          <button className="btn primary" type="submit">Zaloguj</button>
        </form>
      </div>
    </div>
  );
}
