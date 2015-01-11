module.exports = (grunt) ->

  # Project configuration.
  grunt.initConfig
    coffee:
      app:
        expand: true
        cwd: 'worker'
        src: 'beat_detector_worker.coffee'
        dest: 'lib/assets/worker/'
        ext: '.js'
    watch:
      app:
        files: 'worker/*.coffee'
        tasks: ['coffee']

  # These plugins provide necessary tasks.
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  # Default task.
  grunt.registerTask 'default', ['watch']

