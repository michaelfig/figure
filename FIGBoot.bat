:; OUTIN=${1-. figure.glt}; shift; echo "FIGBoot $OUTIN $@"
:; echo "Trying Perl..."; perl -ne '/^\$exe\/perl(:|$)/?($t=1,$_=""):$t&&/^\S/&&exit||s/^\s\s//;$t&&print' "$0" | perl - $OUTIN "$@" && exit
:; echo "Trying Python..."; python -c 'print "FIXME: Python not implemented"; import sys; sys.exit(1)' $OUTIN "$@" && exit
:; echo "Failed!"; exit 1
@echo off
echo Trying %COMSPEC%...
echo FIXME: %COMSPEC% not implemented
exit 1

Run this file to build figure.glt from sources.  This uses a bootstrap
version of the Guilt macro processor, which supports a subset of Figure's
fully-featured Guilt.

On Unix-like:

$ sh FIGBoot.bat

On Windows:

cmd> figboot

Have fun!

Michael FIG <michael+figure@fig.org>, 2018-10-14

[guilt
This identifies the rest of this file as Guilt source code.
]

[define $bin/FIGBoot
  Figure's bootstrap Guilt macro processor, in different languages.
  
  This is only part of the bootstrap process.
  To install Figure completely, you'll still need to run:
  
  $ $bin/FIGBoot FIGURE.glt

  This version understands:
  * [guilt] tag syntax.
  * [define CELLREF ...] for creating cells.
  * [copy SRC-CELLREF DEST-CELLREF] for copying cells.
  * [insert DEST-CELLREF SRC-CELLREF] for putting a cell
  * [replace CELLREF] for expansion of cells.
  * [comment ...] expansions
  * [inline SUBST VALUE] expansions
VERSION 0.0.1
  FIGBoot semantic version.
  
  This is not Figure's version as a whole.  That is located in $FIGURE/VERSION.
LICENSE ISC
  Copyright © 2018, Michael FIG <michael+figure@fig.org>

  Permission to use, copy, modify, and/or distribute this software for any
  purpose with or without fee is hereby granted, provided that the above
  copyright notice and this permission notice appear in all copies.

  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
$exe/gush
  # The Guilt macro processor, recursively in Figure's Gush.
  $bin/FIGBoot $ARGS
$exe/perl
  #! /usr/bin/env perl
  # [guilt
  # ]
  #
  # [comment $bin/FIGBoot/LICENSE
  # ]
  #
  # Michael FIG <michael+figure@fig.org>, 2018-10-14
  
  # [inline @@ $IN/$lineno
  #   #line @@
  #line 80
  # ]

  use strict;
  use warnings;

  package Figure::Boot;
  # [inline @@ $bin/FIGBoot/VERSION
  #   my $VERSION = "@@";
  my $VERSION = "NOTSET";
  # ]

  sub main {
    my ($pkg, @args) = @_;

    my $KS = Figure::KS->new;
  
    print STDERR "Greetings from Perl FIGBoot $VERSION (one part of Figure)!\n";

    my $OUT = shift @args;
    my @IN = (@args);
    if (!@IN) {
      @IN = ($OUT);
    }

    if (!$OUT) {
      print STDERR "You must specify an OUT cell\n";
      exit 1;
    }

    # Input phase.
    for my $in (@IN) {
      print STDERR "Processing \`$in'...\n";
      open(IN, '<', $in) ||
        die "Cannot read \`$in': $!\n";
      my $buf = '';
      while ($_ = <IN>) {
        $buf .= $_;
      }
      close(IN);

      # Save the contents to $OUT.
      my $cell = $KS->cell($in);
      $KS->write($cell, $buf);

      # We reverse the order, so that the last output is the default one
      # to write below.
      $KS->insert('OUT', $cell);
    }

    # Output phase.
    if ($OUT eq '$STDOUT') {
      my $name = $KS->read('OUT/$name');
      print STDERR "Writing $name to \$STDOUT...\n";
      print $KS->read('OUT');
    }
    elsif (-d $OUT) {
      # Find each main output.
      my $cell = $KS->find('OUT');
      while ($cell) {
        print "FIXME: Would replace ", $KS->read($cell, '$name'), "\n";
        $cell = $KS->find($cell, 'OUT');
      }
    }
    else {
      print STDERR "Generating \`$OUT'...\n";
      open(OUT, '>', $OUT) ||
        die "Cannot write \`$OUT': $!\n";
      print OUT $KS->read('OUT');
      close(OUT) ||
        die "Cannot commit \`$OUT': $!\n";
    }
    print STDERR "Success!\n";
    exit 0;
  }

  package Figure::O;

  use constant CONTENT => 0;
  use constant FORWARD => 1;
  use constant BACKWARD => 2;

  sub new {
    my ($pkg) = @_;
    if (ref $pkg) {
      $pkg = ref $pkg;
    }
    my $self = [];
    $self->[CONTENT] = '';
    $self->[FORWARD] = {};
    $self->[BACKWARD] = {};
    bless $self, $pkg;
    return $self;
  }

  sub lookup {
    my ($self, $create, $dir, $dim) = @_;
    my $next = $dir ? FORWARD : BACKWARD;
    my $exists = $self->[$next]{$dim};
    if (defined $exists || !$create) {
      return $exists;
    }
    my $prev = $dir ? BACKWARD : FORWARD;
    my $cell = $self->new();
    $cell->[$prev]{$dim} = $self;
    $self->[$next]{$dim} = $cell;
    return $cell;
  }

  sub insert {
    my ($self, $target, $dir, $dim) = @_;
    my $next = $dir ? FORWARD : BACKWARD;
    my $prev = $dir ? BACKWARD : FORWARD;
    my $snext = $self->[$next]{$dim};
    $target->[$prev]{$dim} = $self;
    if ($snext) {
      $target->[$next]{$dim} = $snext;
      $snext->[$prev]{$dim} = $target;
    }
    $self->[$next]{$dim} = $target;
    return $self;
  }

  sub set {
    my ($self, $content) = @_;
    $self->[CONTENT] = $content;
    return $self;
  }

  sub get {
    my ($self) = @_;
    return $self->[CONTENT];
  }

  package Figure::KS;

  use Scalar::Util qw(blessed);
  use constant CONTEXT => 0;
  use constant GUSH => 1;

  sub new {
    my ($pkg) = @_;
    my $self = [];
    $self->[CONTEXT] = Figure::O->new;
    $self->[GUSH] = Figure::Gush->new;
    bless $self, $pkg;
    return $self;
  }

  sub cell {
    my ($self, $src) = @_;
    my $cell = $self->[CONTEXT]->new();
    if (!defined $src) {
      return $cell;
    }

    my ($parent, $name);
    if ($src =~ m!^((.*)/)?(.*)$!) {
      $parent = $1 || '.';
      $name = $3;
    }
    else {
      $parent = '.';
      $name = $src;
    }

    my $pcell = $cell->new->set($parent);
    my $ncell = $cell->new->set($name);
    my $scell = $cell->new->set($src);

    my (undef, @plink) = $self->[GUSH]->resolve(undef, '$parent', -1);
    my (undef, @nlink) = $self->[GUSH]->resolve(undef, '$name', -1);
    my (undef, @slink) = $self->[GUSH]->resolve(undef, '$src', -1);
    $cell->insert($pcell, @plink);
    $cell->insert($ncell, @nlink);
    $cell->insert($scell, @slink);
    return $cell;
  }

  sub read {
    my $self = shift;
    my $cell = shift;
    my $path;
    if (blessed $cell && $cell->isa('Figure::O')) {
      $path = shift;
    }
    else {
      $path = $cell;
      $cell = $self->[CONTEXT];
    }

    if (!defined $path) {
      # No path at all.
      return $cell->get();
    }

    return $self->[GUSH]->resolve($cell, $path)->get();
  }

  sub write {
    my $self = shift;
    my $cell = shift;
    my $path;
    if (blessed $cell && $cell->isa('Figure::O')) {
      $path = shift;
    }
    else {
      $path = $cell;
      $cell = $self->[CONTEXT];
    }

    my $str = shift;
    if (!defined $str) {
      # No path after all.
      $str = $path;
      $cell->set($str);
      return;
    }

    $self->[GUSH]->resolve($cell, $path, 1)->set($str);
    return;
  }

  sub insert {
    my $self = shift;
    my $cell = shift;
    my $path;
    if (blessed $cell && $cell->isa('Figure::O')) {
      $path = shift;
    }
    else {
      $path = $cell;
      $cell = $self->[CONTEXT];
    }

    my $target = shift;

    my ($parent, @link) = $self->[GUSH]->resolve($cell, $path, -1);
    $parent->insert($target, @link);
    return;
  }

  package Figure::Gush;

  sub new {
    my ($pkg) = @_;
    my $self = {};
    bless $self, $pkg;
    return $self;
  }

  sub link {
    my ($self, $name) = @_;
    my $dir = 1;
    if ($name =~ /^-(.*)/) {
      $dir = 0;
      $name = $1;
    }
    my $dim = $name;
    return ($dir, $dim);
  }

  sub resolve {
    my ($self, $cell, $path, $create) = @_;
    my $i = 0;
    my $name = '';
    my $len = length($path);
    my $target = $cell;
    while ($i < $len) {
      my $c = substr($path, $i, 1);
      if ($c eq '/') {
        my @link = $self->link($name);
        $target = $target->lookup($create, @link);
        $name = '';
        $i ++;
      }
      else {
        $name .= $c;
        $i ++;
      }
    }

    if ($name ne '') {
      my @link = $self->link($name);
      if ($create && $create < 0) {
        return ($target, @link);
      }
      $target = $target->lookup($create, @link);
    }

    if (!$create && !$target) {
      die "Cannot resolve `$path'"
    }
    return $target;
  }

  # Run the bootstrap package, unless we're a module.
  Figure::Boot->main(@ARGV) unless caller;
  1;
]

Expand the cell references within $bin/FIGBoot.

[replace $bin/FIGBoot/$exe/perl]

Mark $bin/FIGBoot as our main output in case they use Guilt on us.

[insert $OUT $bin/FIGBoot]
