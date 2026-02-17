import React, { createContext, useContext, useMemo, useState } from "react";
import api from "../api/client";
import { getAccessToken, setTokens, clearTokens } from "./tokenStore";

const AuthCtx = createContext(null);

export function AuthProvider({ children }) {
  const [accessToken, setAccessToken] = useState(getAccessToken());

  const value = useMemo(() => ({
    isAuthed: !!accessToken,
    async login(email, password) {
      const res = await api.post("/api/auth/login", { email, password }, { headers: {} });
      setTokens({ accessToken: res.data.accessToken, refreshToken: res.data.refreshToken });
      setAccessToken(res.data.accessToken);
      return res.data.user;
    },
    logout() {
      clearTokens();
      setAccessToken("");
    }
  }), [accessToken]);

  return <AuthCtx.Provider value={value}>{children}</AuthCtx.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthCtx);
  if (!ctx) throw new Error("useAuth must be inside AuthProvider");
  return ctx;
}
