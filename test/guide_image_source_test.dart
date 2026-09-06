import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../tool/sync_guide.dart';

Element _img(String html) => html_parser.parse(html).querySelector('img')!;

void main() {
  group('imageSourceOf', () {
    test('ignores the lazyload placeholder and takes the real file', () {
      // Verbatim from srb.guide: `src` is a 462-byte blurred placeholder, and
      // reading it is how the guide came to bundle blurred thumbnails.
      final Element img = _img('''
<img class="lazyload blur-up"
     src=/media/soko_hu_6409ba5140e498ce.webp
     data-srcset="/media/soko_hu_5ff2835af7f1cbf4.webp 480w,
                  /media/soko_hu_d7ffa45e1fa2314a.webp 1080w,
                  /media/soko_hu_f8dc2351730306dc.webp 1280w,
                  /media/soko_hu_84edf71be60ce158.webp 1600w,
                  /media/soko_hu_f4cfac69790844bb.webp 2268w"
     data-src=/media/soko_hu_f4cfac69790844bb.webp alt="Soko">
''');
      // 1280w is the widest a phone can use; 2268w is twelve times the bytes.
      expect(imageSourceOf(img), '/media/soko_hu_f8dc2351730306dc.webp');
    });

    test('falls back to data-src when there is no srcset', () {
      final Element img = _img(
        '<img class="lazyload" src=/media/tiny.webp data-src=/media/real.webp>',
      );
      expect(imageSourceOf(img), '/media/real.webp');
    });

    test('uses src when the image is not lazy-loaded', () {
      final Element img = _img('<img src=/media/plain.png alt="Plain">');
      expect(imageSourceOf(img), '/media/plain.png');
    });

    test('is empty when there is nothing to load', () {
      expect(imageSourceOf(_img('<img alt="broken">')), isEmpty);
    });
  });

  group('widestUnderCap', () {
    test('takes the widest candidate within the cap', () {
      expect(
        widestUnderCap('/a.webp 480w, /b.webp 1080w, /c.webp 1280w'),
        '/c.webp',
      );
    });

    test('takes the smallest when every candidate is over the cap', () {
      expect(widestUnderCap('/big.webp 1600w, /huge.webp 2268w'), '/big.webp');
    });

    test('survives the whitespace and line breaks the site emits', () {
      expect(
        widestUnderCap('  /a.webp   480w ,\n  /b.webp\t720w  '),
        '/b.webp',
      );
    });

    test('ignores candidates with no width, and an empty set', () {
      expect(widestUnderCap('/a.webp, /b.webp 720w'), '/b.webp');
      expect(widestUnderCap(''), isEmpty);
      expect(widestUnderCap('/a.webp'), isEmpty);
    });
  });
}
