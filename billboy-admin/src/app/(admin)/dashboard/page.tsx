import { adminDb } from "@/lib/firebase-admin";

async function getStats() {
  const [usersSnap, billsSnap, subsSnap] = await Promise.all([
    adminDb.collection("users").count().get(),
    adminDb.collection("bills").count().get(),
    adminDb.collection("subscriptions").where("status", "==", "active").count().get(),
  ]);

  return {
    totalUsers: usersSnap.data().count,
    totalBills: billsSnap.data().count,
    activeSubscriptions: subsSnap.data().count,
  };
}

export default async function DashboardPage() {
  const stats = await getStats();

  const cards = [
    { label: "Total Users", value: stats.totalUsers, color: "bg-indigo-600" },
    { label: "Total Bills", value: stats.totalBills, color: "bg-emerald-600" },
    { label: "Active Subscriptions", value: stats.activeSubscriptions, color: "bg-violet-600" },
  ];

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">Dashboard</h1>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        {cards.map((card) => (
          <div key={card.label} className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
            <div className={`inline-flex items-center justify-center w-10 h-10 rounded-lg ${card.color} mb-4`}>
              <span className="text-white font-bold text-lg">
                {String(card.value)[0]}
              </span>
            </div>
            <p className="text-3xl font-bold text-gray-900 dark:text-white">{card.value.toLocaleString()}</p>
            <p className="text-sm text-gray-500 mt-1">{card.label}</p>
          </div>
        ))}
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
        <h2 className="text-lg font-semibold mb-4">Recent Activity</h2>
        <p className="text-sm text-gray-500">Audit log stream — use the Audit Logs section for full history.</p>
      </div>
    </div>
  );
}
