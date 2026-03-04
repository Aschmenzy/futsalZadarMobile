class MatchEvent {
  final String type;        // "goal" | "ownGoal" | "yellowCard" | "redCard" | "timeout"
  final String team;        // "home" | "away"
  final String period;      // "1st" | "2nd" | "ot" | "penalties"
  final String playerId;
  final String playerName;
  final String shirtNumber;
  final int timeInMatch;    // seconds
  final DateTime timestamp;

  const MatchEvent({
    required this.type,
    required this.team,
    required this.period,
    required this.playerId,
    required this.playerName,
    required this.shirtNumber,
    required this.timeInMatch,
    required this.timestamp,
  });

  factory MatchEvent.fromFirestore(Map<String, dynamic> map) {
    return MatchEvent(
      type: map['type'] ?? '',
      team: map['team'] ?? '',
      period: map['period'] ?? '',
      playerId: map['playerId'] ?? '',
      playerName: map['playerName'] ?? '',
      shirtNumber: map['shirtNumber'] ?? '',
      timeInMatch: map['timeInMatch'] ?? 0,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}