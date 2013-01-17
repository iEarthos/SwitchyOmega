library converters;

typedef V Getter<V>();
typedef V Setter<V>(V value);

abstract class Converter<From, To> {
  const Converter();
  ConverterGetter<From, To> operator [](Getter<From> getter) {
    return new ConverterGetter(this, getter);
  }
  To convert(From value);
  From convertBack(To value);
}

class ConverterGetter<From, To> {
  Converter<From, To> converter;
  Getter<From> getter;
  ConverterGetter(this.converter, this.getter);
  
  To operator [](Setter<From> setter) {
    return converter.convert(this.getter());
  }
  
  void operator []=(Setter<From> setter, To value) {
    setter(converter.convertBack(value));
  }
  
}

class _IntStringConverter extends Converter<int, String> {
  const _IntStringConverter();
  String convert(int value) => value == null ? '' : value.toString();
  int convertBack(String value) => value == null ? null : int.parse(value);
}

Converter<int, String> fromInt = const _IntStringConverter();

class Binding<V> extends Converter<V, V> {
  const Binding();
  V convert(V value) => value;
  V convertBack(V value) => value;
}