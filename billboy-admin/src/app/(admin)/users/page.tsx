import { adminDb } from "@/lib/firebase-admin";

async function getUsers() {
  const snap = await adminDb.collection("users").orderBy("createdAt", "desc").limit(50).get();
  return snap.docs.map((doc) => ({
    id: doc.id,
    email: doc.data().email ?? "—",
    displayName: doc.data().displayName ?? "—",
    createdAt: doc.data().createdAt?.toDate?.()?.toLocaleDateString() ?? "—",
  }));
}

export default async function UsersPage() {
  const users = await getUsers();

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Users</h1>
        <span className="text-sm text-gray-500">{users.length} shown (latest 50)</span>
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 dark:bg-gray-900 border-b border-gray-200 dark:border-gray-700">
            <tr>
              {["Name", "Email", "User ID", "Joined"].map((h) => (
                <th key={h} className="text-left px-4 py-3 font-medium text-gray-600 dark:text-gray-400">
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-gray-700">
            {users.map((user) => (
              <tr key={user.id} className="hover:bg-gray-50 dark:hover:bg-gray-750 transition-colors">
                <td className="px-4 py-3 font-medium text-gray-900 dark:text-white">{user.displayName}</td>
                <td className="px-4 py-3 text-gray-600 dark:text-gray-400">{user.email}</td>
                <td className="px-4 py-3 text-gray-400 font-mono text-xs">{user.id}</td>
                <td className="px-4 py-3 text-gray-500">{user.createdAt}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
