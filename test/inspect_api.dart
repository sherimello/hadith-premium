import 'package:hadith/hadith.dart';

void main() async {
  var service = HadithService();
  var collections = await service.getCollections();
  print('Collections type: ${collections.runtimeType}');
  if (collections.isNotEmpty) {
    var c = collections.first;
    print('First collection: $c');
    print('Collection type: ${c.runtimeType}');

    // Check if we can get books
    try {
      var books = await service.getBooks(c);
      print('Books count for first collection: ${books.length}');
      if (books.isNotEmpty) {
        var b = books.first;
        print('First book: $b');
        // Check if we can get hadiths
        // NOTE: getBooks returns List<Book>. A Book likely has a number or id.
        // In the example: service.getBooks(Collection.bukhari)
        // In the example: service.getHadiths(Collection.bukhari, 1) -> 1 is likely book number.

        // Let's inspect Book object properties
        // print('Book properties: ${b.toJson()}'); // if it has toJson
      }
    } catch (e) {
      print('Error getting books: $e');
    }
  }
}
