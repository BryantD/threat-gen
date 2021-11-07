#!/usr/bin/perl -w

#### Author:  	Abbi @ Earthen Ring (US)
####		strand.osric@gmail.com
#### Version:	1.0.1
#			.3 	first version number
#			.31	fixed druid threat to be additive
#			.32	replaced Date::Parse with Time::Local
#			.4	added state machine, Spell Reflect
#			.5	added overhealing
#			.6	reworked the whole loop cause it was wrong
#			.61	tightened up regexps
#			.7	removed threat from Lifebloom
#			.71	removed threat from LotP
#			1.0	first public release!
#			1.0.1	strip high ASCII

use Time::Local;
use Getopt::Std;
use strict;

#### Usage:	-t <tank>
####		-c <class>
####		-v (verbose)

####		Next four options default to on unless one is selected
####		-s (chart threat from specials)
####		-w (chart threat from white damage)
####		-o (chart threat from third parties)
####		-g (chart threat from gear)

####		-[0123] (points in Defiance/Feral Instinct, default is 3)
####		-h (hack in Sunder values once per 3 seconds at start)

my %opts;
getopts('0123swogvht:c:', \%opts);

my $tank = $opts{'t'};
my $debug = $opts{'v'};
my $class = substr(lc($opts{'c'}), 0, 1);

# Default to charting all threat, plz

$opts{'s'} = $opts{'w'} = $opts{'o'} = $opts{'g'} = 1 if (! ($opts{'s'} || $opts{'w'} || $opts{'o'} || $opts{'g'}));

# Set up general threat modifiers; we default to 3/3 tanking talent points

my $talent_mod;
my $t_mod;
my $h_mod;

if ($class eq "w") {
	$talent_mod = 1.15;

	$talent_mod = 1.00 if $opts{'0'};
	$talent_mod = 1.05 if $opts{'1'};
	$talent_mod = 1.10 if $opts{'2'};
	$talent_mod = 1.15 if $opts{'3'};
}
elsif ($class eq "d") {
	$talent_mod = .15;

	$talent_mod = 0 if $opts{'0'};
	$talent_mod = .05 if $opts{'1'};
	$talent_mod = .10 if $opts{'2'};
	$talent_mod = .15 if $opts{'3'};
}
elsif ($class eq "p") {
	$talent_mod = .50;

	$talent_mod = 0 if $opts{'0'};
	$talent_mod = .16 if $opts{'1'};
	$talent_mod = .33 if $opts{'2'};
	$talent_mod = .50 if $opts{'3'};
}

if ($class eq "w") {
	$t_mod = $talent_mod * 1.3;
	$h_mod = 1;
}
elsif ($class eq "d") {
	$t_mod = $talent_mod + 1.3;
	$h_mod = 1;
}
elsif ($class eq "p") {
	$t_mod = 1;
	$h_mod = 1.6 + (.6 * $talent_mod);
}

#### Threat sources:
####	Define one hash for each type (specials, white damage, 3rd party, gear)
####	Third party threat is threat generated through no fault of the 
####	tank -- i.e., healing, Blessing of Sanctuary, etc.

#### To Do:
####	Stances?  Misdirection maybe someday.

my %threatlines;
my %s_threatlines;
my %w_threatlines;
my %o_threatlines;
my %g_threatlines;

