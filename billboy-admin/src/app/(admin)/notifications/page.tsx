import { adminDb } from "@/lib/firebase-admin";

async function getTemplates() {
  const snap = await adminDb.collection("notification_templates").get();
  return snap.docs.map((doc) => {
    const d = doc.data();
    return {
      id: doc.id,
      title: d.title ?? "—",
      body: d.body ?? "—",
      type: d.type ?? "general",
      isActive: d.isActive !== false,
    };
  });
}

const defaultTemplates = [
  { id: "warranty_expiring_30", title: "Warranty Expiring in 30 Days", body: "{{productName}} warranty expires on {{expiryDate}}. Consider extending or purchasing a new one.", type: "warranty", isActive: true },
  { id: "warranty_expiring_7", title: "Warranty Expiring in 7 Days", body: "⚠️ {{productName}} warranty expires in 7 days! Take action now.", type: "warranty", isActive: true },
  { id: "trial_ending_2", title: "Trial Ending Soon", body: "Your BillBoy Pro trial ends in 2 days. Upgrade to keep unlimited access.", type: "subscription", isActive: true },
  { id: "trial_expired", title: "Trial Expired", body: "Your Pro trial has ended. Upgrade to Pro to continue enjoying unlimited bills and no ads.", type: "subscription", isActive: true },
  { id: "bill_limit_80pct", title: "Approaching Bill Limit", body: "You've added {{count}} of 50 free bills. Upgrade to Pro for unlimited storage.", type: "subscription", isActive: true },
];

const typeColors: Record<string, string> = {
  warranty: "bg-yellow-100 text-yellow-800",
  subscription: "bg-indigo-100 text-indigo-800",
  general: "bg-gray-100 text-gray-700",
};

export default async function NotificationsPage() {
  let templates = await getTemplates();
  if (templates.length === 0) templates = defaultTemplates as typeof templates;

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">Notification Templates</h1>
      <p className="text-sm text-gray-500 mb-6">
        Templates stored in Firestore <code className="bg-gray-100 px-1 rounded">notification_templates</code>.
        Variables like <code className="bg-gray-100 px-1 rounded">{"{{productName}}"}</code> are substituted by Cloud Functions at send time.
      </p>

      <div className="space-y-3">
        {templates.map((t) => (
          <div key={t.id} className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5">
            <div className="flex items-start justify-between gap-4">
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${typeColors[t.type] ?? typeColors.general}`}>
                    {t.type}
                  </span>
                  <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${t.isActive ? "bg-emerald-100 text-emerald-800" : "bg-gray-100 text-gray-600"}`}>
                    {t.isActive ? "Active" : "Inactive"}
                  </span>
                </div>
                <p className="font-semibold text-gray-900 dark:text-white">{t.title}</p>
                <p className="text-sm text-gray-500 mt-1">{t.body}</p>
              </div>
              <code className="text-xs text-gray-400 font-mono shrink-0">{t.id}</code>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
