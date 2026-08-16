import { adminDb } from "@/lib/firebase-admin";

async function getHealthMetrics() {
  const [usersCount, billsCount, subsCount, logsCount] = await Promise.all([
    adminDb.collection("users").count().get(),
    adminDb.collection("bills").count().get(),
    adminDb.collection("subscriptions").count().get(),
    adminDb.collection("admin_audit_logs").count().get(),
  ]);

  return {
    users: usersCount.data().count,
    bills: billsCount.data().count,
    subscriptions: subsCount.data().count,
    auditLogs: logsCount.data().count,
    firestoreStatus: "Healthy",
    checkedAt: new Date().toLocaleString(),
  };
}

export default async function SystemHealthPage() {
  const metrics = await getHealthMetrics();

  const checks = [
    { label: "Firestore", status: metrics.firestoreStatus, ok: true },
    { label: "Total Users", status: `${metrics.users.toLocaleString()} documents`, ok: true },
    { label: "Total Bills", status: `${metrics.bills.toLocaleString()} documents`, ok: true },
    { label: "Subscriptions", status: `${metrics.subscriptions.toLocaleString()} documents`, ok: true },
    { label: "Audit Log Entries", status: `${metrics.auditLogs.toLocaleString()} entries`, ok: true },
  ];

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">System Health</h1>
        <p className="text-sm text-gray-400">Checked at {metrics.checkedAt}</p>
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 divide-y divide-gray-100 dark:divide-gray-700">
        {checks.map((check) => (
          <div key={check.label} className="flex items-center justify-between px-6 py-4">
            <div className="flex items-center gap-3">
              <div className={`w-2.5 h-2.5 rounded-full ${check.ok ? "bg-emerald-500" : "bg-red-500"}`} />
              <span className="font-medium text-gray-900 dark:text-white">{check.label}</span>
            </div>
            <span className="text-sm text-gray-500">{check.status}</span>
          </div>
        ))}
      </div>

      <p className="text-xs text-gray-400 mt-4">
        For deeper monitoring, connect Firebase Performance Monitoring and Cloud Monitoring dashboards.
      </p>
    </div>
  );
}
