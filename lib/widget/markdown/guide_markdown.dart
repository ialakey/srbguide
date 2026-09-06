import 'dart:math' as math;

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

/// Inline image: tap to open it full screen.
///
/// Sized to the column and capped in height, so a portrait screenshot does not
/// push the rest of the article off the screen — the full-screen viewer is
/// where you go to actually read one.
///
/// Guide images are hosted on the site; some of the older ones 404, and a
/// broken image must not blow up the article.
class _GuideImage extends StatelessWidget {
  final Uri uri;
  final String? alt;

  /// Roughly half a phone screen. Past that an image stops being an
  /// illustration and becomes the page.
  static const double _maxHeight = 380;

  const _GuideImage({required this.uri, this.alt});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String url = uri.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _ImageViewer(uri: uri, title: alt ?? ''),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: _maxHeight),
            child: Stack(
              children: <Widget>[
                Hero(
                  tag: url,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (
                      BuildContext context,
                      Widget child,
                      ImageChunkEvent? progress,
                    ) {
                      if (progress == null) return child;
                      return Container(
                        height: 160,
                        width: double.infinity,
                        alignment: Alignment.center,
                        color: scheme.surfaceContainerHighest,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (_, __, ___) => _BrokenImage(alt: alt),
                  ),
                ),
                // Says the image opens, which a plain picture does not.
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(
                        Icons.zoom_out_map,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrokenImage extends StatelessWidget {
  final String? alt;

  const _BrokenImage({required this.alt});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
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
    );
  }
}

/// Full-screen image: pinch, double-tap or the toolbar buttons to zoom.
///
/// The buttons are there because the two gestures are invisible, and because
/// zooming a screenshot one-handed is exactly when a second finger is missing.
class _ImageViewer extends StatefulWidget {
  final Uri uri;
  final String title;

  const _ImageViewer({required this.uri, required this.title});

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  /// Zoom per press, and how many presses deep the buttons go. 1.6^4 is a bit
  /// under the 6x ceiling below, so the top step is always reachable.
  static const double _step = 1.6;
  static const int _maxSteps = 4;
  static const double _maxScale = 6;

  final PhotoViewController _controller = PhotoViewController();
  final PhotoViewScaleStateController _scaleState =
      PhotoViewScaleStateController();

  /// Scale at which the image fits the screen. PhotoView computes it from the
  /// image and viewport sizes, neither of which is known until it has laid the
  /// image out, so it is read off the controller on the way out of step 0.
  double? _fitted;
  int _steps = 0;

  @override
  void initState() {
    super.initState();
    _scaleState.addIgnorableListener(_followGestures);
  }

  @override
  void dispose() {
    _scaleState.removeIgnorableListener(_followGestures);
    _scaleState.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// A double-tap back to the fitted size resets the buttons too, so the next
  /// press zooms rather than doing nothing.
  void _followGestures() {
    if (_scaleState.scaleState == PhotoViewScaleState.initial) _steps = 0;
  }

  void _zoom(int delta) {
    final int next = (_steps + delta).clamp(0, _maxSteps);
    if (next == _steps) return;
    // At step 0 the controller holds exactly the fitted scale.
    if (_steps == 0) _fitted = _controller.scale;
    _steps = next;

    if (_steps == 0) {
      // Let PhotoView work the fit out again rather than trusting a number
      // cached before a rotation or a keyboard.
      _scaleState.scaleState = PhotoViewScaleState.initial;
      return;
    }
    final double fitted = _fitted ?? _controller.scale ?? 1;
    _controller.scale = fitted * math.pow(_step, _steps).toDouble();
    _scaleState.scaleState = PhotoViewScaleState.zoomedIn;
  }

  @override
  Widget build(BuildContext context) {
    final String url = widget.uri.toString();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () => _zoom(-1),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => _zoom(1),
          ),
        ],
      ),
      body: PhotoView(
        imageProvider: NetworkImage(url),
        controller: _controller,
        scaleStateController: _scaleState,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        heroAttributes: PhotoViewHeroAttributes(tag: url),
        initialScale: PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.contained * _maxScale,
        loadingBuilder: (BuildContext context, ImageChunkEvent? progress) {
          final int? total = progress?.expectedTotalBytes;
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
              value: total == null || total == 0
                  ? null
                  : progress!.cumulativeBytesLoaded / total,
            ),
          );
        },
        errorBuilder: (_, __, ___) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Изображение недоступно',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}
