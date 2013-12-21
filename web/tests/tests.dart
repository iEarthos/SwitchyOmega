library so_tests;

import 'package:observe/observe.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';
import 'package:switchyomega/profile/lib.dart';
import 'pac_gen_test.dart' as pac_gen_test;

void main() {
  useHtmlEnhancedConfiguration();

  group('Profile', () {
    Profile profile1, profile2;

    setUp(() {
      profile1 = new FixedProfile('profile1');
      profile2 = new FixedProfile('profile2');
    });

    test('Profile.name should be observable', () {
      profile1.changes.listen(expectAsync1((_) {
        expect(profile1.name, equals('new_name1'));
      }));
      profile1.name = 'new_name1';
      profile1.deliverChanges();
    });

    test('Multiple changes should be delivered by dirtyCheck', () {
      profile1.changes.listen(expectAsync1((_) {
        expect(profile1.name, equals('new_name1'));
      }));
      profile2.changes.listen(expectAsync1((_) {
        expect(profile2.name, equals('new_name2'));
      }));
      profile1.name = 'new_name1';
      profile2.name = 'new_name2';

      Observable.dirtyCheck();
    });
  });

  group('ProfileCollection', () {
    SwitchProfile profile1, profile2;
    ProfileCollection col;

    setUp(() {
      profile1 = new SwitchProfile('profile1', 'direct');
      profile2 = new SwitchProfile('profile2', 'direct');
      col = new ProfileCollection();
    });

    test('It should add two profiles to the ProfileCollection', () {
      col.addProfiles([profile1, profile2]);
      expect(col.length,
          equals(ProfileCollection.predefinedProfiles.length + 2));
    });

    test('ProfileCollection should report all references to "direct"', () {
      col.addProfiles([profile1, profile2]);
      Observable.dirtyCheck();

      expect(col.referredBy(new DirectProfile()).length, equals(2));
    });

    test('ProfileCollection should track profile references', () {
      col.addProfiles([profile1, profile2]);
      Observable.dirtyCheck();
      profile2.defaultProfileName = profile1.name;
      Observable.dirtyCheck();
      var list = col.referredBy(profile1).toList();
      expect(list.length, equals(1));
      expect(list[0].name, equals(profile2.name));
    });

    test('ProfileCollection should track changes of profile references', () {
      col.addProfiles([profile1, profile2]);
      Observable.dirtyCheck();
      profile2.defaultProfileName = profile1.name;
      Observable.dirtyCheck();
      profile2.defaultProfileName = new AutoDetectProfile().name;
      Observable.dirtyCheck();

      var list = col.allReferences(profile2).toList();
      expect(list.length, equals(1));
      expect(list[0].name, equals(new AutoDetectProfile().name));
    });
  });

  group('PAC Generation Test', () {
    pac_gen_test.allTests();
  });

  runTests();
}
