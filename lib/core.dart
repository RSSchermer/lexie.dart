library lexie.core;

import 'dart:convert';

typedef State<S, T, L> StateFactory<S, T, L>();
typedef Lexemizer<S, U, L> LexemizerFactory<S, U, L>();

abstract class Token<T, L> {
  T get type;

  L get lexeme;

  int get offset;

  const factory Token(T type, L lexeme, int offset) = _SimpleToken<T, L>;
}

class Lexer<S, U, T, L> extends Converter<S, List<Token<T, L>>> {
  final TokenProvider<T, L> tokenProvider;

  final LexemizerFactory<S, U, L> makeLexemizer;

  final StateFactory<U, T, L> makeInitialState;

  const Lexer(this.makeLexemizer, this.makeInitialState,
      {this.tokenProvider = const SimpleTokenFactory()});

  List<Token<T, L>> convert(S source) => new _LexingSession(
          makeLexemizer()..add(source), tokenProvider, makeInitialState())
      .gatherTokens();

  Sink<S> startChunkedConversion(Sink<List<Token<T, L>>> sink) =>
      new _ChunkedLexingSink(
          sink, makeLexemizer(), tokenProvider, makeInitialState());
}

abstract class State<S, T, V> {
  Transition<S, T, V> process(S symbol);
}

class Transition<S, T, V> {
  final State<S, T, V> next;

  final Action action;

  const Transition(this.next, [this.action = const Action.none()]);
}

class Action<T, V> {
  final bool endLexeme;

  final bool emitToken;

  final T tokenType;

  final V tokenValue;

  final bool eatCurrentUnit;

  const Action(
      {this.endLexeme = false,
      this.emitToken = false,
      this.tokenType,
      this.tokenValue,
      this.eatCurrentUnit = false});

  const Action.none({this.eatCurrentUnit = false})
      : endLexeme = false,
        emitToken = false,
        tokenType = null,
        tokenValue = null;

  const Action.emit(this.tokenType,
      {this.tokenValue, this.eatCurrentUnit = false})
      : endLexeme = true,
        emitToken = true;

  const Action.discard({this.eatCurrentUnit = false})
      : endLexeme = true,
        emitToken = false,
        tokenType = null,
        tokenValue = null;
}

abstract class TokenProvider<T, L> {
  Token<T, L> nextToken(T type, L lexeme, int offset);
}

class SimpleTokenFactory<T, L> implements TokenProvider<T, L> {
  const SimpleTokenFactory();

  Token<T, L> nextToken(T type, L lexeme, int offset) =>
      new _SimpleToken(type, lexeme, offset);
}

abstract class Lexemizer<S, U, L> {
  U get currentUnit;

  L get currentLexeme;

  void add(S sourceChunk);

  bool moveNext();

  void resetLexeme();
}

class _SimpleToken<T, L> implements Token<T, L> {
  final T type;

  final L lexeme;

  final int offset;

  const _SimpleToken(this.type, this.lexeme, this.offset);

  String toString() {
    var lexemeString =
        lexeme.toString().replaceAll('\n', '\\n').replaceAll('\r', '\\r');

    lexemeString = lexemeString.length > 20
        ? lexemeString.substring(0, 12) +
            '...' +
            lexemeString.substring(lexemeString.length - 5)
        : lexemeString;

    return 'Token($type, `$lexemeString`, offset: $offset)';
  }

  bool operator ==(Object other) =>
      other is Token &&
      other.type == type &&
      other.lexeme == lexeme &&
      other.offset == offset;
}

class _ChunkedLexingSink<S, U, T, L> implements Sink<S> {
  final Sink<List<Token<T, L>>> outputSink;

  final Lexemizer<S, U, L> lexemizer;

  final TokenProvider<T, L> tokenProvider;

  final State<U, T, L> initialState;

  final _LexingSession session;

  _ChunkedLexingSink(
      this.outputSink, this.lexemizer, this.tokenProvider, this.initialState)
      : session = new _LexingSession(lexemizer, tokenProvider, initialState);

  void add(S sourceChunk) {
    lexemizer.add(sourceChunk);
    outputSink.add(session.gatherTokens());
  }

  void close() {
    outputSink.close();
  }
}

class _LexingSession<S, U, T, L> {
  final Lexemizer<S, U, L> lexemizer;

  final TokenProvider<T, L> tokenProvider;

  State<U, T, L> state;

  int _offset = 0;

  int _currentLexemeOffset = 0;

  _LexingSession(this.lexemizer, this.tokenProvider, this.state);

  List<Token<T, L>> gatherTokens() {
    final tokens = <Token<T, L>>[];

    while (lexemizer.moveNext()) {
      var currentCodeUnit = lexemizer.currentUnit;
      var transition = state.process(currentCodeUnit);

      while (transition != null) {
        state = transition.next;

        final action = transition.action;

        if (action.emitToken) {
          final value = action.tokenValue ?? lexemizer.currentLexeme;

          tokens.add(tokenProvider.nextToken(
              action.tokenType, value, _currentLexemeOffset));
        }

        if (action.endLexeme) {
          lexemizer.resetLexeme();
          _currentLexemeOffset = _offset;
        }

        if (!action.eatCurrentUnit) {
          transition = state.process(currentCodeUnit);
        } else {
          transition = null;
        }
      }

      ++_offset;
    }

    return tokens;
  }
}
