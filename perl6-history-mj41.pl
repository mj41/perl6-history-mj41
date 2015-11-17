#!/bin/env perl

=pod

    # cleanup
    rm -rf /home/mj/devel/my-slides/perl6-history-mj41/final-slides/*
    # generate slides
    cd ~/devel/dalsi-my/prbuilder-docker/
    ./bin/build-slides ~/devel/my-slides/perl6-history-mj41/ perl6-history-mj41.pl mj41/prbuilder:local DEBUG 1
    firefox ~/devel/my-slides/perl6-history-mj41/final-slides/index.html

    # or node-static
    cd /home/mj/devel/my-slides/perl6-history-mj41/final-slides ; static
    firefox http://127.0.0.1:8080

    # GD project screenshots
    # Start selenium
    cd ~/gd/rolapps/apps/rcheck/ && ./util/pruit-selenium-server.sh

    # Get screenshots
    rm -rf /home/mj/devel/my-slides/perl6-history-mj41/final-slides/
    rm -rf /home/mj/devel/my-slides/perl6-history-mj41/img/gddash/*
    rm -rf /home/mj/gd/rolapps/third-part/Perl6-Analytics-results/slides/mj41-brnopm-prev2/*
    cd ~/gd/rolapps/apps/rcheck/
    perl rcheck.pl --cf config/secure-na.yaml --sc ~/gd/rolapps/apps/rcheck/checks/special/presentation.pl --p 'Perl6-TMP5' --co 'out_dir=/home/mj/gd/rolapps/third-part/Perl6-Analytics-results/slides/mj41-brnopm-prev2/' --co 'gdc_title_prefix=Brno'
    # pdf
    cp /home/mj/gd/rolapps/third-part/Perl6-Analytics-results/slides/mj41-brnopm-prev2/pres-{d01t02,d01t04,d01t07,d02t06}.png /home/mj/devel/my-slides/perl6-history-mj41/img/gddash/
    cd /home/mj/gd/rolapps/third-part/Perl6-Analytics-results/slides/
    convert mj41-brnopm-prev2/*.png mj41-brnopm-prev2.pdf
    evince mj41-brnopm-prev2.pdf
    eog /home/mj/gd/rolapps/third-part/Perl6-Analytics-results/slides/mj41-brnopm-prev2/

    # manual run
    chcon -Rt svirt_sandbox_file_t /home/mj/devel/dalsi-my/Presentation-Builder/
    chcon -Rt svirt_sandbox_file_t /home/mj/devel/my-slides/
    docker run --rm -i -t -v /home/mj/devel/my-slides/perl6-history-mj41/:/home/linus/slides-src/:ro \
      -v /home/mj/devel/my-slides/perl6-history-mj41/final-slides:/home/linus/final-slides:rw \
      -v /home/mj/devel/dalsi-my/Presentation-Builder/lib/:/home/linus/prbuilder/third-part/Presentation-Builder/lib:ro \
      -e SCRIPT_NAME=perl6-history-mj41.pl mj41/prbuilder:local /bin/bash

    docker-bin/docker-build-slides $SCRIPT_NAME

=cut

use strict;
use warnings;
use utf8;

use autodie;
use FindBin ();

use Presentation::Builder::SlideCollection::Reveal;
use Presentation::Builder::RunEnv;
use Presentation::Builder::RunCmd qw/cmdo cd/;

# Parameters:
my $brnopm = $ARGV[0] // 0;
my $details_level = $ARGV[1] // 10;
my $sleep_mult = (defined $ARGV[2]) ? $ARGV[2] : 1;
my $verbose_level = $ARGV[3] // 3;

my $temp_user_name = 'linus';
my $course_dir = 'prbuilder';

my @lt = localtime(time);
my $gen_date = $lt[3].'.'.($lt[4] + 1).'.'.($lt[5] + 1900);

my $rev_struct = cmdo( "cd $FindBin::RealBin; git rev-parse HEAD", no => 1 );
my $src_sha1 = $rev_struct->{out};
my $src_url = "https://github.com/mj41/perl6-history-mj41/commits/$src_sha1/perl6-history-mj41.pl";
my $first_slide_suffix_html =
	  '<small>by <a href="http://mj41.cz">Michal Jurosz (mj41)</a><br />'
	. qq|generated <a href="$src_url">$gen_date</a><br /></small>|;

my $sc = Presentation::Builder::SlideCollection::Reveal->new(
	title => 'Perl Family',
	subtitle => '15 years of Perl 6 and Perl 5',
	author => 'Michal Jurosz (mj41)',
	author_url => 'http://mj41.cz',
	date => $gen_date,
	first_slide_suffix_html => $first_slide_suffix_html,
	revealjs_dir => File::Spec->catdir( $FindBin::RealBin, '..', 'third-part', 'reveal.js' ),
	out_fpath => File::Spec->catfile( $FindBin::RealBin, '..', 'final-slides', 'index.html' ),
	sleep_mult => $sleep_mult,
	vl => $verbose_level,
);
sub ap { $sc->process_slide_part(@_) };
sub pc { $sc->process_command(@_) };
sub ar { $sc->add_slide_raw(@_) };
sub sl_sleep { $sc->process_sleep(@_) };

sub img {
	my ( $img_fname, $width ) = @_;
	$width //= '600px';
	return sprintf(
		'<img%s src="%s" class="stretch">',
		(defined $width) ? qq/ width="$width"/ : '',
		'./img/' . $img_fname
	);
}

my $whoami = pc cmdo 'whoami', no => 1;
die "No user '$temp_user_name' but '$whoami'.\n" unless $whoami eq $temp_user_name;

my $home_dir = '/home/'.$temp_user_name;
my $base_dir = $home_dir . '/' . $course_dir;
my $tmp_dir = $home_dir . '/' . $course_dir . '/temp';

die "Directory '$base_dir' not found." unless -d $base_dir;

my $run_env = Presentation::Builder::RunEnv->new(
	reset_env => sub {
		pc cmdo 'stty cols 70', no => 1;
		pc cmdo "mkdir -p $tmp_dir", no => 1;
	},
	init_env => sub {
		chdir( $home_dir );
	},
);

$sc->add_slide(
	'Michal "mj41" Jurosz',
	markdown => <<'MD_END',
* [BASIC-G](http://mj41.cz/wiki/M%C5%AFj_prvn%C3%AD_program), PMD 85, 2 MHz, 48 kB
* Turbo Pascal, 386 SX 20 MHz, 2 MB
* Linux, Bash, Perl 5+6, Web/Wiki
* [CVIS VUT](http://www.cvis.vutbr.cz/) (PHP, Perl 5), [GoodData](http://www.gooddata.com/) (Perl 5)
* [github.com/mj41](http://github.com/mj41), [TapTinder](https://github.com/TapTinder), [Padre](https://github.com/PadreIDE)
* [Brno Perl Mongers](http://brno.pm.org/) - brno.pm.org
* 1.pivo 24.2.2011 (skim, mj41)
MD_END
) if $brnopm;

$sc->add_slide(
	'YAPC::EU 2012',
	cmd_sub => sub {
		ar img 'yapc-eu-2012.jpg';
	},
	header => 0,
) if $brnopm;

$sc->add_slide(
	'YAPC::EU 2014',
	cmd_sub => sub {
		ar img 'yapc-eu-2014.jpg';
	},
	header => 0,
) if $brnopm;

$sc->add_slide(
	'Perl 6 Progress',
	markdown => <<'MD_END',
* following the day-to-day progress
* Free/OpenSource project
* taking a long time" != "not going to happen"
* [perl6.cz](http://www.perl6.cz/), rakudo.cz
* [Perl 6 and Parrot links](http://perl6.cz/wiki/Perl_6_and_Parrot_links#2011), 2011, >1500 changes
MD_END
	notes => <<'MD_NOTES',
* http://www.perl.com/pub/2010/08/people-of-perl-6-jonathan-worthington.html
* Second system syndrom - done right
MD_NOTES
);

$sc->add_slide(
	'Perl 6 (or P6)',
	markdown => <<'MD_END',
* [perl6.org](http://perl6.org), [Perl 6](http://en.wikipedia.org/wiki/Perl_6) (Wikipedia)
* [learnXinYminutes.com](http://learnxinyminutes.com/docs/perl6/), ...
* [Rosetta Code](http://rosettacode.org/wiki/Category:Perl_6) ([>750](https://github.com/acmeism/RosettaCodeData/tree/master/Lang/Perl-6))
* is anything that passes [the official P6 test suite](https://github.com/perl6/roast)
 * roast - repository of all spec tests
* the break in compatibility was mandated from the start
MD_END
);

$sc->add_slide(
	'Perl - Early versions',
	markdown => <<'MD_END',
* 1987 Perl 1: A general-purpose Unix scripting language to make report processing easier.
* 1988 Perl 2
* 1989 Perl 3
* 1991 Perl 4 (Programming Perl/Camel Book)
* October 17, 1994 - Perl 5.000
MD_END
);

$sc->add_slide(
	'Coffee Mugs',
	cmd_sub => sub {
		ar img 'mugs.jpg', 450;
	},
	header => 0,
	notes => <<'MD_NOTES',
* Perl 6 started in a community session at OSCON
* http://www.spidereyeballs.com/os5/set1/small_os5_r06_9705.html
* "we are fucked unless we can come up with something that will excite the community, because everyone's getting bored and going off and doing other things".
MD_NOTES
);

$sc->add_slide(
	'Perl 6 - beginning',
	markdown => <<'MD_END',
* OSCON 2000 (July 17-20)
 * Perl 6 started in a community session
 * Jon Orwant, Coffee Mugs
* requests for comments
 * [361 RFCs](http://www.perl6.org/archive/rfc/)
 * RFC1 (1 Aug 2000), RFC 361 (30 Sep 2000)
MD_END
	notes => <<'MD_NOTES',
* https://en.wikipedia.org/wiki/O%27Reilly_Open_Source_Convention
* First brief mention of Perl 6 at end of talk.
* http://www.perlfoundation.org/perl6/index.cgi?state_of_the_onion#the_state_of_the_onion_4_2000
* http://archive.oreilly.com/pub/a/oreilly//news/parrotstory_0401.html
* http://www.perl.com/pub/2001/04/01/parrot.htm
* people - Chip, Leo, Dan, Jesse, Alisson, chromatic, ...
* Larry, Damian, Audrey, Patric, ...
* Java has Sun. .NET has Microsoft. Mono has Novell
* volunteers will do what they want
MD_NOTES
);

$sc->add_slide(
	'Perl 6, 2000',
	markdown => <<'MD_END',
> And one of the very very high level goals of Perl 6 is to keep
> Perl capable of evolving.  Perl 5 was running into some limits and
> we're going to figure out how to get around those limits.

-- Larry Wall, 10/2000
MD_END
	notes => <<'MD_NOTES',
MD_NOTES
);

$sc->add_slide(
	'Dynamic languages = Parrot',
	markdown => <<'MD_END',
* April 2001, Parrot [prank](http://archive.oreilly.com/pub/a/oreilly//news/parrotstory_0401.html) = Py3K + Perl 6
* 10/9/2001 - [Parrot](http://en.wikipedia.org/wiki/Parrot_virtual_machine) release [0.0.1](http://www.nntp.perl.org/group/perl.perl6.announce/2001/09/msg294.html)
 * a very, very early alpha - [test.pasm](https://github.com/parrot/parrot/blob/71830e9c1a3b6bbaf3936731de6fd22b45295cd9/test.pasm), [test2.pasm](https://github.com/parrot/parrot/blob/71830e9c1a3b6bbaf3936731de6fd22b45295cd9/test2.pasm)
* virtual machine designed to run dynamic languages efficiently
* 2004 - Pirate (Python on Parrot)
* The Parrot Foundation
MD_END
	notes => <<'MD_NOTES',
* 29.8.2001 13:36:49 - CVS rev1: "first readme."
* third commit - Initial checkin of Simon's work directory
* http://www.perl.com/pub/2000/07/perl6.html
* http://archive.oreilly.com/pub/a/oreilly//news/parrotstory_0401.html
* http://www.perl.com/pub/2001/04/01/parrot.htm
* people - Chip, Leo, Dan, Jesse, Alisson, chromatic, ...
* Larry, Damian, Audrey, Patric, ...
* Java has Sun. .NET has Microsoft. Mono has Novell
* volunteers will do what they want
MD_NOTES
);

$sc->add_slide(
	'The State of the Onion 6',
	markdown => <<'MD_END',
> Let me put this bluntly. If we'd done Perl 6 on a schedule,
> you'd have it by now. And it would be crap.
> ... because we don't have a schedule. We just have a plan.

-- Larry Wall, 2002
MD_END
	notes => <<'MD_NOTES',
MD_NOTES
);

$sc->add_slide(
	'Perl 6 Essentials, 2003',
	cmd_sub => sub {
		ar img 'gddash/pres-d01t02.png';
	},
	header => 0,
);

$sc->add_slide(
	'Synopses, 8/2004',
	markdown => <<'MD_END',
* [The Synopsis documents](http://design.perl6.org/)
* [github.com/perl6/specs](https://github.com/perl6/specs)
* Created: 10 Aug 2004
* Perl 6 - specification + test suite
 * [roast](https://github.com/perl6/roast) (1140 files, spec 37600+79000)
* Perl 5 - interpreter + functional tests
MD_END
	notes => <<'MD_NOTES',
* cd ~/devel/perl6/roast ; find . | grep -P '\.t$' | wc -l
* http://design.perl6.org/S01.html
* http://hhvm.com/blog/5723/announcing-a-specification-for-php
* OSCON 2014, 20 years
* https://github.com/coke/perl6-roast-data/blob/master/perl6_pass_rates.csv
* https://github.com/perl6/roast/tree/master/S15-normalization
MD_NOTES
);

$sc->add_slide(
	'When? Two years',
	markdown => <<'MD_END',
Finally, when ... Perl 6 beta will be available?

> That's a tough question ... With the state of Parrot and
> the design work completed so far ...
> a good chance we'll see one within the next two years.

-- Allison Randal, 5/2004
MD_END
	notes => <<'MD_NOTES',
* http://www.perl.com/pub/2004/05/19/allison.html
MD_NOTES
);

$sc->add_slide(
	'Volunteers',
	markdown => <<'MD_END',
* Java has Sun. .NET has Microsoft.
* FreeSW has grants and volunteers
  * 2005, 70k$ - NLNet grant
  * 2008, 200k$ - Ian Hague grant
  * 2015, 10k€ - Perl 6 Core Development Fund
* volunteers will do what they want
MD_END
	notes => <<'MD_NOTES',
MD_NOTES
);

$sc->add_slide(
	'Punie (Perl 1.000) on Parrot',
	markdown => <<'MD_END',
* 20 years to the day Perl 1.000 was released
* 2007 - Perl 5.10.0 is now out
* [Punie](https://github.com/parrot/punie) (Perl 1) compiler on Parrot VM
* capable of running almost the entire Perl 1 test suite successfully
MD_END
	notes => <<'MD_NOTES',
MD_NOTES
);

$sc->add_slide(
	'Pugs volunteers',
	cmd_sub => sub {
		# todo
		ar img 'gddash/pres-d01t04.png';
	},
	header => 0,
);

$sc->add_slide(
	'Pugs (Audrey Tang), 2005',
	markdown => <<'MD_END',
* >100 developers first month
* "-Ofun", commit bit policy, [IRC logs](http://irclog.perlgeek.de/perl6/)
* Synopses and >10k unit tests
* Haskell - many functional programming influences
* Haskell/Perl 5/STD/JavaScript/Parrot/...
* Parrot - Python, TCL, Ruby, JavaScript, ...
* mod_parrot, mod_perl6, ...
MD_END
	notes => <<'MD_NOTES',
* http://www.perlmonks.org/?node_id=835936
* PONIE, http://news.perlfoundation.org/2006/08/ponie_has_been_put_out_to_past.html
MD_NOTES
);

$sc->add_slide(
	'Pugs (mj41), 2005',
	markdown => <<'MD_END',
* 21.3.2005 - my first Pugs commit
* later testing "Perl 6"

		2005-04-12 mj41: WinXP build failed
		2005-04-12 autrijus: yeah, mj41: try r1848

* mj41 -Ofun
 * TapTinder: [GitHub](https://github.com/TapTinder), [taptinder.org](http://taptinder.org)
 *  [GoodData](http://www.gooddata.com/), [Docker](https://www.docker.com/whatisdocker/), ...
MD_END
	notes => <<'MD_NOTES',
MD_NOTES
) if $brnopm;

$sc->add_slide(
	'Why Perl 6 is Taking So ... Long',
	markdown => <<'MD_END',
When will Perl 6 be ready?

> When it's done.

Seriously, when will it be done?

> When the number of volunteers working on it have completed the amount of work remaining.
MD_END
	notes => <<'MD_NOTES',
MD_NOTES
);

$sc->add_slide(
	'jnthn commits',
	cmd_sub => sub {
		ar img 'gddash/pres-d01t07.png';
	},
	header => 0,
);

$sc->add_slide(
	'jnthn\'s OSCON beers',
	markdown => <<'MD_END',
* 2004 - Parrot
 * Java to Parrot bytecode
* 2007 - Jonathan Worthington
 * Junctions
 * Perl 6 since that
MD_END
	notes => <<'MD_NOTES',
* I didn't really get involved with the Perl 6 compiler itself until 2007.
  That summer, I went to OSCON, drank a few beers and then told Larry Wall,
  of all people, that implementing junctions in the Perl 6 on Parrot compiler
  sounded interesting.
MD_NOTES
);

$sc->add_slide(
	'jnthn',
	markdown => <<'MD_END',
My mission:
> Eliminate the implementation issues that stand
> in the way of greatly increased Perl 6 adoption.

-- Jonathan "jnthn" Worthington
MD_END
	notes => <<'MD_NOTES',
* http://www.perl.com/pub/2010/08/people-of-perl-6-jonathan-worthington.html
* http://edumentab.github.io/rakudo-and-nqp-internals-course/slides-day2.pdf , slide 148
MD_NOTES
);


$sc->add_slide(
	'Architecture (jnthn++)',
	cmd_sub => sub {
		ar img 'architecture.png';
	},
	header => 0,
);

$sc->add_slide(
	'Perl 6 - Glossary',
	markdown => <<'MD_END',
* language: Perl 6 (or Perl 6.0.0)
* implementations: Rakudo (, Niecza, Pugs, ...)
* virtual machines: MoarVM, JVM (, Parrot, ...)

-----
* binary: perl6-m, perl6-j (, perl6-p)
* distribution: Rakudo Star
* grammar: STD
MD_END
	notes => <<'MD_NOTES',
* v6.pm, Niecza, Pugs, ...
* V8 (JavaScript), CLR (.NET, Mono), Haskell, ...
*
MD_NOTES
);

$sc->add_slide(
	'Perl 6 - language/spec',
	markdown => <<'MD_END',
* specified by its test suite
 * [Synopsis](http://design.perl6.org/)/specs - [links](http://design.perl6.org/S06.html#Signatures) to test suite
 * [roast](https://github.com/perl6/roast) - repository of all spec tests
 * [STD.pm6](https://github.com/perl6/std/blob/master/STD.pm6) - standard grammar
* whirlpool model
MD_END
);

$sc->add_slide(
	'Implementations',
	markdown => <<'MD_END',
* Rakudo
* Niecza
* ...
MD_END
	notes => <<'MD_NOTES',
* “rakudo” itself also means “paradise”
* “rakuda do” which in Japanese I presume means “The way of the camel”.
MD_NOTES
);

$sc->add_slide(
	'Niecza',
	markdown => <<'MD_END',
* C#, CLR (.NET, Mono)
* one man show - [sorear](https://github.com/sorear)

> 2010.06.30 <arnsholt> What's "Nie mamy czas"? =)

> 2010.06.30 <masak> it means "We don't have time" in Czech.
MD_END
	notes => <<'MD_NOTES',
* Actually it is in Polish.
MD_NOTES
) if $brnopm;

$sc->add_slide(
	'Virtual Machine (VM)',
	markdown => <<'MD_END',
* execute instructions
 * interpreting, [just-in-time](http://en.wikipedia.org/wiki/Just-in-time_compilation) (JIT)
* memory management
* build-in data structures
 * strings, arrays, objects, ...
* abstract OS
MD_END
	notes => <<'MD_NOTES',
* is compilation done during execution of a program – at run time
* MoarVM/LuaJIT, JVM
* http://jnthn.net/papers/2013-yapceu-moarvm.pdf
* http://jnthn.net/papers/2014-yapceu-performance.pdf
MD_NOTES
);

$sc->add_slide(
	'NQP - Not Quite Perl (6)',
	markdown => <<'MD_END',
* [en-kjů-pí], Patrick R. Michaud, end of 2007
* a small, easier-to-optimize Perl 6 subset
* ideal for writing compilers, especially parse tree to AST mapping
* NQP compiler is implemented in NQP (bootstrapped)
* nearly all of Rakudo is NQP code (except CORE.setting)
MD_END
	notes => <<'MD_NOTES',
* PAST, PCT, PIR, PGE, NQP, ...
* pmichaud - bad news
* http://www.jnthn.net/papers/2011-osdc.tw-compiler.pdf
* https://github.com/edumentab/rakudo-and-nqp-internals-course
MD_NOTES
);

$sc->add_slide(
	'Perl ?',
	markdown => <<'MD_END',
* an easy thing easy
* or a hard thing possible
* you can get your work done efficiently
* ... and have time to go for a beer
MD_END
	notes => <<'MD_NOTES',
MD_NOTES
);

$sc->add_slide(
	'..., 4, 5, 6, ... ?',
	markdown => <<'MD_END',
* backward compatibility
* finished/done?
MD_END
	notes => <<'MD_NOTES',
* MS Windows 95
MD_NOTES
);

$sc->add_slide(
	'Perl 4',
	markdown => <<'MD_END',
* Perl 4 didn't have lexical (my) variables
 * and the package separator was ' (not ::)
 * and really nobody used packages anyway
 * and there was no object support whatsoever
MD_END
	notes => <<'MD_NOTES',
* 5.11 - a monthly release cycle of development releases, with a yearly schedule of stable releases
* On April 12, 2010, Perl 5.12.0 was released.
* On May 14, 2011, Perl 5.14 was released.
* On May 20, 2012, Perl 5.16 was released.
* On May 18, 2013, Perl 5.18 was released.
* On May 27, 2014, Perl 5.20 was released.
MD_NOTES
);

$sc->add_slide(
	'Perl 5 + 6',
	markdown => <<'MD_END',
* Perl 5
 * not a dead-end language
 * Perl 5 renaissance as [Modern Perl](http://onyxneon.com/books/modern_perl/)
 * development in parallel with Perl 6
 * stealing features
 * use feature, use 5.x
 * release cycle
MD_END
	notes => <<'MD_NOTES',
* Python 3 vs. Python 2
MD_NOTES
);

$sc->add_slide(
	'Perl 6 + 5',
	markdown => <<'MD_END',
* "Perl 6 is Perl." -- Larry Wall
 * Rule 1: Whatever Larry says about Perl is correct.
* sister languages
 * no intention to have Perl 6 replace Perl 5
MD_END
	notes => <<'MD_NOTES',
* http://perlhist.com/perl6/damian-conway
MD_NOTES
);

$sc->add_slide(
	'Perl 6 killing Perl 5? No.',
	markdown => <<'MD_END',
* hugely expanded test suite (27k 2002, 93k 2009)
* refactored internal - fixes, speed, memory
 * [Ponie](https://en.wikipedia.org/wiki/PONIE) 8/2006 dead
* regex engine improvements, named captures
* smart matching, given/when, state variables, defined-or, say, ...
* Moose, [Pluggable keywords](http://search.cpan.org/dist/perl-5.12.0/pod/perl5120delta.pod#Pluggable_keywords), CPAN modules
* git, rapid release cycle, cpants
MD_END
	notes => <<'MD_NOTES',
* http://www.slideshare.net/Tim.Bunce/perl-myths-200909
* http://use.perl.org/use.perl.org/_chromatic/journal/35560.html
MD_NOTES
);

$sc->add_slide(
	'The State of the Onion, 2002 - dying',
	markdown => <<'MD_END',
> But two years ago Perl 5 had already started dying, because people
> were starting to see it as a dead-end language.
> ... when we announced Perl&nbsp;6, Perl&nbsp;5 suddenly took on a new life ...

-- Larry Wall, 2002
MD_END
	notes => <<'MD_NOTES',
* http://www.perlfoundation.org/perl6/index.cgi?state_of_the_onion
MD_NOTES
);

$sc->add_slide(
	'Perl 6 - Features 1',
	markdown => <<'MD_END',
* signatures
 * positional, named, slurpy
 * is ro, is rw, is copy
* [references gone](https://perl6advent.wordpress.com/2011/12/16/where-have-all-the-references-gone/)
* [Unicode](https://6guts.wordpress.com/2015/04/12/this-week-unicode-normalization-many-rts/) - Buf, Uni, Str
* chained comparisons
* multiline comments, heredocs
* Rat type, Complex, Big integers, Buf, native
MD_END
);

$sc->add_slide(
	'Perl 6 - Features 2',
	markdown => <<'MD_END',
* scales better from script to application
* OO including roles and introspection
* multiple dispatch
* gradually typed - performance
* lazy evaluation
* concurrency - Promises, Channels, Supplies
* junctions (autothreading)
MD_END
	notes => <<'MD_NOTES',
* Huffman coding
* https://www.python.org/dev/peps/pep-0484/
MD_NOTES
);

$sc->add_slide(
	'Perl 6 - Features 3, ...',
	markdown => <<'MD_END',
* digest CPAN down into something more coherent
* install more than one version of package
* grammars and regexes
* STD.pm6 written in Perl 6 - overloading
* meta-operators, user-defined operators
* macros
* see [features matrix](http://www.perl6.org/compilers/features)
MD_END
);

$sc->add_slide(
	'Spectest chart 5/2008..7/2009',
	cmd_sub => sub {
		ar img 'rakudo-tests-2009-07-14.png', 500;
	},
	header => 0,
);

$sc->add_slide(
	'Rakudo leaving the Parrot nest',
	markdown => <<"MD_END",
* 3/2009 1.0.0 "Haru Tatsu" released
 * the first "stable" release to developers
* 1/2010 2.0.0 Production use
* one bytecode to rule them all
* separated repositories
* the deprecation policy (6 months, 3 months)
* people
MD_END
	notes => <<'MD_NOTES',
* http://developers.slashdot.org/story/09/03/18/1826201/parrot-100-released
* Cardinal (Ruby), Pynie (Python), Lua, ParTCL, LOLCODE
* PMC, PBC, PASM, POST, PAST, IMCC, PIR, PGE, PCT, NQP
MD_NOTES
);

$sc->add_slide(
	'Rakudo today',
	markdown => <<'MD_END',
* "Rakudo" - a Perl 6 language implementation
* reference (or "official") Perl 6 implementation
* primary backend is [MoarVM](http://moarvm.com/)
* JVM is also supported
* Parrot VM abonded - at least for 2015
 * focus on "The Christmas" ToDo list
* [rakudo.org](http://rakudo.org/), [github.com/rakudo](https://github.com/rakudo/)
MD_END
	notes => <<'MD_NOTES',
* Perl 6 like C or C++
* gcc, clang, ...
* https://github.com/rakudo/rakudo/blob/nom/docs/announce/2009-02
MD_NOTES
);

$sc->add_slide(
	'Rakudo &#9733;',
	markdown => <<'MD_END',
* Rakudo Star - since 29.7.2010
* distribution - including VM, modules, ...
* a useful and usable distribution of Perl 6
* aimed at "early adopters" of Perl 6
* "... pretty near does exist, ..." even if it "... still runs very slowly ... and has lots of bugs ..." -- lwall, OSCON 2010
MD_END
	notes => <<'MD_NOTES',
* http://rakudo.org/2010/07/29/rakudo-star-2010-07/
* http://www.pcworld.com/article/201743/article.html
MD_NOTES
);

$sc->add_slide(
	'6guts by jnthn',
	markdown => <<'MD_END',
* Torment the implementers for the sake of the users" isn't a joke!
* In my first couple of years, I learned rather a lot about how not to implement Perl 6.
* [6guts.wordpress.com](https://6guts.wordpress.com/), [slides on jnthn.net](http://jnthn.net/articles.shtml)
MD_END
	notes => <<'MD_NOTES',
* "When will Perl 6 be finished?"
* Robust compile - time / runtime boundary handling is key to Perl 6 implementation
* Allowing some runtime at compile time makes compile time much more powerfulhttp://jnthn.net/papers/2014-yapceu-performance.pdf
MD_NOTES
);

$sc->add_slide(
	'nom/6model/QRegex - 2010..',
	markdown => <<'MD_END',
* “nom” Rakudo branch – short for “new object model”
* 6model - design and implement a metamodel core
* NQP re-built to use 6model rather than the Parrot object model
* a parallel effort to port the NQP language to the .Net CLR and the JVM
MD_END
	notes => <<'MD_NOTES',
* https://github.com/jnthn/6model/blob/master/overview.pod
* https://6guts.wordpress.com/2011/08/01/a-hint-of-meta-programming/
* https://github.com/stevan/p5-mop-redux
* https://6guts.wordpress.com/2011/05/10/rakudo-on-6model-gets-underway/
* https://6guts.wordpress.com/2011/06/28/another-little-nom-update/
* https://6guts.wordpress.com/2011/09/13/whats-coming-up-in-septemberoctober/
* https://6guts.wordpress.com/2011/11/20/rakudo-this-weeks-release-and-the-next-rakudo-star/
* https://6guts.wordpress.com/2012/01/29/this-months-rakudo-star-release-and-whats-coming-next/
* QAST is a replacement for PAST, Q is just P++
* https://6guts.wordpress.com/2012/05/26/switching-to-qregex-for-parsing-perl-6-source/
* https://6guts.wordpress.com/2012/07/20/the-rakudo-move-to-qast-progressing-nicely/
* chromatic http://www.modernperlbooks.com/mt/2013/02/goodnight-parrot.html
MD_NOTES
);

$sc->add_slide(
	'nom/6model/QRegex - ..2012',
	markdown => <<'MD_END',
* 1/2011 chromatic - stopped working on Parrot (contributor since late 2001)
* 9/2011 - Rakudo itself is now mostly written in NQP and Perl 6 (90-95%),
* 1/2012 - so, we made it, in many sense this is a revolution
* 5/2012 - QRegex, QAST is AST design and implementation, written in NQP
MD_END
	notes => <<'MD_NOTES',
MD_NOTES
);

$sc->add_slide(
	'Rakudo on the JVM - 2013',
	markdown => <<'MD_END',
* invokedynamic instruction
* awful startup time
* perl6-j instead of perl6-m
* concurrency only provided on JVM so far
 * Thread, Promise, Supply, Channel, ...
* 7/2013 92%, 10/2013 99.9%
MD_END
	notes => <<'MD_NOTES',
* http://jnthn.net/papers/2013-yapceu-jvm.pdfc
MD_NOTES
);

$sc->add_slide(
	'MoarVM - 2013/2014',
	markdown => <<'MD_END',
* lightweight and metamodel-focused runtime for NQP and Rakudo
* supports 6model and various other needs natively (efficiently)
* enable the near-term exploration of JIT compilation in 6model
* quick and easy build
* 1/2014 99%, 3/2015 "100%"
* [moarvm.com](http://moarvm.com/)
MD_END
	notes => <<'MD_NOTES',
* http://jnthn.net/papers/2013-yapceu-moarvm.pdf
* http://jnthn.net/papers/2014-yapceu-performance.pdf
MD_NOTES
);

$sc->add_slide(
	'MoarVM vs. Parrot 1',
	markdown => <<'MD_END',
* Parrot
 * started as a great VM to run Perl 5.6
 * performance - a 10+ year old codebase
 * visions of multiple architects
 * experimental code, rush to finish
 * the deprecation policy
MD_END
	notes => <<'MD_NOTES',
* Parrot - merging experimental code and having to maintain it -> 2007 a rush to finish specifications
* http://www.modernperlbooks.com/mt/2013/02/goodnight-parrot.html
* http://jnthn.net/papers/2013-yapceu-moarvm.pdf
MD_NOTES
);

$sc->add_slide(
	'MoarVM vs. Parrot 2',
	markdown => <<'MD_END',
* MoarVM
 * lower startup times and lower memory use
 * spesh and JIT - sophisticated dynamic optimization
 * performance
 * precise, generational GC
 * ...
MD_END
);

$sc->add_slide(
	'Roast Data',
	cmd_sub => sub {
		ar img 'gddash/pres-d02t06.png';
	},
	header => 0,
);

$sc->add_slide(
	'Perl 6 - Christmas ToDo',
	markdown => <<'MD_END',
* Great List Refactor (GLR)
* the Native, Shaped Arrays (NSA)
* the Normalization Form Grapheme (NFG)
MD_END
	notes => <<'MD_NOTES',
MD_NOTES
);

$sc->add_slide(
	'Perl 6.0',
	markdown => <<'MD_END',
* Feb 2015, FOSDEM - a 6.0 language
* [Perl 6 Core Development Fund](http://www.perlfoundation.org/perl_6_core_development_fund)
 * WenZPerl Donate 10,000 EUR
 * 4/2015 - jnthn: [NFG, native arrays, ...](http://news.perlfoundation.org/2015/04/grant-proposal-perl-6-release.html)
* May 2008, 200k$ - [Ian Hague grant](http://www.perlfoundation.org/ian_hague_perl_6_development_grants)
 * 4/2015 - Bart Wiegmans: [Advancing the MoarVM JIT](http://news.perlfoundation.org/2015/04/perl-6-hague-grant-application.html)
MD_END
	notes => <<'MD_NOTES',
* WenZPerl BV is the Dutch open source consultancy company of Elizabeth Mattijsen and Wendy van Dijk, specialised in Perl programming and development.
* The initial objective of this fund is to raise $25,000 to fund Jonathan Worthington’s work on Perl 6 in 2015.
* 3 months, $10,000 - $40 USD / hour, working around 50% of full time
MD_NOTES
);

$sc->add_slide(
	'Slow Rakudo',
	markdown => <<'MD_END',
* Perl 6 - lazy lists
* 8/2013 - about 3,600x slower than Perl 5
* 8/2014 - is 34x slower
 * Better. But still sucks.
MD_END
	notes => <<'MD_NOTES',
* http://jnthn.net/papers/2014-yapceu-performance.pdf
MD_NOTES
);

$sc->add_slide(
	'Fast Rakudo',
	markdown => <<'MD_END',
* 8/2014 - loop_empty_native test/micro-benchmark
 * 355x faster than 8/2013
 * so 14x faster than Perl 5
MD_END
	notes => <<'MD_NOTES',
MD_NOTES
);


$sc->add_slide(
	'Perl 6 - Pick two',
	markdown => <<'MD_END',

> "Good, fast, cheap: pick two." Well, by definition our community
> has to do it cheap, so the saying reduces to "Good, Fast: pick one."
> And we quite intentionally picked good rather than fast.

— Larry Wall (Feb 11 2015, [infoworld.com](http://www.infoworld.com/article/2882300/perl/perl-creator-larry-wall-rethought-version-6-due-this-year.html))
MD_END
	notes => <<'MD_NOTES',
* Second System Syndrome Done Right
MD_NOTES
);

$sc->add_slide(
	'Výborně, díky!',
	markdown => '',
) if $brnopm;

$sc->add_slide(
	'Questions?',
	markdown => <<'MD_END',
> Michal "mj41" Jurosz
<br />
>  [GoodData](http://www.gooddata.com/) Perl 6 guy
<br />
<br />
<p><small>
Generated from <a href="https://github.com/mj41/perl6-history-mj41">github.com/mj41/perl6-history-mj41</a> source<br />
by <a href="https://github.com/mj41/Presentation-Builder">Presentation::Builder</a>
 inside <a href="https://github.com/mj41/prbuilder-docker">prbuilder Docker container</a>.<br />
<br />
Powered by <a href="https://github.com/hakimel/reveal.js">reveal.js</a>.<br />
</small></p>
MD_END
);

$sc->add_slide(
	'GoodData - We are hiring!',
	cmd_sub => sub {
		ar img 'gd-minecraft.png';
	},
	header => 0,
);

$sc->run_all( $run_env );
