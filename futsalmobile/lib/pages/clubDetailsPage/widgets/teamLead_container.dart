import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/team_lead_data.dart';
import 'package:futsalmobile/widgets/cached_image.dart';

/// Voditelj card. With several voditelji it shows one card with overlapping
/// photos and "+N"; tapping it opens a sheet listing all of them.
class TeamleadContainer extends StatelessWidget {
  const TeamleadContainer({
    super.key,
    required this.screenHeight,
    this.teamLeads = const [],
  });

  final double screenHeight;

  /// Empty when the club has no voditelj entered.
  final List<TeamLeadData> teamLeads;

  static const _avatarSize = 50.0;

  /// How far each extra avatar is shifted right in the stack.
  static const _avatarStep = 22.0;

  /// Avatars drawn in the stack; the rest are counted in "+N".
  static const _maxStacked = 3;

  bool get _isMultiple => teamLeads.length > 1;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _isMultiple ? () => _showAll(context) : null,
        child: Container(
          width: double.infinity,
          height: screenHeight * 0.08,
          decoration: BoxDecoration(
            color: AppColors.ternary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              _isMultiple
                  ? _avatarStack()
                  : _avatar(teamLeads.isEmpty ? null : teamLeads.first),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isMultiple
                          ? "Voditelji (${teamLeads.length})"
                          : "Voditelj",
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ternaryGray,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _title(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isMultiple)
                Icon(Icons.chevron_right, color: AppColors.ternaryGray),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }

  String _title() {
    if (teamLeads.isEmpty) return "Voditelj nije upisan";
    if (!_isMultiple) return teamLeads.first.fullName;
    final others = teamLeads.length - 1;
    return "${teamLeads.first.fullName} i još $others";
  }

  Widget _avatarStack() {
    final shown = teamLeads.take(_maxStacked).toList();
    final extra = teamLeads.length - shown.length;
    final count = shown.length + (extra > 0 ? 1 : 0);
    return SizedBox(
      width: _avatarSize + _avatarStep * (count - 1),
      height: _avatarSize,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(left: _avatarStep * i, child: _avatar(shown[i])),
          if (extra > 0)
            Positioned(
              left: _avatarStep * shown.length,
              child: _circle(
                child: Container(
                  color: const Color(0xFFEEEEEE),
                  alignment: Alignment.center,
                  child: Text(
                    "+$extra",
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.ternaryGray,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAll(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  "Voditelji",
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: teamLeads.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                    color: Color(0xFFF0F0F0),
                  ),
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        _avatar(teamLeads[i]),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            teamLeads[i].fullName,
                            style: TextStyle(
                              fontFamily: AppFonts.roboto,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(TeamLeadData? lead) {
    final url = lead?.profilePicture ?? '';
    return _circle(
      child: url.isEmpty
          ? _photoFallback()
          : CachedImage(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_) => _photoFallback(),
            ),
    );
  }

  Widget _circle({required Widget child}) => Container(
    width: _avatarSize,
    height: _avatarSize,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.ternaryGray),
    ),
    child: ClipOval(child: child),
  );

  Widget _photoFallback() =>
      Image.asset("assets/images/defProfile.png", fit: BoxFit.cover);
}
