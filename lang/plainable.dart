/**
 * An object that could be translated to and from a plain data structrure.
 */
abstract class Plainable {
  /**
   * Convert this object to a plain data structure using [config].
   * if [p] is not null, the data of this object should be added to [p].
   */
  abstract Object toPlain([Object p, Object config]);
  
  // Plainable classes should implement the following constructor:
  
  // Construct an object from the plain data structure [p] with [config].
  // Plainable.fromPlain(Object p, [Object config]);
}