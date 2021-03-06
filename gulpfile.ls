require! <[gulp gulp-util express connect-livereload gulp-jade tiny-lr gulp-livereload path]>
require! <[gulp-if gulp-livescript gulp-less gulp-concat gulp-json-editor gulp-commonjs gulp-insert streamqueue gulp-uglify]>

gutil = gulp-util

app = express!
lr = tiny-lr!

build_path = '_public'
production = true if gutil.env.env is \production

gulp.task 'html', ->
  gulp.src 'app/**/*.jade'
    .pipe gulp-jade!
    .pipe gulp.dest "#build_path"
    .pipe gulp-livereload lr


gulp.task 'js:vendor', ->
  vendor = gulp.src 'vendor/scripts/*.js'

  streamqueue { +objectMode }
    .done vendor
    .pipe gulp-concat 'vendor.js'
    .pipe gulp-if production, gulp-uglify()
    .pipe gulp.dest "#{build_path}/js"

gulp.task 'js:app', ->
  env = gulp.src 'app/**/*.jsenv'
    .pipe gulp-json-editor (json) ->
      for key of json when process.env[key]?
        json[key] = that
      json
    .pipe gulp-insert.prepend 'module.exports = '
    .pipe gulp-commonjs!

  app = gulp.src 'app/**/*.ls'
    .pipe gulp-livescript({+bare}).on 'error', gutil.log

  streamqueue { +objectMode }
    .done env, app
    .pipe gulp-concat 'app.js'
    .pipe gulp-if production, gulp-uglify()
    .pipe gulp.dest "#{build_path}/js"
    .pipe gulp-livereload lr

gulp.task 'css', ->
  compress = production
  gulp.src 'app/styles/app.less'
    .pipe gulp-less compress: compress
    .pipe gulp.dest "#{build_path}/css"
    .pipe gulp-livereload lr

gulp.task 'assets', ->
  gulp.src 'app/assets/**/*'
    .pipe gulp.dest "#{build_path}"
    .pipe gulp-livereload lr

gulp.task 'server', ->
  app.use connect-livereload!
  app.use express.static path.resolve "#build_path"
  app.listen 3000
  gulp-util.log 'Listening on port 3000'

gulp.task 'watch', ->
  lr.listen 35729, ->
    return gulp-util.log it if it
  gulp.watch 'app/**/*.jade', <[html]>
  gulp.watch 'app/assets/**/*', <[assets]>
  gulp.watch 'app/**/*.less', <[css]>
  gulp.watch 'app/**/*.ls', <[js]>

gulp.task 'build', <[html js:vendor js:app assets css]>
gulp.task 'dev', <[build server watch]>
gulp.task 'default', <[build]>