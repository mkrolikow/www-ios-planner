const KEY_ACCESS = "planer_access";
const KEY_REFRESH = "planer_refresh";

export function getAccessToken() {
  return localStorage.getItem(KEY_ACCESS) || "";
}
export function getRefreshToken() {
  return localStorage.getItem(KEY_REFRESH) || "";
}
export function setTokens({ accessToken, refreshToken }) {
  if (accessToken) localStorage.setItem(KEY_ACCESS, accessToken);
  if (refreshToken) localStorage.setItem(KEY_REFRESH, refreshToken);
}
export function clearTokens() {
  localStorage.removeItem(KEY_ACCESS);
  localStorage.removeItem(KEY_REFRESH);
}
