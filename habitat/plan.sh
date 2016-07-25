pkg_name="conveyor"
pkg_version="1.0.1"
pkg_origin="uafgina"
pkg_maintainer="UAF GINA <support+habitat@gina.alaska.edu>"
pkg_license=('MIT')
pkg_source="https://github.com/gina-alaska/${pkg_name}/archive/v${pkg_version}.tar.gz"
pkg_shasum="3b00ec91854a61c6ddfa0cb004ef06e17912dddd488bed0bf921611d4a7b47c1"

pkg_deps=(
  core/ruby
  core/bundler
)

pkg_build_deps=(
  core/ruby
  core/bundler
  core/git
  core/coreutils
  core/gcc
  core/make
)

pkg_bin_dirs=(bin)

do_build() {
  local _bundler_dir=$(pkg_path_for bundler)

  export GEM_HOME=${pkg_path}/vendor/bundler
  export GEM_PATH=${_bundler_dir}:${GEM_HOME}

  bundle install --jobs 2 --retry 5 --path vendor/bundle --binstubs --without development test
}

do_install() {
  cp -R . ${pkg_prefix}

  for binstub in ${pkg_prefix}/bin/*; do
    build_line "Setting shebang for ${binstub} to 'ruby'"
    [[ -f $binstub  ]] && sed -e "s#/usr/bin/env ruby#$(pkg_path_for ruby)/bin/ruby#" -i $binstub
  done
} 

