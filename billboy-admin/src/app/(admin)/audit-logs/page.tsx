import { adminDb } from "@/lib/firebase-admin";

async function getAuditLogs() {
  const snap = await adminDb
    .collection("admin_audit_logs")
    .orderBy("timestamp", "desc")
    .limit(100)
    .get();

  return snap.docs.map((doc) => {
    const d = doc.data();
    return {
      id: doc.id,
      adminEmail: d.adminEmail ?? "—",
      adminRole: d.adminRole ?? "—",
      action: d.action ?? "—",
      timestamp: d.timestamp?.toDate?.()?.toLocaleString() ?? "—",
    };
  });
}

export default async function AuditLogsPage() {
  const logs = await getAuditLogs();

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Audit Logs</h1>
          <p className="text-sm text-gray-500 mt-1">Immutable — all admin actions are recorded and cannot be edited.</p>
        </div>
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 dark:bg-gray-900 border-b border-gray-200 dark:border-gray-700">
            <tr>
              {["Timestamp", "Admin", "Role", "Action"].map((h) => (
                <th key={h} className="text-left px-4 py-3 font-medium text-gray-600 dark:text-gray-400">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-gray-700">
            {logs.length === 0 ? (
              <tr>
                <td colSpan={4} className="px-4 py-8 text-center text-gray-400">No audit logs yet.</td>
              </tr>
            ) : logs.map((log) => (
              <tr key={log.id} className="hover:bg-gray-50 transition-colors">
                <td className="px-4 py-3 text-gray-500 text-xs font-mono">{log.timestamp}</td>
                <td className="px-4 py-3 text-gray-700 dark:text-gray-300">{log.adminEmail}</td>
                <td className="px-4 py-3">
                  <span className="px-2 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800">
                    {log.adminRole}
                  </span>
                </td>
                <td className="px-4 py-3 text-gray-900 dark:text-white font-medium">{log.action}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
