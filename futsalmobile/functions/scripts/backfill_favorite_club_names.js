// One-off backfill: realign stored club favorites with the clubs-document name.
//
// Older favorites were saved with the standings name (e.g. "Mnk Kontrol / Biro")
// while match documents — and therefore the FCM topics the Cloud Functions push
// to — use the clubs-document name ("Mnk Kontrol Biro Teatro bar"). A favorite
// stuck on the standings name is subscribed to a topic that never fires.
//
// The app fixes this per club when the club page is opened (see
// FavoritesService.syncEntityName); this script catches every other favorite.
//
// Usage (from functions/), cmd.exe or PowerShell:
//   node scripts/backfill_favorite_club_names.js --key=C:/path/to/key.json
//   node scripts/backfill_favorite_club_names.js --key=C:/path/to/key.json --apply
//
// Options:
//   --key=PATH           service-account JSON; omit to use gcloud ADC
//                        (gcloud auth application-default login)
//   --project=ID         project id for the ADC path (default: fucalzadar)
//   --apply              actually write (default is a dry run)
//   --leagues=a,b,c      league collections to read clubs from
//
// Note: devices re-subscribe to the corrected topic on next app start via
// FavoritesService.restoreSubscriptions(). The stale topic subscription lingers
// on the device but never receives anything, since no match carries that name.

const { initializeApp, cert, applicationDefault } = require("firebase-admin/app");
const fs = require("fs");
const path = require("path");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const args = process.argv.slice(2);
const APPLY = args.includes("--apply");
const leaguesArg = args.find((a) => a.startsWith("--leagues="));
const LEAGUE_IDS = leaguesArg
  ? leaguesArg.slice("--leagues=".length).split(",").filter(Boolean)
  : ["liga1", "liga2", "liga3", "liga4"];

const keyArg = args.find((a) => a.startsWith("--key="));
const keyPath = keyArg
  ? keyArg.slice("--key=".length).replace(/^"|"$/g, "")
  : process.env.GOOGLE_APPLICATION_CREDENTIALS;

const PROJECT_ID = (args.find((a) => a.startsWith("--project=")) || "")
  .slice("--project=".length) || process.env.GOOGLE_CLOUD_PROJECT || "fucalzadar";

if (keyPath && !fs.existsSync(keyPath)) {
  console.error(`Service-account file not found: ${path.resolve(keyPath)}`);
  process.exit(1);
}

if (keyPath) {
  initializeApp({ credential: cert(require(path.resolve(keyPath))) });
} else {
  // No key file — fall back to gcloud Application Default Credentials:
  //   gcloud auth application-default login
  initializeApp({ credential: applicationDefault(), projectId: PROJECT_ID });
}
const db = getFirestore("main");

async function loadClubNames() {
  const names = new Map(); // clubId -> clubName
  for (const leagueId of LEAGUE_IDS) {
    const snap = await db.collection(leagueId).get();
    for (const doc of snap.docs) {
      const name = doc.data().clubName;
      if (typeof name === "string" && name.length > 0) {
        names.set(doc.id, name);
      }
    }
    console.log(`[clubs] ${leagueId}: ${snap.size} docs`);
  }
  return names;
}

async function main() {
  const clubNames = await loadClubNames();
  console.log(`[clubs] ${clubNames.size} club names loaded`);
  if (clubNames.size === 0) {
    console.error("No clubs found — check --leagues and the database id.");
    process.exit(1);
  }

  // listDocuments(), not get(): the app never creates the users/{uid} document
  // itself, only the favorites subcollection, so those parents are "ghosts"
  // that a normal collection read does not return.
  const users = await db.collection("users").listDocuments();
  console.log(`[users] ${users.length} users`);

  let scanned = 0;
  let stale = 0;
  let unknown = 0;
  let writer = APPLY ? db.bulkWriter() : null;

  for (const user of users) {
    const favs = await user
      .collection("favorites")
      .where("type", "==", "club")
      .get();

    for (const fav of favs.docs) {
      scanned++;
      const current = fav.get("name");
      const correct = clubNames.get(fav.id);
      if (!correct) {
        unknown++;
        console.warn(`[skip] ${fav.ref.path} — club ${fav.id} not found`);
        continue;
      }
      if (current === correct) continue;

      stale++;
      console.log(`[fix] ${fav.ref.path}: "${current}" -> "${correct}"`);
      if (writer) {
        writer.update(fav.ref, {
          name: correct,
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
    }
  }

  if (writer) await writer.close();

  console.log(
    `\n${APPLY ? "Updated" : "Would update"} ${stale} of ${scanned} club favorites` +
      (unknown ? ` (${unknown} skipped — club doc missing)` : "")
  );
  if (!APPLY && stale > 0) console.log("Re-run with --apply to write.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
