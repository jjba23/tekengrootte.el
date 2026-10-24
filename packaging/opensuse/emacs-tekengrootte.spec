#
# spec file for package emacs-tekengrootte
#
# Copyright (c) 2026 SUSE LLC and contributors
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

Name:           emacs-tekengrootte
Version:        0.2.1
Release:        0
Summary:        Proportionally scaled face sizes for Emacs
License:        GPL-3.0-or-later
URL:            https://codeberg.org/jjba23/tekengrootte.el
Source0:        tekengrootte.el-%{version}.tar.gz
BuildRequires:  emacs
Requires:       emacs

%description
Tekengrootte keeps face heights proportional to a single adjustable scale,
so every face set up through it grows or shrinks together.

%prep
%autosetup -n tekengrootte.el-%{version}

%build
emacs -Q --batch -f batch-byte-compile tekengrootte.el

%install
install -d %{buildroot}%{_datadir}/emacs/site-lisp
install -m 0644 tekengrootte.el tekengrootte.elc %{buildroot}%{_datadir}/emacs/site-lisp/

%check
emacs -Q --batch -L . -L test -l test/tekengrootte-tests.el -f ert-run-tests-batch-and-exit

%files
%license COPYING
%doc README.org
%{_datadir}/emacs/site-lisp/tekengrootte.el
%{_datadir}/emacs/site-lisp/tekengrootte.elc

%changelog
