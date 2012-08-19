/*!
 * Copyright (C) 2012, The SwitchyOmega Authors. Please see the AUTHORS file
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

/**
 * An object that could be translated to and from a plain data structrure.
 */
abstract class Plainable {
  /**
   * Convert this object to a plain data structure.
   * if [p] is not null, the data of this object should be added to [p].
   * If base is also [Plainable], please call [:super.toPlain(p):] at the 
   * beginning of the implementation.
   */
  abstract Object toPlain([Object p]);
  
  /**
   * Modify this object's current state according to plain data structure [p].
   * If base is also [Plainable], please call [:super.fromPlain(p):] at the
   * beginning of the implementation.
   */
  abstract void fromPlain(Object p);
  
  // Plainable classes should implement the following constructor:
  
  //** Construct an object from the plain data structure [p].
  // * If the constructor is a factory, call the .fromPlain constructors of the
  // * subclasses. Otherwise, just call [:this.fromPlain(p):] to initialize this
  // * object.
  // */
  // Plainable.fromPlain(Object p);
}