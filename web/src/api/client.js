import axios from "axios";
import { getAccessToken, getRefreshToken, setTokens, clearTokens } from "../auth/tokenStore";

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE,
  timeout: 20000,
});

api.interceptors.request.use((config) => {
  const token = getAccessToken();
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

let refreshing = false;
let queue = [];

function resolveQueue(error, token) {
  queue.forEach(({ resolve, reject }) => {
    if (error) reject(error);
    else resolve(token);
  });
  queue = [];
}

api.interceptors.response.use(
  (res) => res,
  async (err) => {
    const original = err.config;
    const status = err?.response?.status;

    // jeśli 401 na endpointach poza login/refresh -> próbujemy refresh
    if (status === 401 && !original._retry && !original.url.includes("/api/auth/login") && !original.url.includes("/api/auth/refresh")) {
      original._retry = true;

      if (refreshing) {
        return new Promise((resolve, reject) => {
          queue.push({ resolve, reject });
        }).then((token) => {
          original.headers.Authorization = `Bearer ${token}`;
          return api(original);
        });
      }

      refreshing = true;

      try {
        const refreshToken = getRefreshToken();
        if (!refreshToken) throw new Error("No refresh token");

        const r = await api.post("/api/auth/refresh", { refreshToken }, { headers: {} });
        const newAccess = r.data.accessToken;
        setTokens({ accessToken: newAccess });

        resolveQueue(null, newAccess);
        original.headers.Authorization = `Bearer ${newAccess}`;
        return api(original);
      } catch (e) {
        resolveQueue(e, null);
        clearTokens();
        window.location.href = "/login";
        return Promise.reject(e);
      } finally {
        refreshing = false;
      }
    }

    return Promise.reject(err);
  }
);

export default api;
