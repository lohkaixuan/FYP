import { createContext, useContext, useEffect, useMemo, useState } from "react";
import { api } from "../api/client.js";

const AuthContext = createContext(null);

function normalizeRole(role, user) {
  const value = String(role || user?.roleName || user?.role_name || "").toLowerCase();
  if (value) return value;
  if (user?.providerId || user?.provider_id) return "provider";
  if (user?.merchantId || user?.merchant_id) return "merchant";
  return "user";
}

export function AuthProvider({ children }) {
  const [token, setToken] = useState(() => localStorage.getItem("unipay_token") || "");
  const [user, setUser] = useState(null);
  const [role, setRole] = useState("");
  const [status, setStatus] = useState("idle");
  const [error, setError] = useState("");

  async function refreshMe() {
    if (!localStorage.getItem("unipay_token")) return null;
    setStatus("loading");
    try {
      const me = await api.me();
      const nextRole = normalizeRole(role, me);
      setUser(me);
      setRole(nextRole);
      setStatus("ready");
      return me;
    } catch (err) {
      setError(err.message);
      setStatus("error");
      return null;
    }
  }

  async function login(credentials) {
    setStatus("loading");
    setError("");
    const result = await api.login(credentials);
    localStorage.setItem("unipay_token", result.token);
    setToken(result.token);
    setUser(result.user);
    setRole(normalizeRole(result.role, result.user));
    setStatus("ready");
    return result;
  }

  async function logout() {
    try {
      if (token) await api.logout();
    } catch {
      // Clear local state even if the remote logout endpoint is unavailable.
    } finally {
      localStorage.removeItem("unipay_token");
      setToken("");
      setUser(null);
      setRole("");
      setStatus("idle");
    }
  }

  useEffect(() => {
    refreshMe();
  }, []);

  const value = useMemo(
    () => ({
      token,
      user,
      role,
      status,
      error,
      isAuthed: Boolean(token),
      isAdmin: role.includes("admin"),
      isProvider: role.includes("provider") || role.includes("thirdparty"),
      isMerchant: role.includes("merchant"),
      login,
      logout,
      refreshMe,
      setUser
    }),
    [token, user, role, status, error]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error("useAuth must be used inside AuthProvider");
  return context;
}
