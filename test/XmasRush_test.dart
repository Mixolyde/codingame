import '../bin/XmasRush_Original.dart';
import 'package:test/test.dart';

void main() {  
  print('XmasRush_test.dart');
  group('dart math', (){
    test('truncate', (){
      expect((2.1).truncate(), 2);
      expect((2.9).truncate(), 2);
      expect((-2.1).truncate(), -2);
      expect((-2.9).truncate(), -2);      
    });
  });
}