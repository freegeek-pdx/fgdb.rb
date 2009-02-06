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
                process_thing($xpath, $thing, $text, $pdf, $page, $cur_col, $cur_row, $info);
            }
            if($list->size() == 0) {
                last LABELS;
            }
        }
    }
  }
    $pdf->saveas($filename);
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

sub process_thing {
    my ($xpath, $thing, $text, $pdf, $page, $cur_col, $cur_row, $info) = @_;
    my $barcode = $xpath->find("barcode", $thing);
    my ($x, $y) = get_magic_location($info, $cur_row, $cur_col);
    $text->translate($x, $y);
    $text->text($barcode);

# DOESNT WORK....UGH! maybe I should read the docs and/or source and/or examples
#    my $bar = PDF::API2::Resource::XObject::Form::BarCode::code3of9->new($pdf);
#    $bar->translate($x, $y);
#    $bar->encode($barcode);
}

1;
