import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../state/AuthContext.jsx";

export default function SplashPage() {
  const { isAuthed, isAdmin, isProvider, status } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    const timer = setTimeout(() => {
      if (!isAuthed) navigate("/login", { replace: true });
      else if (isAdmin) navigate("/admin", { replace: true });
      else if (isProvider) navigate("/provider", { replace: true });
      else navigate("/home", { replace: true });
    }, status === "loading" ? 900 : 450);
    return () => clearTimeout(timer);
  }, [isAuthed, isAdmin, isProvider, status, navigate]);

  return (
    <main className="splash">
      <img src="/logo.png" alt="" />
      <h1>UniPay</h1>
      <p>Multi-bank digital wallet</p>
    </main>
  );
}
