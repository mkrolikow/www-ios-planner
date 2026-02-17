import React from "react";
import { AuthProvider, useAuth } from "./auth/AuthContext";
import LoginPage from "./pages/LoginPage";
import CalendarPage from "./pages/CalendarPage";

function Router() {
  const { isAuthed } = useAuth();
  const path = window.location.pathname;

  if (!isAuthed) return <LoginPage />;
  if (path === "/login") return <LoginPage />;
  return <CalendarPage />;
}

export default function App() {
  return (
    <AuthProvider>
      <Router />
    </AuthProvider>
  );
}
