:; OUTIN=${1-. $0};shift;echo 1>&2 "Configure $OUTIN $@"
:; echo 1>&2 "Trying Perl...";perl -ne '/^\$exe\/perl( |$)/?($t=1,$_=""):$t&&/^\S/&&exit||s/^\s\s//;$t&&print' "$0"|perl - $OUTIN "$@"&&exit
:; echo 1>&2 "Trying Python...";python -c 'import sys;print>>sys.stderr,"FIXME: Python not implemented";sys.exit(1)' $OUTIN "$@"&&exit
:; echo 1>&2 "Failed!";exit 1
@echo off
echo Trying %COMSPEC%...
echo FIXME: %COMSPEC% not implemented
exit 1

Launch this file to install Figure from sources.

C:\User\Figure> configure

It works on Unix-like platforms, too (the '.bat' extension is irrelevant):

$ ./Configure.bat

On success, a friendly welcome will be displayed, as well as instructions
for where to go next.

Have fun!

Michael FIG <michael+figure@fig.org>, 2018-10-16

[guilt
This identifies the rest of this file as Guilt source code.
]

[define figure/configure Figure bootstrap
  Figure's bootstrap, in different languages.
  
  This version understands:
  * [guilt] tag defining comment syntax and activating Guilt
  * [define DEST ...] for creating cells
  * [insert DEST SRC] for putting a cell before others in the DEST
  * [comment SRC] expansions
  * [inline SUBST=EXPR [SUBST2=EXPR2...]] expansions
  * [+ EXPR...] addition
VERSION 0.1.0
  Figure's Configure semantic version.
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
$exe/perl guilt
  #! /usr/bin/env perl
  # [guilt
  # ]
  #
  # [comment $cc/LICENSE
  # Copyright © 2018, Michael FIG <michael+figure@fig.org>
  #
  # Permission to use, copy, modify, and/or distribute this software for any
  # purpose with or without fee is hereby granted, provided that the above
  # copyright notice and this permission notice appear in all copies.
  #
  # THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
  # WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
  # MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
  # ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
  # WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
  # ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
  # OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  # ]
  #
  # Michael FIG <michael+figure@fig.org>, 2018-10-14
  
  # [inline @line@=[+ $GUILT/IN/line-number 3] @src@=$GUILT/IN/$src
  # #line @line@ @src@
  #line 92
  # ]

  # Comments are for the weak.  I'll add them once Guilt actually processes
  # Configure.bat.
  use strict;
  use warnings;

  package Figure::Boot;
  # [inline @VERSION@=./VERSION
  # my $VERSION = "@VERSION@";
  my $VERSION = "0.1.0";
  # ]

  sub main {
    my ($pkg, @args) = @_;

    my $KS = Figure::KS->new;
    $KS->slog(1, "Greetings from Figure Configure/Perl $VERSION!");
    $KS->write('$/guilt/$exe/perl-primitive', 'Figure::Guilt');

    # Input phase.  Run as a subroutine, using the same kernel.
    $KS->apply($KS, '$/guilt', @args);
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

    if (!$create) {
      my $fw = $dir ? '' : '-';
      die "Cannot lookup `$fw$dim'";
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

    my $res = eval {
      return $self->[GUSH]->resolve($cell, $path)->get();
    };
    if ($@) {
      $self->slog(0, $@);
    }
    return $res;
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

  sub apply {
    my ($self, $ks, $path, @args) = @_;
    my $env = {PROGNAME => $path};
    if (ref $args[0]){
      my $toadd = shift @args;
      $env = {%$env, %$toadd};
    }
    my $prim = $self->read($self->[CONTEXT], $path . '/$exe/perl-primitive');
    {
      no strict 'refs';
      my $sym = "$prim\::apply";
      return &$sym($ks, $env, @args);
    }
  }

  sub slog {
    my ($self, $level, @args) = @_;
    my $context = {};
    if (ref $args[0]) {
      # Context hash.
      $context = shift @args;
    }

    if (!$level) {
      require Carp;
      Carp::confess("Fatal error: ", @args);
    }

    local $, = '';
    print STDERR @args, "\n";
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
      if ($target) {
        $target = $target->lookup($create, @link);
      }
    }

    if (!$create && !$target) {
      die "Cannot resolve `$path'"
    }
    return $target;
  }

  package Figure::Guilt;

  # If present, a PKG::op($KS, $text) sub will be called with the macro body
  # text.  It does parsing by itself, and can choose to apply() later.

  sub apply {
    my ($KS, $KW, @ARGS) = @_;

    my $OUT = shift @ARGS;
    my @IN = @ARGS;
    if (!@IN) {
      @IN = ($OUT);
    }

    if (!$OUT) {
      $KS->slog(0, "You must specify an OUT cell");
    }

    for my $in (@IN) {
      $KS->slog(1, "Processing \`$in'...");
      open(IN, '<', $in) ||
        $KS->slog(0, "Cannot read \`$in': $!");
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
      $KS->insert('$OUT', $cell);
    }

    # Output phase.
    if ($OUT eq '$STDOUT') {
      my $name = $KS->read('$OUT/$name');
      $KS->slog(1, "Writing $name to \$STDOUT...");
      print $KS->read('$OUT');
    }
    elsif (-d $OUT) {
      # Find each main output.
      my $cell = $KS->find('$OUT');
      while ($cell) {
        $KS->slog(1, "FIXME: Would replace ", $KS->read($cell, '$name'));
        $cell = $KS->find($cell, '$OUT');
      }
    }
    else {
      $KS->slog(1, "Generating \`$OUT'...");
      open(OUT, '>', $OUT) ||
        $KS->slog(0, "Cannot write \`$OUT': $!");
      print OUT $KS->read('$OUT');
      close(OUT) ||
        $KS->slog(0, "Cannot commit \`$OUT': $!");
    }
    $KS->slog(1, "Success!");
    return 0;
  }

  # Run the bootstrap package, unless we're a module.
  Figure::Boot->main(@ARGV) unless caller;
  1;
]

FIXME: The rest of Figure would go here!
