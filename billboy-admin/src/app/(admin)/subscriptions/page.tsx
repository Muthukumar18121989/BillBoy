import { adminDb } from "@/lib/firebase-admin";

async function getSubscriptions() {
  const snap = await adminDb.collection("subscriptions").orderBy("updatedAt", "desc").limit(50).get();
  return snap.docs.map((doc) => {
    const d = doc.data();
    return {
      userId: doc.id,
      plan: d.plan ?? "free",
      status: d.status ?? "active",
      trialEnd: d.trialEnd?.toDate?.()?.toLocaleDateString() ?? "—",
      currentPeriodEnd: d.currentPeriodEnd?.toDate?.()?.toLocaleDateString() ?? "—",
      updatedAt: d.updatedAt?.toDate?.()?.toLocaleDateString() ?? "—",
    };
  });
}

const statusColors: Record<string, string> = {
  active: "bg-emerald-100 text-emerald-800",
  expired: "bg-red-100 text-red-800",
  cancelled: "bg-gray-100 text-gray-800",
  paused: "bg-yellow-100 text-yellow-800",
};

const planColors: Record<string, string> = {
  pro: "bg-indigo-100 text-indigo-800",
  trial: "bg-violet-100 text-violet-800",
  free: "bg-gray-100 text-gray-700",
};

export default async function SubscriptionsPage() {
  const subs = await getSubscriptions();

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">Subscriptions</h1>

      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 dark:bg-gray-900 border-b border-gray-200 dark:border-gray-700">
            <tr>
              {["User ID", "Plan", "Status", "Trial End", "Period End", "Updated"].map((h) => (
                <th key={h} className="text-left px-4 py-3 font-medium text-gray-600 dark:text-gray-400">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-gray-700">
            {subs.map((sub) => (
              <tr key={sub.userId} className="hover:bg-gray-50 transition-colors">
                <td className="px-4 py-3 font-mono text-xs text-gray-500">{sub.userId}</td>
                <td className="px-4 py-3">
                  <span className={`px-2 py-0.5 rounded-full text-xs font-medium capitalize ${planColors[sub.plan] ?? planColors.free}`}>
                    {sub.plan}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <span className={`px-2 py-0.5 rounded-full text-xs font-medium capitalize ${statusColors[sub.status] ?? statusColors.active}`}>
                    {sub.status}
                  </span>
                </td>
                <td className="px-4 py-3 text-gray-500">{sub.trialEnd}</td>
                <td className="px-4 py-3 text-gray-500">{sub.currentPeriodEnd}</td>
                <td className="px-4 py-3 text-gray-500">{sub.updatedAt}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
