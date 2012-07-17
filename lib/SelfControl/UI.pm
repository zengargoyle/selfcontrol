package SelfControl::UI;
my $ID = {
        date => q$Date$,
        headurl => q$HeadURL$,
        author => q$Author$,
        revision => q$Revision$,
};
use SelfControl;

use warnings;
use strict;

use constant TRUE => 1;
use constant FALSE => 0;

use Time::Local;


=head1 NAME

SelfControl::UI - The Gtk2 user interface for the SelfControl application.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This module allows a user to configure a run of the SelfControl application.
It is given a starting configuration which the user can manipulate and then
either cancel or start the application with the configuration.

Perhaps a little code snippet will help.

    use SelfControl::UI;

    my $ui = SelfControl::UI->new({
      config => $SelfControlConfig,
    });

    $ui->run();
    if ( $ui->{started} ) {
      # user hit start.
      do_something_with( $ui->{config} );
    }
    else {
      # user hit cancel.
    }

=head1 EXPORT

No Exports.  Useful entries in the object hash are:

=over

=item started

True if user clicked the 'Start' button.

=item config

Contains the reference to the configuration hash.

=back

=head1 SUBROUTINES/METHODS

=cut

=head2 new()

    $ui = SelfControl::UI->new({ config => $SelfControlConfig })

Only one option at the moment.

=cut

sub new {
  my ($class, $conf) = @_;
  $conf->{started} = 0;
  return bless $conf, $class;
}

=head2 run()

Builds the Gtk2 interface and runs Gtk2->main().

=cut

sub run {
  my ($self) = @_;
  require Gtk2;
  require Gtk2::SimpleList;
  require Gtk2::SimpleMenu;
  Gtk2->init;
  add_custom_col();
  $self->build_ui;
  Gtk2->main;
}

sub add_custom_col {
Gtk2::SimpleList->add_column_type(
  'ts',
    type => 'Glib::Scalar',
    renderer => 'Gtk2::CellRendererText',
    attr => sub {
      my ($tree_column, $cell, $model, $iter, $i) = @_;
      my $info = $model->get ($iter, $i);
      my @t = localtime($info);
      $t[4]++;$t[5]+=1900;$t[5]=~s/^\d\d//;
      $info = sprintf "%02d/%02d/%02d %02d:%02d:%02d", @t[4,3,5,2,1,0,];
      $cell->set(text => $info);
    },
);
}

=head1 AUTHOR

zengargoyle C<< <zengargoyle at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<zengargoyle at gmail.com>.

=head1 SUPPORT

You can find documentation for this application with the perldoc command.

    perldoc SelfControl


You can also look for information at:

=over 4

=item * The SelfControl Linux homepage

L<http://svn.jklmnop.net/projects/SelfControl.html>

=item * The SelfControl Linux subversion repository

L<http://svn.jklmnop.net/proj/SelfControl>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 zengargoyle.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

#
# Build the UI.
#
sub menu {
  my ($self) = @_;
  my $mt = [
    _Application => {
      item_type => '<Branch>',
      children => [
        _Start => {
          callback => sub { $self->start; },
          accelerator => '<ctrl>S',
        },
        _Quit => {
          callback => sub { $self->cancel; },
          accelerator => '<ctrl>Q',
        },
      ],
    },
    _View => {
      item_type => '<Branch>',
      children => [
        '_Active Blocks' => {
          callback => sub { $self->view_active; },
        },
      ],
    },
    _Help => {
      item_type => '<Branch>',
      children => [
        _About => {
          callback => sub { $self->about; },
        },
      ],
    },
  ];
  my $menu = Gtk2::SimpleMenu->new(
    menu_tree => $mt,
  );
  return $menu;
}


