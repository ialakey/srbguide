class ContentUtil {
  String removeATags(String htmlString) {
    String contentWithoutATags;
    final patternTagA = RegExp(r'<a\b[^>]*>(.*?)<\/a>');
    final patternTagCard = RegExp(r'<card>|<\/card>');
    contentWithoutATags = htmlString.replaceAll(patternTagA, '');
    contentWithoutATags.replaceAll(patternTagCard, '');
    return contentWithoutATags;
  }
}