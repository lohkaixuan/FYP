import { Navigate, Outlet, useLocation } from "react-router-dom";
import { useAuth } from "../state/AuthContext.jsx";

export default function ProtectedRoute() {
  const { isAuthed, status } = useAuth();
  const location = useLocation();

  if (status === "loading") return <main className="center-screen">Loading...</main>;
  if (!isAuthed) return <Navigate to="/login" replace state={{ from: location }} />;
  return <Outlet />;
}
