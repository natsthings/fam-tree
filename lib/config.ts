// ============================================================
//  ✏️  SETTINGS — FILL THESE IN ONCE, THEN YOU'RE DONE
//  Everything personal to YOUR family lives in this one file.
//  (None of these are secret — they're safe to commit to GitHub.)
// ============================================================

// The name shown at the top of the site and in the browser tab.
export const SITE_NAME = 'The Alexander Family Tree'

// YOUR email — the same one you will register with.
// The person with this email becomes the ADMIN (can delete things,
// approve deletion requests, import GEDCOM files, see private tools).
// ⚠️ Must match the email in supabase/schema.sql (see README, Step 3).
export const ADMIN_EMAIL = 'coltonalexander@outlook.com'

// YOUR first name. Shown in messages like "Ask <name> for the code"
// and in the welcome letter signature.
export const ADMIN_NAME = 'Colton'

// The secret word relatives must type on the Register page to join.
// Not case-sensitive. Pick anything and text it to your family.
// ⚠️ This is a "keep casual visitors out" gate, not bank-level security.
//    (See README → "Locking it down" for the real lock.)
export const FAMILY_CODE = 'Password123'

// ---- Photo uploads (Cloudinary — free). See README, Part 3. ----
// Leave as-is to skip photo uploads for now (the rest of the app still works).
export const CLOUDINARY_CLOUD_NAME = 'your-cloud-name'
export const CLOUDINARY_UPLOAD_PRESET = 'family_tree_unsigned'

// Helper used across the app. Case-insensitive email comparison.
export function isAdminEmail(email?: string | null): boolean {
  return !!email && email.trim().toLowerCase() === ADMIN_EMAIL.trim().toLowerCase()
}
