'use strict';

Package.describe({
  summary: 'Beat detection with reactivity',
  version: '0.0.8',
  name: 'fds:beat-detector',
  git: 'https://github.com/foxdog-studios/fds-beat-detector.git'
});

Package.onUse(function (api) {
  api.versionsFrom('1.0');

  api.use([
    'coffeescript',
    'jquery',
    'reactive-var'
  ]);

  api.addFiles('lib/beat_detector.coffee', 'client');
  api.addFiles('lib/client/audio_sample.coffee', 'client');
  api.addFiles('lib/client/pcm_audio_data_generator.coffee', 'client');
  api.addFiles('lib/client/beat_detector.coffee', 'client');
  api.addFiles('lib/client/beat_detector_visualisation.coffee', 'client');
  api.addFiles('lib/client/beat_manager.coffee', 'client');
  api.addFiles('lib/client/click_track_player.coffee', 'client');
  api.addFiles('lib/client/timeline.coffee', 'client');
  api.addFiles('lib/client/beat_flash.coffee', 'client');
  api.addFiles('lib/client/visualisation.coffee', 'client');
  api.addFiles('lib/client/style/style.css', 'client');
  api.addFiles('lib/assets/metronome.ogg', 'client');
  api.addFiles(
    'lib/assets/worker/beat_detector_worker.js',
    'client',
    {isAsset: true}
  );
});


