package SelfControl::Root;
my $ID = {
        date => q$Date$,
        headurl => q$HeadURL$,
        author => q$Author$,
        revision => q$Revision$,
};

use warnings;
use strict;

use Exporter qw<import>;
our @EXPORT = qw<check_chain add_chain add_hosts>;

use Sys::Syslog;
use YAML;
use SelfControl::Config;

=head1 NAME

SelfControl::Root - The great new SelfControl::Root!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use SelfControl::Root;

    my $foo = SelfControl::Root->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

#
# Manipulate firewall.
#

sub check_chain {
  my ($self) = @_;
  my $out;
syslog('info',"check_chain");
  $out = `iptables -S SelfControl 2>/dev/null`;
  unless ($out =~ m/^-N SelfControl\s*$/m) {
    syslog('info','creating SelfControl chain');
    system("iptables -N SelfControl 2>/dev/null") and syslog('error','could not create SelfControl chain');
  }

  $out = `iptables -S OUTPUT 2>/dev/null`;
  unless ($out =~ m/^-A OUTPUT -j SelfControl\s*$/m) {
    syslog('info','adding SelfControl chain to OUTPUT chain');
    system("iptables -A OUTPUT -j SelfControl 2>/dev/null") and syslog('error','could not add SelfControl chain to OUTPUT chain');
  }
}
sub new {
  my ($class, $self) = @_;
  bless $self, $class;
  $self->init();
  return $self;
}
sub init {
  my ($self) = @_;
  $self->{config} = load_config($self->{config_file});
}
sub run {
  my ($self) = @_;
#  print YAML::Dump($self);
  $self->{ts} = "now + $self->{config}->{timeout} minutes";
  $self->check_chain;
  $self->add_chain;
  $self->add_hosts;
  $self->do_undo;
  save_config($self->{config_file}, $self->{config});
}

sub add_chain {
  my ($self) = @_;
  for my $hr (@{$self->{config}->{hosts}}) {
    push @{$self->{blocked}}, [@{$hr}];
    my $h = $hr->[1];
    push @{$self->{iptables_do}},   "iptables -I SelfControl -d $h -j DROP";
    push @{$self->{iptables_undo}}, "iptables -D SelfControl -d $h -j DROP";
  }
}
sub add_hosts {
  my ($self) = @_;
  my @hn;
  for my $hr (@{$self->{config}->{hosts}}) {
    my $h = $hr->[0];
    next if $h =~ /\.\d{1,3}$/;  # purge any IP only.
    push @hn, $h;
  }
  for my $h (@hn) {
    push @{$self->{hosts_do}},   "127.0.0.2 $h # SelfControl - DO NOT EDIT!";
    push @{$self->{hosts_undo}}, "/^".quotemeta("127.0.0.2 $h")." # SelfControl - DO NOT EDIT!\$/d";
  }
}

sub do_undo {
  my ($self) = @_;

  # do /etc/hosts
  open my $hf, '>>', '/etc/hosts';
  unless ($hf) {
    syslog('error','can not open /etc/hosts for writing');
  }
  else {
    print $hf "$_\n" for @{$self->{hosts_do}};
    close $hf;
  }
  $self->{hosts_do} = undef;

  # do iptables
  for (@{$self->{iptables_do}}) {
    if (system($_)) {
      syslog('error',"iptables failed: $_");
      last;
    }
  }
  if (system('/etc/init.d/selfcontrol', 'stop')) {
    syslog('error',"init.d save failed: $_");
  }
  $self->{iptables_do} = undef;

  # undo
  my $cmd = join("\n",
    @{$self->{iptables_undo}},
    '/etc/init.d/selfcontrol stop',
    'ed /etc/hosts <<_EOF_ 2>/dev/null',
    @{$self->{hosts_undo}},
    'wq',
    '_EOF_',
  );
  $self->{iptables_undo} = undef;
  $self->{hosts_undo} = undef;
  
  my ($job, $when) = do_at($cmd, $self->{ts});
  $when = time() + ($self->{config}->{timeout} * 60);
  $self->{config}{jobs}{$job} = [$when, $self->{blocked}];
}

sub do_at {                  # $jid,$when = $cmd,$tspec
  my ($cmd, $ts) = @_;
  my ($rc, $output) = spawn_simple($cmd,'at',$ts);
  return undef if $rc;
  my ($job, $when) = "@{$output}" =~ m/^\s*job\s+(\d+)\s+at\s+(.*?)\s*$/m;
  return ($job, $when);
}
sub spawn {
  pipe(my $fp, my $tc);
  pipe(my $fc, my $tp);
  my $pid = fork();
  if (!defined $pid) {
    close $fp; close $tc;
    close $fc; close $tp;
    warn "fork failed.\n";
    return;
  }
  elsif ($pid == 0) {
    # in the child
    close $tc; close $fc;
    open STDIN, "<&", $fp;
    open STDERR, ">&", $tp;
    open STDOUT, ">&", $tp;
    { exec @_ };
    print $tp "Failed to execute: ". join (" ", @_) ."\n";
    print $tp "Command '$_[0]' not accessible.\n"
        if $!{ENOENT} or $!{EPERM};
    close $tp;
    close $fp;
    exit -1;
  }
  else {
    close $fp; close $tp;
    return ($pid, $tc, $fc);
  }
}
sub spawn_simple {
  my ($input, @cmd) = @_;
  my ($status, @output);
  my ($pid, $tc, $fc) = spawn(@cmd);
  return unless defined $pid;
  print $tc $input if defined $input;
  close $tc;
  waitpid($pid, 0);
  $status = $? >> 8;
  $status = -1 if $status == 255;
  @output = <$fc>;
  close $fc;
  return ($status, \@output);
}

=head1 AUTHOR

zengargoyle, C<< <zengargoyle at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-selfcontrol at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SelfControl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SelfControl::Root


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SelfControl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SelfControl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SelfControl>

=item * Search CPAN

L<http://search.cpan.org/dist/SelfControl/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 zengargoyle.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of SelfControl::Root
