const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const {
  onDocumentUpdated,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");

initializeApp();

const db = getFirestore("main");

// Croatia is UTC+2 in summer, UTC+1 in winter — derive the offset from the
// Europe/Zagreb zone so DST switches are handled automatically.
const CROATIA_TZ = "Europe/Zagreb";
const zagrebFormatter = new Intl.DateTimeFormat("en-US", {
  timeZone: CROATIA_TZ,
  hourCycle: "h23",
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
  hour: "2-digit",
  minute: "2-digit",
  second: "2-digit",
});

// Offset of Croatian local time from UTC (ms) at the given instant.
function croatiaOffsetMs(date) {
  const parts = Object.fromEntries(
    zagrebFormatter.formatToParts(date).map((p) => [p.type, p.value]),
  );
  const asUTC = Date.UTC(
    Number(parts.year),
    Number(parts.month) - 1,
    Number(parts.day),
    Number(parts.hour),
    Number(parts.minute),
    Number(parts.second),
  );
  return asUTC - Math.floor(date.getTime() / 1000) * 1000;
}

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

// Regular season, playoff (Finale + Ligaška) and tournament match documents
// share the same shape, so one handler serves all four triggers.
async function handleGoalScored(event) {
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
}

const GOAL_TRIGGER_PATHS = {
  onGoalScored: "seasons/{season}/leagues/{league}/matches/{matchId}",
  onPlayoffGoalScored: "seasons/{season}/playoff/{playoffId}/matches/{matchId}",
  onLigaskaGoalScored:
    "seasons/{season}/playoff/{playoffId}/groups/{groupId}/matches/{matchId}",
  onTournamentGoalScored: "tournaments/{tournamentId}/matches/{matchId}",
};

for (const [name, document] of Object.entries(GOAL_TRIGGER_PATHS)) {
  exports[name] = onDocumentUpdated(
    { document, database: "main" },
    handleGoalScored,
  );
}

// ── News published notification ───────────────────────────────────────────────
// Fires when a news article becomes active (created active, or flipped
// isActive false → true). All app installs subscribe to the "news" topic.

exports.onNewsPublished = onDocumentWritten(
  {
    document: "seasons/{season}/news/{newsId}",
    database: "main",
  },
  async (event) => {
    const after = event.data.after.exists ? event.data.after.data() : null;
    if (!after) return null; // deleted

    const before = event.data.before.exists ? event.data.before.data() : null;
    const wasActive = before?.isActive === true;
    const isActive = after.isActive === true;
    if (wasActive || !isActive) return null; // only on publish transition

    const title = "Nova vijest 📰";
    const body = after.header ?? "";
    await sendToTopic("news", title, body);
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
  const nowCroatia = new Date(now.getTime() + croatiaOffsetMs(now));
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

    // Kickoff wall-clock time read as UTC, then shifted by Croatia's offset
    // on that day (DST switches happen at night, never around kickoff).
    const kickoffWall = new Date(Date.UTC(year, month - 1, day, h, m));
    const kickoffUTC = new Date(
      kickoffWall.getTime() - croatiaOffsetMs(kickoffWall),
    );

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
