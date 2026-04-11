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

  Map<String, dynamic> toJson() => {
    'type': type,
    'team': team,
    'period': period,
    'playerId': playerId,
    'playerName': playerName,
    'shirtNumber': shirtNumber,
    'timeInMatch': timeInMatch,
    'timestamp': timestamp.toIso8601String(),
  };

  factory MatchEvent.fromJson(Map<String, dynamic> map) => MatchEvent(
    type: map['type'] as String,
    team: map['team'] as String,
    period: map['period'] as String,
    playerId: map['playerId'] as String,
    playerName: map['playerName'] as String,
    shirtNumber: map['shirtNumber'] as String,
    timeInMatch: map['timeInMatch'] as int,
    timestamp: DateTime.parse(map['timestamp'] as String),
  );

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