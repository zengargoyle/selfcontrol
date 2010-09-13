#!perl
use strict;
use warnings;
use Module::Build;
use File::Spec::Functions;

my $class = Module::Build->subclass(
  class => MyBuild => code => q{
#    eval 'use Module::Build::Debian';
    1;
  },
);

my $builder = MyBuild->new(
#    module_name         => 'SelfControl',
    dist_name => 'selfcontrol',
    license             => 'perl',
    dist_author         => q{zengargoyle <zengargoyle@gmail.com>},
    dist_version_from   => 'lib/SelfControl.pm',
#    dist_version   => '0.0.20100817',
#    dist_abstract  => 'SelfControl - duh',
    requires => {
        'YAML' => 0,
        'Gtk2' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'SelfControl-*' ],
    create_makefile_pl => 'small',

    gnome_files => {
      'contrib/icons/selfcontrol.svg'     => 'gnome/icons/hicolor/scalable/apps/selfcontrol.svg',
      'contrib/selfcontrol.desktop' => 'gnome/applications/selfcontrol.desktop',
    },
    etc_files => {
      'contrib/selfcontrol.sh' => 'etc/init.d/selfcontrol',
      'contrib/keep'           => 'etc/selfcontrol/.keep',
    },
);

$builder->install_path(gnome => '/usr/share');
$builder->add_build_element('gnome');
$builder->install_path(etc => '/etc');
$builder->add_build_element('etc');

$builder->create_build_script();
