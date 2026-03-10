import 'package:flutter/material.dart';

import 'app_theme.dart';

Color riskColor(String status) {
  switch (status.toLowerCase()) {
    case 'safe':
      return AppTheme.safe;
    case 'warning':
      return AppTheme.warning;
    default:
      return AppTheme.critical;
  }
}

String riskLabel(String status) {
  switch (status.toLowerCase()) {
    case 'safe':
      return 'Stable';
    case 'warning':
      return 'Watch';
    default:
      return 'Action';
  }
}
