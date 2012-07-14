/** Returns [def] if [test] == null. Otherwise [test]. */
Dynamic ifNull(Dynamic test, Dynamic def) {
  return test == null ? def : test;
}