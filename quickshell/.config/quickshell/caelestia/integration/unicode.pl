use strict;
use warnings;
use utf8;
use Unicode::UCD qw(charinfo charscript prop_invmap);

binmode STDOUT, ':encoding(UTF-8)';

my ($block_map, $block_vals) = prop_invmap('Block');
my @rows;
my $allowed_blocks = qr/^(?:Basic Latin|Latin-1 Supplement|Latin Extended-[A-G]|Latin Extended Additional|Greek and Coptic|Greek Extended|Combining Diacritical Marks(?: Supplement| Extended| for Symbols)?|Spacing Modifier Letters|Modifier Tone Letters|General Punctuation|Supplemental Punctuation|Superscripts and Subscripts|Currency Symbols|Letterlike Symbols|Number Forms|Arrows|Supplemental Arrows-[ABC]|Mathematical Operators|Supplemental Mathematical Operators|Miscellaneous Mathematical Symbols-[AB]|Miscellaneous Technical|Control Pictures|Optical Character Recognition|Enclosed Alphanumerics(?: Supplement)?|Box Drawing|Block Elements|Geometric Shapes(?: Extended)?|Miscellaneous Symbols(?: and Arrows)?|Dingbats|Braille Patterns|Symbols for Legacy Computing|Transport and Map Symbols|Alchemical Symbols|Chess Symbols|Playing Cards|Mahjong Tiles|Domino Tiles|Ancient Symbols|Ancient Greek Numbers|Ancient Greek Musical Notation|Byzantine Musical Symbols|Musical Symbols|Tai Xuan Jing Symbols|Yijing Hexagram Symbols|Aegean Numbers|Counting Rod Numerals|Rumi Numeral Symbols|Indic Siyaq Numbers|Ottoman Siyaq Numbers|Coptic Epact Numbers|Supplemental Symbols and Pictographs|Symbols and Pictographs Extended-A)$/;
my $excluded_label_terms = qr/(?:aegean|alchemical|combining greek|white cross mark|admetos|apollon|xiangqi|zeus|astraea|uranus|russian)/;

for (my $i = 0; $i < @$block_map - 1; $i++) {
    my $block = $block_vals->[$i] // q();

    next unless $block =~ $allowed_blocks;

    for my $cp ($block_map->[$i] .. $block_map->[$i + 1] - 1) {
        my $info = charinfo($cp) or next;
        my $name = $info->{name} // next;
        my $category = $info->{category} // q();
        my $script = charscript($cp) // q();

        next if $name =~ /^</;
        next if $category =~ /^(?:Cc|Cf|Cs|Co)$/;
        next unless $script =~ /^(?:Common|Inherited|Latin|Greek)$/;

        if ($category =~ /^(?:L|M)/) {
            next unless $block =~ /(?:Latin|Greek)/ || $name =~ /^(?:LATIN|GREEK) /;
        }

        my $char = chr($cp);
        my $code = sprintf('U+%04X', $cp);
        my $label = lc $name;
        my $block_label = lc $block;

        $label =~ s/-/ /g;
        $block_label =~ s/_/ /g;
        next if $label =~ $excluded_label_terms;
        next if $block_label =~ $excluded_label_terms;

        my $alias = $label;
        $alias =~ s/\s+/_/g;

        my $meta = join ' ',
            $label,
            $alias,
            ($label =~ s/\s+//gr),
            $code,
            lc($code),
            (sprintf '%04x', $cp),
            $block_label;

        push @rows, join("\t", $char, $code, $label, $meta);
    }
}

@rows = sort {
    (split /\t/, $a, 4)[2] cmp (split /\t/, $b, 4)[2]
} @rows;

print "$_\n" for @rows;
