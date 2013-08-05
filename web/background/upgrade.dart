part of switchy_background;


SwitchyOptions upgradeOptions(Map<String, Object> oldOptions) {
  var options = new SwitchyOptions.defaults();
  var config = oldOptions['config'] as Map<String, Object>;
  if (config != null && config['firstTime']) {
    // Upgrade from SwitchySharp options
    if (config['confirmDeletion'] != null) {
      options.confirmDeletion = config['confirmDeletion'] == true;
    }
    if (config['refreshTab'] != null) {
      options.refreshOnProfileChange = config['refreshTab'] == true;
    }
    if (config['quickSwitch'] != null) {
      options.enableQuickSwitch = config['quickSwitch'] == true;
    }
    if (config['preventProxyChanges'] != null) {
      options.revertProxyChanges = config['preventProxyChanges'] == true;
    }
    if (config['startupProfileId'] != null) {
      options.startupProfileName = config['startupProfileId'];
    }

    var profiles = oldOptions['profiles'] as Map<String, Map<String, Object>>;

    if (profiles != null) {
      var colorTranslations = {
                               'blue': '#99ccee',
                               'green': '#99dd99',
                               'red': '#ffaa88',
                               'yellow': '#ffee99',
                               'purple': '#d497ee',
                               '': '#99ccee'
      };
      var updatedProfiles = new Map<String, Profile>();
      profiles.forEach((_, profile) {
        Profile pf;
        /*
color: "blue"
id: "SSH"
name: "SSH"
proxyConfigUrl: ""
proxyExceptions: "localhost; 127.0.0.1; <local>"
proxyFtp: ""
proxyHttp: ""
proxyHttps: ""
proxyMode: "manual"
proxySocks: "127.0.0.1:7070"
socksVersion: 5
        */
        switch (profile['proxyMode']) {
          case 'manual': {
            var fixedProfile = new FixedProfile(profile['id']);
            if (profile['useSameProxy'] == true) {
              fixedProfile.fallbackProxy = new ProxyServer.parse(
                  profile['proxyHttp'], 'http');
            } else if (profile['proxySocks'] != '') {
              fixedProfile.fallbackProxy = new ProxyServer.parse(
                  profile['proxySocks'],
                  profile['socksVersion'] == 5 ? 'socks5' : 'socks4');
            } else {
              fixedProfile.proxyForHttp = new ProxyServer.parse(
                  profile['proxyHttp'], 'http');
              fixedProfile.proxyForHttp = new ProxyServer.parse(
                  profile['proxyHttps'], 'https');
              fixedProfile.proxyForFtp = new ProxyServer.parse(
                  profile['proxyFtp'], 'ftp');
            }
            if (profile['proxyExceptions'] != null) {
              fixedProfile.bypassList.addAll(
                  (profile['proxyExceptions'] as String)
                  .split(';').map((x) => new BypassCondition(x.trim())));
            }
            pf = fixedProfile;
          }
          break;
          case 'pac': {
            var pacProfile = new PacProfile(profile['id']);
            pacProfile.pacUrl = profile['proxyConfigUrl'];
            pf = pacProfile;
          }
          break;
        }
        var rgbColor = colorTranslations[profile['color']];
        if (rgbColor == null) rgbColor = colorTranslations[''];
        pf.color = rgbColor;
      });
    }

    var rules = oldOptions['rules'] as Map<String, Map<String, String>>;

    if (rules != null) {
      var defaultProfileName =
          (oldOptions['defaultRule'] as Map<String, String>)['profileId'];
      var switchProfile = new SwitchProfile('auto', defaultProfileName);
      rules.forEach((_, rule) {
        Condition c;
        switch(rule['patternType']) {
          case 'wildcard': {
            // TODO(catus): Recognize HostWildcardCondition.
            c = new UrlWildcardCondition(rule['urlPattern']);
          }
          break;
          case 'regexp': {
            c = new UrlRegexCondition(rule['urlPattern']);
          }
          break;
        }
        switchProfile.add(new Rule(c, rule['profileId']));
      });

      options.profiles.add(switchProfile);
    }

    if (config['ruleListEnabled'] == true) {
      RuleListProfile ruleList;
      if (config['ruleListAutoProxy'] == true) {
        ruleList = new AutoProxyRuleListProfile('rulelist', 'direct',
            config['ruleListProfileId']);
      } else {
        ruleList = new SwitchyRuleListProfile('rulelist', 'direct',
            config['ruleListProfileId']);
      }
      ruleList.sourceUrl = config['ruleListUrl'];
      if (rules != null) {
        var switchProfile = options.profiles['auto'] as SwitchProfile;
        ruleList.defaultProfileName = switchProfile.defaultProfileName;
        switchProfile.defaultProfileName = ruleList.name;
      }
      options.profiles.add(ruleList);
    }

    if (config['quickSwitchProfiles'] == true) {
      options.quickSwitchProfiles.addAll(config['quickSwitchProfiles']);
    }
  }
  return options;
}