import { adminDb } from "@/lib/firebase-admin";

async function getFlags() {
  const snap = await adminDb.collection("feature_flags").get();
  return snap.docs.map((doc) => ({
    id: doc.id,
    enabled: doc.data().enabled ?? false,
    description: doc.data().description ?? "—",
    updatedAt: doc.data().updatedAt?.toDate?.()?.toLocaleDateString() ?? "—",
  }));
}

// Seed list of flags the app expects
const expectedFlags = [
  { id: "ocr_enabled", description: "Bill scanning via camera (ML Kit OCR)" },
  { id: "ads_enabled", description: "Show AdMob banner ads to free-tier users" },
  { id: "subscription_enabled", description: "Enable in-app subscription purchase flow" },
  { id: "annual_plan_enabled", description: "Show annual plan option on paywall" },
];

export default async function FeatureFlagsPage() {
  const liveFlags = await getFlags();
  const flagMap = Object.fromEntries(liveFlags.map((f) => [f.id, f]));

  const flags = expectedFlags.map((ef) => ({
    ...ef,
    enabled: flagMap[ef.id]?.enabled ?? false,
    updatedAt: flagMap[ef.id]?.updatedAt ?? "not set",
  }));

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">Feature Flags</h1>
      <p className="text-sm text-gray-500 mb-6">
        Toggle flags in Firestore <code className="bg-gray-100 px-1 rounded">feature_flags</code> collection.
        Changes take effect on next app launch (Firebase Remote Config sync planned).
      </p>

      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 divide-y divide-gray-100 dark:divide-gray-700">
        {flags.map((flag) => (
          <div key={flag.id} className="flex items-center justify-between px-6 py-4">
            <div>
              <p className="font-medium text-gray-900 dark:text-white font-mono text-sm">{flag.id}</p>
              <p className="text-sm text-gray-500 mt-0.5">{flag.description}</p>
              <p className="text-xs text-gray-400 mt-1">Last updated: {flag.updatedAt}</p>
            </div>
            <span className={`px-3 py-1 rounded-full text-sm font-medium ${flag.enabled ? "bg-emerald-100 text-emerald-800" : "bg-gray-100 text-gray-600"}`}>
              {flag.enabled ? "Enabled" : "Disabled"}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}
