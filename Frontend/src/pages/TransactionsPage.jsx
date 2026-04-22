import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client.js";
import { EmptyState, Notice, formatCurrency } from "../components/Ui.jsx";

export default function TransactionsPage() {
  const [items, setItems] = useState([]);
  const [error, setError] = useState("");

  useEffect(() => {
    api.transactions().then((data) => setItems(Array.isArray(data) ? data : [])).catch((err) => setError(err.message));
  }, []);

  return (
    <section className="page-stack">
      <div className="page-title"><h2>Transactions</h2><Link className="primary-button small" to="/transfer">New transfer</Link></div>
      <Notice type="error">{error}</Notice>
      <article className="panel">
        {items.length ? (
          <div className="table-list">
            {items.map((tx, index) => {
              const id = tx.transaction_id || tx.transactionId || tx.id || index;
              return (
                <Link to={`/transactionDetails/${id}`} className="table-row" key={id}>
                  <span>{tx.description || tx.transaction_type || tx.type || "Transaction"}</span>
                  <span>{tx.category || tx.status || "General"}</span>
                  <strong>{formatCurrency(tx.amount ?? tx.transaction_amount)}</strong>
                </Link>
              );
            })}
          </div>
        ) : (
          <EmptyState title="No transactions" text="Once the server returns wallet activity, it will be listed here." />
        )}
      </article>
    </section>
  );
}
