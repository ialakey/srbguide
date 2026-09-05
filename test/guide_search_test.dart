import 'package:flutter_test/flutter_test.dart';
import 'package:srbguide/data/guide_dto.dart';
import 'package:srbguide/data/guide_repository.dart';

GuideArticle _article({
  required String title,
  String lead = '',
  String body = '',
  String section = 'Личное',
  String slug = 'personal',
}) =>
    GuideArticle(
      smile: '📄',
      title: title,
      lead: lead,
      description: body,
      source: 'https://www.srb.guide/guides/$slug/${title.hashCode}/',
      updated: '',
      sectionTitle: section,
      sectionSlug: slug,
    );

GuideContent _content(List<GuideArticle> articles) => GuideContent(
      source: 'https://www.srb.guide',
      syncedAt: DateTime(2026, 1, 1),
      sections: <GuideSection>[
        GuideSection(
          slug: 'personal',
          title: 'Личное',
          smile: '👤',
          icon: 'person',
          items: articles
              .where((GuideArticle a) => a.sectionSlug == 'personal')
              .toList(),
        ),
        GuideSection(
          slug: 'banks',
          title: 'Банки',
          smile: '🏦',
          icon: 'bank',
          items: articles
              .where((GuideArticle a) => a.sectionSlug == 'banks')
              .toList(),
        ),
      ],
    );

void main() {
  final GuideRepository repo = GuideRepository.instance;

  final GuideContent content = _content(<GuideArticle>[
    _article(title: 'Белый картон', lead: 'Регистрация по месту проживания'),
    _article(
      title: 'Аренда жилья',
      lead: 'Как снять квартиру',
      body: 'Хозяин квартиры делает белый картон в полиции.',
    ),
    _article(
      title: 'Банки',
      slug: 'banks',
      section: 'Банки',
      lead: 'Какие банки открывают счёт',
    ),
    _article(
      title: 'Райфайзен',
      slug: 'banks',
      section: 'Банки',
      body: 'В этом банке нерезиденту нужен белый картон.',
    ),
  ]);

  test('finds an article by its exact title', () {
    final List<SearchHit> hits = repo.search(content, 'Белый картон');
    expect(hits, isNotEmpty);
    expect(hits.first.article.title, 'Белый картон');
    expect(hits.first.rank, 0);
  });

  test('inflected query still matches — the reason stemming exists', () {
    // "банка" must find "Банки"; a plain substring search would not.
    final List<SearchHit> hits = repo.search(content, 'банка');
    expect(hits.map((SearchHit h) => h.article.title), contains('Банки'));
  });

  test('title matches rank above body matches', () {
    final List<SearchHit> hits = repo.search(content, 'картон');
    expect(hits.length, greaterThan(1));
    expect(hits.first.article.title, 'Белый картон');
    // The article that only mentions it in the body comes later.
    expect(
        hits.map((SearchHit h) => h.article.title), contains('Аренда жилья'));
  });

  test('every term has to match, so extra words narrow the results', () {
    final List<SearchHit> broad = repo.search(content, 'картон');
    final List<SearchHit> narrow = repo.search(content, 'картон полиции');
    expect(narrow.length, lessThan(broad.length));
    expect(narrow.single.article.title, 'Аренда жилья');
  });

  test('section filter restricts the results', () {
    final List<SearchHit> all = repo.search(content, 'картон');
    final List<SearchHit> banksOnly =
        repo.search(content, 'картон', sectionSlug: 'banks');
    expect(banksOnly.length, lessThan(all.length));
    expect(
      banksOnly.every((SearchHit h) => h.article.sectionSlug == 'banks'),
      isTrue,
    );
  });

  test('a body-only hit gets a snippet showing why it matched', () {
    final List<SearchHit> hits =
        repo.search(content, 'полиции', sectionSlug: 'personal');
    expect(hits, hasLength(1));
    expect(hits.single.rank, 2);
    expect(hits.single.snippet, contains('полиции'));
  });

  test('empty and whitespace queries return nothing', () {
    expect(repo.search(content, ''), isEmpty);
    expect(repo.search(content, '   '), isEmpty);
  });

  test('a query that matches nothing returns nothing', () {
    expect(repo.search(content, 'зимбабве'), isEmpty);
  });
}