sub build_ui {
  my ($self) = @_;

  $self->{menu} = $self->menu;

# Tooltip
  my $tt = Gtk2::Tooltips->new;

# Window
  my $window = Gtk2::Window->new('toplevel');
  $self->{main_window} = $window;

  $window->set_title("SelfControl");
  $window->set_border_width(0);
  #$window->set_default_size(500,500);

  $window->signal_connect(delete_event => sub { FALSE; });
  $window->signal_connect(destroy => sub { Gtk2->main_quit; });

# VBox
  my $box = Gtk2::VBox->new(FALSE, 0);

# Frame
  my $frame;
  $frame = Gtk2::Frame->new('Block Method');
  $frame->add($box);

# RadioButton
  my $radio;
  #$radio = Gtk2::RadioButton->new(undef, 'Whitelist');
  #$radio->set_active(TRUE) if !$self->{config}->{allow};
  #$radio->signal_connect(toggled => sub { $self->{config}->{allow} = 0; });
  #$box->pack_start($radio, TRUE, TRUE, 0);
  #my @group = $radio->get_group;

# RadioButton
  #$radio = Gtk2::RadioButton->new_with_label(@group, 'Blacklist');
  $radio = Gtk2::RadioButton->new(undef, 'Blacklist');
  $radio->signal_connect(toggled => sub { $self->{config}->{allow} = 1; });
  $radio->set_active(TRUE) if $self->{config}->{allow};
  $box->pack_start($radio, TRUE, TRUE, 0);

# VBox
  $box = Gtk2::VBox->new(FALSE, 0);
  $box->pack_start($self->{menu}->{widget}, FALSE, FALSE, 0);
  $box->pack_start($frame, FALSE, FALSE, 0);

# Frame
  $frame = Gtk2::Frame->new('Host List');

# VBox
  my $vbox;
  $vbox = Gtk2::VBox->new(FALSE, 0);
  $frame->add($vbox);

# HBox
  my $hbox;
  $hbox = Gtk2::HBox->new(FALSE, 0);
  $vbox->pack_start($hbox, TRUE, TRUE, 0);

# SimpleList
  my $list = Gtk2::SimpleList->new('Host'=>'text', 'IP'=>'text');
  $self->{host_list} = $list;
  $tt->set_tip($list, "Select hosts for deletion.");
  $list->set_data_array($self->{config}->{hosts});
  $list->get_selection->set_mode('multiple');

  # we need the following line otherwise the list is too small
  $list->set_size_request(350,500);

  my @columns = $list->get_columns;
  my $cnum = scalar(@columns);
  my $c;
  foreach $c (@columns) {
	$c->set_resizable(TRUE);
  }

  my $rows = $self->{config}->{hosts};
  my $rnum = scalar(@$rows);

  if ($rnum > 10){ $rnum = 10; }
  if ($rnum < 2){ $rnum = 2; }

  $list->set_size_request (175 * $cnum, 28 * $rnum);

# ScrolledWindow
  my $scroll = Gtk2::ScrolledWindow->new;
  $scroll->set_policy('automatic', 'automatic');
  $scroll->add($list);
  $hbox->pack_start($scroll, TRUE, TRUE, 0);

# Button
  my $button;
  $button = Gtk2::Button->new("Delete");
  $tt->set_tip($button, "Delete selected hosts.");
  $button->signal_connect(clicked => sub { $self->del_host; });
my $bb = Gtk2::VButtonBox->new;
$bb->set_layout_default('start');
$bb->add($button);
  $hbox->pack_end($bb, FALSE, FALSE, 0);

# HBox
  $hbox = Gtk2::HBox->new(FALSE, 0);
  $vbox->pack_start($hbox, FALSE, TRUE, 0);

  
# Entry
  my $entry = Gtk2::Entry->new;
  $self->{host_entry} = $entry;
  $entry->set_width_chars(30);
  $tt->set_tip($entry, "Enter a hostname or IP.");
  $entry->signal_connect(activate => sub { $self->add_host; });
  $hbox->pack_start($entry, TRUE, TRUE, 0);

# Button
  $button = Gtk2::Button->new("Add");
  $tt->set_tip($button, "Add host to list.");
  $button->signal_connect(clicked => sub { $self->add_host; });
$bb = Gtk2::HButtonBox->new;
$bb->set_layout_default('end');
$bb->add($button);
  $hbox->pack_start($bb, FALSE, TRUE, 0);

  $box->pack_start($frame, TRUE, TRUE, 0);

# Frame
  $frame = Gtk2::Frame->new('Block Time');
  $box->pack_start($frame, FALSE, FALSE, 0);

  {
    my $vbox = Gtk2::VBox->new(FALSE, 0);

    my $scale = Gtk2::HScale->new_with_range(5, (24*60), 5);
    $self->{config}->{timeout} = 5 if $self->{config}->{timeout} < 5;
    $scale->set_digits(0);
    $scale->set_draw_value(0);
    my $label = Gtk2::Label->new('');
    $self->{config}->{timeout} = update_time($label, $self->{config}->{timeout});
    $scale->set_value($self->{config}->{timeout});

    $scale->signal_connect(value_changed => sub {
      my ($s) = @_;
      my $t = $s->get_adjustment->value;
      $self->{config}->{timeout} = update_time($label, $t);
      $s->set_value($self->{config}->{timeout});
      }
    );

    $vbox->pack_start($scale, FALSE, FALSE, 0);
    $vbox->pack_start($label, FALSE, FALSE, 0);
    $frame->add($vbox);
  }

# Button
$bb = Gtk2::HButtonBox->new;
$bb->set_layout_default('edge');
  $button = Gtk2::Button->new("Cancel");
  $tt->set_tip($button, "Quit without doing anything.");
  $button->signal_connect(clicked => sub { $self->cancel; });
$bb->add($button);
  $button = Gtk2::Button->new("Start");
  $tt->set_tip($button, "Start SelfControl");
  $button->signal_connect(clicked => sub { $self->start; });
$bb->add($button);
  $box->pack_start($bb, FALSE, FALSE, 0);

# Show
  $window->add($box);
  $window->show_all;
}

