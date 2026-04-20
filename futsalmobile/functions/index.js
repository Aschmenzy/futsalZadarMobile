const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");

initializeApp();

const db = getFirestore("main");

// Croatia is UTC+2 in summer, UTC+1 in winter.
// Using a fixed +2 offset (daylight saving). Adjust if needed.
const CROATIA_OFFSET_MS = 2 * 60 * 60 * 1000;

// Matches the sanitization in Flutter's _topicFor()
function sanitize(name) {
  return name.replace(/[^a-zA-Z0-9_\-]/g, "_");
}

function clubTopic(teamName) {
  return "club_" + sanitize(teamName);
}

function matchTopic(matchId) {
  return "match_" + matchId;
}

function playerTopic(playerId) {
  return "player_" + playerId;
}

// Sends a notification to a topic, silently skips on error.
async function sendToTopic(topic, title, body) {
  try {
    await getMessaging().send({
      topic,
      notification: { title, body },
      android: { priority: "high" },
      apns: { payload: { aps: { sound: "default" } } },
    });
    console.log(`[FCM] sent to topic=${topic} title="${title}"`);
  } catch (e) {
    console.error(`[FCM] failed to send to topic=${topic}:`, e.message);
  }
}

// ── Goal notification ─────────────────────────────────────────────────────────
// Fires on every match document update. Only sends if a goal was scored.

exports.onGoalScored = onDocumentUpdated(
  {
    document: "seasons/{season}/leagues/{league}/matches/{matchId}",
    database: "main",
  },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    const homeGoalsBefore = before.homeTeamGoals ?? 0;
    const awayGoalsBefore = before.awayTeamGoals ?? 0;
    const homeGoalsAfter = after.homeTeamGoals ?? 0;
    const awayGoalsAfter = after.awayTeamGoals ?? 0;

    const homeScored = homeGoalsAfter > homeGoalsBefore;
    const awayScored = awayGoalsAfter > awayGoalsBefore;

    if (!homeScored && !awayScored) return null;

    const matchId = event.params.matchId;
    const scoringTeam = homeScored ? "home" : "away";

    // Find the scorer from the events array
    const events = after.matchState?.events ?? [];
    const lastGoal = [...events]
      .reverse()
      .find((e) => e.type === "goal" && e.team === scoringTeam);

    const scorerName = lastGoal?.playerName ?? null;
    const scorerId = lastGoal?.playerId ?? null;
    const minute = lastGoal?.timeInMatch ?? null;
    const score = `${homeGoalsAfter}-${awayGoalsAfter}`;
    const scoringTeamName = homeScored ? after.homeTeam : after.awayTeam;

    const title = `GOL! ${scoringTeamName}`;
    const body = [
      scorerName,
      minute != null ? `${minute}'` : null,
      `• ${after.homeTeam} ${score} ${after.awayTeam}`,
    ]
      .filter(Boolean)
      .join(" ");

    const sends = [
      // Users who favorited this match directly
      sendToTopic(matchTopic(matchId), title, body),
      // Fans of the scoring club
      sendToTopic(clubTopic(scoringTeamName), title, body),
    ];

    // Fans of the scorer (player notification)
    if (scorerId) {
      sends.push(sendToTopic(playerTopic(scorerId), title, body));
    }

    await Promise.all(sends);
    return null;
  },
);

// ── 30-minute match reminder ──────────────────────────────────────────────────
// Runs every 5 minutes. Sends a reminder for matches starting in ~30 minutes.

exports.matchReminder = onSchedule("every 5 minutes", async () => {
  const now = new Date();
  const windowStart = new Date(now.getTime() + 25 * 60 * 1000);
  const windowEnd = new Date(now.getTime() + 35 * 60 * 1000);

  // Today's date in Croatia timezone
  const nowCroatia = new Date(now.getTime() + CROATIA_OFFSET_MS);
  const todayStr = nowCroatia.toISOString().slice(0, 10);

  console.log(
    `[matchReminder] now=${now.toISOString()} todayStr=${todayStr} window=${windowStart.toISOString()}–${windowEnd.toISOString()}`,
  );

  // Query all scheduled matches for today across all seasons/leagues
  const snap = await db
    .collectionGroup("matches")
    .where("status", "==", "scheduled")
    .where("matchDate", "==", todayStr)
    .get();

  console.log(
    `[matchReminder] found ${snap.size} scheduled matches for ${todayStr}`,
  );

  if (snap.empty) return;

  const sends = [];

  for (const doc of snap.docs) {
    const match = doc.data();
    const matchId = doc.id;
    const matchTime = match.matchTime;

    if (!matchTime || !matchTime.includes(":")) {
      console.log(
        `[matchReminder] skipping ${matchId} — invalid matchTime: ${matchTime}`,
      );
      continue;
    }

    const [h, m] = matchTime.split(":").map(Number);
    const [year, month, day] = todayStr.split("-").map(Number);

    const kickoffUTC = new Date(Date.UTC(year, month - 1, day, h - 2, m));

    console.log(
      `[matchReminder] match=${matchId} matchTime=${matchTime} kickoffUTC=${kickoffUTC.toISOString()} inWindow=${kickoffUTC >= windowStart && kickoffUTC <= windowEnd}`,
    );

    if (kickoffUTC >= windowStart && kickoffUTC <= windowEnd) {
      const title = "Utakmica uskoro počinje! ⚽";
      const body = `${match.homeTeam} vs ${match.awayTeam} za 30 minuta`;
      sends.push(sendToTopic(matchTopic(matchId), title, body));
    }
  }

  await Promise.all(sends);
});
