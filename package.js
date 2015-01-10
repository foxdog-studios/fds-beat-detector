'use strict';

Package.describe({
  summary: 'Beat detectionr',
  version: '0.0.0',
  name: 'fds:beat-detector',
  git: 'https://github.com/foxdog-studios/fds-beat-detector.git'
});

Package.onUse(function (api) {
  api.versionsFrom('1.0');

  api.use([
    'coffeescript',
  ]);

  api.addFiles('lib/client/beat_detector.coffee', 'client');
});


