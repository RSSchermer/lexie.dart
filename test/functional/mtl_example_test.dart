import 'dart:convert';

import 'package:lexie/lexie.dart';
import 'package:resource/resource.dart';
import 'package:test/test.dart';

import '../../example/mtl/main.dart';

void main() {
  group('MTL example', () {
    test('Produces the correct tokens', () async {
      final lexer = const AsciiDecoder().fuse(
          new UnicodeLexer(() => const BaseState()));
      final resource = new Resource('example/mtl/flat_green.mtl');

      final tokens = await resource.openRead().transform(lexer)
          .fold([], (res, tokens) => res..addAll(tokens));

      expect(tokens, equals([
        const Token(MtlToken.comment, '# A flat green material.', 0),
        const Token(MtlToken.newline, '\n', 24),
        const Token(MtlToken.comment, '#', 24),
        const Token(MtlToken.newline, '\n', 26),
        const Token(MtlToken.comment, '# Example taken from the MTL specification.', 26),
        const Token(MtlToken.newline, '\n', 70),
        const Token(MtlToken.newline, '\n', 70),
        const Token(MtlToken.word, 'newmtl', 71),
        const Token(MtlToken.word, 'flat_green', 78),
        const Token(MtlToken.newline, '\n', 89),
        const Token(MtlToken.word, 'Ka', 89),
        const Token(MtlToken.float, '0.0000', 92),
        const Token(MtlToken.float, '1.0000', 99),
        const Token(MtlToken.float, '0.0000', 106),
        const Token(MtlToken.newline, '\n', 113),
        const Token(MtlToken.word, 'Kd', 113),
        const Token(MtlToken.float, '0.0000', 116),
        const Token(MtlToken.float, '1.0000', 123),
        const Token(MtlToken.float, '0.0000', 130),
        const Token(MtlToken.newline, '\n', 137),
        const Token(MtlToken.word, 'illum', 137),
        const Token(MtlToken.integer, '1', 143),
        const Token(MtlToken.newline, '\n', 145)
      ]));
    });
  });
}
