#!/usr/bin/perl -w
use Data::Dumper;
use Gtk2 '-init';
use Glib qw(TRUE FALSE);
use Gtk2::SimpleList;
use Gtk2::Gdk::Keysyms;
use utf8;
use HC;


my $h = HC->new();

$h->OpenStep("panel");
$h->SetUnits("inch");

#删层建层
if ($h->LayerExists("panel", "bh_gtl")) {
	$h->DeleteLayer("bh_gtl")
}

if ($h->LayerExists("panel", "bh_gbl")) {
	$h->DeleteLayer("bh_gbl")
}

$h->CreateLayer("bh_gtl","board", "solder_paste","in2b");
$h->CreateLayer("bh_gbl","board", "solder_paste","gbl");

#铺铜避开的symbol
if ($h->LayerExists("panel", "fill_tmp")) {
	$h->DeleteLayer("fill_tmp");
	$h->CreateLayer("fill_tmp");
}
$h->ClearAll();
$h->AffectedLayer("in3t");

$h->ResetFilter();
$h->FilterIncludeSymbol("h-rh-drill-by;h-rh-drill;h-daba;h-daba-by");
$h->FilterSelect();

if ($h->GetSelectNumber() > 0) {
	$h->COM("sel_copy_other,dest=layer_name,target_layer=fill_tmp,invert=no,dx=0,dy=0,size=0,x_anchor=0,y_anchor=0,rotation=0,mirror=none");
}

$h->ClearAll();
$h->AffectedLayer("fill_tmp");

$h->COM("fill_params,type=solid,origin_type=datum,solid_type=surface,std_type=line,min_brush=1,use_arcs=yes,symbol=,dx=0.1,dy=0.1,x_off=0,y_off=0,std_angle=45,std_line_width=10,std_step_dist=50,std_indent=odd,break_partial=yes,cut_prims=no,outline_draw=no,outline_width=0,outline_invert=no");
$h->COM("sr_fill,polarity=positive,step_margin_x=0,step_margin_y=0,step_max_dist_x=100,step_max_dist_y=100,sr_margin_x=-100,sr_margin_y=-100,sr_max_dist_x=0,sr_max_dist_y=0,nest_sr=yes,stop_at_steps=,consider_feat=yes,consider_drill=no,consider_rout=no,dest=affected_layers,attributes=no");

$h->ResetFilter();
$h->COM("filter_set,filter_name=popup,update_popup=no,feat_types=surface");
$h->COM("filter_set,filter_name=popup,update_popup=no,polarity=positive");

$h->FilterSelect();
if ($h->GetSelectNumber() > 0) {
	$h->COM("sel_copy_other,dest=layer_name,target_layer=bh_gtl,invert=no,dx=0,dy=0,size=0,x_anchor=0,y_anchor=0,rotation=0,mirror=none");
	$h->FilterSelect();
	$h->COM("sel_copy_other,dest=layer_name,target_layer=bh_gbl,invert=no,dx=0,dy=0,size=0,x_anchor=0,y_anchor=0,rotation=0,mirror=none");
}

#bh_gtl
$h->ClearAll();
$h->AffectedLayer("bh_gtl");

$h->ClearAll();
$h->AffectedLayer("in3t");

$h->ResetFilter();
$h->FilterIncludeSymbol("r94.248;r94.961;r393.74;s110.236;s118.11;s137.795;s216.535;1bi1;board_line;donut_r50.5x39.5;donut_r53.622x43.78;h-erciyuan;h-rhccd-3;h-screen-hole-pad3;jing;rect216.535x244.094;rect244.094x216.535;scale-y-jing-new;wei;yymmdd;h-rhccd-2;r47.244;r78.74");
$h->FilterSelect();
if ($h->GetSelectNumber() > 0) {
	$h->COM("sel_copy_other,dest=layer_name,target_layer=bh_gtl,invert=no,dx=0,dy=0,size=0,x_anchor=0,y_anchor=0,rotation=0,mirror=none");

}

#文字
$h->ResetFilter();
$h->COM("filter_set,filter_name=popup,update_popup=no,feat_types=text");
$h->COM("filter_set,filter_name=popup,update_popup=no,profile=in");

