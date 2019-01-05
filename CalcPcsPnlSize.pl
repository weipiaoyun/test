#! perl -w
#
#源码名称: CalcPcsPnlSize
#功能描述: 计算软板单个pcs面积和pnl利用率百分比
#开发单位: 集团工程系统开发部
#作者    : 王新梁
#开发日期: 2017.11.24
#版本号  : 1.1
#
use strict;
use warnings;
use lib qw(/gen_db/odb2/.hc/lib F:/lib);
use HC;
use POSIX qw(strftime);
use utf8;
use Data::Dumper;
use Tk;
use Tk::PNG;
use Tk::LabFrame;

#设置版本号
my $version = 1.0;

#初始化模块
my $h = HC->new();

my $pnlStep = 'pnl';
my $pcsStep = 'pcs'; 
#---------------------------------------------------------------------------------
#是否存在pcs和pnl两个step，
unless ($h->StepExists($pcsStep)){
    $h->StopMsgBox( 'error', "必须存在 ${pcsStep} step!" );
    exit; 
}
unless ($h->StepExists($pnlStep)){
    $h->StopMsgBox( 'error', "必须存在 ${pnlStep} step!" );
    exit; 
}

#pcs-step是否都有profile
$h->INFO(
    units       => 'mm',
    entity_type => 'step',
    entity_path => "$h->{Job}/$pcsStep",
    data_type   => 'PROF_LENGTH'
);
if ($h->{doinfo}{gPROF_LENGTH} eq '0'){
    $h->StopMsgBox( 'error', "${pcsStep} step 必须建立profile！" );
    exit; 
}

#pnl-step是否都有profile
$h->INFO(
    units       => 'mm',
    entity_type => 'step',
    entity_path => "$h->{Job}/$pnlStep",
    data_type   => 'PROF_LENGTH'
);
if ($h->{doinfo}{gPROF_LENGTH} eq '0'){
    $h->StopMsgBox( 'error', "${pnlStep} step 必须建立profile！" );
    exit; 
}
#
$h->OpenStep($pcsStep);
$h->COM( 'units', type => 'mm' );
my $tmpcu=$$;
$h->CreateLayer($tmpcu,'');
$h->ClearAll();
$h->AffectedLayer($tmpcu);

#铺铜
$h->COM(
    'fill_params',
    type           => 'solid',
    origin_type    => 'datum',
    solid_type     => 'surface',
    std_type       => 'line',
    min_brush      => '25.4',
    use_arcs       => 'yes',
    symbol         => '',
    dx             => '2.54',
    dy             => '2.54',
    std_angle      => 45,
    std_line_width => 254,
    std_step_dist  => 1270,
    std_indent     => 'odd',
    break_partial  => 'yes',
    cut_prims      => 'no',
    outline_draw   => 'no',
    outline_width  => 0,
    outline_invert => 'no'
);

$h->COM(
    'sr_fill',
    polarity        => 'positive',
    step_margin_x   => 0,
    step_margin_y   => 0,
    step_max_dist_x => 2540,
    step_max_dist_y => 2540,
    sr_margin_x     => 0,
    sr_margin_y     => 0,
    sr_max_dist_x   => 0,
    sr_max_dist_y   => 0,
    nest_sr         => 'yes',
    stop_at_steps   => '',
    consider_feat   => 'no',
    consider_drill  => 'no',
    consider_rout   => 'no',
    dest            => 'affected_layers',
    attributes      => 'no',
    use_profile     => 'use_profile'
);
#取得pcs面积
my $pcsCopper = $h->COM(
    'copper_area',
    layer1            => $tmpcu,
    layer2            => '',
    drills            => 'yes',
    consider_rout     => 'no',
    ignore_pth_no_pad => 'no',
    drills_source     => 'matrix',
    thickness         => 0,
    resolution_value  => '25.4',
    x_boxes           => 3,
    y_boxes           => 3,
    area              => 'no',
    dist_map          => 'yes'
);
my $pcsSize = (split('\s',$pcsCopper))[0];
$pcsSize = $pcsSize/1000/1000;#得出PCS平方米
if ($pcsSize == 0 or $pcsSize eq '' ){
     $h->StopMsgBox( 'error', "pcs面积获取不成功，请查看单只profile填铜是否存在问题!" );
    exit; 
}

