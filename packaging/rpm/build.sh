#!/usr/bin/env sh

# Common paths used in this script
# NB: Name will need to be updated for both ODL and RMP version bumps
version=5
HOME=/net/tau/localdisk/wwang/
rpm_name="opendaylight-0.2.3-$version.noarch.rpm"
rpm_out_path="$HOME/rpmbuild/RPMS/noarch/opendaylight-0.2.3-$version.fc20.noarch.rpm"
srpm_name="opendaylight-0.2.3-$version.src.rpm"
srpm_out_path="$HOME/rpmbuild/SRPMS/opendaylight-0.2.3-$version.fc20.src.rpm"
src_name="distribution-karaf-0.2.3-Helium-SR3.tar.gz"
src_cache_path="$HOME/vagrant/$src_name"
mkdir -p $HOME/vagrant
sysd_commit=4a87227

# Install required software, add user to mock group for rpmbuild

# Configure rpmbuild dir
rpmdev-setuptree

# Download ODL release tarball if it's not cached locally already
if [ ! -f  $src_cache_path ]; then
    echo "No cached ODL found, downloading from Nexus..."
    curl -o $src_cache_path https://nexus.opendaylight.org/content/groups/public/org/opendaylight/integration/distribution-karaf/0.2.3-Helium-SR3/$src_name
else
    echo "Using cached version of ODL at $src_cache_path"
fi

# Put ODL release tarball in the location required by rpmbuild
cp $src_cache_path $HOME/rpmbuild/SOURCES/$src_name

# Put systemd unit file archive in rpmbuild's SOURCES dir
# Need `-L` to follow redirects
curl -L -o $HOME/rpmbuild/SOURCES/opendaylight-systemd-$sysd_commit.tar.gz https://github.com/dfarrell07/opendaylight-systemd/archive/$sysd_commit/opendaylight-systemd-$sysd_commit.tar.gz

# Put ODL RPM .spec file in location required by rpmbuild
cp opendaylight.spec $HOME/rpmbuild/SPECS

# Build ODL RPM
cd $HOME/rpmbuild/SPECS
rpmbuild -ba opendaylight.spec

# Confirm SRPM found in expected location
if [ -f  $srpm_out_path ]; then
    echo "SRPM built!"
    echo "Location: $srpm_out_path"
    if [ -d  $HOME/vagrant/ ]; then
        echo "Assuming you want to move RPM off Vagrant box"
        echo "Also renaming RPM, not actually tagged as for FC20 target OS"
        echo "cp $srpm_out_path $HOME/vagrant/$srpm_name"
        cp $srpm_out_path $HOME/vagrant/$srpm_name
    fi
else
    echo "SRPM seems to have failed. :(" >&2
fi

# Confirm RPM found in expected location
if [ -f  $rpm_out_path ]; then
    echo "RPM built!"
    echo "Location: $rpm_out_path"
    if [ -d  $HOME/vagrant/ ]; then
        echo "Assuming you want to move RPM off Vagrant box"
        echo "Also renaming RPM, not actually tagged as for FC20 target OS"
        echo "cp $rpm_out_path $HOME/vagrant/$rpm_name"
        cp $rpm_out_path $HOME/vagrant/$rpm_name
    fi
else
    echo "RPM seems to have failed. :(" >&2
fi
