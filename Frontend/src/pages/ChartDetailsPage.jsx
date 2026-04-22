import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client.js";
import { EmptyState, Notice, StatCard, balanceOf, formatCurrency, walletIdOf } from "../components/Ui.jsx";
import { Icon } from "../components/Icons.jsx";
import { useAuth } from "../state/AuthContext.jsx";

export default function ChartDetailsPage({ home = false, title = "Dashboard" }) {
  const auth = useAuth();
  const [transactions, setTransactions] = useState([]);
  const [budgets, setBudgets] = useState([]);
  const [error, setError] = useState("");

  useEffect(() => {
    async function load() {
      try {
        const [tx, budget] = await Promise.allSettled([api.transactions(), api.budgets()]);
        if (tx.status === "fulfilled") setTransactions(Array.isArray(tx.value) ? tx.value : []);
        if (budget.status === "fulfilled") setBudgets(Array.isArray(budget.value) ? budget.value : []);
      } catch (err) {
        setError(err.message);
      }
    }
    load();
  }, []);

  const summary = useMemo(() => {
    const walletId = walletIdOf(auth.user);
    return transactions.reduce(
      (acc, tx) => {
        const amount = Math.abs(Number(tx.amount ?? tx.transaction_amount ?? 0));
        const from = tx.from ?? tx.from_wallet_id ?? tx.fromWalletId;
        const to = tx.to ?? tx.to_wallet_id ?? tx.toWalletId;
        if (from === walletId || Number(tx.amount) < 0) acc.debit += amount;
        if (to === walletId || Number(tx.amount) > 0) acc.credit += amount;
        const category = tx.category || tx.transaction_category || tx.type || "Other";
        acc.categories[category] = (acc.categories[category] || 0) + amount;
        return acc;
      },
      { debit: 0, credit: 0, categories: {} }
    );
  }, [transactions, auth.user]);

  return (
    <section className="page-stack">
      <Notice type="error">{error}</Notice>
      <div className="hero-panel">
        <div>
          <p>{home ? "Wallet overview" : "Details"}</p>
          <h2>{home ? `Welcome, ${auth.user?.userName || auth.user?.user_name || "User"}` : title}</h2>
        </div>
        <strong>{formatCurrency(balanceOf(auth.user))}</strong>
      </div>

      <div className="action-grid">
        <Link className="action-tile" to="/reload"><Icon name="plus" />Reload</Link>
        <Link className="action-tile" to="/transfer"><Icon name="send" />Transfer</Link>
        <Link className="action-tile" to="/pay"><Icon name="qr" />Pay</Link>
        <Link className="action-tile" to="/bank/link"><Icon name="bank" />Link bank</Link>
      </div>

      <div className="stats-grid">
        <StatCard label="Debit" value={formatCurrency(summary.debit)} tone="red" />
        <StatCard label="Credit" value={formatCurrency(summary.credit)} tone="green" />
        <StatCard label="Transactions" value={transactions.length} />
        <StatCard label="Budgets" value={budgets.length} tone="gold" />
      </div>

      <section className="content-grid two">
        <article className="panel">
          <h3>Spending categories</h3>
          {Object.keys(summary.categories).length ? (
            <div className="bar-list">
              {Object.entries(summary.categories).slice(0, 7).map(([label, value]) => (
                <div key={label}>
                  <span>{label}</span>
                  <meter min="0" max={Math.max(...Object.values(summary.categories))} value={value} />
                  <strong>{formatCurrency(value)}</strong>
                </div>
              ))}
            </div>
          ) : (
            <EmptyState title="No spending yet" text="Transactions from the server will appear here." />
          )}
        </article>
        <article className="panel">
          <h3>Recent transactions</h3>
          <div className="list">
            {transactions.slice(0, 6).map((tx, index) => (
              <Link className="list-row" to={`/transactionDetails/${tx.transaction_id || tx.transactionId || tx.id || index}`} key={tx.transaction_id || index}>
                <span>{tx.description || tx.transaction_type || tx.type || "Transaction"}</span>
                <strong>{formatCurrency(tx.amount ?? tx.transaction_amount)}</strong>
              </Link>
            ))}
          </div>
        </article>
      </section>
    </section>
  );
}