sub about {
  my ($self) = @_;
  my $about = $self->{about};
  if ($about) {
    $about->run;
    $about->hide;
    return;
  }
  $about = Gtk2::AboutDialog->new;
  $self->{about} = $about;
  $about->set_logo_icon_name('selfcontrol');
  $about->set_program_name('SelfControl');
  $about->set_version($SelfControl::VERSION);
  $about->set_comments("Helping you get things done\nby not getting things done myself.");
  $about->set_copyright("\x{00a9}".'2010 zengargoyle');
  $about->set_website_label('SelfControl Homepage');
  $about->set_website('http://svn.jklmnop.net/projects/SelfControl.html');
  $about->set_license(<<_EOL_);
LICENSE AND COPYRIGHT

Copyright \x{00a9} 2010 zengargoyle

This program is free software; you can redistribute it and/or modify it under the terms of either: the GNU General Public License as published by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
_EOL_
  $about->set_wrap_license(TRUE);
  $about->set_authors('zengargoyle <zengargoyle@gmail.com>');
  #$about->set_documenters('zengargoyle <zengargoyle@gmail.com');
  #$about->set_translator_credits('translator');
  #$about->set_artists('artist1');
  $about->run;
  $about->hide;
}

sub view_active {
  my ($self) = @_;
  my $w = $self->{window};

  my $d;
  $d = Gtk2::Dialog->new('Active Blocks',$w,'destroy-with-parent', 'gtk-ok' => 'none');
  $d->set_default_size(500,240);

  my $f = Gtk2::Frame->new();
  $d->get_content_area()->add($f);

  my $s = Gtk2::ScrolledWindow->new;
  $s->set_policy('automatic','automatic');
  $f->add($s);

  my $ls = Gtk2::SimpleList->new(
    'tsort'  => 'text',
    'Job ID' => 'text',
    'Expiration Time'   => 'ts',
    'Host'   => 'text',
    'IP'     => 'text',
    'ipsort' => 'text'
  );
  $s->add($ls);

  $ls->set_rules_hint(TRUE);

  $ls->get_column(0)->set_visible(FALSE);
  $ls->get_column(1)->set_visible(FALSE);
  $ls->get_column(2)->set_sort_column_id(0);
  $ls->get_column(3)->set_sort_column_id(3);
  $ls->get_column(4)->set_sort_column_id(5);
  $ls->get_column(5)->set_visible(FALSE);
if (0) {
  my $filter = SelfControl::get_active($self->{config});
  my $jobs = $self->{config}{jobs};
  for my $k (keys %{$jobs}) {
    my ($d, $q) = @{$jobs->{$k}};
    for my $y (@{$q}) {
      my ($h, $i) = @{$y};
      push @{$ls->{data}}, [$d, $d, $h, $i, ip_toi($i)];
    }
  }
}
  my @abl;
  @abl = map {[$_->[1],@{$_},ip_toi($_->[3])]} @{$self->{active_blocks}};
  $ls->set_data_array(\@abl);
  $d->set_default_response('ok');
  $d->show_all;
  $d->run;
  $d->destroy;
}

