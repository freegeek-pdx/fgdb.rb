package LibraryLabels;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = qw(get_number gen_pdf);
@EXPORT_OK   = ();
%EXPORT_TAGS = ();

use Paper::Specs brand => 'Avery', layout => 'pdf';
use XML::XPath;
use PDF::API2;
use Carp;
use PDF::Rectangle;

sub get_number {
    my $label = shift;
    my $a = get_info($label);
    return ($a->label_cols, $a->label_rows);
}

sub get_info {
    my $label = shift;
    my $info = Paper::Specs->find(code => $label);
    return $info;
}

sub gen_pdf {
    my $filename = shift;
    my $datafile = shift;
    my $pages = shift;
    my $label = shift;
    my $skips = shift;

    my $pdf=PDF::API2->new;
    my $info = get_info($label);
    my @skippers = split(/[, ]+/, $skips);
    $pages = 1 if($pages == 0);
    open(DATA, $datafile);
    my $data = join("", <DATA>);
    close(DATA);
    my $xpath = XML::XPath->new(xml => $data);
    my $list = $xpath->find("/records/record");
    my $needs = $list->size() + scalar(@skippers);
    my $has = ($info->label_rows * $info->label_cols) * $pages;
    if($needs > $has) {
        croak("Not enough pages choosen");
    }
  PAGE: for(my $cur_page = 0; $cur_page < $pages; $cur_page++) {
      my $page = $pdf->page();
      my $gfx = $page->gfx();
      my $text = $page->text();
      $text->font($pdf->corefont('Helvetica',1),10);
      if($list->size() == 0) {
          next PAGE;
      }
    LABELS: for(my $cur_row = 0; $cur_row < $info->label_rows; $cur_row++) {
        for(my $cur_col = 0; $cur_col < $info->label_cols; $cur_col++) {
            my $num = ($cur_page * $info->label_cols * $info->label_rows) + ($cur_row * $info->label_cols) + $cur_col + 1;
            if(grep {$_ == $num} @skippers) {
                add_blank_thing($cur_col, $cur_row);
            } else {
                my $thing = $list->shift();
                process_thing($xpath, $thing, $text, $pdf, $page, $cur_col, $cur_row, $info, $gfx);
            }
            if($list->size() == 0) {
                last LABELS;
            }
        }
    }
  }
    $pdf->saveas($filename);
    $pdf->end();
}

sub add_blank_thing {
    my ($cur_col, $cur_row) = @_;
}

sub get_magic_location {
    my ($info, $cur_row, $cur_col) = @_;
    my $col_temp = $info->margin_left + ($info->gutter_cols + $info->label_width) * $cur_col;
    my $row_temp = $info->margin_top + ($info->gutter_rows + $info->label_height) * $cur_row;
    return ($col_temp, $info->sheet_height - $row_temp);
}

# TODO: need to make the barcode a bit smaller, the text a bit bigger,
# and make the text wrap in certain places (so it doesn't run into the
# barcode or other labels)
sub process_thing {
    my ($xpath, $thing, $text, $pdf, $page, $cur_col, $cur_row, $info, $gfx) = @_;
    my $barcode = $xpath->find("barcode", $thing);
#    $barcode = substr($barcode, 2, 4) if(substr($barcode, 0, 2) eq "00");
    my $title = $xpath->find("title", $thing);
    my $callno = $xpath->find("callno", $thing);
    my $author = $xpath->find("author", $thing); # hrm. maybe I shoulda used XML::Simple...*shrug*
    my ($x, $y) = get_magic_location($info, $cur_row, $cur_col);
    my $y_limit = $y - $info->label_height(); # wtf?
    my $x_limit = $x + $info->label_width(); # wtf?
    $x += 15;
    $y -= 10;
    $x_limit -= 10;
    my $y_offset = 20;
    my $rectangle = PDF::Rectangle->new($pdf, $text, $x, $y - $y_offset, $x + 50, $y_limit);
    my $size = 8; # use for all sizes
    $rectangle->set_fontsize($size); #    $rectangle->set_fontsize($size + 2);
    $rectangle->be_bold();
    if(!$rectangle->add_text($callno)) {
        die("epic fail"); # TODO: FIXME
    }
    # based on http://osdir.com/ml/lang.perl.modules.pdfapi2/2004-06/msg00014.html
    my $bar = $pdf->xo_3of9(-font => $pdf->corefont('Helvetica'), # the font to use for text
                            -code => $barcode, # the code of the barcode
                            -umzn => 10, # (u)pper (m)ending (z)o(n)e
                            -lmzn => 10, # (l)ower (m)ending (z)o(n)e
                            -zone => 50, # height (zone) of bars
                            -quzn => 10, # (qu)iet (z)o(n)e
                            -ofwt => 0.01, # (o)ver(f)low (w)id(t)h
                            -fnsz => $size, # (f)o(n)t(s)i(z)e
                            -text => $barcode
        );
    $gfx->formimage($bar, $x + 50, ($y - $bar->height()));
    $rectangle = PDF::Rectangle->new($pdf, $text, $x + 50 + $bar->width(), $y - $y_offset, $x_limit, $y_limit);
    $rectangle->set_fontsize($size);
    $rectangle->add_text($title);
    $rectangle->add_text($author);
    $rectangle->add_text("Free Geek Library");
}

1;

