/*!
 * Copyright (C) 2012-2013, The SwitchyOmega Authors. Please see the AUTHORS file
 * for details.
 *
 * This file is part of SwitchyOmega.
 *
 * SwitchyOmega is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * SwitchyOmega is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with SwitchyOmega.  If not, see <http://www.gnu.org/licenses/>.
 */

library converters;

/** Get a value of type [V]. */
typedef V Getter<V>();

/** Set a value of type [V]. */
typedef V Setter<V>(V value);

/**
 * A [Converter] defines a two-way convention between [From] and [To].
 * Besides calling [convert] and [convertBack] directly, the expression
 * [:converter[getter][setter]:] can also be used to get and set the
 * converted value.
 * When evaluating [:converter[getter][setter]:], the getter is called and the
 * [convert]ed result is returned.
 * When assigning to [:converter[getter][setter]:], the setter is called with
 * the result of the [convertBack] value.
 * In this way, [:converter[getter][setter]:] acts like an assignable variable,
 * which can be useful in bindings.
 * All converters should be const, because converters do not hold states.
 */
abstract class Converter<From, To> {
  const Converter();
  ConverterGetter<From, To> operator [](Getter<From> getter) {
    return new ConverterGetter(this, getter);
  }
  To convert(From value);
  From convertBack(To value);
}

/**
 * The helper class of [Converter]. It holds a [converter] and the [getter].
 * This class enables the form of [:converter[getter][setter]:].
 */
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

/**
 * The implementation class of [fromInt], which is a converter between [int]
 * and [String].
 */
class _IntStringConverter extends Converter<int, String> {
  const _IntStringConverter();
  String convert(int value) => value == null ? '' : value.toString();
  int convertBack(String value) => value == null ? null : int.parse(value);
}

/**
 * A convenient converter between [int] and [String].
 */
Converter<int, String> fromInt = const _IntStringConverter();

/**
 * A converter that does not do any convert. It can only be used as a wrapper
 * for the getter and the setter.
 */
class Binding<V> extends Converter<V, V> {
  const Binding();
  V convert(V value) => value;
  V convertBack(V value) => value;
}