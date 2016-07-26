pkg_name="conveyor"
pkg_version="1.0.2"
pkg_origin="uafgina"
pkg_maintainer="UAF GINA <support+habitat@gina.alaska.edu>"
pkg_license=('MIT')
pkg_source="https://github.com/gina-alaska/${pkg_name}/archive/${pkg_version}.tar.gz"
pkg_shasum="f5a89c713699f5902d0f35939187cfd5c79dbdc728b31dd78a0914c8af5fb0ba"

pkg_deps=(
  core/ruby
  core/bundler
  core/gcc-libs
  core/openssl
)

pkg_build_deps=(
  core/ruby
  core/bundler
  core/git
  core/coreutils
  core/gcc
  core/openssl
  core/make
)

pkg_bin_dirs=(bin)

do_build() {
  export CPPFLAGS="${CPPFLAGS} ${CFLAGS}"
  local _bundler_dir=$(pkg_path_for bundler)

  export GEM_HOME=${pkg_path}/vendor/bundler
  export GEM_PATH=${_bundler_dir}:${GEM_HOME}

  bundle install --jobs 2 --retry 5 --path vendor/bundle --without development test
}

do_install() {
  cp -R . ${pkg_prefix}

  for binstub in ${pkg_prefix}/bin/*; do
    build_line "Setting shebang for ${binstub} to 'ruby'"
    [[ -f $binstub  ]] && sed -e "s#/usr/bin/env ruby#$(pkg_path_for ruby)/bin/ruby#" -i $binstub
  done
} 