if ($class eq "w") {
	#### Warrior threat

	#### Missing: 	Demo Shout, Commanding Shout, Battle Shout, 
	####		Sunder Armor, Disarm (not assigned to specific actor) 
	####		Execute (won't happen in def stance)

	%s_threatlines = (
	# Basic damage
	$tank . '\'s Shoot (cr|h)its (.+) for (\d+).' =>
				'$3 * ' . $t_mod,
	'(.+) suffers (\d+) Physical damage from ' . $tank . '\'s Rend.' =>  
				'$2 * ' . $t_mod,
	'(.+) suffers (\d+) Physical damage from ' . $tank . '\'s Deep Wounds.' =>  
				'$2 * ' . $t_mod,

	# Threat moves
	$tank . '\'s Revenge (cr|h)its (.+) for (\d+).' => 
				'($3 + 201) * ' . $t_mod, 
	$tank . '\'s Heroic Strike (cr|h)its (.+) for (\d+).' => 
				'($3 + 196) * ' . $t_mod, 
	$tank . '\'s Shield Slam (cr|h)its (.+) for (\d+).' => 
				'($3 + 307) * ' . $t_mod, 
	$tank . '\'s Shield Bash (cr|h)its (.+) for (\d+).' => 
				'($3 + 230) * ' . $t_mod, 
	$tank . '\'s Devastate (cr|h)its (.+) for (\d+).' => 
				'($3 + 101) * ' . $t_mod, 
	$tank . '\'s Thunder Clap (cr|h)its (.+) for (\d+).' => 
				'$3 * 1.75 * ' . $t_mod, 
	$tank . '\'s Cleave (cr|h)its (.+) for (\d+).' => 
				'($3 + 130) * ' . $t_mod, 
	$tank . '\'s Hamstring (cr|h)its (.+) for (\d+).' => 
				'($3 + 181) * ' . $t_mod, 

	# Rage gain -- not modified by forms or talents!
	$tank . ' gains (\d+) Rage from ' . $tank . '\'s (.+).' => 
				'$1 * 5',

	# Spell reflection
	'(.+)\'s (.+) (cr|h)its (.+) for (\d+) (.+) damage.' =>
				'$state{\'spell_reflect\'} ? spell_reflect($1, $4, $5, $t_mod) : 0',
			

	) if $opts{'s'};
}

sub spell_reflect {
	return ( $_[0] eq $_[1] ? $_[2] * $_[3] : 0 );
}

if ($class eq "d") {
	#### Druid threat

	#### Missing:	Faerie Fire, Demo Roar (not assigned to specific
	####		actor)

	%s_threatlines = (
	# Basic damage
	$tank . '\'s Swipe (cr|h)its (.+) for (\d+).' => 
				'$3 * ' . $t_mod, 

	# Threat moves
	$tank . '\'s Maul (cr|h)its (.+) for (\d+).' => 
				'($3 + 322) * ' . $t_mod, 
	$tank . '\'s Lacerate (cr|h)its (.+) for (\d+).' => 
				'(($3 * 1.2) + 285) * ' . $t_mod, 
	'(.+) suffers (\d+) Physical damage from ' . $tank . '\'s Lacerate.' => 
				'($2 * 1.2) * ' . $t_mod,
	$tank . '\'s Mangle \(Bear\) (cr|h)its (.+) for (\d+).' => 
				'$3 * 1.3 * ' . $t_mod, 

	# Rage gain -- not modified by forms or talents!
	$tank . ' gains (\d+) Rage from ' . $tank . '\'s (.+).' => 
				'$1 * 5',
	) if $opts{'s'};
}

if ($class eq "p") {
	#### Paladin threat

	%s_threatlines = (
	# Threat moves
	$tank . '\'s Seal of Righteousness (cr|h)its (.+) for (\d+) Holy damage.' => 
				'$3 * ' . $h_mod, 
	$tank . '\'s Judgement of Righteousness (cr|h)its (.+) for (\d+) Holy damage.' => 
				'$3 * ' . $h_mod, 
	$tank . '\'s Seal of Vengeance (cr|h)its (.+) for (\d+) Holy damage.' => 
				'$3 * ' . $h_mod, 
	$tank . '\'s Seal of Command (cr|h)its (.+) for (\d+) Holy damage.' => 
				'$3 * ' . $h_mod, 
	$tank . '\'s Judgement of Command (cr|h)its (.+) for (\d+) Holy damage.' => 
				'$3 * ' . $h_mod, 
	$tank . '\'s Seal of Blood (cr|h)its (.+) for (\d+) Holy damage.' => 
				'$3 * ' . $h_mod, 
	$tank . '\'s Judgement of Blood (cr|h)its (.+) for (\d+) Holy damage.' => 
				'$3 * ' . $h_mod, 
	'(.+) suffers (\d+) Holy Damage from ' . $tank . '\'s Consecration.' => 
				'$2 * ' . $h_mod, 
	$tank . '\'s Holy Vengeance (cr|h)its (.+) for (\d+) Holy damage.' => 
				'$3 * ' . $h_mod, 
	$tank . '\'s Exorcism (cr|h)its (.+) for (\d+) Holy damage.' => 
				'$3 * ' . $h_mod, 
	$tank . '\'s Holy Wrath (cr|h)its (.+) for (\d+) Holy damage.' => 
				'$3 * ' . $h_mod, 
	$tank . '\'s Avenger\'s Shield (cr|h)its (.+) for (\d+) Holy damage.' => 
				'$3 * ' . $h_mod, 
	$tank . '\'s Holy Shield (cr|h)its (.+) for (\d+) Holy damage.' => 
				'$3 * 1.35 * ' . $h_mod, 

	# Mana gains -- Mana Spring, BoW, and I think Vampiric Touch don't
	# generate threat.
	$tank . ' gains (\d+) Mana from ' . $tank . '\'s Spiritual Attunement.' =>
				'$1 * .5',
	$tank . ' gains (\d+) Mana from ' . $tank . '\'s Judgement of Wisdom.' =>
				'$1 * .5',
	$tank . ' gains (\d+) Mana from ' . $tank . '\'s Seal of Wisdom.' =>
				'$1 * .5',
	$tank . ' gains (\d+) Mana from ' . $tank . '\'s Illumination.' =>
				'$1 * .5',
	$tank . ' gains (\d+) Mana from ' . $tank . '\'s Restore Mana.' =>
				'$1 * .5',

	# Paladin healing -- rare, but you never know.

	$tank . '\'s Holy Light (critically )*heals (.+) for (\d+).' => 
				'($3 > $state{\'max_heal\'} ? $state{\'max_heal\'} : $3) / 2 * ' . $t_mod,
	$tank . '\'s Flash of Light (critically )*heals (.+) for (\d+).' => 
				'($3 > $state{\'max_heal\'} ? $state{\'max_heal\'} : $3) / 2 * ' . $t_mod,
	) if $opts{'s'};
}

