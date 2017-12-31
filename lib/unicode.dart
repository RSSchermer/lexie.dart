library lexie.unicode;

import 'dart:collection';

import 'core.dart';

class UnicodeLexer<TokenType> extends Lexer<String, int, TokenType, String> {
  const UnicodeLexer(StateFactory<int, TokenType, String> makeInitialState,
      {TokenProvider<TokenType, String> tokenProvider =
      const SimpleTokenFactory()})
      : super(_makeUnicodeRuneLexemizer, makeInitialState,
      tokenProvider: tokenProvider);
}

class UnicodeRuneLexemizer implements Lexemizer<String, int, String> {
  Queue<String> _chunkQueue = new Queue();

  String _currentChunk;

  Iterator<int> _runesIterator;

  String _remainder;

  int _position = -1;

  int _lexemeStart = 0;

  int get currentUnit => _runesIterator?.current;

  String get currentLexeme {
    if (_lexemeStart < 0) {
      return _remainder + _currentChunk.substring(0, _position);
    } else {
      return _currentChunk.substring(_lexemeStart, _position);
    }
  }

  bool moveNext() {
    if (_currentChunk != null) {
      if (_runesIterator.moveNext()) {
        _position++;

        return true;
      } else {
        if (_lexemeStart < 0) {
          _remainder = _remainder + _currentChunk;
        } else {
          _remainder = _currentChunk.substring(_lexemeStart);
        }

        if (_chunkQueue.isNotEmpty) {
          _currentChunk = _chunkQueue.removeFirst();
          _runesIterator = _currentChunk.runes.iterator;
          _position = -1;

          return moveNext();
        } else {
          _currentChunk = null;
          _runesIterator = null;
          _position = -1;

          return false;
        }
      }
    } else {
      return false;
    }
  }

  void add(String chunk) {
    if (_currentChunk == null) {
      _currentChunk = chunk;
      _runesIterator = chunk.runes.iterator;
      _position = -1;
    } else {
      _chunkQueue.add(chunk);
    }
  }

  void resetLexeme() {
    _lexemeStart = _position;
  }
}

UnicodeRuneLexemizer _makeUnicodeRuneLexemizer() => new UnicodeRuneLexemizer();
