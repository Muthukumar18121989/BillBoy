import { adminDb } from "@/lib/firebase-admin";

async function getBills() {
  const snap = await adminDb.collection("bills").orderBy("createdAt", "desc").limit(50).get();
  return snap.docs.map((doc) => {
    const d = doc.data();
    return {
      id: doc.id,
      userId: d.userId ?? "—",
      productName: d.productName ?? "—",
      category: d.category ?? "—",
      purchaseAmount: typeof d.purchaseAmount === "number"
        ? `₹${d.purchaseAmount.toLocaleString()}`
        : "—",
      warrantyStatus: d.warrantyStatus ?? "—",
      createdAt: d.createdAt?.toDate?.()?.toLocaleDateString() ?? "—",
    };
  });
}

const warrantyColors: Record<string, string> = {
  active: "bg-emerald-100 text-emerald-800",
  expiringSoon: "bg-yellow-100 text-yellow-800",
  expired: "bg-red-100 text-red-800",
  noWarranty: "bg-gray-100 text-gray-600",
};

export default async function BillsPage() {
  const bills = await getBills();

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Bills</h1>
        <span className="text-sm text-gray-500">{bills.length} shown (latest 50)</span>
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 dark:bg-gray-900 border-b border-gray-200 dark:border-gray-700">
            <tr>
              {["Product", "Category", "Amount", "Warranty", "User ID", "Added"].map((h) => (
                <th key={h} className="text-left px-4 py-3 font-medium text-gray-600 dark:text-gray-400">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-gray-700">
            {bills.map((bill) => (
              <tr key={bill.id} className="hover:bg-gray-50 transition-colors">
                <td className="px-4 py-3 font-medium text-gray-900 dark:text-white">{bill.productName}</td>
                <td className="px-4 py-3 text-gray-600">{bill.category}</td>
                <td className="px-4 py-3 font-mono text-gray-700">{bill.purchaseAmount}</td>
                <td className="px-4 py-3">
                  <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${warrantyColors[bill.warrantyStatus] ?? warrantyColors.noWarranty}`}>
                    {bill.warrantyStatus}
                  </span>
                </td>
                <td className="px-4 py-3 text-gray-400 font-mono text-xs">{bill.userId}</td>
                <td className="px-4 py-3 text-gray-500">{bill.createdAt}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