%w_threatlines = (
	#### White damage

	# Basic damage
	$tank . ' (cr|h)its (.+) for (\d+).' =>
				'$3 * ' . $t_mod,
) if $opts{'w'};

%o_threatlines = (
	#### Threat generated by other people

	# Healing threat
	$tank . '\'s Earth Shield (critically )*heals ' . $tank . ' for (\d+).' => 
				'($2 > $state{\'max_heal\'} ? $state{\'max_heal\'} : $2) / 2 * ' . $t_mod,
	$tank . '\'s Prayer of Mending heals ' . $tank . ' for (\d+).' => 
				'($1 > $state{\'max_heal\'} ? $state{\'max_heal\'} : $1) / 2 * ' . $t_mod,

	# Random damage
	$tank . '\'s Greater Blessing of Sanctuary (cr|h)its (.+) for (\d+) Holy damage.' => 
				'$3 * ' . $t_mod . ' * ' .  $h_mod,

	# Damage shields
	$tank . '\'s Retribution Aura (cr|h)its (.+) for (\d+) Holy damage.' => 
				'$3 * ' . $t_mod . ' * ' .  $h_mod,
	$tank . ' reflects (\d+) Holy damage to (.+).' => 
				'$1 * ' . $t_mod . ' * ' .  $h_mod,
	$tank . ' reflects (\d+) Nature damage to (.+).' => 
				'$1 * ' . $t_mod,
	$tank . ' reflects (\d+) Fire damage to (.+).' => 
				'$1 * ' . $t_mod,
	$tank . ' reflects (\d+) Frost damage to (.+).' => 
				'$1 * ' . $t_mod,
	$tank . ' reflects (\d+) Arcane damage to (.+).' => 
				'$1 * ' . $t_mod,
	$tank . ' reflects (\d+) Shadow damage to (.+).' => 
				'$1 * ' . $t_mod,
) if $opts{'o'};

%g_threatlines = (
	#### Gear damage

	$tank . '\'s (.+) Shield Spike (cr|h)its (.+) for (\d+).' =>
				'$4 * ' . $t_mod,
	$tank . '\'s Vengeance (cr|h)its (.+) for (\d+) Holy damage.' =>
				'$3 * ' . $t_mod . ' * ' . $h_mod,
) if $opts{'g'};

# Merge threat sources

@threatlines{keys %s_threatlines} = values %s_threatlines;
@threatlines{keys %w_threatlines} = values %w_threatlines;
@threatlines{keys %o_threatlines} = values %o_threatlines;
@threatlines{keys %g_threatlines} = values %g_threatlines;

#### State parsing

