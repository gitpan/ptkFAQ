#!/usr/bin/perl

# Dial widget
# ***********
# 
# Roy Johnson (rjohnson@shell.com)
# Tue, 22 Aug 95 16:07:59 CDT 
# 
# Here's a dial widget I wrote as an exercise in learning how to write
# Composite widgets. If noone else has written a good dial widget, I'd
# be happy to let this one be the start. If there is a dial widget
# already out there, I'd like to know about it, but I'd still like my
# code critiqued by any of you who has some time to do so.
# 
# I especially want comments regarding:
# 
# - features it should have (not so important if it's not going to be
#   an "official" widget). See the documentation for features I already
#   have in mind.
# - poor use of Tk: working too hard to accomplish something
# - poor use of Perl's object-oriented features
# 
# -------- Roy Johnson ---- rjohnson@shell.com ---- Speaking for myself --------
# "When the only tool you have is Perl, the whole | "Hooray for snakes!"
# world begins to look like your oyster." -- Me   | -- The Simpsons (29 Apr 93)
# ============== And remember, you heard it first on Usenet News ===============

use Tk;

package Dial;
@ISA = qw(Tk::Frame); 

$pi = atan2(1, 1) * 4;

Tk::Widget->Construct('Dial');

=head1 NAME

Dial - an alternative to the scale widget

=head1 SYNOPSIS

use Tk::Dial;

$dial = $top->Dial(-margin => 20,
-radius => 48,
-min => 0,
-max => 100,
-value => 0,
-format => '%d');

margin - blank space to leave around dial
radius - radius of dial
min, max - range of possible values
value - current value
format - printf-style format for displaying format

Values shown above are defaults.

=head1 DESCRIPTION

A dial looks like a speedometer: a 3/4 circle with a needle indicating
the current value. Below the graphical dial is an entry that displays
the current value, and which can be used to enter a value by hand.

The needle is moved by pressing button 1 in the canvas and dragging. The
needle will follow the mouse, even if the mouse leaves the canvas, which
allows for high precision. Alternatively, the user can enter a value in
the entry space and press Return to set the value; the needle will be
set accordingly.

=head1 TO DO

Configure
Tick marks
Step size

=head1 AUTHORS

Roy Johnson, rjohnson@shell.com

Based on a similar widget in XV, a program by John Bradley,
bradley@cis.upenn.edu

=head1 HISTORY 

August 1995: Released for critique by pTk mailing list

=cut 

@flags = qw(-margin -radius -min -max -value -format);

sub Populate
{
my ($w, $args) = @_;

@$w{@flags} = (20, 48, (0, 100), 0, '%d');
for $key (@flags) {
my $val = delete $args->{$key};
if (defined $val) {
$$w{$key} = $val;
}
}

# Pass other args on to Frame
$w->InheritThis($args);

# Convenience variables, based on flag settings
my ($margin, $radius, $min, $max, $format) = @$w{@flags};
my ($center_x, $center_y) = ($margin + $radius) x 2;

# Create Widgets
my $c = $w->Canvas(-width => 2 * ($radius + $margin),
-height => 1.75 * $radius + $margin);

$c->create('arc',
($center_x - $radius, $center_y - $radius),
($center_x + $radius, $center_y + $radius),
-start => -45, -extent => 270, -style => 'chord',
-width => 2);

$c->pack(-expand => 1, -fill => 'both');

$w->bind($c, '<1>' => \&drawPointer);
$w->bind($c, '<B1-Motion>' => \&drawPointer);

my $e = $w->Entry(-textvariable => \$w->{-value});
$e->pack();

$w->bind($e, '<Return>' => sub { &setvalue($c) });

&setvalue($c);
}
#------------------------------
sub drawPointer
{
my $c = shift;
my $w = $c->parent;
my $e = $c->XEvent;

# Convenience variables, based on flag settings
my ($margin, $radius, $min, $max, $value, $format) = @$w{@flags};
my ($center_x, $center_y) = ($margin + $radius) x 2;

my ($delta_x, $delta_y) = ($e->x - $center_x, $e->y - $center_y);
my $distance = sqrt($delta_x**2 + $delta_y**2);
return if ($distance < 1);

# atan2/pi returns the angle in pi-radians, but out-of-phase;
# here we correct it to be 0 at the start of the arc
my $angle = atan2($delta_y, $delta_x) / $pi + 1.25;
if ($angle > 2) { $angle -= 2 }

if ($angle < 1.5) {
my $factor = $radius/$distance;
my $newx = $center_x + int($factor * $delta_x);
my $newy = $center_y + int($factor * $delta_y);

$c->delete('oldpointer');
$c->create('line', ($newx, $newy, $center_x, $center_y),
-arrow => 'first', -tags => 'oldpointer',
-width => 2);

$w->{-value} = sprintf($format,
$angle / 1.5 * ($max - $min) + $min);
} elsif ($angle < 1.75) {
if ($w->{-value} < $max) {
&setvalue($c);
$w->{-value} = $max;
}
} else {
if ($w->{-value} > $min) {
&setvalue($c);
$w->{-value} = $min;
}
}

}

#------------------------------

sub setvalue {
my $c = shift;
my $w = $c->parent;

my $value = $w->{-value};

# Convenience variables, based on flag settings
my ($margin, $radius, $min, $max, $dummy, $format) = @$w{@flags};
my ($center_x, $center_y) = ($margin + $radius) x 2;

if ($value > $max) {
$value = $max;
} elsif ($value < $min) {
$value = $min;
}

$w->{-value} = sprintf($format, $value);

# value = (angle / 1.5) * (max-min) + min
# Solving backwards...
# value - min = angle / 1.5 * (max-min)
# (value - min) * 1.5 / (max-min) = angle

my $angle = ($value - $min) * 1.5 / ($max - $min);
$angle -= 1.25;
$angle *= $pi;

# Now just figure out X and Y where atan2 == $angle
my($x, $y) = (cos($angle) * $radius, sin($angle) * $radius);
$x += $center_x;
$y += $center_y;
$c->delete('oldpointer');
$c->create('line', ($x, $y, $center_x, $center_y),
-arrow => 'first', -tags => 'oldpointer',
-width => 2);

}

