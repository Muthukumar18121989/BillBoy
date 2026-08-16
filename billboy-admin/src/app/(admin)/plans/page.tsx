import { adminDb } from "@/lib/firebase-admin";

async function getPlans() {
  const snap = await adminDb.collection("plans").get();
  return snap.docs.map((doc) => {
    const d = doc.data();
    return {
      id: doc.id,
      name: d.name ?? "—",
      price: d.price != null ? `₹${d.price}` : "Free",
      billLimit: d.billLimit === -1 ? "Unlimited" : (d.billLimit ?? 50),
      features: (d.features as string[] | undefined) ?? [],
      isActive: d.isActive !== false,
    };
  });
}

const defaultPlans = [
  { id: "free", name: "Free", price: "Free", billLimit: 50, features: ["50 bills", "CSV export", "Warranty alerts"], isActive: true },
  { id: "trial", name: "Trial", price: "Free (7 days)", billLimit: "Unlimited", features: ["All Pro features", "No ads", "7-day limit"], isActive: true },
  { id: "pro_monthly", name: "Pro Monthly", price: "₹299/mo", billLimit: "Unlimited", features: ["Unlimited bills", "No ads", "Priority support", "PDF export"], isActive: true },
  { id: "pro_annual", name: "Pro Annual", price: "₹1,999/yr", billLimit: "Unlimited", features: ["Unlimited bills", "No ads", "Priority support", "PDF export", "Save 44%"], isActive: true },
];

export default async function PlansPage() {
  let plans = await getPlans();
  // Show default plan definitions if Firestore has none yet
  if (plans.length === 0) {
    plans = defaultPlans as typeof plans;
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">Plans</h1>
      <p className="text-sm text-gray-500 mb-6">
        Plans are managed in Firestore <code className="bg-gray-100 px-1 rounded">plans</code> collection.
        Only SUPER_ADMIN can modify plans.
      </p>

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
        {plans.map((plan) => (
          <div key={plan.id} className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5">
            <div className="flex items-center justify-between mb-3">
              <h2 className="font-semibold text-gray-900 dark:text-white">{plan.name}</h2>
              <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${plan.isActive ? "bg-emerald-100 text-emerald-800" : "bg-gray-100 text-gray-600"}`}>
                {plan.isActive ? "Active" : "Inactive"}
              </span>
            </div>
            <p className="text-2xl font-bold text-indigo-600 mb-1">{plan.price}</p>
            <p className="text-xs text-gray-500 mb-4">Bill limit: {String(plan.billLimit)}</p>
            <ul className="space-y-1">
              {plan.features.map((f) => (
                <li key={f} className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400">
                  <span className="text-emerald-500">✓</span> {f}
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>
    </div>
  );
}
