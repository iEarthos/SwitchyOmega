import 'dart:io';

void main() {
  Process.run('make', []).then((r) => print(r.stdout),
      onError: (e) => print(e));
}