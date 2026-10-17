import 'package:flutter_test/flutter_test.dart';
import 'package:futsalmobile/utils/name_format.dart';

void main() {
  test('formatPersonName', () {
    expect(formatPersonName('LUKA BURCUL'), 'Luka Burcul');
    expect(formatPersonName('DINO SUSAK VRHAR'), 'Dino Susak Vrhar');
    expect(formatPersonName('  Duje  Predovan '), 'Duje Predovan');
    expect(formatPersonName('ŠIME ZDRILIĆ'), 'Šime Zdrilić');
    expect(formatPersonName('đani milin'), 'Đani Milin');
    expect(formatPersonName('ANTE JOSIĆ-JURJEVIĆ'), 'Ante Josić-Jurjević');
    expect(formatPersonName("O'NEIL"), "O'Neil");
    expect(formatPersonName('Ante perinić'), 'Ante Perinić');
    expect(formatPersonName(null), '');
  });
}
