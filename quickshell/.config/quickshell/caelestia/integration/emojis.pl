use strict;
use warnings;
use utf8;
use Unicode::UCD qw(charinfo prop_invmap);

binmode STDOUT, ':encoding(UTF-8)';

my ($emoji_map, $emoji_vals) = prop_invmap('Emoji');
my ($presentation_map, $presentation_vals) = prop_invmap('Emoji_Presentation');
my %is_presentation;

for (my $i = 0; $i < @$presentation_map - 1; $i++) {
    next unless $presentation_vals->[$i] eq 'Y';
    for my $cp ($presentation_map->[$i] .. $presentation_map->[$i + 1] - 1) {
        $is_presentation{$cp} = 1;
    }
}

my @rows;

for (my $i = 0; $i < @$emoji_map - 1; $i++) {
    next unless $emoji_vals->[$i] eq 'Y';

    for my $cp ($emoji_map->[$i] .. $emoji_map->[$i + 1] - 1) {
        next if $cp <= 0x7F;

        my $info = charinfo($cp) or next;
        my $name = $info->{name} // next;
        next if $name =~ /^</;
        next if $name =~ /^(?:REGIONAL INDICATOR SYMBOL LETTER|TAG )/;
        next if $name =~ /(?:EMOJI MODIFIER|VARIATION SELECTOR|COMBINING ENCLOSING KEYCAP|DIGIT ZERO|DIGIT ONE|DIGIT TWO|DIGIT THREE|DIGIT FOUR|DIGIT FIVE|DIGIT SIX|DIGIT SEVEN|DIGIT EIGHT|DIGIT NINE|NUMBER SIGN|ASTERISK)/;

        my $emoji = chr($cp);
        $emoji .= chr(0xFE0F) unless $is_presentation{$cp};

        my $label = lc $name;
        $label =~ s/-/ /g;

        my $alias = $label;
        $alias =~ s/\s+/_/g;

        my $meta = join ' ',
            $label,
            $alias,
            ($label =~ s/\s+//gr);

        push @rows, join("\t", $emoji, $label, $meta);
    }
}

@rows = sort {
    (split /\t/, $a, 3)[1] cmp (split /\t/, $b, 3)[1]
} @rows;

print "$_\n" for @rows;
