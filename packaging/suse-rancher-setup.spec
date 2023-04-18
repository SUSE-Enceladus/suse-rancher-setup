#
# spec file for package suse-rancher-setup
#
# Copyright (c) 2022 SUSE LLC
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via https://bugs.opensuse.org/
#
%define         app_dir      %{_datadir}/suse-rancher-setup
%define         lib_dir      %{_libdir}/suse-rancher-setup
%define         data_dir     %{_sharedstatedir}/suse-rancher-setup

%define         ruby_version ruby3.1

Name:           suse-rancher-setup
Version:        2.0.5
Release:        0
Summary:        SUSE Rancher Setup on Public Cloud k8s service
License:        GPL-3.0
Group:          Productivity/Networking/Web/Frontends
URL:            http://www.github.com/suse-enceladus/suse-rancher-setup
Source0:        %{name}-%{version}.tar.bz2
Source1:        suse-rancher-setup.rpmlintrc
BuildRequires:  %{ruby_version}-devel
BuildRequires:  chrpath
BuildRequires:  gcc
BuildRequires:  nginx
BuildRequires:  openssl
BuildRequires:  sqlite3-devel
Requires:       %{ruby_version}
Requires:       kuberlr
Requires:       helm
Requires:       nginx
Requires:       openssl
Requires:       python3-cloudinstancecredentials
Requires:       python3-ec2metadata
Requires:       supportutils-plugin-suse-rancher-setup

# Does not build for i586, s390, aarch64 and is not supported on those architectures
ExcludeArch:    %{ix86} s390 aarch64

%description
Simple, usable web application for deploying complex applications to the cloud;
wrapping cloud native SDK/CLIs

%prep

%setup
sed -i '1 s|/usr/bin/env\ ruby|/usr/bin/ruby.%{ruby_version}|' bin/*

%build

# Drop 'BUNDLED WITH' line from Gemfile.lock. It causes trouble when the Gemfile.lock
# was created with a different major version than the distribution's bundler.
sed -i '/BUNDLED WITH/{N;d;}' Gemfile.lock

bundle.%{ruby_version} config build.nio4r --with-cflags='%{optflags} -Wno-return-type'
bundle.%{ruby_version} config set deployment 'true'
bundle.%{ruby_version} config set without 'test development'
bundle config set force_ruby_platform true
bundle config build.sqlite3 --enable-system-libraries
bundle.%{ruby_version} install --local

%install
mkdir -p %{buildroot}%{app_dir}
mkdir -p %{buildroot}%{lib_dir}
mkdir -p %{buildroot}%{data_dir}
mkdir -p %{buildroot}%{_sharedstatedir}/%{name}

mv vendor %{buildroot}%{lib_dir}
mv db %{buildroot}%{data_dir}
mv tmp %{buildroot}%{data_dir}
mv log %{buildroot}%{data_dir}
cp -ar . %{buildroot}%{app_dir}

ln -s %{data_dir}/tmp %{buildroot}%{app_dir}/tmp
ln -s %{data_dir}/db %{buildroot}%{app_dir}/db
ln -s %{data_dir}/log %{buildroot}%{app_dir}/log
ln -s %{lib_dir}/vendor %{buildroot}%{app_dir}/vendor

# systemd
mkdir -p %{buildroot}%{_unitdir}
install -m 644 server-configs/systemd/suse-rancher-setup.service %{buildroot}%{_unitdir}

# nginx
install -D -m 644 server-configs/nginx/suse-rancher-setup.conf %{buildroot}%{_sysconfdir}/nginx/vhosts.d/suse-rancher-setup.conf

# set relocated destination for gems
sed -i -e '/BUNDLE_PATH: .*/cBUNDLE_PATH: "\/usr\/lib64\/suse-rancher-setup\/vendor\/bundle\/"' \
    -e 's/^BUNDLE_JOBS: .*/BUNDLE_JOBS: "1"/' \
    %{buildroot}%{app_dir}/.bundle/config

# cleanup of /usr/bin/env commands
grep -rl '\/usr\/bin\/env ruby' %{buildroot}%{lib_dir}/vendor/bundle/ruby | xargs \
    sed -i -e 's@\/usr\/bin\/env ruby.%{ruby_version}@\/usr\/bin\/ruby\.%{ruby_version}@g' \
    -e 's@\/usr\/bin\/env ruby@\/usr\/bin\/ruby\.%{ruby_version}@g'
grep -rl '\/usr\/bin\/env bash' %{buildroot}%{lib_dir}/vendor/bundle/ruby | xargs \
    sed -i -e 's@\/usr\/bin\/env bash@\/bin\/bash@g'

# cleanup unneeded files
find %{buildroot}%{lib_dir} "(" -name "*.c" -o -name "*.h" -o -name .keep ")" -delete
find %{buildroot}%{app_dir} -name .keep -delete
find %{buildroot}%{data_dir} -name .keep -delete
rm %{buildroot}%{app_dir}/README.md
rm %{buildroot}%{app_dir}/LICENSE
rm -r  %{buildroot}%{lib_dir}/vendor/bundle/ruby/[23].*.0/cache
rm -rf %{buildroot}%{lib_dir}/vendor/cache
rm -rf %{buildroot}%{lib_dir}/vendor/bundle/ruby/*/gems/*/doc
rm -rf %{buildroot}%{lib_dir}/vendor/bundle/ruby/*/gems/*/examples
rm -rf %{buildroot}%{lib_dir}/vendor/bundle/ruby/*/gems/*/samples
rm -rf %{buildroot}%{lib_dir}/vendor/bundle/ruby/*/gems/*/test
rm -rf %{buildroot}%{lib_dir}/vendor/bundle/ruby/*/gems/*/ports
rm -rf %{buildroot}%{lib_dir}/vendor/bundle/ruby/*/gems/*/ext
rm -rf %{buildroot}%{lib_dir}/vendor/bundle/ruby/*/gems/*/bin
rm -rf %{buildroot}%{lib_dir}/vendor/bundle/ruby/*/gems/*/spec
rm -f %{buildroot}%{lib_dir}/vendor/bundle/ruby/*/gems/*/.gitignore
rm -f %{buildroot}%{lib_dir}/vendor/bundle/ruby/*/gems/*/*/*/.gitignore
rm -f %{buildroot}%{lib_dir}/vendor/bundle/ruby/*/extensions/*/*/*/gem_make.out
rm -f %{buildroot}%{lib_dir}/vendor/bundle/ruby/*/extensions/*/*/*/mkmf.log
rm -rf %{buildroot}%{app_dir}/server-configs

%fdupes %{buildroot}/%{app_dir}
%fdupes %{buildroot}/%{lib_dir}

# drop custom rpath from native gems
chrpath -d %{buildroot}%{lib_dir}/vendor/bundle/ruby/*/gems/nokogiri-*/lib/nokogiri/*/nokogiri.so

# generate TLS self-signed cert for nginx
cd %{buildroot}%{app_dir}/public/ && openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "/CN=localhost" -keyout suse-rancher-setup.key -out suse-rancher-setup.crt

%files
%attr(-,root,root) %{app_dir}
%doc README.md
%license LICENSE
%{lib_dir}
%attr(-,root,root) %{data_dir}
%{_unitdir}/suse-rancher-setup.service
%config(noreplace) %{_sysconfdir}/nginx/vhosts.d/suse-rancher-setup.conf

%pre
%service_add_pre suse-rancher-setup.service

%post
%service_add_post suse-rancher-setup.service

%preun
%service_del_preun suse-rancher-setup.service

%postun
%service_del_postun suse-rancher-setup.service

%changelog
