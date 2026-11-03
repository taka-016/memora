const _weekdays = {'MO': '月', 'TU': '火', 'WE': '水', 'TH': '木', 'FR': '金', 'SA': '土', 'SU': '日'};

String _weekday(String value) {
  final match = RegExp(r'^([+-]?\d+)?(MO|TU|WE|TH|FR|SA|SU)$').firstMatch(value);
  if (match == null) return value;
  final day = _weekdays[match[2]]!;
  final ordinal = int.tryParse(match[1] ?? '');
  return switch (ordinal) {
    null => day,
    -1 => '最終$day',
    < 0 => '末尾から${-ordinal}番目の$day',
    _ => '第$ordinal$day',
  };
}

String _date(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  final day = '${date.year}/${date.month}/${date.day}';
  if (!value.contains('T')) return day;
  String two(int n) => n.toString().padLeft(2, '0');
  return '$day ${two(date.hour)}:${two(date.minute)}:${two(date.second)}${date.isUtc ? ' UTC' : ''}';
}

String externalCalendarRecurrenceText(String value) {
  final colon = value.indexOf(':');
  if (colon < 0) return value;
  final property = value.substring(0, colon);
  final body = value.substring(colon + 1);
  if (property.startsWith('EXDATE') || property.startsWith('RDATE')) {
    final zone = RegExp(r'TZID=([^;:]+)').firstMatch(property)?.group(1);
    return '${property.startsWith('EXDATE') ? '除外日' : '追加日'}${zone == null ? '' : ' ($zone)'}: ${body.split(',').map(_date).join('・')}';
  }
  if (property != 'RRULE' && property != 'EXRULE') return value;
  final fields = <String, String>{};
  for (final part in body.split(';')) {
    final equals = part.indexOf('=');
    if (equals > 0) fields[part.substring(0, equals)] = part.substring(equals + 1);
  }
  const units = {'YEARLY': '年', 'MONTHLY': 'か月', 'WEEKLY': '週間', 'DAILY': '日', 'HOURLY': '時間', 'MINUTELY': '分', 'SECONDLY': '秒'};
  final frequency = fields['FREQ'];
  final unit = units[frequency];
  final parts = <String>[
    if (unit != null) '${fields['INTERVAL'] ?? '1'}$unitごと',
    if (unit == null && frequency != null) '頻度: $frequency',
    if (fields['BYDAY'] != null) '曜日: ${fields['BYDAY']!.split(',').map(_weekday).join('・')}',
    if (fields['BYMONTH'] != null) '月: ${fields['BYMONTH']}',
    if (fields['BYMONTHDAY'] != null) '日: ${fields['BYMONTHDAY']!.split(',').map((v) => v == '-1' ? '月末' : v).join('・')}',
    if (fields['COUNT'] != null) '${fields['COUNT']}回',
    if (fields['UNTIL'] != null) '終了: ${_date(fields['UNTIL']!)}',
    if (fields['COUNT'] == null && fields['UNTIL'] == null) '終了なし',
    if (fields['WKST'] != null) '週の開始: ${_weekday(fields['WKST']!)}',
  ];
  const otherLabels = {'BYSETPOS': '候補内の順番', 'BYYEARDAY': '年内の日番号', 'BYWEEKNO': '週番号', 'BYHOUR': '時', 'BYMINUTE': '分', 'BYSECOND': '秒'};
  const displayed = {'FREQ', 'INTERVAL', 'BYDAY', 'BYMONTH', 'BYMONTHDAY', 'COUNT', 'UNTIL', 'WKST'};
  for (final entry in fields.entries.where((entry) => !displayed.contains(entry.key))) {
    parts.add('${otherLabels[entry.key] ?? entry.key}: ${entry.value}');
  }
  return '${property == 'EXRULE' ? '除外する繰り返し: ' : ''}${parts.join('、')}';
}
