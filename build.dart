import 'dart:io';

void main() {
  Process.run('make', ['dwc']).then((r) => print(r.stdout),
      onError: (e) => print(e));
}