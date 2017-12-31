import 'dart:convert';
import 'package:lexie/lexie.dart';
import 'package:resource/resource.dart';

/// Enumerates the token types for the MTL data format.
enum MtlToken {
  word,
  integer,
  float,
  comment,
  backslash,
  newline,
  endOfText,
  invalid
}

class BaseState implements State<int, MtlToken, String> {
  const BaseState();

  Transition<int, MtlToken, String> process(int byte) {
    if (byte == 32 /* space */ ||
        byte == 9 /* tab */ ||
        byte == 13 /* carriage return */) {
      return const Transition(
          const BaseState(), const Action.discard(eatCurrentUnit: true));
    } else if (byte == 10 /* new-line */) {
      return const Transition(const BaseState(),
          const Action.emit(MtlToken.newline, eatCurrentUnit: true));
    } else if (byte == 3 /* end-of-text */) {
      return const Transition(const TerminalState(),
          const Action.emit(MtlToken.endOfText, eatCurrentUnit: true));
    } else if (byte == 35 /* # */) {
      return const Transition(const CommentState());
    } else if (byte == 45 /* - */ || byte >= 48 && byte <= 57 /* 0-9 */) {
      return const Transition(
          const IntegerState(), const Action.none(eatCurrentUnit: true));
    } else if (byte == 46 /* . */) {
      return const Transition(
          const FloatState(), const Action.none(eatCurrentUnit: true));
    } else {
      return const Transition(const WordState());
    }
  }
}

class TerminalState implements State<int, MtlToken, String> {
  const TerminalState();

  Transition<int, MtlToken, String> process(int byte) => null;
}

class CommentState implements State<int, MtlToken, String> {
  const CommentState();

  Transition<int, MtlToken, String> process(int byte) {
    if (byte == 10 /* new-line */ || byte == 3 /* end-of-text */) {
      return const Transition(
          const BaseState(), const Action.emit(MtlToken.comment));
    } else {
      return null;
    }
  }
}

class IntegerState implements State<int, MtlToken, String> {
  const IntegerState();

  Transition<int, MtlToken, String> process(int byte) {
    if (byte >= 48 && byte <= 57 /* 0-9 */) {
      return null;
    } else if (byte == 46 /* . */) {
      return const Transition(
          const FloatState(), const Action.none(eatCurrentUnit: true));
    } else if (byte == 101 /* e */ || byte == 69 /* E */) {
      return const Transition(const IntegerWithSignableExponentState(),
          const Action.none(eatCurrentUnit: true));
    } else if (byte == 32 /* space */ ||
        byte == 9 /* tab */ ||
        byte == 13 /* Carriage return */ ||
        byte == 10 /* new-line */ ||
        byte == 3 /* end-of-text */) {
      return const Transition(
          const BaseState(), const Action.emit(MtlToken.integer));
    } else {
      return const Transition(const WordState());
    }
  }
}

class IntegerWithSignableExponentState implements State<int, MtlToken, String> {
  const IntegerWithSignableExponentState();

  Transition<int, MtlToken, String> process(int byte) {
    if (byte == 45 /* - */ || byte >= 48 && byte <= 57 /* 0-9 */) {
      return const Transition(const IntegerWithExponentState(),
          const Action.none(eatCurrentUnit: true));
    } else if (byte == 32 /* space */ ||
        byte == 9 /* tab */ ||
        byte == 13 /* Carriage return */ ||
        byte == 10 /* new-line */ ||
        byte == 3 /* end-of-text */) {
      return const Transition(
          const BaseState(), const Action.emit(MtlToken.integer));
    } else {
      return const Transition(const WordState());
    }
  }
}

class IntegerWithExponentState implements State<int, MtlToken, String> {
  const IntegerWithExponentState();

  Transition<int, MtlToken, String> process(int byte) {
    if (byte >= 48 && byte <= 57 /* 0-9 */) {
      return null;
    } else if (byte == 32 /* space */ ||
        byte == 9 /* tab */ ||
        byte == 13 /* Carriage return */ ||
        byte == 10 /* new-line */ ||
        byte == 3 /* end-of-text */) {
      return const Transition(
          const BaseState(), const Action.emit(MtlToken.integer));
    } else {
      return const Transition(const WordState());
    }
  }
}

class FloatState implements State<int, MtlToken, String> {
  const FloatState();

  Transition<int, MtlToken, String> process(int byte) {
    if (byte >= 48 && byte <= 57 /* 0-9 */) {
      return null;
    } else if (byte == 101 /* e */ || byte == 69 /* E */) {
      return const Transition(const FloatWithSignableExponentState(),
          const Action.none(eatCurrentUnit: true));
    } else if (byte == 32 /* space */ ||
        byte == 9 /* tab */ ||
        byte == 13 /* Carriage return */ ||
        byte == 10 /* new-line */ ||
        byte == 3 /* end-of-text */) {
      return const Transition(
          const BaseState(), const Action.emit(MtlToken.float));
    } else {
      return const Transition(const WordState());
    }
  }
}

class FloatWithSignableExponentState implements State<int, MtlToken, String> {
  const FloatWithSignableExponentState();

  Transition<int, MtlToken, String> process(int byte) {
    if (byte == 45 /* - */ || byte >= 48 && byte <= 57 /* 0-9 */) {
      return const Transition(const FloatWithExponentState(),
          const Action.none(eatCurrentUnit: true));
    } else if (byte == 32 /* space */ ||
        byte == 9 /* tab */ ||
        byte == 13 /* Carriage return */ ||
        byte == 10 /* new-line */ ||
        byte == 3 /* end-of-text */) {
      return const Transition(
          const BaseState(), const Action.emit(MtlToken.float));
    } else {
      return const Transition(const WordState());
    }
  }
}

class FloatWithExponentState implements State<int, MtlToken, String> {
  const FloatWithExponentState();

  Transition<int, MtlToken, String> process(int byte) {
    if (byte >= 48 && byte <= 57 /* 0-9 */) {
      return null;
    } else if (byte == 32 /* space */ ||
        byte == 9 /* tab */ ||
        byte == 13 /* Carriage return */ ||
        byte == 10 /* new-line */ ||
        byte == 3 /* end-of-text */) {
      return const Transition(
          const BaseState(), const Action.emit(MtlToken.float));
    } else {
      return const Transition(const WordState());
    }
  }
}

class WordState implements State<int, MtlToken, String> {
  const WordState();

  Transition<int, MtlToken, String> process(int byte) {
    if (byte >= 33 && byte <= 126 /* any printable ASCII symbol */) {
      return null;
    } else if (byte == 32 /* space */ ||
        byte == 9 /* tab */ ||
        byte == 13 /* Carriage return */ ||
        byte == 10 /* new-line */ ||
        byte == 3 /* end-of-text */) {
      return const Transition(
          const BaseState(), const Action.emit(MtlToken.word));
    } else {
      return new Transition(
          const BaseState(),
          new Action.emit(MtlToken.invalid,
              tokenValue: 'Unexpected symbol `${new String.fromCharCode(byte)}`'
                  ' (ASCII code: $byte)',
              eatCurrentUnit: true));
    }
  }
}

void main() {
  final lexer = const AsciiDecoder().fuse(
      new UnicodeLexer(() => const BaseState()));
  final resource = new Resource('flat_green.mtl');

  resource.openRead().transform(lexer).listen((tokens) {
    print(tokens);
  });
}
