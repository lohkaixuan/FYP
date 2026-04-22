import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import { api } from "../api/client.js";
import { Notice, formatCurrency } from "../components/Ui.jsx";

export default function TransactionDetailsPage() {
  const { id } = useParams();
  const [tx, setTx] = useState(null);
  const [error, setError] = useState("");

  useEffect(() => {
    api.transaction(id).then(setTx).catch((err) => setError(err.message));
  }, [id]);

  return (
    <section className="page-stack">
      <div className="page-title"><h2>Transaction details</h2></div>
      <Notice type="error">{error}</Notice>
      <article className="panel detail-panel">
        {tx ? Object.entries(tx).map(([key, value]) => (
          <div key={key}><span>{key}</span><strong>{key.toLowerCase().includes("amount") ? formatCurrency(value) : String(value ?? "-")}</strong></div>
        )) : <p>Loading transaction...</p>}
      </article>
    </section>
  );
}