#获取set Size
if ($h->StepExists("set")) {
	#获取set里面pcs的个数
	$h->INFO(entity_type => 'step',
		entity_path => "$h->{Job}/set",
		data_type 	 => 'REPEAT',
        parameters => "step");
	my @pcsStep = @{$h->{doinfo}{gREPEATstep}};
	@pcsStep = grep /pcs.*/, @pcsStep;	
	my $set_qty = $#pcsStep + 1;

	if ($h->StepExists("pnl")){
		$h->INFO(entity_type => 'step',
			entity_path => "$h->{Job}/pnl",
			data_type 	 => 'REPEAT',
			parameters => "step");
		my @setStep = @{$h->{doinfo}{gREPEATstep}};
		@setStep = grep /set.*/, @setStep;	
		#set数量*set里面的pcs数量
		my $spell_qty = ($#setStep + 1)*$set_qty;

		#获取pcs
		$h->GetPROFLimit("pcs");
		my $pcs_lngth = $h->{PROF}{xmax} - $h->{PROF}{xmin};
		my $pcs_width = $h->{PROF}{ymax} - $h->{PROF}{ymin};

		$h->GetPROFLimit("set");
		my $set_lngth = $h->{PROF}{xmax} - $h->{PROF}{xmin};
		my $set_width = $h->{PROF}{ymax} - $h->{PROF}{ymin};

		$h->GetPROFLimit("pnl");
		my $spell_lngth = $h->{PROF}{xmax} - $h->{PROF}{xmin};
		my $spell_width = $h->{PROF}{ymax} - $h->{PROF}{ymin};

		#查找erp是pcs交货还是set交货
		#如果是pcs交货。则
		#if

		$h->{pcs_lngth} = $pcs_lngth;
		$h->{pcs_width}  = $pcs_width;
		$h->{pcs_sq } = $pcsSize;
		$h->{set_lngth}  = $set_lngth;
		$h->{set_width}  = $set_width;
		$h->{set_qty} = $set_qty;
		$h->{unit_sq} = $set_lngth*$set_width/$set_qty*0.000001;
		$h->{spell_lngth} = $spell_lngth;
		$h->{spell_width} = $spell_width;
		$h->{spell_qty}  = $spell_qty;
		$h->{spell_sq } = $spell_lngth*$spell_width/$spell_qty*0.000001;

		
		print "#$h->{pcs_lngth}#$h->{pcs_width}#	$h->{pcs_sq }#$h->{set_lngth}#$h->{set_width}#$h->{set_qty}#$h->{unit_sq}#####$h->{spell_lngth}#$h->{spell_width}#$h->{spell_qty}##$h->{spell_sq }################";

		my $so_unit = $h->get_SO_UNIT();
		if ($so_unit eq 'SET') {
			$h->InitFPCMsSql();
			UpdateSize1();
			$h->disconnectMsSql();
		} else {
			$h->{set_lngth}  = $pcs_lngth;
			$h->{set_width}  = $pcs_width;
			$h->{set_qty} = 1;
			$h->{unit_sq} = $pcsSize;
			$h->InitFPCMsSql();
			UpdateSize1();
			$h->disconnectMsSql();
		}

		print "$so_unit # $pcs_width # $pcs_lngth # $set_width # $set_lngth # $#pcsStep # $#setStep\n";

	}
}


$h->ClearAll();
#
#如果有旋转的step，刷新旋转的step。
#此处定义旋转或阴阳排版的step命名特征为 flip flp pcs_
#获取所有step
$h->INFO(
    units       => 'mm',
    entity_type => 'job',
    entity_path => $h->{Job},
    data_type   => 'STEPS_LIST'
);
my @step = @{ $h->{doinfo}{gSTEPS_LIST} };    #所有step
for ( my $i = 0 ; $i <= $#step ; $i++ ) {
    if (   $step[$i] =~ /flip/
        or $step[$i] =~ /flp/
        or $step[$i] =~ /pcs_/ )
    {
        $h->VOF();
        $h->COM(
            'change_step_dependency',
            job       => $h->{Job},
            step      => $step[$i],
            operation => 'release'
        );
        $h->COM(
            'change_step_dependency',
            job       => $h->{Job},
            step      => $step[$i],
            operation => 'restore'
        );
        $h->COM(
            'update_dependent_step',
            job  => $h->{Job},
            step => $step[$i]
        );
        $h->VON();
    }
}
#pnl
$h->OpenStep($pnlStep);
$h->COM( 'units', type => 'mm' );
$h->ClearAll();
$h->AffectedLayer($tmpcu);
#取得pnl百分比
my $pnlCopper = $h->COM(
    'copper_area',
    layer1            => $tmpcu,
    layer2            => '',
    drills            => 'yes',
    consider_rout     => 'no',
    ignore_pth_no_pad => 'no',
    drills_source     => 'matrix',
    thickness         => 0,
    resolution_value  => '25.4',
    x_boxes           => 3,
    y_boxes           => 3,
    area              => 'no',
    dist_map          => 'yes'
);
my $pnlSize = (split('\s',$pnlCopper))[1];
$pnlSize = sprintf ("%.2f",$pnlSize);#得出PNL的百分比
if ($pnlSize == 0 or $pnlSize eq '' ){
     $h->StopMsgBox( 'error', "pnl百分比获取不成功，请查看单只profile填铜是否存在问题!" );
    exit; 
}
$h->ClearAll();
$h->DeleteLayer($tmpcu);

#ERP操作

$h->InitFPCMsSql();

#获取pcs面积
my $orig_pcs_size=FindSize();

#获取百分比
my $pnl_bfb =FindPnlBfb();

#上传PCS面积
#UpdateSize($h->{Job},$pcsSize);

#上传百分比
UpdatePnlBfb($h->{Job},$pnlSize);

#关闭数据库连接
$h->disconnectMsSql();


$h->StopMsgBox('info',"上传成功！");

exit;


sub FindSize{
    my $job = shift || $h->{Job};
    my $orig_pcs_size;
    #查询sql设定
    my  $sqlCmd = qq{SELECT PCS_SQ FROM [wisdompcb_rb].[dbo].[Data0025] WHERE MANU_PART_NUMBER= '$job'};            
    my  $matrix_ref;
    eval{
        $matrix_ref = $h->{MsSql}{dbh}->selectall_arrayref($sqlCmd) or die $h->{MsSql}{dbh}->error;
    };
    #数据库查询异常时操作
    if($@){
	$h->StopMsgBox('error',"数据库操作失败！\n$@");
        return;
    }
    
    my ($row) = (!defined ($matrix_ref) ? 0 : scalar (@{$matrix_ref}));
    
    if ($row == 1){
        $orig_pcs_size = $matrix_ref->[0]->[0];
    }
  return   $orig_pcs_size;
}

sub FindPnlBfb{
    my $job = shift || $h->{Job};
    my $pnl_bfb;
    
    #查询sql设定
    my  $sqlCmd = qq{
                    SELECT a.PARAMETER_VALUE FROM  [wisdompcb_rb].[dbo].[Data0279] AS a INNER JOIN [wisdompcb_rb].[dbo].[Data0278] AS b ON a.PARAMETER_PTR=b.RKEY INNER JOIN [wisdompcb_rb].[dbo].[Data0025] AS c ON c.RKEY = a.SOURCE_PTR WHERE a.PARAMETER_PTR=14  AND c.MANU_PART_NUMBER= '$job'
                    };            
    my  $matrix_ref;
    eval{
        $matrix_ref = $h->{MsSql}{dbh}->selectall_arrayref($sqlCmd) or die $h->{MsSql}{dbh}->error;
    };
    
    #数据库查询异常时操作
    if($@){
	$h->StopMsgBox('error',"数据库操作失败！\n$@");
        return;
    }
    
    my ($row) = (!defined ($matrix_ref) ? 0 : scalar (@{$matrix_ref}));
    
    if ($row == 1){
        $pnl_bfb = $matrix_ref->[0]->[0];
    }
    
  return   $pnl_bfb;
  
}

#更新大料利用率
sub UpdatePnlBfb{
    my $job = shift || $h->{Job};
    my $bfb = shift;
    #查询sql设定
    my  $sqlCmd = qq{
                   UPDATE [wisdompcb_rb].[dbo].[Data0279]  SET PARAMETER_VALUE = '$bfb' WHERE PARAMETER_PTR=14 AND SOURCE_PTR IN(SELECT c.RKEY FROM [wisdompcb_rb].[dbo].[Data0279] AS a
                   INNER JOIN [wisdompcb_rb].[dbo].[Data0278] AS b ON a.PARAMETER_PTR=b.RKEY
                   INNER JOIN [wisdompcb_rb].[dbo].[Data0025] AS c ON c.RKEY = a.SOURCE_PTR WHERE a.PARAMETER_PTR=14 AND c.MANU_PART_NUMBER='$job')
                    };            
    my  $matrix_ref;
    eval{
        $matrix_ref = $h->{MsSql}{dbh}->selectall_arrayref($sqlCmd) or die $h->{MsSql}{dbh}->error;
    };
    
    #数据库查询异常时操作
    if($@){
	$h->StopMsgBox('error',"数据库操作失败！\n$@");
        return;
    }
    
  return 1;
  
}

#更新PCS面积
sub UpdateSize{
    my $job = shift || $h->{Job};
    my $size = shift;
    #查询sql设定
    my  $sqlCmd = qq{
                   UPDATE [wisdompcb_rb].[dbo].[Data0025] SET PCS_SQ='$size' WHERE MANU_PART_NUMBER = '$job'
				   UPDATE [wisdompcb_rb].[dbo].[Data0025] SET UNIT_SQ ='$size' WHERE MANU_PART_NUMBER = '$job' AND SO_UNIT='PCS'
                    };            
    my  $matrix_ref;
    eval{
        $matrix_ref = $h->{MsSql}{dbh}->selectall_arrayref($sqlCmd) or die $h->{MsSql}{dbh}->error;
    };
    
    #数据库查询异常时操作
    if($@){
	$h->StopMsgBox('error',"数据库操作失败！\n$@");
        return;
    }
    
  return 1;
  
}

sub UpdateSize1{
    my $job = shift || $h->{Job};

    #查询sql设定
	my  $sqlCmd = qq{
	UPDATE [wisdompcb_rb].[dbo].[Data0025] SET pcs_lngth='$h->{pcs_lngth}' WHERE MANU_PART_NUMBER = '$job'
	UPDATE [wisdompcb_rb].[dbo].[Data0025] SET pcs_width ='$h->{pcs_width}' WHERE MANU_PART_NUMBER = '$job' 
	UPDATE [wisdompcb_rb].[dbo].[Data0025] SET pcs_sq ='$h->{pcs_sq}' WHERE MANU_PART_NUMBER = '$job' 
	UPDATE [wisdompcb_rb].[dbo].[Data0025] SET set_lngth ='$h->{set_lngth}' WHERE MANU_PART_NUMBER = '$job'
	UPDATE [wisdompcb_rb].[dbo].[Data0025] SET set_width ='$h->{set_width}' WHERE MANU_PART_NUMBER = '$job'
	UPDATE [wisdompcb_rb].[dbo].[Data0025] SET set_qty ='$h->{set_qty}' WHERE MANU_PART_NUMBER = '$job'
	UPDATE [wisdompcb_rb].[dbo].[Data0025] SET unit_sq ='$h->{unit_sq}' WHERE MANU_PART_NUMBER = '$job'
	UPDATE [wisdompcb_rb].[dbo].[Data0025] SET spell_lngth ='$h->{spell_lngth}' WHERE MANU_PART_NUMBER = '$job'
	UPDATE [wisdompcb_rb].[dbo].[Data0025] SET spell_width ='$h->{spell_width}' WHERE MANU_PART_NUMBER = '$job'
	UPDATE [wisdompcb_rb].[dbo].[Data0025] SET spell_qty ='$h->{spell_qty}' WHERE MANU_PART_NUMBER = '$job'
	UPDATE [wisdompcb_rb].[dbo].[Data0025] SET spell_sq ='$h->{spell_sq}' WHERE MANU_PART_NUMBER = '$job'
	};            
	my  $matrix_ref;
	eval{
        $matrix_ref = $h->{MsSql}{dbh}->selectall_arrayref($sqlCmd) or die $h->{MsSql}{dbh}->error;
    };
    
    #数据库查询异常时操作
    if($@){
	$h->StopMsgBox('error',"数据库操作失败！\n$@");
        return;
    }
    
  return 1;
  
}

