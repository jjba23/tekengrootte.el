# tekengrootte.el

# SPDX-License-Identifier: MIT
# Copyright © Josep Bigorra <jjbigorra@gmail.com>

# The package of this checkout, built with `melpaBuild' -- the builder MELPA
# itself uses, which reads the headers, writes the -pkg.el and the autoloads,
# and byte-compiles, so that `(require 'tekengrootte)' and the autoloaded
# commands work for whoever installs it.
#
# The arguments have defaults so that `nix-build' works here; a flake that
# pins nixpkgs passes `lib' and `melpaBuild' from its own Emacs package scope
# instead, since `melpaBuild' belongs to that scope and not to `pkgs'.

{ pkgs ? import <nixpkgs> { }
, lib ? pkgs.lib
, melpaBuild ? pkgs.emacsPackages.melpaBuild
}:

let
  # The version is written once, in the package's own header, which is where
  # Emacs reads it.  Reading it here instead of repeating the literal is what
  # keeps a release to one edit: the derivation cannot fall behind the file.
  # The header is matched loosely -- how many semicolons lead a comment is the
  # file's formatting, and maak's own `version-check' reads it the same way.
  headerLines = builtins.filter
    (line: builtins.match ";;+[[:space:]]*Version:.*" line != null)
    (lib.splitString "\n" (builtins.readFile ./tekengrootte.el));
in
melpaBuild {
  pname = "tekengrootte";
  version =
    if headerLines == [ ] then
      throw ''
        tekengrootte.el has no `Version:' header, which is where default.nix
        reads the version from.  Put it back, or set the version by hand here.
      ''
    else
      lib.trim (builtins.elemAt
        (builtins.split "Version:" (builtins.head headerLines)) 2);

  # `cleanSource' because the name `melpaBuild' gives this path must not end in
  # `.el': its unpack hook reads that suffix as "a single .el file", and a
  # directory by that name would then not be found.  It also keeps .git and
  # editor backups out of the store.
  src = lib.cleanSource ./.;

  # The repository carries its tests and its LICENSE next to the package; the
  # package is the .el files at the top level and nothing else.
  files = ''("*.el")'';

  meta = {
    description = "Proportionally scaled face sizes";
    homepage = "https://github.com/jjba23/tekengrootte.el";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.jjba23 ];
  };
}
