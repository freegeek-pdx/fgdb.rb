package PDF::Rectangle;

use strict;
use Carp;

sub new {
    my $class = shift;
    my $self = { 'pdftext' => shift, 'x' => shift, 'y' => shift, 'x2' => shift, 'y2' => shift, 'cur_x' => 0, 'cur_y' => 0 };
    # make y the upper (bigger) of the two
    if($self->{'y'} < $self->{'y2'}) {
        my $temp = $self->{'y'};
        $self->{'y'} = $self->{'y2'};
        $self->{'y2'} = $temp;
    }
    # make x the left most (smaller) of the two
    if($self->{'x'} > $self->{'x2'}) {
        my $temp = $self->{'x'};
        $self->{'x'} = $self->{'x2'};
        $self->{'x2'} = $temp;
    }
    $self->{'width'} = $self->{'x2'} - $self->{'x'};
    $self->{'height'} = $self->{'y'} - $self->{'y2'};
    bless $self, $class;
    return $self;
}

sub move_down {
    my ($self, $num) = @_;
    $self->{'cur_y'} += $num;
    if(!$self->bad_y()) {
        $self->{'cur_y'} -= $num;
        return 0;
    }
    return $self->{'cur_y'} || -1;
}

sub move_right {
    my ($self, $num) = @_;
    $self->{'cur_x'} += $num;
    if(!$self->bad_x()) {
        $self->{'cur_x'} -= $num;
        return 0;
    }
    return $self->{'cur_x'} || -1;
}

sub move_up {
    my ($self, $num) = @_;
    $self->{'cur_y'} -= $num;
    if(!$self->bad_y()) {
        $self->{'cur_y'} += $num;
        return 0;
    }
    return $self->{'cur_y'} || -1;
}

sub move_left {
    my ($self, $num) = @_;
    $self->{'cur_x'} -= $num;
    if(!$self->bad_x()) {
        $self->{'cur_x'} += $num;
        return 0;
    }
    return $self->{'cur_x'} || -1;
}

sub bad_x {
    my $self = shift;
    return 0 if($self->{'cur_x'} < 0);
    return 0 if($self->{'cur_x'} > $self->{'width'});
    return 1;
}

sub word_height {
    return 10;
}

sub bad_y {
    my $self = shift;
    return 0 if($self->{'cur_y'} < 0);
    return 0 if($self->{'cur_y'} > $self->{'height'});
    return 1;
}

sub cur_y_loc {
    my $self = shift;
    return $self->{'y'} - $self->{'cur_y'};
}

sub cur_x_loc {
    my $self = shift;
    return $self->{'x'} + $self->{'cur_x'};
}

sub width_left {
    my $self = shift;
    return $self->{'width'} - $self->{'cur_x'};
}

sub height_left {
    my $self = shift;
    return $self->{'height'} - $self->{'cur_y'};
}

sub total_width {
    my $self = shift;
    return $self->{'width'};
}

sub total_height {
    my $self = shift;
    return $self->{'height'};
}

sub add_text {
    my($self, $text) = @_;
    my @list = split(" ", $text);
    my $pdftext = $self->{'pdftext'};
    # while:
    # * we still have words
    # * we can move down and then back up the height of a line
    while(scalar @list > 0 && ($self->move_down($self->word_height()) && $self->move_up($self->word_height()))) {
        # if there's too much
        if($pdftext->advancewidth(" $list[0]") > $self->width_left() && 0) {
            # loop through until we fill it up
            my $bad = shift @list;
            my $good1 = "";
            my $good2 = "";
            my $i = 0;
#            while($pdftext->advancewidth(substr($bad, 0, $i + 1)) < $self->width_left()) {
#                $i += 1;
#            }
            $i = 5;
            $good1 = substr($bad, 0, $i);
            $good2 = substr($bad, $i, length($bad) - length($good1));
            unshift @list, $good2;
            unshift @list, $good1;
        }
        my @temp = ();
        my $y = $self->cur_y_loc();
        my $x = $self->cur_x_loc();
        $pdftext->translate($self->cur_x_loc, $self->cur_y_loc);
        # while:
        # if we add the next thing, then it will fit width wise
        # out list is not empty
        until($pdftext->advancewidth("@temp $list[0]") > $self->width_left() || scalar @list == 0) {
            push @temp, shift @list;
        }
        $pdftext->text("@temp");
        $self->move_down($self->word_height());
    }
#    return 0 if(scalar @list > 0); #TODO: FIXME
    carp("epic fail") if(scalar @list > 0);
    return 1;
}

1;
