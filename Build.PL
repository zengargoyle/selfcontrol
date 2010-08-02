#!perl
use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
  class => MyBuild => code => q{
    eval 'use Module::Build::Debian';
  },
);

#BEGIN { eval 'use Module::Build::Debian'; }

my $builder = MyBuild->new(
    module_name         => 'SelfControl',
    license             => 'perl',
    dist_author         => q{zengargoyle <zengargoyle@gmail.com>},
    dist_version_from   => 'lib/SelfControl.pm',
    requires => {
        'YAML' => 0,
        'Gtk2' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'SelfControl-*' ],
    create_makefile_pl => 'traditional',
);
$builder->create_build_script();
