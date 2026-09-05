import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:photo_view/photo_view.dart';

/// Renders a guide article.
///
/// The previous renderer split the Markdown on `\n` and built a separate
/// `MarkdownBody` per line, which broke every construct that spans lines —
/// lists, tables and block quotes all collapsed into unrelated fragments. This
/// hands the whole document to the parser once.
class GuideMarkdown extends StatelessWidget {
  final String data;

  /// Body font size in logical pixels, controlled by the reader's text-size
  /// setting.
  final double textSize;

  final void Function(String href) onTapLink;

  const GuideMarkdown({
    super.key,
    required this.data,
    required this.textSize,
    required this.onTapLink,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return MarkdownBody(
      data: data,
      selectable: true,
      fitContent: false,
      onTapLink: (String text, String? href, String title) {
        if (href != null && href.isNotEmpty) onTapLink(href);
      },
      imageBuilder: (Uri uri, String? title, String? alt) =>
          _GuideImage(uri: uri, alt: alt),
      styleSheet: _styleSheet(theme, scheme),
    );
  }

  MarkdownStyleSheet _styleSheet(ThemeData theme, ColorScheme scheme) {
    final TextStyle body = TextStyle(
      fontSize: textSize,
      height: 1.5,
      color: scheme.onSurface,
    );

    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: body,
      pPadding: const EdgeInsets.only(bottom: 10),
      listBullet: body,
      listIndent: 20,
      h1: TextStyle(
        fontSize: textSize + 10,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        height: 1.3,
      ),
      h1Padding: const EdgeInsets.only(top: 20, bottom: 8),
      h2: TextStyle(
        fontSize: textSize + 6,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        height: 1.3,
      ),
      h2Padding: const EdgeInsets.only(top: 20, bottom: 8),
      h3: TextStyle(
        fontSize: textSize + 3,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
        height: 1.3,
      ),
      h3Padding: const EdgeInsets.only(top: 16, bottom: 6),
      h4: TextStyle(
        fontSize: textSize + 1,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      h4Padding: const EdgeInsets.only(top: 12, bottom: 4),
      a: TextStyle(
        fontSize: textSize,
        color: scheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: scheme.primary.withValues(alpha: 0.4),
      ),
      strong: TextStyle(fontSize: textSize, fontWeight: FontWeight.w700),
      em: TextStyle(fontSize: textSize, fontStyle: FontStyle.italic),
      code: TextStyle(
        fontSize: textSize - 1,
        fontFamily: 'monospace',
        backgroundColor: scheme.surfaceContainerHighest,
        color: scheme.onSurface,
      ),
      codeblockDecoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      // Alerts from the site arrive as block quotes; give them a tinted card
      // with an accent rule so warnings read as warnings.
      blockquote: body,
      blockquotePadding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      blockquoteDecoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: scheme.primary, width: 4),
        ),
      ),
      tableHead: TextStyle(
        fontSize: textSize - 1,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      tableBody: TextStyle(fontSize: textSize - 1, color: scheme.onSurface),
      tableBorder: TableBorder.all(color: scheme.outlineVariant, width: 1),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
    );
  }
}

/// Inline image with a tap-to-zoom viewer and a graceful failure state.
///
/// Guide images are hosted on the site; some of the older ones 404, and a
/// broken image should not blow up the article.
class _GuideImage extends StatelessWidget {
  final Uri uri;
  final String? alt;

  const _GuideImage({required this.uri, this.alt});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _ImageViewer(uri: uri, title: alt ?? ''),
            ),
          ),
          child: Image.network(
            uri.toString(),
            fit: BoxFit.contain,
            loadingBuilder: (BuildContext context, Widget child,
                ImageChunkEvent? progress) {
              if (progress == null) return child;
              return Container(
                height: 160,
                alignment: Alignment.center,
                color: scheme.surfaceContainerHighest,
                child: const CircularProgressIndicator(strokeWidth: 2),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              padding: const EdgeInsets.all(16),
              color: scheme.surfaceContainerHighest,
              child: Row(
                children: <Widget>[
                  Icon(Icons.image_not_supported_outlined,
                      color: scheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      alt?.isNotEmpty == true ? alt! : 'Изображение недоступно',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageViewer extends StatelessWidget {
  final Uri uri;
  final String title;

  const _ImageViewer({required this.uri, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontSize: 16)),
      ),
      body: PhotoView(
        imageProvider: NetworkImage(uri.toString()),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 4,
      ),
    );
  }
}
