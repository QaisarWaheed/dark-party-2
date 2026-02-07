String formatNumberReadable(num number) {
  if (number >= 1000000000000) {
    double trillions = number / 1000000000000;
    return '${trillions.toStringAsFixed(trillions.truncateToDouble() == trillions ? 0 : 1)}T';
  } else if (number >= 1000000000) {
    double billions = number / 1000000000;
    return '${billions.toStringAsFixed(billions.truncateToDouble() == billions ? 0 : 1)}B';
  } else if (number >= 1000000) {
    double millions = number / 1000000;
    return '${millions.toStringAsFixed(millions.truncateToDouble() == millions ? 0 : 1)}M';
  } else if (number >= 1000) {
    double thousands = number / 1000;
    return '${thousands.toStringAsFixed(thousands.truncateToDouble() == thousands ? 0 : 1)}K';
  } else {
    return number.toString();
  }
}