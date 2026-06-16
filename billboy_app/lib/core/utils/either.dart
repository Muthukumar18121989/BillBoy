typedef Either<L, R> = _Either<L, R>;

abstract class _Either<L, R> {
  const _Either();
  bool get isLeft;
  bool get isRight;
  L get left;
  R get right;
  T fold<T>(T Function(L) onLeft, T Function(R) onRight);
}

class Left<L, R> extends _Either<L, R> {
  final L _value;
  const Left(this._value);

  @override
  bool get isLeft => true;
  @override
  bool get isRight => false;
  @override
  L get left => _value;
  @override
  R get right => throw Exception('Called right on Left');

  @override
  T fold<T>(T Function(L) onLeft, T Function(R) onRight) => onLeft(_value);
}

class Right<L, R> extends _Either<L, R> {
  final R _value;
  const Right(this._value);

  @override
  bool get isLeft => false;
  @override
  bool get isRight => true;
  @override
  L get left => throw Exception('Called left on Right');
  @override
  R get right => _value;

  @override
  T fold<T>(T Function(L) onLeft, T Function(R) onRight) => onRight(_value);
}