my %statelines = (
	# Spell Reflect

	$tank . ' gains Spell Reflection.' => 
				'$state{\'spell_reflect\'} = 1',
	'Spell Reflection fades from ' . $tank => 
				'$state{\'spell_reflect\'} = 0',

	# Incoming damage
	'(.+)\'s (.+) (cr|h)its ' . $tank . ' for (\d+) (\w+) damage.' =>
				'$state{\'health_deficit\'} -= $4',
	'(.+) (cr|h)its ' . $tank . ' for (\d+).' =>
				'$state{\'health_deficit\'} -= $3',
	'(.+) reflects (\d+) (\w+) damage to ' . $tank . '.' =>
				'$state{\'health_deficit\'} -= $2',
	$tank . ' suffers (\d+) (\w+) damage from (.+)\'s (.+).' =>
				'$state{\'health_deficit\'} -= $1',

	# Healing
	$tank . 'gains (\d+) health from (.+)\'s (.+).' =>
				'$state{\'max_heal\'} = 0 - $state{\'health_deficit\'}; $state{\'health_deficit\'} += (($state{\'health_deficit\'} + $1) > 0 ? $state{\'max_heal\'} : $1)',
	'(.+)\'s (.+) heals ' . $tank . ' for (\d+).' =>
				'$state{\'max_heal\'} = 0 - $state{\'health_deficit\'}; $state{\'health_deficit\'} += (($state{\'health_deficit\'} + $3) > 0 ? $state{\'max_heal\'} : $3)',
	);

my %state = (
	'spellreflect' => 0,
	'misdirect' => 0,
	'misdirect_hunter' => 0,
	'health_deficit' => 0,
	);

# Set up regexps

my $threatline = "((" . join(")|(", keys %threatlines) . "))";
my $stateline = "((" . join(")|(", keys %statelines) . "))";

my $starttime;
my $then = 0;		# Last time for which a line was recorded
my @five_sec;
my @ten_sec;
my @seconds;

if ($opts{'h'} && $class eq "w") {
	$seconds[3] = $seconds[6] = $seconds[9] = $seconds[12] = $seconds[15] = 301 * $t_mod;
	# Sunder support -- -h stands for hack!
}

foreach my $line (<>) {
	my $threatval = 0;

	# Fix the 's gap -- addons do this, grr
	$line =~ s/ 's/'s/g;

	# Strip random junk chars
	$line =~ s/[\x80-\xFF]//g;

	# Work out time stuff
	my @parts = split(/  /, $line);
	my $time = log2time($parts[0]);
	$starttime = $starttime || $time;
	my $now = $time - $starttime;

	$seconds[$now] += 0;

	# Report values for previous second if we've finished it

	while ($now > $then) {
		# Make sure there's some data there
		$seconds[$then] += 0;

		# The next five lines deserve to be an array slice

		push @five_sec, $seconds[$then];
		push @ten_sec, $seconds[$then];

		shift @five_sec if ($#five_sec == 5);
		shift @ten_sec if ($#ten_sec == 10);

		print_threat($then, \@seconds, \@five_sec, \@ten_sec);

		$then++;
	}

	# These are mergable, in due time, but separate is nice for debugging

	if ($parts[1] =~ /$threatline/ || $parts[1] =~ /$stateline/) {
		foreach my $state (keys(%statelines)) {
			next unless ($parts[1] =~ /$state/);
			eval $statelines{$state};
			print "==== ", $statelines{$state}, "\t", $line if $debug;
		}

		foreach my $threat (keys(%threatlines)) {
			next unless ($parts[1] =~ /$threat/);
			$threatval = eval $threatlines{$threat};
			$seconds[$now] += $threatval;
			print "%%%% ", $threatval, "\t", $threatlines{$threat}, "\t", $line if $debug;
		}
	}
}

# And we'll always need to handle the last second of the log

print_threat($#seconds, \@seconds, \@five_sec, \@ten_sec);

#### Subroutines
####

sub array_sum {
	my $a = shift;
	my $tot = 0;
	foreach my $i (@{$a}) {
		$tot += ($i || 0);
	}
	return $tot;
}

sub log2time {
	my $date = shift;
	my @time = split(/[ :.\/]/, $date);
	return timegm($time[4], $time[3], $time[2], $time[1], $time[0] - 1, 2000);
}

sub print_threat {
	my $time = shift;
	my $seconds = shift;
	my $five_sec = shift;
	my $ten_sec = shift;

	print "#### ", $time, "\t", $seconds->[$time], "\n" if $debug;

	print 	$time, "\t", 
		int $seconds->[$time], "\t", 
		int array_sum($five_sec) / ($#{$five_sec} + 1), "\t", 
		int array_sum($ten_sec) / ($#{$ten_sec} + 1), "\t", 
		int array_sum($seconds) / ($#{$seconds} + 1), "\n" 
			unless $debug;
}
