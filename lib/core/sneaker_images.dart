/// Free-to-use sneaker photography from Unsplash (https://unsplash.com/license).
/// Every photo below was reviewed by hand: sneakers only, editorial / studio style.
///
/// Used when the API sends no image, or always when
/// [SneakerImages.forceDemoPhotos] = true (demo mode).
class SneakerImages {
  /// false → use the sneaker photos uploaded in the dashboard (default — the
  ///         store's products, categories and banners now have pro photos).
  /// true  → always show the curated photos below instead.
  static const forceDemoPhotos = false;

  static String _u(String id, {int w = 900}) =>
      'https://images.unsplash.com/photo-$id?auto=format&fit=crop&w=$w&q=80';

  /// Product shots (clean sneaker, studio or minimal background)
  static final products = <String>[
    _u('1608231387042-66d1773070a5'), // white low-top on black
    _u('1542291026-7eec264c27ff'), // red runner
    _u('1600185365926-3a2ce3cdb9eb'), // white/orange, light bg
    _u('1491553895911-0055eca6402d'), // floating grey runner
    _u('1543508282-6319a3e2621f'), // black low on white plinth
    _u('1600185365483-26d7a4cc7519'), // white & coral
    _u('1606107557195-0e29a4b5b4aa'), // neon green trainer
    _u('1605408499391-6368c628ef42'), // black & white on lilac
    _u('1549298916-b41d501d3772'), // tan leather on mustard
    _u('1512374382149-233c42b6a83b'), // white high-tops
    _u('1595950653106-6c9ebd614d3a'), // pastel low-top
    _u('1600269452121-4f2416e55c28'), // white leather on black
    _u('1597045566677-8cf032ed6634'), // black/red high-top, graphic
    _u('1525966222134-fcfa99b8ae77'), // burgundy skate shoe on yellow
    _u('1607522370275-f14206abe5d3'), // red canvas high-top on blue
    _u('1584735175315-9d5df23860e6'), // peach high-top
    _u('1588361861040-ac9b1018f6d5'), // grey leather pair on black
    _u('1579338559194-a162d19bf842'), // white low on blue court
    _u('1515955656352-a1fa3ffcd111'), // electric blue runner
    _u('1603808033192-082d6919d3e1'), // cream minimal on orange
    _u('1608667508764-33cf0726b13a'), // pink chunky runner
    _u('1551107696-a4b0c5a0d9a2'), // pink/grey on black
    _u('1539185441755-769473a23570'), // olive runner, dark
    _u('1465453869711-7e174808ace9'), // lavender & peach runner
    _u('1605348532760-6753d2c43329'), // black trainer on sky blue
    _u('1611510338559-2f463335092c'), // white/red high-top held
    _u('1575537302964-96cd47c06b1b'), // red suede high-top
    _u('1597248881519-db089d3744a5'), // yellow/white high-top
  ];

  /// Wide editorial shots for banners and hero backgrounds
  static final heroes = <String>[
    _u('1552346154-21d32810aba3', w: 1400), // black/red high-tops close-up
    _u('1597248881519-db089d3744a5', w: 1400), // yellow high-top on yellow
    _u('1514989940723-e8e51635b782', w: 1400), // orange air runner, street
    _u('1595341888016-a392ef81b7de', w: 1400), // multicolour runner, urban
    _u('1575537302964-96cd47c06b1b', w: 1400), // red suede on white
    _u('1460353581641-37baddab0fa2', w: 1400), // runners on concrete
    _u('1608231387042-66d1773070a5', w: 1400), // white low-top, dark
    _u('1539185441755-769473a23570', w: 1400), // olive runner, moody
  ];

  /// Lifestyle shots (on feet / in scene) for onboarding & store page
  static final lifestyle = <String>[
    _u('1556906781-9a412961c28c', w: 1200), // sitting on a rooftop
    _u('1586525198428-225f6f12cff5', w: 1200), // laced up, on feet
    _u('1604671801908-6f0c6a092c05', w: 1200), // neon glow pair
    _u('1628253747716-0c4f5c90fdda', w: 1200), // yellow pair on box
  ];

  static const slides =
      'https://images.unsplash.com/photo-1606846865025-883b347b9b9a?auto=format&fit=crop&w=900&q=80';

  static int _hash(String s) =>
      s.codeUnits.fold(7, (h, c) => (h * 31 + c) & 0x7fffffff);

  /// Stable image per product, derived from its id
  static String forId(String id, [int offset = 0]) =>
      products[(_hash(id) + offset) % products.length];

  /// 4-image gallery for a product
  static List<String> galleryFor(String id) =>
      List.generate(4, (i) => forId(id, i * 7));

  static String hero(int i) => heroes[i % heroes.length];

  static String life(int i) => lifestyle[i % lifestyle.length];

  /// Category image: slides get their own photo
  static String forCategory(String name, int i) {
    final n = name.toLowerCase();
    if (n.contains('slide') || n.contains('sandal') ||
        n.contains('شبش') || n.contains('صندل')) {
      return slides;
    }
    return products[(i * 5 + 2) % products.length];
  }
}