#
# Actions
#

sub start {
  my ($self) = @_;
  $self->{started} = 1;
  $self->{main_window}->destroy;
}
sub cancel {
  my ($self) = @_;
  $self->{main_window}->destroy;
}
sub del_host {
  my ($self) = @_;
  my ($list) = $self->{host_list};
  my (@sel) = $list->get_selected_indices;
  for my $s (@sel) {
    splice @{$list->{data}}, $s, 1;
    splice @{$self->{config}->{hosts}}, $s, 1;
  }
}
sub add_host {
  my ($self) = @_;
  my ($list) = $self->{host_list};
  my ($entry) = $self->{host_entry};
  return unless length $entry->get_text;
  my (@info) = host2name_ip($entry->get_text);
  return unless @info;
  my @data = sort {$a->[0] cmp $b->[0]} @{$self->{config}->{hosts}}, [@info];
  $self->{config}->{hosts} = [@data];
  $list->set_data_array($self->{config}->{hosts});
  $entry->set_text('');
}

#
# Support routines
#

sub host2name_ip {
  use Socket;

  my $host = shift;

  # Get an IP address.
  my $packed = gethostbyname($host);

  # Lookup failed?
  return if not defined $packed; 

  my $ip = inet_ntoa($packed);
  if ( $host eq $ip ) {
  # Was given IP, return reverse lookup or IP as name.
    my $name = gethostbyaddr($packed,AF_INET);
    $name = $ip unless defined $name;
    return ($name, $ip);
  }
  else {
  # Was given hostname, return it.
    return ($host, $ip);
  }
} 
sub update_time {
  my ($l,$t) = @_;
  $t = int($t/5)*5;
  my ($h,$m) = (int($t/60), $t%60);
  my $text;
  $text .= "$h hour" if $h > 0;
  $text .= "s"       if $h > 1;
  $text .= " $m minute" if $m > 0;
  $text .= "s"          if $m > 1;
  $l->set_text($text);
  return $t;
}
sub ip_toi {
  use Socket;
  unpack "N", inet_aton($_[0]);
}

1; # End of SelfControl::UI

__END__
sub build_dialog {
  #$d = Gtk2::MessageDialog->new($w, 'destroy-with-parent', 'info', 'ok', 'My message here');
  #$d = Gtk2::MessageDialog->new_with_markup($w, 'destroy-with-parent', 'info', 'ok', '<b>My message</b> here');
  $d = Gtk2::MessageDialog->new_with_markup($w, 'destroy-with-parent', 'error', 'ok', '<b>My message</b> here');
  $d->format_secondary_markup('<i>what is this</i>');
  $d->run;
  $d->destroy;
}

