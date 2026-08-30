# Shared project navigation from the previous work profile.
for _dotfiles_cd_dir in "$HOME" "$HOME/projects" .; do
  (( ${cdpath[(Ie)$_dotfiles_cd_dir]} )) || cdpath+=("$_dotfiles_cd_dir")
done
unset _dotfiles_cd_dir

if [[ $OSTYPE == darwin* ]]; then
  # Homebrew keeps keg-only LLVM and GNU Make outside its primary bin directory.
  for _dotfiles_development_bin_dir in \
    /opt/homebrew/opt/make/libexec/gnubin \
    /opt/homebrew/opt/llvm/bin
  do
    [[ -d $_dotfiles_development_bin_dir ]] || continue
    case ":$PATH:" in
      *":$_dotfiles_development_bin_dir:"*) ;;
      *) PATH="$_dotfiles_development_bin_dir:$PATH" ;;
    esac
  done
  unset _dotfiles_development_bin_dir

  [[ -x /opt/homebrew/opt/llvm/bin/clang ]] &&
    export CC=/opt/homebrew/opt/llvm/bin/clang
  [[ -x /opt/homebrew/opt/llvm/bin/clang++ ]] &&
    export CXX=/opt/homebrew/opt/llvm/bin/clang++
  export CCACHE_DIR="$HOME/.ccache"

  if (( $+commands[xcrun] )); then
    _dotfiles_sdkroot=$(xcrun --sdk macosx --show-sdk-path 2>/dev/null) &&
      export SDKROOT=$_dotfiles_sdkroot
    unset _dotfiles_sdkroot
  fi

  if (( $+commands[hdiutil] )); then
    alias mountkernel='hdiutil attach ~/linux.dmg.sparseimage'
    alias umountkernel='hdiutil detach /Volumes/Linux'
  fi
fi

_build_llvm_project() {
  emulate -L zsh

  if (( $# != 2 )); then
    print -u2 'usage: _build_llvm_project BUILD_TYPE ENABLE_CLANG'
    return 2
  fi

  local build_type=$1
  local enable_clang=$2
  local llvm_project="$HOME/projects/llvm-project"
  local build_dir="$llvm_project/build"
  local install_dir="$llvm_project/install"
  local -a configure_options

  case $build_type in
    Debug|Release|RelWithDebInfo|MinSizeRel) ;;
    *)
      print -u2 "unsupported CMake build type: $build_type"
      return 2
      ;;
  esac

  [[ -d "$llvm_project/llvm" ]] || {
    print -u2 "LLVM source directory not found: $llvm_project/llvm"
    return 1
  }
  (( $+commands[cmake] )) || {
    print -u2 'cmake is not available'
    return 127
  }

  if [[ $enable_clang == yes ]]; then
    configure_options+=('-DLLVM_ENABLE_PROJECTS=clang')
  fi

  command cmake \
    -S "$llvm_project/llvm" \
    -B "$build_dir" \
    -G Ninja \
    "-DCMAKE_BUILD_TYPE=$build_type" \
    '-DLLVM_TARGETS_TO_BUILD=AArch64' \
    '-DLLVM_OPTIMIZED_TABLEGEN=1' \
    "-DCMAKE_INSTALL_PREFIX=$install_dir" \
    "${configure_options[@]}" || return
  command cmake --build "$build_dir" || return
  command cmake --install "$build_dir"
}

build_llvm() {
  if (( $# != 1 )); then
    print -u2 'usage: build_llvm BUILD_TYPE'
    return 2
  fi
  _build_llvm_project "$1" no
}

build_clang() {
  if (( $# != 1 )); then
    print -u2 'usage: build_clang BUILD_TYPE'
    return 2
  fi
  _build_llvm_project "$1" yes
}