$h->FilterSelect();
if ($h->GetSelectNumber() > 0) {
	$h->COM("sel_copy_other,dest=layer_name,target_layer=bh_gtl,invert=no,dx=0,dy=0,size=0,x_anchor=0,y_anchor=0,rotation=0,mirror=none");

}


#gtl
$h->ResetFilter();
$h->ClearAll();
$h->AffectedLayer("gtl");

$h->ResetFilter();
$h->FilterIncludeSymbol("hwjs;i*-sz-new");
$h->FilterSelect();
if ($h->GetSelectNumber() > 0) {
	$h->COM("sel_copy_other,dest=layer_name,target_layer=bh_gtl,invert=no,dx=0,dy=0,size=0,x_anchor=0,y_anchor=0,rotation=0,mirror=none");

}


#底层
#bh_gbl
$h->OpenStep("panel");
$h->SetUnits("inch");
$h->ClearAll();
$h->AffectedLayer("bh_gbl");

$h->ClearAll();
$h->AffectedLayer("in4b");

$h->ResetFilter();
$h->FilterIncludeSymbol("r94.248;r94.961;r393.74;s110.236;s118.11;s137.795;s216.535;1bi1;board_line;donut_r50.5x39.5;donut_r53.622x43.78;h-erciyuan;h-rhccd-3;h-screen-hole-pad3;jing;rect216.535x244.094;rect244.094x216.535;scale-y-jing-new;wei;yymmdd;h-rhccd-2;r47.244;r78.74;r393.701;h-rhccd-bitong;");
$h->FilterSelect();
if ($h->GetSelectNumber() > 0) {
	$h->COM("sel_copy_other,dest=layer_name,target_layer=bh_gbl,invert=no,dx=0,dy=0,size=0,x_anchor=0,y_anchor=0,rotation=0,mirror=none");

}

#文字
$h->ResetFilter();
$h->COM("filter_set,filter_name=popup,update_popup=no,feat_types=text");
$h->COM("filter_set,filter_name=popup,update_popup=no,profile=in");

$h->FilterSelect();
if ($h->GetSelectNumber() > 0) {
	$h->COM("sel_copy_other,dest=layer_name,target_layer=bh_gbl,invert=no,dx=0,dy=0,size=0,x_anchor=0,y_anchor=0,rotation=0,mirror=none");

}


#gbl
$h->ResetFilter();
$h->ClearAll();
$h->AffectedLayer("gbl");

$h->ResetFilter();
$h->FilterIncludeSymbol("hwjs;i*-sz-new");
$h->FilterSelect();
if ($h->GetSelectNumber() > 0) {
	$h->COM("sel_copy_other,dest=layer_name,target_layer=bh_gbl,invert=no,dx=0,dy=0,size=0,x_anchor=0,y_anchor=0,rotation=0,mirror=none");

}

#川宝和巴赫

#川宝和巴赫
foreach my $machine ("panel-cb", "panel-bh") {
	$h->OpenStep("$machine");
	$h->COM("copy_layer,source_job=$h->{Job},source_step=$machine,source_layer=in2b,dest=layer_name,dest_layer=bh_gtl,mode=replace,invert=no,copy_notes=no,copy_attrs=new_layers_only");
	$h->COM("copy_layer,source_job=$h->{Job},source_step=$machine,source_layer=in2b,dest=layer_name,dest_layer=bh_gbl,mode=replace,invert=no,copy_notes=no,copy_attrs=new_layers_only");
	$h->ClearAll();
	$h->AffectedLayer("bh_gtl");
	$h->AffectedLayer("bh_gbl");
	$h->ResetFilter();
	if ($machine eq 'panel-cb') {
		$h->FilterIncludeSymbol("cb-top-new-bm");
		$h->FilterSelect();

		if ($h->GetSelectNumber() > 0) {
			$h->COM("sel_change_sym,symbol=cb-bot-new-bm,reset_angle=no");
		}
	} else {
		$h->FilterIncludeSymbol("bh-top");
		$h->FilterSelect();

		if ($h->GetSelectNumber() > 0) {
			$h->COM("sel_change_sym,symbol=bh-bot,reset_angle=no");
		}
	}
}



# 复制symbol

#$h->


__END__
