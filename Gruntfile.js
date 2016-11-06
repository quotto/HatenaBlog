module.exports = function(grunt) {
  grunt.initConfig({
    sass:{
      dist:{
        options: {
          sourcemap: 'none'
        },
        files:[{
          expand: true,
          cwd: 'app/assets/stylesheets',
          src: ['**/*.scss'],
          dest: 'app/assets/stylesheets',
          ext: '.css'
        }]
      }
    },
    cssmin:{
      target:{
        files:[{
          expand: true,
          cwd: 'app/assets/stylesheets',
          src: ['**/*.css'],
          dest: 'public/assets',
          ext: '.min.css'
        }]
      }
    },
    uglify:{
      my_target:{
        files:[{
          expand: true,
          cwd: 'app/assets/javascripts',
          src: ['**/*.js'],
          dest: 'public/assets',
          ext: '.min.js'
        }]
      }
    }
  });
  grunt.loadNpmTasks('grunt-contrib-sass'); 
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.registerTask('default',['sass','cssmin','uglify']);
};
