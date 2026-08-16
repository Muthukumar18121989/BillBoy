import { NextRequest, NextResponse } from "next/server";
import { adminAuth, adminDb } from "./firebase-admin";

export type AdminRole = "ADMIN" | "SUPER_ADMIN" | "SUPPORT" | "ANALYST";

export interface AdminUser {
  uid: string;
  email: string;
  role: AdminRole;
}

/**
 * Verify the session cookie and return the admin user.
 * Throws a 401 response if the token is invalid or the user is not an admin.
 * Throws a 403 response if the user lacks the required role.
 *
 * Backend enforcement: roles are stored in Firestore admin_users collection
 * and verified server-side here. Never rely on client-supplied role claims.
 */
export async function requireAdmin(
  request: NextRequest,
  requiredRole?: AdminRole
): Promise<AdminUser> {
  const sessionCookie = request.cookies.get("admin_session")?.value;
  if (!sessionCookie) {
    throw NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  let decodedToken;
  try {
    decodedToken = await adminAuth.verifySessionCookie(sessionCookie, true);
  } catch {
    throw NextResponse.json({ error: "Invalid session" }, { status: 401 });
  }

  // Verify admin status from Firestore — not from token claims alone
  const adminDoc = await adminDb
    .collection("admin_users")
    .doc(decodedToken.uid)
    .get();

  if (!adminDoc.exists) {
    throw NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const adminData = adminDoc.data()!;
  const role = adminData.role as AdminRole;

  if (requiredRole && !hasRole(role, requiredRole)) {
    throw NextResponse.json({ error: "Insufficient permissions" }, { status: 403 });
  }

  return { uid: decodedToken.uid, email: decodedToken.email ?? "", role };
}

/**
 * Role hierarchy: SUPER_ADMIN > ADMIN > SUPPORT, ANALYST
 */
function hasRole(userRole: AdminRole, required: AdminRole): boolean {
  if (userRole === "SUPER_ADMIN") return true;
  if (userRole === "ADMIN" && required !== "SUPER_ADMIN") return true;
  return userRole === required;
}

/**
 * Write an immutable audit log entry. Called after every state-changing
 * admin action. Logs cannot be deleted (Firestore rules deny all writes
 * to admin_audit_logs except from Cloud Functions / Admin SDK).
 */
export async function writeAuditLog(
  adminUser: AdminUser,
  action: string,
  details: Record<string, unknown>
): Promise<void> {
  await adminDb.collection("admin_audit_logs").add({
    adminUid: adminUser.uid,
    adminEmail: adminUser.email,
    adminRole: adminUser.role,
    action,
    details,
    timestamp: new Date(),
  });
}
