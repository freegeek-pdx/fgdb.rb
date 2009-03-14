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
    my $title = $xpath->find("title", $thing);
    my $callno = $xpath->find("callno", $thing);
    my $author = $xpath->find("author", $thing); # hrm. maybe I shoulda used XML::Simple...*shrug*
    my ($x, $y) = get_magic_location($info, $cur_row, $cur_col);
    $x += 10;
    $y -= 10;
    my $rectangle = PDF::Rectangle->new($text, $x, $y - 30, $x + 50, $y - 60);
    if(!$rectangle->add_text($callno)) {
        die("epic fail"); # TODO: FIXME
    }
#    $text->paragraph($callno, 50, -spillover => 0);
    # based on http://osdir.com/ml/lang.perl.modules.pdfapi2/2004-06/msg00014.html
    my $bar = $pdf->xo_3of9(-font => $pdf->corefont('Helvetica-Bold'), # the font to use for text
                            -code => $barcode, # the code of the barcode
                            -umzn => 10, # (u)pper (m)ending (z)o(n)e
                            -lmzn => 10, # (l)ower (m)ending (z)o(n)e
                            -zone => 50, # height (zone) of bars
                            -quzn => 10, # (qu)iet (z)o(n)e
                            -ofwt => 0.01, # (o)ver(f)low (w)id(t)h
                            -fnsz => 10, # (f)o(n)t(s)i(z)e
                            -text => $barcode
        );
    $gfx->formimage($bar, $x + 50, ($y - $bar->height()));
    $text->translate($x + 50 + $bar->width(), $y - 30);
    my(undef, $first_height) = $text->paragraph($title, $info->label_width - 50 - $bar->width(), $info->label_height - 30, -spillover => 0);
    $text->translate($x + 50 + $bar->width(), $first_height);
    my(undef, $second_height) = $text->paragraph($author, $info->label_width - 50 - $bar->width(), $first_height, -spillover => 0);
    $text->translate($x + 50 + $bar->width(), $y - 30 - ($first_height + $second_height));
    $text->text("Free Geek Library"); # TODO: get this from the db
}

1;

