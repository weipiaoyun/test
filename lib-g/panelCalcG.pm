#!/usr/bin/perl
#源码名称: panelCalc.pm
#功能描述: 板边的数据计算
#开发单位: 集团工程系统开发部
#作者    : 林伟
#开发日期: 2014.10.15
#版本号  : 1.1

#修改人:   林伟
#修改后版本号: 1.1
#修改日期: 2015.01.21
#修改内容: 添加多层板层间对准度

#修改人:   张辉
#修改后版本号: 1.1
#修改日期: 2016-2-26
#修改内容: #内层打靶靶标距最后一次锣边距离大于50mm时，移动打靶靶标到距锣边小于50mm（实际做的是48mm）   2016-2-26

#修改人:   王新梁
#修改后版本号: 1.1
#修改日期: 2016-10-25
#修改内容: 之前没有定dot_t dot_b 的misc type。dot_t dot_b是misc type，丝印孔位要添加'h-screen-hole-pad3_silk'。


package panelCalcG;

#导入模块
use strict;
use warnings;
use POSIX qw(strftime);
use Storable;
use Data::Dumper;
use utf8;
require Exporter;

#设置程式名称
my $appName = 'panelCalcG';

#设置版本号
my $version = 1.0;


#**********************************************
#名字		:PreCalculate
#功能		:前计算
#参数		:无
#返回值		:1
#使用例子	:$self->PreCalculate();
#**********************************************
sub PreCalculate {
	my $self = shift;

	#计算PROF_LimitS和SR_Limits
	$self->GetPROFLimit("$self->{panelStep}");
	$self->GetSRLimit("$self->{panelStep}");

	#计算PROF的长度的一半
	$self->{PROF}{xHalf} = ($self->{PROF}{xmax} - $self->{PROF}{xmin})/2;
	$self->{PROF}{yHalf} = ($self->{PROF}{ymax} - $self->{PROF}{ymin})/2;

	#计算PROF中心点坐标
	$self->{PROF}{xCenter} = $self->{PROF}{xHalf} + $self->{PROF}{xmin};
	$self->{PROF}{yCenter} = $self->{PROF}{yHalf} + $self->{PROF}{ymin};

	#SR到PROF的距离
	$self->{SRToPROF}{x} = $self->{SR}{xmin} - $self->{PROF}{xmin};
	$self->{SRToPROF}{y} = $self->{SR}{ymin} - $self->{PROF}{ymin};

	#计算压合和锣边所在次数
	$self->CountYaHeLuoBian();

	#计算真假hdi
	$self->{hdi}{jia} = 'no';
	if (($self->{hdi}{jieShu} < $#{$self->{laser}{drillTop}} + 1
		or $self->{hdi}{jieShu} < $#{$self->{laser}{drillBottom}} + 1)){
		$self->{hdi}{jia} = 'yes';
	}


	#$self->{cfg}{luoBianSize}{lastX} = 523;
	#$self->{cfg}{luoBianSize}{lastY} = 604.5;


	#计算总共锣掉的尺寸
	my $luoSizeX = ($self->{PROF}{xmax} - $self->{cfg}{luoBianSize}{lastX}) / 2;
	my $luoSizeY = ($self->{PROF}{ymax} - $self->{cfg}{luoBianSize}{lastY}) / 2;

	#计算最后一次锣边后坐标
	$self->{liuBian}{xmin} = $luoSizeX;
	$self->{liuBian}{ymin} = $luoSizeY;


	$self->{liuBian}{xmax} = $self->{PROF}{xmax} - $luoSizeX;
	$self->{liuBian}{ymax} = $self->{PROF}{ymax} - $luoSizeY;

	#计算最后锣边后留边大小
	$self->{liuBian}{xSize} = $self->{SR}{xmin} - $self->{liuBian}{xmin};
	$self->{liuBian}{ySize} = $self->{SR}{ymin} - $self->{liuBian}{ymin};
	
	#有效边大小
	$self->{SR}{ValidX} = $self->{SR}{xmax} - $self->{SR}{xmin};
	$self->{SR}{ValidY} = $self->{SR}{ymax} - $self->{SR}{ymin};

	#ccd和daba
	#两层ccd之间的距离
	$self->{layerBaBiaoJianJu} = '8';

	#ccd的大小
	$self->{daba}{size} = '6.5';

	#F靶和B靶之间的距离
	$self->{FB}{value} = '50';

	$self->{cfg}{maxBc} = $self->{SR}{xmax} - 8.5 - ($self->{hdi}{jieShu}*$self->{layerBaBiaoJianJu}*3 + 5*2 + 9.5) - $self->{SR}{xmin} - 59 - 3;


	#daba和ccd之间的镭射靶标的个数
	$self->{laser}{leftNum} = sprintf "%1.0f", ($self->{FB}{value} - $self->{layerBaBiaoJianJu}*($self->{hdi}{jieShu}) - 6.5) / 8;


	#ccd的高度
	$self->{ccd}{hight} = ($self->{daba}{num}-1) * 0.5;

	#保证内层ccd和daba中心到prof的大小，(最小值)
	$self->{ccd}{inner}{toPROF} = '7';

	#if ($self->{SRToPROF}{y} > $self->{ccd}{inner}{toPROF} + 4.5 + $self->{ccd}{hight}){
	#	$self->{dabaMain}{outer}{toSR} = $self->{liuBian}{ySize} - $self->{ccd}{inner}{toPROF} - $self->{ccd}{hight};
	#}
	#else{
	#	$self->{dabaMain}{outer}{toSR} = '4.5';
	#}


	#df_size
	my $dfSize = $self->{dfSize};
	$dfSize = $dfSize*25.4;
	#my $dfRelsize = $self->{SR}{ValidY} + $self->{dabaMain}{outer}{toSR}*2 + $self->{hdi}{jieShu}*0.5*2 + $self->{daba}{size};

	#if ($dfSize < $dfRelsize) {
	#	$self->{dabaMain}{outer}{toSR} = '3.8';
	#}

	if ($self->{liuBian}{ySize} > 8 + 3.2 + $self->{hdi}{jieShu}*0.5 + 4 and ($self->{SR}{ValidY} + 9.6*2 + $self->{hdi}{jieShu}*0.5*2 + $self->{daba}{size}) < $dfSize) {
		#$self->{dabaMain}{outer}{toSR} = $self->{liuBian}{ySize} - $self->{hdi}{jieShu}*0.5 - 2;
		$self->{dabaMain}{outer}{toSR} = '9.6';
	}
	elsif ($self->{liuBian}{ySize} - 4 - 1.6 - $self->{hdi}{jieShu}*0.5 > 4.5 and ($self->{SR}{ValidY} + ($self->{liuBian}{ySize} - $self->{hdi}{jieShu}*0.5 - 4 - 1.6)*2 + $self->{hdi}{jieShu}*0.5*2 + $self->{daba}{size}) < $dfSize) {
		$self->{dabaMain}{outer}{toSR} = $self->{liuBian}{ySize} - $self->{hdi}{jieShu}*0.5 - 4 - 1.6;
	}
	elsif (($self->{SR}{ValidY} + 4.5*2 + $self->{hdi}{jieShu}*0.5*2 + $self->{daba}{size}) < $dfSize) {
		$self->{dabaMain}{outer}{toSR} = '4.5';
	} else {
		$self->{dabaMain}{outer}{toSR} = '3.8';
	}


	if ($self->{liuBian}{xSize} > 8 + 3.2 + $self->{hdi}{jieShu}*0.5 + 4) {
		$self->{dabaSub}{outer}{toSR} = 9.6;
	} 
	elsif ($self->{liuBian}{xSize} - 4 - 1.6 - $self->{hdi}{jieShu}*0.5 > 4.5) {
		$self->{dabaSub}{outer}{toSR} = $self->{liuBian}{xSize} - $self->{hdi}{jieShu}*0.5 - 4 - 1.6;
	}
   	else {
		$self->{dabaSub}{outer}{toSR} = 4.5;
	}

	#$self->{dabaSub}{outer}{toSR} = '4.5';

	#计算防呆
	$self->{Target}{getType} = $self->{cfg}{ReFangDai};
	$self->{Target}{endRoutX} = $self->{cfg}{luoBianSize}{lastX};
	$self->{Target}{endRoutY} = $self->{cfg}{luoBianSize}{lastY};
	$self->{Target}{procCOunt} = $self->{ccd}{num};
	$self->{Target}{sr2Target} = $self->{dabaMain}{outer}{toSR};
	$self->{Target}{maxBc} = $self->{cfg}{maxBc};
	$self->{Target}{B_X} = $self->{SR}{xmin} + 59;
	$self->{Target}{E_X} = $self->{SR}{xmin} + 9;

	#6.5靶的大小，8.5距离SR
	$self->{Target}{G_X} = $self->{SR}{xmax} - 8.5 - ($self->{ccd}{num} - 1) *8 - 6.5;

	if ($self->{hdi}{jieShu} == 0) {
		$self->{Target}{G_X} = $self->{Target}{G_X} - 7 - 6;
	}


	$self->{Step} = $self->{panelStep};

	if ($self->{hdi}{jia} eq 'yes'){
		if ($self->{hdi}{jieShu} == 0){
			#8.5距离SR，6.5靶的大小，3.5假hdi板的镭射，6.5防焊ccd
			$self->{Target}{G_X} = $self->{SR}{xmax} - 8.5 - ($self->{ccd}{num} - 1) *8 - 6.5 -  3.5 - 6.5;
		}
		else {
			$self->{Target}{G_X} = $self->{SR}{xmax} - 8.5 - ($self->{ccd}{num} - 1) *8 - 6.5 -  3.5;
		}
	}

	#计算bc靶距值
	$self->{baju}{value} = $self->getBCFangDai();

	#如果没有找到，默认添加45%
	if ($self->{baju}{value} == 0){
		$self->{endMsg} .= "尺寸太小，无法满足靶距大于60%的要求，跑完后请检查修改！";
		$self->{msgSwitch} = "yes";
		$self->{baju}{value} = $self->{SR}{ValidX} * 45/100;
	}

	$self->CountFangDai();
	#镭射
	#镭射高度
	$self->{laser}{hight} = 3.68;
	$self->{laser}{cuoBa} = $self->{laser}{hight} * 2 + 0.4;

	#计算镭射所占长度
	if ($#{$self->{laser}{drillTop}} >  $#{$self->{laser}{drillBottom}}){
		$self->{laser}{drillNum} = $#{$self->{laser}{drillTop}} + 1;
	}
	else{
		$self->{laser}{length} = (2 * $#{$self->{laser}{drillBottom}} + 2)*$self->{laser}{hight} - 3.8;
		$self->{laser}{drillNum} = $#{$self->{laser}{drillBottom}} + 1;
	}
	$self->{laser}{length} = $self->{laser}{cuoBa} * $self->{laser}{drillNum};

	#初始化一些参数
	if ($self->{coreNum} > 0){
		$self->{inner}{have} = 'yes';
	}
	else {
		$self->{inner}{have} = 'no';
	}

	if ($#{$self->{allLayers}} >= 3){
		$self->{IsFillCu} = 'yes';
	}

	if ($self->{Job} =~ /^[tb]m.*/) {
		$self->{hdiType} = 'muti';
	} else {
		$self->{hdiType} = 'hdi';
	}

	return 1;
}

#**********************************************
#名字		:CountLayerType
#功能		:设置step的名字
#参数		:无
#返回值		:1
#使用例子	:$self->CountLayerType();
#**********************************************
sub CountLayerType {
	my $self = shift;

	#根据层名计算各层类别

	#设置文字类型
	if ($self->{Layer} =~ /^g[tb]o$/) {
		$self->{layerType} = 'ss';
	}

	#设置防焊p类型
	elsif ($self->{Layer} =~ /^g[tb]s$/){ 
		$self->{layerType} = 'sm'; 
	}

	#设置防焊p类型
	elsif ($self->{Layer} =~ /^cop[tb]$/){ 
		$self->{layerType} = 'sp'; 
	}

	#设置外层类型
	elsif ($self->{Layer} =~ /^g[tb]l$/){ 
		$self->{layerType} = 'outer'; 
	}

	#设置次外层类型
	elsif ($self->{Layer} =~ /^sec\d{1,2}[tb]$/){ 
		$self->{layerType} = 'second'; 
	}

	#设置内层类型
	elsif ($self->{Layer} =~ /^(in\d{1,2}[tb])$/){ 
		$self->{layerType} = 'inner'; 
	}

	#设置通孔类型
	elsif ($self->{Layer} =~ /^(d\d{2,4})$/){ 
		$self->{layerType} = 'via'; 
	}

	#设置镭射孔
	elsif ($self->{Layer} =~ /^l\d{2,4}$/){
		$self->{layerType} = 'laser';
	}

	#设置盲孔
	elsif ($self->{Layer} =~ /^m\d{2,4}$/){
		$self->{layerType} = 'bury';
	}

	else{
		$self->{layerType} = 'misc';
	}

	return 1;
}

#**********************************************
#名字		:CountIfAddMangKongDuiWei
#功能		:计算是否添加盲孔对位
#参数		:无
#返回值		:1
#使用例子	:$self->CountIfAddMangKongDuiWei();
#**********************************************
sub CountIfAddMangKongDuiWei {
	my $self = shift;

	my $pcsStep = 'edit';

	if ($self->StepExists($pcsStep)){
		$self->OpenStep($pcsStep);
		#顶层
		foreach my $i (0..$#{$self->{laser}{drillTop}}){
			$self->SetLayer($self->{laser}{drillTop}[$i]);
			$self->ClearAll();
			$self->AffectedLayer($self->{laser}{drillTop}[$i]);
			#碰其他层
			foreach my $j ($i..$#{$self->{laser}{drillTop}}){
				$self->COM('sel_ref_feat', 
					layers       => "$self->{laser}{drillTop}[$j]",
					use          => 'filter',
					mode         => 'touch',
					pads_as      => 'shape',
				);
				if ($self->GetSelectNumber()){
					$self->CloseStep();
					return 'add';
				}
			}
		}

		#底层
		foreach my $i (0..$#{$self->{laser}{drillBottom}}){
			$self->SetLayer($self->{laser}{drillBottom}[$i]);
			$self->ClearAll();
			$self->AffectedLayer($self->{laser}{drillBottom}[$i]);
			#碰其他层
			foreach my $j ($i..$#{$self->{laser}{drillBottom}}){
				$self->COM('sel_ref_feat', 
					layers       => "$self->{laser}{drillBottom}[$j]",
					use          => 'filter',
					mode         => 'touch',
					pads_as      => 'shape',
				);
				if ($self->GetSelectNumber()){
					#关闭Step
					$self->CloseStep();
					return 'add';
				}
			}
		}

		$self->CloseStep();
	}
	else {
		$self->StopMsgBox('error', "程序没有找到edit，请确认！");
	}
	
	return 1;
}

#**********************************************
#名字		:CountFillCu
#功能		:计算阻流边数据
#参数		:铺铜方式
#返回值		:1
#使用例子	:$self->CountFillCu();
#**********************************************
sub CountFillCu {
	my $self = shift;

	if ($self->{fillCuMode} eq 'zuLiuTiao'){
		#计算symbol
		if ($self->{Layer} eq "h-fillcut$self->{PID}"){
			${$self->{fillCu}{symbol}}[0] = 'h-fillcu-l';
			${$self->{fillCu}{symbol}}[1] = 'h-fillcu-t';
			${$self->{fillCu}{symbol}}[2] = 'h-fillcu-r';
			${$self->{fillCu}{symbol}}[3] = 'h-fillcu-b';
		}
		elsif ($self->{Layer} eq "h-fillcub$self->{PID}"){
			${$self->{fillCu}{symbol}}[0] = 'h-fillcu-r';
			${$self->{fillCu}{symbol}}[1] = 'h-fillcu-b';
			${$self->{fillCu}{symbol}}[2] = 'h-fillcu-l';
			${$self->{fillCu}{symbol}}[3] = 'h-fillcu-t';
		}

		if ($self->{Layer} eq "h-fillcub$self->{PID}"){
			#左边的
			${$self->{fillCu}{x}}[0] -= 4.5;
			#上
			${$self->{fillCu}{y}}[1] += 4.5;
			#右
			${$self->{fillCu}{x}}[2] += 4.5;
			#下
			${$self->{fillCu}{y}}[3] -= 4.5;
		}

		#计算个数,横向个数一样，纵向个数一样
		if ($self->{fillCu}{hengX}){
			return 0;
		}

		$self->{fillCu}{hengX} = $self->{PROF}{xmax} / 14 + 1;
		$self->{fillCu}{hengY} = ($self->{SR}{ymin} - $self->{PROF}{ymin}) / 6 + 1;

		$self->{fillCu}{zongX} = ($self->{SR}{xmin} - $self->{PROF}{xmin}) / 6 + 1;
		$self->{fillCu}{zongY} = $self->{PROF}{ymax} / 14 + 1;

		push @{$self->{fillCu}{countX}}, sprintf "%d", "$self->{fillCu}{zongX}";
		push @{$self->{fillCu}{countX}}, sprintf "%d", $self->{fillCu}{hengX};
		push @{$self->{fillCu}{countX}}, sprintf "%d", $self->{fillCu}{zongX};
		push @{$self->{fillCu}{countX}}, sprintf "%d", $self->{fillCu}{hengX};

		push @{$self->{fillCu}{countY}}, sprintf "%d", $self->{fillCu}{zongY};
		push @{$self->{fillCu}{countY}}, sprintf "%d", $self->{fillCu}{hengY};
		push @{$self->{fillCu}{countY}}, sprintf "%d", $self->{fillCu}{zongY};
		push @{$self->{fillCu}{countY}}, sprintf "%d", $self->{fillCu}{hengY};

		#间距
		push @{$self->{fillCu}{distanceX}}, "-6262";
		push @{$self->{fillCu}{distanceX}}, "14002.54";
		push @{$self->{fillCu}{distanceX}}, "6262";
		push @{$self->{fillCu}{distanceX}}, "14002.54";


		push @{$self->{fillCu}{distanceY}}, "14002.54";
		push @{$self->{fillCu}{distanceY}}, "6262";
		push @{$self->{fillCu}{distanceY}}, "14002.54";
		push @{$self->{fillCu}{distanceY}}, "-6262";

		#计算坐标
		if ($self->{fillCu}{x}){
			return 0;
		}

		#左边
		push @{$self->{fillCu}{x}}, $self->{SR}{xmin} - 2 ;
		#上边
		push @{$self->{fillCu}{x}}, $self->{PROF}{xmin};
		#右边
		push @{$self->{fillCu}{x}}, $self->{SR}{xmax} + 2 ;
		#下边
		push @{$self->{fillCu}{x}}, $self->{PROF}{xmin};


		push @{$self->{fillCu}{y}}, $self->{PROF}{ymin};
		push @{$self->{fillCu}{y}}, $self->{SR}{ymax} + 2;
		push @{$self->{fillCu}{y}}, $self->{PROF}{ymin};
		push @{$self->{fillCu}{y}}, $self->{SR}{ymin} - 2;
	}
	else {
		my $s1 = $self->{SRToPROF}{x} + 20;
		my $s2 = $self->{SRToPROF}{x} + 20;
		my $s3 = $self->{SRToPROF}{y} + 20;
		my $s4 = $self->{SRToPROF}{y} + 20;
		if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
			
			$self->{liuJiao}{Start}{x}[0] = $self->{SR}{xmin} + $s1;
			$self->{liuJiao}{Start}{y}[0] = $self->{PROF}{yCenter} + 165 - $s1;
			$self->{liuJiao}{End}{x}[0] = $self->{SR}{xmin} - $s2;
			$self->{liuJiao}{End}{y}[0] = $self->{PROF}{yCenter} + 165 + $s2;

			$self->{liuJiao}{Start}{x}[1] = $self->{liuJiao}{Start}{x}[0];
			$self->{liuJiao}{Start}{y}[1] = $self->{PROF}{yCenter} + 95 - $s1;
			$self->{liuJiao}{End}{x}[1] = $self->{liuJiao}{End}{x}[0];
			$self->{liuJiao}{End}{y}[1] = $self->{PROF}{yCenter} + 95 + $s2;

			$self->{liuJiao}{Start}{x}[2] = $self->{liuJiao}{Start}{x}[0];
			$self->{liuJiao}{Start}{y}[2] = $self->{PROF}{yCenter} - 105 - $s1;
			$self->{liuJiao}{End}{x}[2] = $self->{liuJiao}{End}{x}[0];
			$self->{liuJiao}{End}{y}[2] = $self->{PROF}{yCenter} - 105 + $s2;

			$self->{liuJiao}{Start}{x}[3] = $self->{liuJiao}{Start}{x}[0];
			$self->{liuJiao}{Start}{y}[3] = $self->{PROF}{yCenter} - 175 - $s1;
			$self->{liuJiao}{End}{x}[3] = $self->{liuJiao}{End}{x}[0];
			$self->{liuJiao}{End}{y}[3] = $self->{PROF}{yCenter} - 175 + $s2;

			$self->{liuJiao}{Start}{x}[4] = $self->{SR}{xmax} - $s1;
			$self->{liuJiao}{Start}{y}[4] = $self->{liuJiao}{Start}{y}[0];
			$self->{liuJiao}{End}{x}[4] = $self->{SR}{xmax} + $s2;
			$self->{liuJiao}{End}{y}[4] = $self->{liuJiao}{End}{y}[0];

			$self->{liuJiao}{Start}{x}[5] = $self->{liuJiao}{Start}{x}[4];
			$self->{liuJiao}{Start}{y}[5] = $self->{liuJiao}{Start}{y}[1];
			$self->{liuJiao}{End}{x}[5] = $self->{liuJiao}{End}{x}[4];
			$self->{liuJiao}{End}{y}[5] = $self->{liuJiao}{End}{y}[1];

			$self->{liuJiao}{Start}{x}[6] = $self->{liuJiao}{Start}{x}[4];
			$self->{liuJiao}{Start}{y}[6] = $self->{liuJiao}{Start}{y}[2];
			$self->{liuJiao}{End}{x}[6] = $self->{liuJiao}{End}{x}[4];
			$self->{liuJiao}{End}{y}[6] = $self->{liuJiao}{End}{y}[2];

			$self->{liuJiao}{Start}{x}[7] = $self->{liuJiao}{Start}{x}[4];
			$self->{liuJiao}{Start}{y}[7] = $self->{liuJiao}{Start}{y}[3];
			$self->{liuJiao}{End}{x}[7] = $self->{liuJiao}{End}{x}[4];
			$self->{liuJiao}{End}{y}[7] = $self->{liuJiao}{End}{y}[3];

			#下
			$self->{liuJiao}{Start}{x}[8] = $self->{PROF}{xCenter}/2 - $s3;
			$self->{liuJiao}{Start}{y}[8] = $self->{SR}{ymin} + $s3;
			$self->{liuJiao}{End}{x}[8] = $self->{PROF}{xCenter}/2 + $s4;
			$self->{liuJiao}{End}{y}[8] = $self->{SR}{ymin} - $s4;

			$self->{liuJiao}{Start}{x}[9] = $self->{PROF}{xCenter}*3/2 - $s3;
			$self->{liuJiao}{Start}{y}[9] = $self->{SR}{ymin} + $s3;
			$self->{liuJiao}{End}{x}[9] = $self->{PROF}{xCenter}*3/2 + $s4;
			$self->{liuJiao}{End}{y}[9] = $self->{SR}{ymin} - $s4;

			$self->{liuJiao}{Start}{x}[10] = $self->{PROF}{xCenter} - 15 - $s3;
			$self->{liuJiao}{Start}{y}[10] = $self->{SR}{ymin} + $s3;
			$self->{liuJiao}{End}{x}[10] = $self->{PROF}{xCenter} - 15 + $s4;
			$self->{liuJiao}{End}{y}[10] = $self->{SR}{ymin} - $s4;

			#上
			$self->{liuJiao}{Start}{x}[11] = $self->{PROF}{xCenter}/2 + $s3;
			$self->{liuJiao}{Start}{y}[11] = $self->{SR}{ymax} + $s3;
			$self->{liuJiao}{End}{x}[11] = $self->{PROF}{xCenter}/2 - $s4;
			$self->{liuJiao}{End}{y}[11] = $self->{SR}{ymax} - $s4;

			$self->{liuJiao}{Start}{x}[12] = $self->{PROF}{xCenter}*3/2 - $s3;
			$self->{liuJiao}{Start}{y}[12] = $self->{SR}{ymax} - $s3;
			$self->{liuJiao}{End}{x}[12] = $self->{PROF}{xCenter}*3/2 + $s4;
			$self->{liuJiao}{End}{y}[12] = $self->{SR}{ymax} + $s4;

			$self->{liuJiao}{Start}{x}[13] = $self->{PROF}{xCenter} - 15 + $s3;
			$self->{liuJiao}{Start}{y}[13] = $self->{SR}{ymax} + $s3;
			$self->{liuJiao}{End}{x}[13] = $self->{PROF}{xCenter} - 15 - $s4;
			$self->{liuJiao}{End}{y}[13] = $self->{SR}{ymax} - $s4;
		}
		else {
			$self->{liuJiao}{Start}{x}[0] = $self->{SR}{xmin} + $s1;
			$self->{liuJiao}{Start}{y}[0] = $self->{PROF}{yCenter} + 180 + $s1;
			$self->{liuJiao}{End}{x}[0] = $self->{SR}{xmin} - $s2;
			$self->{liuJiao}{End}{y}[0] = $self->{PROF}{yCenter} + 180 - $s2;

			$self->{liuJiao}{Start}{x}[1] = $self->{liuJiao}{Start}{x}[0];
			$self->{liuJiao}{Start}{y}[1] = $self->{PROF}{yCenter} + 110 + $s1;
			$self->{liuJiao}{End}{x}[1] = $self->{liuJiao}{End}{x}[0];
			$self->{liuJiao}{End}{y}[1] = $self->{PROF}{yCenter} + 110 - $s2;

			$self->{liuJiao}{Start}{x}[2] = $self->{liuJiao}{Start}{x}[0];
			$self->{liuJiao}{Start}{y}[2] = $self->{PROF}{yCenter} - 91 + $s1;
			$self->{liuJiao}{End}{x}[2] = $self->{liuJiao}{End}{x}[0];
			$self->{liuJiao}{End}{y}[2] = $self->{PROF}{yCenter} - 91 - $s2;

			$self->{liuJiao}{Start}{x}[3] = $self->{liuJiao}{Start}{x}[0];
			$self->{liuJiao}{Start}{y}[3] = $self->{PROF}{yCenter} - 161 + $s1;
			$self->{liuJiao}{End}{x}[3] = $self->{liuJiao}{End}{x}[0];
			$self->{liuJiao}{End}{y}[3] = $self->{PROF}{yCenter} - 161 - $s2;

			$self->{liuJiao}{Start}{x}[4] = $self->{SR}{xmax} - $s1;
			$self->{liuJiao}{Start}{y}[4] = $self->{liuJiao}{Start}{y}[0];
			$self->{liuJiao}{End}{x}[4] = $self->{SR}{xmax} + $s2;
			$self->{liuJiao}{End}{y}[4] = $self->{liuJiao}{End}{y}[0];

			$self->{liuJiao}{Start}{x}[5] = $self->{liuJiao}{Start}{x}[4];
			$self->{liuJiao}{Start}{y}[5] = $self->{liuJiao}{Start}{y}[1];
			$self->{liuJiao}{End}{x}[5] = $self->{liuJiao}{End}{x}[4];
			$self->{liuJiao}{End}{y}[5] = $self->{liuJiao}{End}{y}[1];

			$self->{liuJiao}{Start}{x}[6] = $self->{liuJiao}{Start}{x}[4];
			$self->{liuJiao}{Start}{y}[6] = $self->{liuJiao}{Start}{y}[2];
			$self->{liuJiao}{End}{x}[6] = $self->{liuJiao}{End}{x}[4];
			$self->{liuJiao}{End}{y}[6] = $self->{liuJiao}{End}{y}[2];

			$self->{liuJiao}{Start}{x}[7] = $self->{liuJiao}{Start}{x}[4];
			$self->{liuJiao}{Start}{y}[7] = $self->{liuJiao}{Start}{y}[3];
			$self->{liuJiao}{End}{x}[7] = $self->{liuJiao}{End}{x}[4];
			$self->{liuJiao}{End}{y}[7] = $self->{liuJiao}{End}{y}[3];

			#下
			$self->{liuJiao}{Start}{x}[8] = $self->{PROF}{xCenter}/2 + $s3;
			$self->{liuJiao}{Start}{y}[8] = $self->{SR}{ymin} + $s3;
			$self->{liuJiao}{End}{x}[8] = $self->{PROF}{xCenter}/2 - $s4;
			$self->{liuJiao}{End}{y}[8] = $self->{SR}{ymin} - $s4;

			$self->{liuJiao}{Start}{x}[9] = $self->{PROF}{xCenter}*3/2 + $s3;
			$self->{liuJiao}{Start}{y}[9] = $self->{SR}{ymin} + $s3;
			$self->{liuJiao}{End}{x}[9] = $self->{PROF}{xCenter}*3/2 - $s4;
			$self->{liuJiao}{End}{y}[9] = $self->{SR}{ymin} - $s4;

			$self->{liuJiao}{Start}{x}[10] = $self->{PROF}{xCenter} - 15 + $s3;
			$self->{liuJiao}{Start}{y}[10] = $self->{SR}{ymin} + $s3;
			$self->{liuJiao}{End}{x}[10] = $self->{PROF}{xCenter} - 15 - $s4;
			$self->{liuJiao}{End}{y}[10] = $self->{SR}{ymin} - $s4;

			#上
			$self->{liuJiao}{Start}{x}[11] = $self->{PROF}{xCenter} - 15 - $s3;
			$self->{liuJiao}{Start}{y}[11] = $self->{SR}{ymax} + $s3;
			$self->{liuJiao}{End}{x}[11] = $self->{PROF}{xCenter} - 15 + $s4;
			$self->{liuJiao}{End}{y}[11] = $self->{SR}{ymax} - $s4;

			$self->{liuJiao}{Start}{x}[12] = $self->{PROF}{xCenter}/2 - $s3;
			$self->{liuJiao}{Start}{y}[12] = $self->{SR}{ymax} + $s3;
			$self->{liuJiao}{End}{x}[12] = $self->{PROF}{xCenter}/2 + $s4;
			$self->{liuJiao}{End}{y}[12] = $self->{SR}{ymax} - $s4;

			$self->{liuJiao}{Start}{x}[13] = $self->{PROF}{xCenter}*3/2 + $s3;
			$self->{liuJiao}{Start}{y}[13] = $self->{SR}{ymax} - $s3;
			$self->{liuJiao}{End}{x}[13] = $self->{PROF}{xCenter}*3/2 - $s4;
			$self->{liuJiao}{End}{y}[13] = $self->{SR}{ymax} + $s4;
			
			$self->{liuJiao}{Start}{x}[14] = $self->{PROF}{xmin} - 20;
			$self->{liuJiao}{Start}{y}[14] = $self->{PROF}{ymax} + 50;
			$self->{liuJiao}{End}{x}[14] = $self->{SR}{xmin} + 20;
			$self->{liuJiao}{End}{y}[14] = $self->{SR}{ymax} + 50;
			
		}

		$self->{out_line}{x}[0] = -3;
		$self->{out_line}{y}[0] = -3;

		$self->{out_line}{x}[1] = $self->{PROF}{xmax} + 3;
		$self->{out_line}{y}[1] = $self->{PROF}{ymax} + 3;
	}

	return 1;
}

#**********************************************
#名字		:CountYaHeLuoBian
#功能		:计算压合和锣边
#参数		:无
#返回值		:1
#使用例子	:$self->CountYaHeLuoBian();
#**********************************************
sub CountYaHeLuoBian {
	my $self = shift;
	
	#计算锣边所在次数
	foreach (@{$self->{signalLayer}{layer}}){
		if ($_  !~ /^in.*/){
			if ($_ =~ /.*t.*$/){
				$self->{$_}{yaheN} = $self->{hdi}{jieShu} + 2 - $self->{$_}{layNum};
			}
			else {
				$self->{$_}{yaheN} = $self->{hdi}{jieShu} + 2 - ($self->{signalLayer}{num} - $self->{$_}{layNum} + 1);
			}
		}
		else {
			$self->{$_}{yaheN} = 1;
		}
	}

	#镭射孔所对应的压合次数
	foreach (@{$self->{laser}{layer}}){
		my $characterAmount = length $_;
		my $quZhi;
		if ($characterAmount == 3){
			$quZhi = substr ($_, 1, 1);
		}
		else {
			$quZhi = substr ($_, 1, 2);
		}

		if ($quZhi <= $self->{signalLayer}{num} / 2){
			$self->{$_}{yaheN} = $self->{hdi}{jieShu} + 2 - $quZhi;
		}
		else {
			if ($characterAmount <= 4){
				$quZhi = substr ($_, 2);
			}
			else {
				$quZhi = substr ($_, 3);
			}
			$self->{$_}{yaheN} = $self->{hdi}{jieShu} + 2 - ($self->{signalLayer}{num} - $quZhi + 1);;
		}
	}

	return 1;
}

#**********************************************
#名字		:CountBoardLine
#功能		:计算boardline
#参数		:无
#返回值		:1
#使用例子	:$self->CountBoardLine();
#**********************************************
sub CountBoardLine {
	my $self = shift;
	$self->{boardLine}{symbool} = 'board_line';
	if ($self->{ERP}{isInnerHT} eq "yes" || $self->{ERP}{isOuterHT} eq "yes") {
		$self->{boardLine}{symbool} = "board_line-ht";
	}
	#计算坐标
	if ($self->{boardLine}{x}){
		return 0;
	}

	push @{$self->{boardLine}{x}}, $self->{SR}{xmin} - 0.64;
	push @{$self->{boardLine}{y}}, $self->{SR}{ymin} - 0.64;

	push @{$self->{boardLine}{x}}, $self->{SR}{xmin} - 0.64;
	push @{$self->{boardLine}{y}}, $self->{SR}{ymax} + 0.64;

	push @{$self->{boardLine}{x}}, $self->{SR}{xmax} + 0.64;
	push @{$self->{boardLine}{y}}, $self->{SR}{ymax} + 0.64;

	push @{$self->{boardLine}{x}}, $self->{SR}{xmax} + 0.64;
	push @{$self->{boardLine}{y}}, $self->{SR}{ymin} - 0.64;

	#角度
	@{$self->{boardLine}{angle}} = qw(270 0 90 180);

	return 1;
}

#**********************************************
#名字		:CountLiuJiao
#功能		:计算流胶数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountLiuJiao();
#**********************************************
sub CountLiuJiao {
	my $self = shift;
	
	if ($self->{liuJiao}{x}){
		return 0;
	}

	my $s = 3.254;

	$self->{liuJiao}{x}[0] = $self->{PROF}{xmin} + $s;
	$self->{liuJiao}{y}[0] = $self->{PROF}{ymin} + $s;

	$self->{liuJiao}{x}[1] = $self->{PROF}{xmin} + $s;
	$self->{liuJiao}{y}[1] = $self->{PROF}{ymax} - $s;

	$self->{liuJiao}{x}[2] = $self->{PROF}{xmax} - $s;
	$self->{liuJiao}{y}[2] = $self->{PROF}{ymax} - $s;

	$self->{liuJiao}{x}[3] = $self->{PROF}{xmax} - $s;
	$self->{liuJiao}{y}[3] = $self->{PROF}{ymin} + $s;
	
	@{$self->{liuJiao}{angle}} = qw(0 90 180 270);

	return 1;
}

#**********************************************
#名字		:CountScreenHole
#功能		:计算丝印孔数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountScreenHole();
#**********************************************
sub CountScreenHole {
	my $self = shift;

	#设置距离PROF的距离为3mm
	my $s = 4;
	
	#设置Symbol的名称
	if ($self->{layerType} eq 'inner'
			or $self->{layerType} eq 'second'
			or $self->{layerType} eq 'outer') {
		if ($self->{hdi}{jieShu} > 0){
			if ($self->{layerType} eq 'outer'){
				$self->{screenHole}{symbol} = 'h-screen-hole-pad3';
			}
			else {
				$self->{screenHole}{symbol} = 'h-screen-hole-pad3';
			}
		}
		else {
			$self->{screenHole}{symbol} = 'h-screen-hole-pad3';
		}
	}
	elsif ($self->{layerType} eq 'ss'){
		$self->{screenHole}{symbol} = 'h-screen-hole-pad3_silk';
	}
	elsif ($self->{layerType} eq 'sm'){
			$self->{screenHole}{symbol} = 'h-screen-hole-pad4';
	}
	elsif ($self->{layerType} eq 'via'
			or $self->{layerType} eq 'bury'){
			$self->{screenHole}{symbol} = 'r3175';
	}elsif ($self->{layerType} eq 'misc'){ #20161025 定义dot_t dot_b
		$self->{screenHole}{symbol} = 'h-screen-hole-pad3_silk';
	}

	#设置坐标
	#当数据已经存在的是后，返回状态0
	if ($self->{screenHole}{x}){
		if ($self->{Layer} =~ /(sec)|m/){
			$self->{screenHole}{x}[2] = $self->{SR}{xmax} + $s + 1.5;
		}
		else {
			$self->{screenHole}{x}[2] = $self->{SR}{xmax} + $s + 0.5;
		}
		return 0;
	}
	
	push @{$self->{screenHole}{x}}, $self->{SR}{xmin} - $s;
	push @{$self->{screenHole}{y}}, $self->{SR}{ymin} - $s;

	push @{$self->{screenHole}{x}}, $self->{SR}{xmin} - $s;
	push @{$self->{screenHole}{y}}, $self->{SR}{ymax} + $s;

	if ($self->{Layer} =~ /(sec)|m/){
		push @{$self->{screenHole}{x}}, $self->{SR}{xmax} + $s + 1.5;
	}
	else {
		push @{$self->{screenHole}{x}}, $self->{SR}{xmax} + $s + 0.5;
	}

	push @{$self->{screenHole}{y}}, $self->{SR}{ymax} + $s;

	#HDI板
	#if ($self->{hdi}{jieShu} > 0){
		push @{$self->{screenHole}{x}}, $self->{SR}{xmax} + $s;
		push @{$self->{screenHole}{y}}, $self->{SR}{ymin} + 2.5 + $self->{fangXiangKong}{jianJuValue};

		#防呆
		push @{$self->{screenHole}{x}}, $self->{SR}{xmax} + $s;
		push @{$self->{screenHole}{y}}, $self->{SR}{ymin} - $s - 1.5;

		#}
#	else {
#		push @{$self->{screenHole}{x}}, $self->{SR}{xmax} + $s;
#		push @{$self->{screenHole}{y}}, $self->{SR}{ymin} - $s;
#
#		#防呆
#		push @{$self->{screenHole}{x}}, $self->{SR}{xmax} + $s - 5;
#		push @{$self->{screenHole}{y}}, $self->{SR}{ymin} - $s;
#	}

	return 1;
}

#**********************************************
#名字		:CountErCiYuan
#功能		:计算二次元数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountErCiYuan();
#**********************************************
sub CountErCiYuanOld {
	my $self = shift;


	#设置坐标
	#当数据已经存在的是后，返回状态0
	if (not $self->{erCiYuan}{x}[0]){
		#设置距离
		my $xs = 4;	
		my $ys = 3.5;

		${$self->{erCiYuan}{x}}[0] = $self->{SR}{xmin} + $xs;
		${$self->{erCiYuan}{y}}[0] = $self->{SR}{ymin} - $ys;

		${$self->{erCiYuan}{x}}[1] = $self->{SR}{xmin} + $xs;
		${$self->{erCiYuan}{y}}[1] = $self->{SR}{ymax} + $ys;

		if ($self->{hdi}{jieShu} < 1
				or $self->{liuBian}{xSize} < 12){
			${$self->{erCiYuan}{x}}[2] = $self->{SR}{xmax} - 8.5;
			${$self->{erCiYuan}{y}}[2] = $self->{SR}{ymax} + $ys;

			${$self->{erCiYuan}{x}}[3] = $self->{SR}{xmax} - 8.5;
			${$self->{erCiYuan}{y}}[3] = $self->{SR}{ymin} - $ys;
		}
		else {
			${$self->{erCiYuan}{x}}[2] = $self->{liuBian}{xmax} - 2;
			${$self->{erCiYuan}{y}}[2] = $self->{SR}{ymax} + $ys;

			${$self->{erCiYuan}{x}}[3] = $self->{liuBian}{xmax} - 2;
			${$self->{erCiYuan}{y}}[3] = $self->{SR}{ymin} - $ys;
		}

	}

	#计算二次元数据x和y值
	$self->{erCiYuanValue}{xSize} = sprintf "%0.3f", ${$self->{erCiYuan}{x}}[2] - ${$self->{erCiYuan}{x}}[0];
	$self->{erCiYuanValue}{ySize} = sprintf "%0.3f", ${$self->{erCiYuan}{y}}[1] - ${$self->{erCiYuan}{y}}[0];

	if ($self->{hdi}{jieShu} < 1
			or $self->{liuBian}{xSize} < 12){
		#计算负片坐标点
		$self->{erCiYuanValue}{x} = ${$self->{erCiYuan}{x}}[2] - 10;

		#计算文字坐标点
		$self->{erCiYuanTextX}{x} = $self->{erCiYuanValue}{x} - 3.5;
		$self->{erCiYuanTextY}{x} = $self->{erCiYuanValue}{x} - 3.5;
	}
	else {
		#如果留边大于23，则二次元加在丝印孔右边，否则，加在丝印孔左边
		if ($self->{liuBian}{xSize} > 20){
			#计算负片坐标点
			$self->{erCiYuanValue}{x} = $self->{screenHole}{x}[2] + 7;

			#计算文字坐标点
			$self->{erCiYuanTextX}{x} = $self->{screenHole}{x}[2] + 3.5;
			$self->{erCiYuanTextY}{x} = $self->{erCiYuanTextX}{x};
		}
		else {
			#计算负片坐标点
			$self->{erCiYuanValue}{x} = $self->{screenHole}{x}[2] - 8;
			#计算文字坐标点
			$self->{erCiYuanTextX}{x} = $self->{screenHole}{x}[2] - 8 - 3.5;
			$self->{erCiYuanTextY}{x} = $self->{erCiYuanTextX}{x};
		}
	}

	$self->{erCiYuanText}{mirror} = 'no';
	if ($self->{Layer} =~ /b/){
		$self->{erCiYuanTextX}{x} = $self->{erCiYuanTextX}{x} + 7;
		$self->{erCiYuanTextY}{x} = $self->{erCiYuanTextY}{x} + 7;
		$self->{erCiYuanText}{mirror} = 'yes';
	}

	#计算角度
	@{$self->{erCiYuan}{angle}} = qw(0 180 180 0);

	$self->{erCiYuanValue}{y} = ${$self->{erCiYuan}{y}}[2];
	$self->{erCiYuanTextX}{y} = $self->{erCiYuanValue}{y};
	$self->{erCiYuanTextY}{y} = $self->{erCiYuanValue}{y} - 1.5;

	return 1;
}

#**********************************************
#名字		:CountErCiYuan
#功能		:计算二次元数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountErCiYuan();
#**********************************************
sub CountErCiYuanOld1 {
	my $self = shift;


	#设置坐标
	#当数据已经存在的是后，返回状态0
	if (not $self->{erCiYuan}{x}[0]){
		#设置距离
		my $xs = 1;	
		my $ys = 3.5;

		#if (($self->{hdi}{jieShu} < 1 and $self->{liuBian}{xSize} < 30)
		if ($self->{hdi}{jieShu} < 1
				or ($self->{hdi}{jieShu} > 0 and $self->{liuBian}{xSize} < 20)){
			${$self->{erCiYuan}{x}}[0] = $self->{SR}{xmin} + $xs;
			${$self->{erCiYuan}{y}}[0] = $self->{SR}{ymin} - $ys;

			${$self->{erCiYuan}{x}}[1] = $self->{SR}{xmin} + $xs;
			${$self->{erCiYuan}{y}}[1] = $self->{SR}{ymax} + $ys;

			${$self->{erCiYuan}{x}}[2] = $self->{SR}{xmax} - 8.5;
			${$self->{erCiYuan}{y}}[2] = $self->{SR}{ymax} + $ys;

			${$self->{erCiYuan}{x}}[3] = $self->{SR}{xmax} - 8.5;
			${$self->{erCiYuan}{y}}[3] = $self->{SR}{ymin} - $ys;
		}
		else {
			${$self->{erCiYuan}{x}}[0] = $self->{liuBian}{xmin} + 9;
			${$self->{erCiYuan}{y}}[0] = $self->{SR}{ymin} - $ys;

			${$self->{erCiYuan}{x}}[1] = $self->{liuBian}{xmin} + 9;
			${$self->{erCiYuan}{y}}[1] = $self->{SR}{ymax} + $ys;

			${$self->{erCiYuan}{x}}[2] = $self->{liuBian}{xmax} - 9;
			${$self->{erCiYuan}{y}}[2] = $self->{SR}{ymax} + $ys;

			${$self->{erCiYuan}{x}}[3] = $self->{liuBian}{xmax} - 9;
			${$self->{erCiYuan}{y}}[3] = $self->{SR}{ymin} - $ys;
		}

	}

	#计算二次元数据x和y值
	$self->{erCiYuanValue}{xSize} = sprintf "%0.3f", ${$self->{erCiYuan}{x}}[2] - ${$self->{erCiYuan}{x}}[0];
	$self->{erCiYuanValue}{ySize} = sprintf "%0.3f", ${$self->{erCiYuan}{y}}[1] - ${$self->{erCiYuan}{y}}[0];

#	if ($self->{hdi}{jieShu} < 1
#			or $self->{liuBian}{xSize} < 11){
#
	#if (($self->{hdi}{jieShu} < 1 and $self->{liuBian}{xSize} < 30)
	if ($self->{hdi}{jieShu} < 1
			or ($self->{hdi}{jieShu} > 0 and $self->{liuBian}{xSize} < 20)){
		#计算负片坐标点
		$self->{erCiYuanValue}{x} = ${$self->{erCiYuan}{x}}[2] - 10;

		#计算文字坐标点
		$self->{erCiYuanTextX}{x} = $self->{erCiYuanValue}{x} - 3.5;
		$self->{erCiYuanTextY}{x} = $self->{erCiYuanValue}{x} - 3.5;
	}
	else {
		#如果x留边大于21，则二次元加在丝印孔右边，否则，加在丝印孔左边 $self->{SR}{xmax} + 4为丝印孔坐标 +1是和埋孔防呆
		if ($self->{liuBian}{xSize} > 29){
			#计算负片坐标点
			$self->{erCiYuanValue}{x} = $self->{SR}{xmax} + 4 + 1 + 7;

			#计算文字坐标点
			$self->{erCiYuanTextX}{x} = $self->{SR}{xmax} + 4 + 1 + 3.5;
			$self->{erCiYuanTextY}{x} = $self->{erCiYuanTextX}{x};
		}
		#如果x留边小于21，则二次元加在丝印孔左边 $self->{SR}{xmax} + 4为丝印孔坐标
		else {
			#计算负片坐标点
			$self->{erCiYuanValue}{x} = $self->{SR}{xmax} + 4 - 8;
			#计算文字坐标点
			$self->{erCiYuanTextX}{x} = $self->{SR}{xmax} + 4 - 8 - 3.5;
			$self->{erCiYuanTextY}{x} = $self->{erCiYuanTextX}{x};
		}
	}

	$self->{erCiYuanText}{mirror} = 'no';
	if ($self->{Layer} =~ /b/){
		$self->{erCiYuanTextX}{x} = $self->{erCiYuanTextX}{x} + 7;
		$self->{erCiYuanTextY}{x} = $self->{erCiYuanTextY}{x} + 7;
		$self->{erCiYuanText}{mirror} = 'yes';
	}



	#计算角度
	@{$self->{erCiYuan}{angle}} = qw(0 180 180 0);

	$self->{erCiYuanValue}{y} = ${$self->{erCiYuan}{y}}[2];
	$self->{erCiYuanTextX}{y} = $self->{erCiYuanValue}{y};
	$self->{erCiYuanTextY}{y} = $self->{erCiYuanValue}{y} - 1.5;

	return 1;
}

#**********************************************
#名字		:CountErCiYuan
#功能		:计算二次元数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountErCiYuan();
#**********************************************
sub CountHuaWeiLayerDuiwei {
    my $self = shift;
    $self->{HuaWeiLayerDuiwei}{symbool} = "";
    if ($self->{layerType} eq 'inner')
    {
        $self->{HuaWeiLayerDuiwei}{symbool} = 'g-hw-layer-duiwei-inner';
    }
    elsif($self->{layerType} eq 'outer')
    {
        $self->{HuaWeiLayerDuiwei}{symbool} = 'g-hw-layer-duiwei-outer';
    }
    elsif($self->{layerType} eq 'via')
    {
        $self->{HuaWeiLayerDuiwei}{symbool} = 'g-hw-layer-duiwei-drl';
    }
    elsif($self->{layerType} eq 'sm')
    {
        $self->{HuaWeiLayerDuiwei}{symbool} = 'g-hw-layer-duiwei-sm';
    }

    unless ($self->{HuaWeiLayerDuiwei}{symbool})
    {
        return;
    }
    #设置坐标
    #当数据已经存在的是后，返回状态0
    if (not $self->{HuaWeiLayerDuiwei}{x}[0]){
        #设置距离

        ${$self->{HuaWeiLayerDuiwei}{x}}[0] = $self->{SR}{xmin} + 1;
        ${$self->{HuaWeiLayerDuiwei}{y}}[0] = $self->{SR}{ymin} - 7.5;

        ${$self->{HuaWeiLayerDuiwei}{x}}[1] = $self->{SR}{xmin} + 1;
        ${$self->{HuaWeiLayerDuiwei}{y}}[1] = $self->{SR}{ymax} + 7.5;

        ${$self->{HuaWeiLayerDuiwei}{x}}[2] = $self->{SR}{xmax} - 0.77;
        ${$self->{HuaWeiLayerDuiwei}{y}}[2] = $self->{SR}{ymax} + 7.5;

        ${$self->{HuaWeiLayerDuiwei}{x}}[3] = $self->{SR}{xmax} - 0.77;
        ${$self->{HuaWeiLayerDuiwei}{y}}[3] = $self->{SR}{ymin} - 7.5;
    }
    return 1;
}

#**********************************************
#名字		:CountErCiYuan
#功能		:计算二次元数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountErCiYuan();
#**********************************************
sub CountErCiYuan {
	my $self = shift;
	$self->{erCiYuan}{symbool} = 'h-erciyuan';
	if ($self->{ERP}{isInnerHT} eq "yes" || $self->{ERP}{isOuterHT} eq "yes") {
		$self->{erCiYuan}{symbool} = 'h-erciyuan-ht';
	}
	#设置坐标
	#当数据已经存在的是后，返回状态0
	if (not $self->{erCiYuan}{x}[0]){
		#设置距离
		my $xs = 1;	
		my $ys = 3.5;

		${$self->{erCiYuan}{x}}[0] = $self->{SR}{xmin} + $xs;
		${$self->{erCiYuan}{y}}[0] = $self->{SR}{ymin} - $ys;

		${$self->{erCiYuan}{x}}[1] = $self->{SR}{xmin} + $xs;
		${$self->{erCiYuan}{y}}[1] = $self->{SR}{ymax} + $ys;

		${$self->{erCiYuan}{x}}[2] = $self->{SR}{xmax} - 0.77;
		${$self->{erCiYuan}{y}}[2] = $self->{SR}{ymax} + $ys;

		${$self->{erCiYuan}{x}}[3] = $self->{SR}{xmax} - 0.77;
		${$self->{erCiYuan}{y}}[3] = $self->{SR}{ymin} - $ys;
	}

	#计算二次元数据x和y值
	$self->{erCiYuanValue}{xSize} = sprintf "%0.3f", ${$self->{erCiYuan}{x}}[2] - ${$self->{erCiYuan}{x}}[0];
	$self->{erCiYuanValue}{ySize} = sprintf "%0.3f", ${$self->{erCiYuan}{y}}[1] - ${$self->{erCiYuan}{y}}[0];

	#计算负片坐标点
	$self->{erCiYuanValue}{x} = $self->{SR}{xmin} - 3.2;

	#计算文字坐标点
	$self->{erCiYuanTextX}{x} = $self->{erCiYuanValue}{x} - 1.2;
	$self->{erCiYuanTextY}{x} = $self->{erCiYuanTextX}{x} + 1.5;
	if ($self->{ERP}{isInnerHT} eq "yes" || $self->{ERP}{isOuterHT} eq "yes") {
		$self->{erCiYuanTextX}{x} = $self->{erCiYuanValue}{x} - 1.2 - 0.8;
	}
	

	$self->{erCiYuanText}{mirror} = 'no';
	if ($self->{Layer} =~ /b/){
		$self->{erCiYuanTextX}{x} = $self->{erCiYuanTextX}{x} + 1;
		$self->{erCiYuanTextY}{x} = $self->{erCiYuanTextY}{x} + 1;
		if ($self->{ERP}{isInnerHT} eq "yes" || $self->{ERP}{isOuterHT} eq "yes")
		{
			$self->{erCiYuanTextX}{x} = $self->{erCiYuanTextX}{x} + 1 - 0.4;
			$self->{erCiYuanTextY}{x} = $self->{erCiYuanTextY}{x} + 1 - 0.4;
		}
		$self->{erCiYuanText}{mirror} = 'yes';
	}

	#计算角度
	@{$self->{erCiYuan}{angle}} = qw(0 180 180 0);
	if ($self->{coreNum} > 2
			and $self->{Layer} =~ /in/){
		$self->{erCiYuanValue}{y} = $self->{PROF}{yCenter} - 21;
	}
	else {
		$self->{erCiYuanValue}{y} = $self->{PROF}{yCenter} - 27;
	}
	$self->{erCiYuanTextX}{y} = $self->{erCiYuanValue}{y} + 3.5;
	$self->{erCiYuanTextY}{y} = $self->{erCiYuanTextX}{y};

	return 1;
}

#**********************************************
#名字		:CountLaser
#功能		:计算镭射数据, 放熔合块中间
#参数		:无
#返回值		:1
#使用例子	:$self->CountLaser();
#**********************************************
sub CountLaserOldOld {
	my $self = shift;
	
	#计算symbol

	#计算靶标坐标
	my $xs = 5;
	#如果为真hdi，则第一次锣边加在第一个位置，否则，加在第二个位置
	#左下
	if ($self->{hdi}{jia} eq 'yes'){
		$self->{laser}{baBiao}{x}[0] = $self->{SR}{xmin} - $xs + 0.7;
		$self->{laser}{baBiao}{y}[0] = $self->{PROF}{yCenter} - 125 + 1;

		$self->{laser}{baBiao}{x}[1] = $self->{SR}{xmin} - $xs + 0.7;
		$self->{laser}{baBiao}{y}[1] = $self->{PROF}{yCenter} + 145 + 1;

		$self->{laser}{baBiao}{x}[2] = $self->{SR}{xmax} + $xs + 0.7;
		$self->{laser}{baBiao}{y}[2] = $self->{PROF}{yCenter} + 145 + 1;

		$self->{laser}{baBiao}{x}[3] = $self->{SR}{xmax} + $xs + 0.7;
		$self->{laser}{baBiao}{y}[3] = $self->{PROF}{yCenter} - 125 + 1;
	}
	else {
		$self->{laser}{baBiao}{x}[0] = $self->{SR}{xmin} - $xs + 0.7;
		$self->{laser}{baBiao}{y}[0] = $self->{PROF}{yCenter} - 116 + 1;

		$self->{laser}{baBiao}{x}[1] = $self->{SR}{xmin} - $xs + 0.7;
		$self->{laser}{baBiao}{y}[1] = $self->{PROF}{yCenter} + 153 + 1;

		$self->{laser}{baBiao}{x}[2] = $self->{SR}{xmax} + $xs + 0.7;
		$self->{laser}{baBiao}{y}[2] = $self->{PROF}{yCenter} + 153 + 1;

		$self->{laser}{baBiao}{x}[3] = $self->{SR}{xmax} + $xs + 0.7;
		$self->{laser}{baBiao}{y}[3] = $self->{PROF}{yCenter} - 116 + 1;
	}


	#计算避铜
	if ($self->{laser}{biTong}){
		return 0;
	}

	#左下
	$self->{laser}{biTong}{xs}[0] = $self->{SR}{xmin} - $xs;
	if ($self->{hdi}{jia} eq 'yes'){
		$self->{laser}{biTong}{ys}[0] = $self->{PROF}{yCenter} - 125 + 0.5;
	}
	else {
		$self->{laser}{biTong}{ys}[0] = $self->{PROF}{yCenter} - 118 + 0.5;
	}

	$self->{laser}{biTong}{xe}[0] = $self->{SR}{xmin} - $xs;
	#镭射孔层的个数-7.7(线本身所占宽度)
	$self->{laser}{biTong}{ye}[0] = $self->{laser}{biTong}{ys}[0] - ($#{$self->{laser}{drillTop}} + $#{$self->{laser}{drillBottom}} + 2)*6 - 0.5 + 7.7;

	#左上
	$self->{laser}{biTong}{xs}[1] = $self->{SR}{xmin} - $xs;
	if ($self->{hdi}{jia} eq 'yes'){
		$self->{laser}{biTong}{ys}[1] = $self->{PROF}{yCenter} + 145 + 0.5;
	}
	else {
		$self->{laser}{biTong}{ys}[1] = $self->{PROF}{yCenter} + 153 + 0.5;
	}

	$self->{laser}{biTong}{xe}[1] = $self->{SR}{xmin} - $xs;
	#镭射孔层的个数-7.7(线本身所占宽度)
	$self->{laser}{biTong}{ye}[1] = $self->{laser}{biTong}{ys}[1] - ($#{$self->{laser}{drillTop}} + $#{$self->{laser}{drillBottom}} + 2)*6 - 0.5 + 7.7;

	#右上
	$self->{laser}{biTong}{xs}[2] = $self->{SR}{xmax} + $xs;
	if ($self->{hdi}{jia} eq 'yes'){
		$self->{laser}{biTong}{ys}[2] = $self->{PROF}{yCenter} + 145 + 0.5;
	}
	else {
		$self->{laser}{biTong}{ys}[2] = $self->{PROF}{yCenter} + 153 + 0.5;
	}

	$self->{laser}{biTong}{xe}[2] = $self->{SR}{xmax} + $xs;
	#镭射孔层的个数-7.7(线本身所占宽度)
	$self->{laser}{biTong}{ye}[2] = $self->{laser}{biTong}{ys}[1] - ($#{$self->{laser}{drillTop}} + $#{$self->{laser}{drillBottom}} + 2)*6 - 0.5 + 7.7;

	#右下
	$self->{laser}{biTong}{xs}[3] = $self->{SR}{xmax} + $xs;
	if ($self->{hdi}{jia} eq 'yes'){
		$self->{laser}{biTong}{ys}[3] = $self->{PROF}{yCenter} - 125 + 0.5;
	}
	else {
		$self->{laser}{biTong}{ys}[3] = $self->{PROF}{yCenter} - 118 + 0.5;
	}

	$self->{laser}{biTong}{xe}[3] = $self->{SR}{xmax} + $xs;
	#镭射孔层的个数-7.7(线本身所占宽度)
	$self->{laser}{biTong}{ye}[3] = $self->{laser}{biTong}{ys}[0] - ($#{$self->{laser}{drillTop}} + $#{$self->{laser}{drillBottom}} + 2)*6 - 0.5 + 7.7;

	return 1;
}

#**********************************************
#名字		:CountLaserBiaoJi
#功能		:计算镭射标记数据
#参数		:无
#返回值		:1
#使用例子	:$h->CountLaserBiaoJi();
#**********************************************
sub CountLaserBiaoJi {
	my $self = shift;

	#如果已经计算，返回
	if ($self->{laser}{biaoJi}{x}){
		return 0;
	}

	my $xs = 5;
	my $fangDai = $self->{screenHole}{y}[3] - $self->{screenHole}{y}[0] + 2.5 + 2 - 8;

	$self->{laser}{biaoJi}{x}[0] = $self->{SR}{xmin} - $xs + 0.8;
	$self->{laser}{biaoJi}{y}[0] = $self->{SR}{ymin} + 4;

	$self->{laser}{biaoJi}{x}[1] = $self->{laser}{biaoJi}{x}[0];
	$self->{laser}{biaoJi}{y}[1] = $self->{SR}{ymax} - 4;

	$self->{laser}{biaoJi}{x}[2] = $self->{SR}{xmax} + $xs;
	$self->{laser}{biaoJi}{y}[2] = $self->{laser}{biaoJi}{y}[1];

	#右下角，丝印孔防呆
	$self->{laser}{biaoJi}{x}[3] = $self->{laser}{biaoJi}{x}[2];
	$self->{laser}{biaoJi}{y}[3] = 	$self->{laser}{biaoJi}{y}[0] + $fangDai;

	return 1;
}

#**********************************************
#名字		:CountLaserBYBiaoJi
#功能		:计算镭射备用靶标记
#参数		:无
#返回值		:1
#使用例子	:$h->CountLaserBYBiaoJi();
#**********************************************
sub CountLaserBYBiaoJi {
	my $self = shift;

	#如果已经计算，则返回
	if ($self->{laserBY}{biaoJi}{x}){
		return 0;
	}

	my $ys = $self->{ccd}{length} + 9;

	$self->{laserBY}{biaoJi}{x}[0] = $self->{SR}{xmin} + $ys + 3.68;
	$self->{laserBY}{biaoJi}{x}[1] = $self->{laserBY}{biaoJi}{x}[0] - $self->{laser}{hight};
	$self->{laserBY}{biaoJi}{x}[2] = $self->{SR}{xmax} - 6  - $self->{laser}{length} + $self->{laser}{hight}/2;
	$self->{laserBY}{biaoJi}{x}[3] = $self->{laser}{hight} + $self->{SR}{xmax}  - 5.5 - $self->{ccd}{length} - $self->{laser}{length} + $self->{laser}{hight}/2;

	$self->{laserBY}{biaoJi}{y}[0] = $self->{SR}{ymin} - 5 + 0.7;
	$self->{laserBY}{biaoJi}{y}[1] = $self->{SR}{ymax} + 5 - 0.7;
	$self->{laserBY}{biaoJi}{y}[2] = $self->{laserBY}{biaoJi}{y}[1];
	$self->{laserBY}{biaoJi}{y}[3] = $self->{laserBY}{biaoJi}{y}[0];

	@{$self->{laserBY}{biaoJi}{angle}} = qw(270 90 90 270);

	if ($self->{hdi}{jieShu} == 0){
		$self->{laserBY}{biaoJi}{x}[0] = $self->{laserBY}{biaoJi}{x}[0] + 4.5;
		$self->{laserBY}{biaoJi}{x}[1] = $self->{laserBY}{biaoJi}{x}[1] + 4.5;
	}

	return 1;
}


#**********************************************
#名字		:CountLaser
#功能		:计算镭射数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountLaser();
#**********************************************
sub CountLaserOld {
	my $self = shift;
	
	#镭射孔层计算顶底层
	my $shangXia;
	if ($self->{layerType} eq 'laser'){
		my $characterAmount = length $self->{Layer};
		my $quZhi;
		if ($characterAmount == 3){
			$quZhi = substr ($self->{Layer}, 1, 1);
		}
		else {
			$quZhi = substr ($self->{Layer}, 1, 2);
		}

		if ($quZhi <= $self->{signalLayer}{num} / 2){
			$shangXia = 'shang';
		}
		else {
			$shangXia = 'xia';
		}
	}

	#计算靶标坐标
	#x偏移值
	my $xs = 5;
	my $xTiao = 0.8;

	#右下角防呆值
	my $fangDai = $self->{screenHole}{y}[3] + 2.5 - $self->{SR}{ymin};

	#如果为真hdi，则第一次锣边加在第一个位置，否则，加在第二个位置
	#左下
	#计算第一个的位置
	if ($self->{hdi}{jia} eq 'yes') {
		#假hdi板，内层
		if ($self->{Layer} =~ /in/){
			#假hdi板，内层，顶层
			if ($self->{Layer} =~ /t/
					or $shangXia eq 'shang'){
				$self->{laser}{baBiao}{x}[0] = $self->{SR}{xmin} - $xs + 0.8;
				$self->{laser}{baBiao}{y}[0] =  $self->{SR}{ymin} + 4;

				$self->{laser}{baBiao}{x}[1] = $self->{SR}{xmin} - $xs + 0.8;
				$self->{laser}{baBiao}{y}[1] = $self->{SR}{ymax} - 4;

				$self->{laser}{baBiao}{x}[2] = $self->{SR}{xmax} + $xs + 0.8;
				$self->{laser}{baBiao}{y}[2] = $self->{laser}{baBiao}{y}[1];

				#右下角，丝印孔防呆
				$self->{laser}{baBiao}{x}[3] = $self->{SR}{xmax} + $xs + 0.8;
				$self->{laser}{baBiao}{y}[3] = 	$self->{laser}{baBiao}{y}[0] + $fangDai;
			}
			#假hdi板，内层底层
			else {
				$self->{laser}{baBiao}{x}[0] = $self->{SR}{xmin} - $xs + 0.8;
				$self->{laser}{baBiao}{y}[0] = $self->{SR}{ymin} + 4 + $self->{laser}{hight};

				$self->{laser}{baBiao}{x}[1] = $self->{SR}{xmin} - $xs + 0.8;
				$self->{laser}{baBiao}{y}[1] = $self->{SR}{ymax} - 4 - $self->{laser}{hight};

				$self->{laser}{baBiao}{x}[2] = $self->{SR}{xmax} + $xs + 0.8;
				$self->{laser}{baBiao}{y}[2] = $self->{laser}{baBiao}{y}[1];

				#右下角，丝印孔防呆
				$self->{laser}{baBiao}{x}[3] = $self->{SR}{xmax} + $xs + 0.8;
				$self->{laser}{baBiao}{y}[3] = $self->{laser}{baBiao}{y}[0] + $fangDai;
			}
		}
		else {
			#假hdi板，次外层或外层，顶层
			if ($self->{Layer} =~ /t/
					or $shangXia eq 'shang'){
				$self->{laser}{baBiao}{x}[0] = $self->{SR}{xmin} - $xs + 0.8;
				$self->{laser}{baBiao}{y}[0] =  $self->{SR}{ymin} + 4 + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa};

				$self->{laser}{baBiao}{x}[1] = $self->{SR}{xmin} - $xs + 0.8;
				$self->{laser}{baBiao}{y}[1] = $self->{SR}{ymax} - 4  - ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa};

				$self->{laser}{baBiao}{x}[2] = $self->{SR}{xmax} + $xs + 0.8;
				$self->{laser}{baBiao}{y}[2] = $self->{laser}{baBiao}{y}[1];

				#右下角，丝印孔防呆
				$self->{laser}{baBiao}{x}[3] = $self->{SR}{xmax} + $xs + 0.8;
				$self->{laser}{baBiao}{y}[3] = 	$self->{laser}{baBiao}{y}[0] + $fangDai;

			}
			##假hdi板，次外层或外层，底层
			else {
				$self->{laser}{baBiao}{x}[0] = $self->{SR}{xmin} - $xs + 0.8;
				$self->{laser}{baBiao}{y}[0] = $self->{SR}{ymin} + 4 + $self->{laser}{hight} + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa};

				$self->{laser}{baBiao}{x}[1] = $self->{SR}{xmin} - $xs + 0.8;
				$self->{laser}{baBiao}{y}[1] = $self->{SR}{ymax} - 4 - ($self->{laser}{hight} + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa});

				$self->{laser}{baBiao}{x}[2] = $self->{SR}{xmax} + $xs + 0.8;
				$self->{laser}{baBiao}{y}[2] = $self->{laser}{baBiao}{y}[1];

				#右下角，丝印孔防呆
				$self->{laser}{baBiao}{x}[3] = $self->{SR}{xmax} + $xs + 0.8;
				$self->{laser}{baBiao}{y}[3] = $self->{laser}{baBiao}{y}[0] + $fangDai;
			}
		}

		#假hdi板，计算symbol
		if ($self->{Layer} =~ /in/){
			$self->{laser}{baBiao}{symbol} = "h-laser-babiao"."$self->{$self->{Layer}}{yaheN}";
		}
		else {
			my $num;
			$num = $self->{$self->{Layer}}{yaheN} + 1;
			$self->{laser}{baBiao}{symbol} = "h-laser-babiao"."$num";
		}
	}
	#真hdi板
	else {
		#真hdi板，顶层
		if ($self->{Layer} =~ /t/
				or $shangXia eq 'shang'){
			$self->{laser}{baBiao}{x}[0] = $self->{SR}{xmin} - $xs + 0.8;
			$self->{laser}{baBiao}{y}[0] =  $self->{SR}{ymin} + 4 + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};

			$self->{laser}{baBiao}{x}[1] = $self->{SR}{xmin} - $xs + 0.8;
			$self->{laser}{baBiao}{y}[1] = $self->{SR}{ymax} - 4  - ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};

			$self->{laser}{baBiao}{x}[2] = $self->{SR}{xmax} + $xs + 0.8;
			$self->{laser}{baBiao}{y}[2] = $self->{laser}{baBiao}{y}[1];

			#右下角，丝印孔防呆
			$self->{laser}{baBiao}{x}[3] = $self->{SR}{xmax} + $xs + 0.8;
			$self->{laser}{baBiao}{y}[3] = 	$self->{laser}{baBiao}{y}[0] + $fangDai;
		}
		#真hdi板，底层
		else {
			$self->{laser}{baBiao}{x}[0] = $self->{SR}{xmin} - $xs + 0.8;
			$self->{laser}{baBiao}{y}[0] = $self->{SR}{ymin} + 4 + $self->{laser}{hight} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};

			$self->{laser}{baBiao}{x}[1] = $self->{SR}{xmin} - $xs + 0.8;
			$self->{laser}{baBiao}{y}[1] = $self->{SR}{ymax} - 4 - ($self->{laser}{hight} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa});

			$self->{laser}{baBiao}{x}[2] = $self->{SR}{xmax} + $xs + 0.8;
			$self->{laser}{baBiao}{y}[2] = $self->{laser}{baBiao}{y}[1];

			#右下角，丝印孔防呆
			$self->{laser}{baBiao}{x}[3] = $self->{SR}{xmax} + $xs + 0.8;
			$self->{laser}{baBiao}{y}[3] = $self->{laser}{baBiao}{y}[0] + $fangDai;
		}
		#真hdi 板
		#计算symbol
		$self->{laser}{baBiao}{symbol} = "h-laser-babiao"."$self->{$self->{Layer}}{yaheN}";
	}

	#添加对位点
	$self->{laser}{duiWei}{x}[0] = $self->{laser}{baBiao}{x}[0];
	$self->{laser}{duiWei}{y}[0] = $self->{laser}{baBiao}{y}[0] - $self->{laser}{cuoBa};

	$self->{laser}{duiWei}{x}[1] = $self->{laser}{baBiao}{x}[1];
	$self->{laser}{duiWei}{y}[1] = $self->{laser}{baBiao}{y}[1] + $self->{laser}{cuoBa};

	$self->{laser}{duiWei}{x}[2] = $self->{laser}{baBiao}{x}[2];
	$self->{laser}{duiWei}{y}[2] = $self->{laser}{baBiao}{y}[2] + $self->{laser}{cuoBa};

	#右下角，丝印孔防呆
	$self->{laser}{duiWei}{x}[3] = $self->{laser}{baBiao}{x}[3];
	$self->{laser}{duiWei}{y}[3] = $self->{laser}{baBiao}{y}[3] - $self->{laser}{cuoBa};

	#计算避铜
	if ($self->{laser}{biTong}{xs}){
		return 0;
	}

	#左下
	$self->{laser}{biTong}{xs}[0] = $self->{SR}{xmin} - $xs;
	$self->{laser}{biTong}{ys}[0] = $self->{SR}{ymin} + 4;

	$self->{laser}{biTong}{xe}[0] = $self->{SR}{xmin} - $xs;
	#镭射孔层的个数-7.7(线本身所占宽度)
	$self->{laser}{biTong}{ye}[0] = $self->{laser}{biTong}{ys}[0] + $self->{laser}{biTong}{length};

	#左上
	$self->{laser}{biTong}{xs}[1] = $self->{SR}{xmin} - $xs;
	$self->{laser}{biTong}{ys}[1] = $self->{SR}{ymax} - 4;

	$self->{laser}{biTong}{xe}[1] = $self->{SR}{xmin} - $xs;
	#镭射孔层的个数-7.7(线本身所占宽度)
	$self->{laser}{biTong}{ye}[1] = $self->{laser}{biTong}{ys}[1] - $self->{laser}{biTong}{length};

	#右上
	$self->{laser}{biTong}{xs}[2] = $self->{SR}{xmax} + $xs;
	$self->{laser}{biTong}{ys}[2] = $self->{SR}{ymax} - 4;

	$self->{laser}{biTong}{xe}[2] = $self->{SR}{xmax} + $xs;
	#镭射孔层的个数-7.7(线本身所占宽度)
	$self->{laser}{biTong}{ye}[2] = $self->{laser}{biTong}{ys}[1] - $self->{laser}{biTong}{length};

	#右下
	$self->{laser}{biTong}{xs}[3] = $self->{SR}{xmax} + $xs;
	$self->{laser}{biTong}{ys}[3] = $self->{SR}{ymin} + 4 + $fangDai;

	$self->{laser}{biTong}{xe}[3] = $self->{SR}{xmax} + $xs;
	#镭射孔层的个数-7.7(线本身所占宽度)
	$self->{laser}{biTong}{ye}[3] = $self->{laser}{biTong}{ys}[3] + $self->{laser}{biTong}{length};

	return 1;
}

#**********************************************
#名字		:CountLaser
#功能		:计算镭射数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountLaser();
#**********************************************
sub CountLaser {
	my $self = shift;
	
	#镭射孔层计算顶底层
	my $shangXia;
	if ($self->{layerType} eq 'laser'){
		my $characterAmount = length $self->{Layer};
		my $quZhi;
		if ($characterAmount == 3){
			$quZhi = substr ($self->{Layer}, 1, 1);
		}
		else {
			$quZhi = substr ($self->{Layer}, 1, 2);
		}

		if ($quZhi <= $self->{signalLayer}{num} / 2){
			$shangXia = 'shang';
		}
		else {
			$shangXia = 'xia';
		}
	}

	#计算靶标坐标
	#x偏移值
	my $xs = 5;
	my $xTiao = 0.8;

	#右下角防呆值
	#2.5半个孔大小，2半个镭射，8左边镭射到丝印孔距离
	my $fangDai = $self->{screenHole}{y}[3] - $self->{screenHole}{y}[0] + 2.5 + 2 - 8;

	#如果为真hdi，则第一次锣边加在第一个位置，否则，加在第二个位置
	#左下
	#计算第一个的位置
	if ($self->{hdi}{jia} eq 'yes') {
		#假hdi板，内层
		if ($self->{Layer} =~ /in/){
			#假hdi板，内层，顶层
			if ($self->{Layer} =~ /t/
					or $shangXia eq 'shang'){
				$self->{laser}{baBiao}{y}[0] =  $self->{SR}{ymin} + 4;

				$self->{laser}{baBiao}{y}[1] = $self->{SR}{ymax} - 4;

				$self->{laser}{baBiao}{y}[2] = $self->{laser}{baBiao}{y}[1];

				#右下角，丝印孔防呆
				$self->{laser}{baBiao}{y}[3] = 	$self->{laser}{baBiao}{y}[0] + $fangDai;
			}
			#假hdi板，内层底层
			else {
				$self->{laser}{baBiao}{y}[0] = $self->{SR}{ymin} + 4 + $self->{laser}{hight};

				$self->{laser}{baBiao}{y}[1] = $self->{SR}{ymax} - 4 - $self->{laser}{hight};

				$self->{laser}{baBiao}{y}[2] = $self->{laser}{baBiao}{y}[1];

				#右下角，丝印孔防呆
				$self->{laser}{baBiao}{y}[3] = $self->{laser}{baBiao}{y}[0] + $fangDai;
			}
		}
		else {
			#假hdi板，次外层或外层，顶层
			if ($self->{Layer} =~ /t/
					or $shangXia eq 'shang'){
				$self->{laser}{baBiao}{y}[0] =  $self->{SR}{ymin} + 4 + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa};

				$self->{laser}{baBiao}{y}[1] = $self->{SR}{ymax} - 4  - ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa};

				$self->{laser}{baBiao}{y}[2] = $self->{laser}{baBiao}{y}[1];

				#右下角，丝印孔防呆
				$self->{laser}{baBiao}{y}[3] = 	$self->{laser}{baBiao}{y}[0] + $fangDai;

			}
			##假hdi板，次外层或外层，底层
			else {
				$self->{laser}{baBiao}{y}[0] = $self->{SR}{ymin} + 4 + $self->{laser}{hight} + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa};

				$self->{laser}{baBiao}{y}[1] = $self->{SR}{ymax} - 4 - ($self->{laser}{hight} + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa});

				$self->{laser}{baBiao}{y}[2] = $self->{laser}{baBiao}{y}[1];

				#右下角，丝印孔防呆
				$self->{laser}{baBiao}{y}[3] = $self->{laser}{baBiao}{y}[0] + $fangDai;
			}
		}

		#假hdi板，计算symbol
		if ($self->{Layer} =~ /in/){
			$self->{laser}{baBiao}{symbol} = "h-laser-babiao"."$self->{$self->{Layer}}{yaheN}";
		}
		else {
			my $num;
			$num = $self->{$self->{Layer}}{yaheN} + 1;
			$self->{laser}{baBiao}{symbol} = "h-laser-babiao"."$num";
		}
	}
	#真hdi板
	else {
		#真hdi板，顶层
		if ($self->{Layer} =~ /t/
				or $shangXia eq 'shang'){
			$self->{laser}{baBiao}{y}[0] =  $self->{SR}{ymin} + 4 + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};

			$self->{laser}{baBiao}{y}[1] = $self->{SR}{ymax} - 4  - ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};

			$self->{laser}{baBiao}{y}[2] = $self->{laser}{baBiao}{y}[1];

			#右下角，丝印孔防呆
			$self->{laser}{baBiao}{y}[3] = 	$self->{laser}{baBiao}{y}[0] + $fangDai;
		}
		#真hdi板，底层
		else {
			$self->{laser}{baBiao}{y}[0] = $self->{SR}{ymin} + 4 + $self->{laser}{hight} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};

			$self->{laser}{baBiao}{y}[1] = $self->{SR}{ymax} - 4 - ($self->{laser}{hight} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa});

			$self->{laser}{baBiao}{y}[2] = $self->{laser}{baBiao}{y}[1];

			#右下角，丝印孔防呆
			$self->{laser}{baBiao}{y}[3] = $self->{laser}{baBiao}{y}[0] + $fangDai;
		}
		#真hdi 板
		#计算symbol
		$self->{laser}{baBiao}{symbol} = "h-laser-babiao"."$self->{$self->{Layer}}{yaheN}";
	}


	#添加对位点
	$self->{laser}{duiWei}{y}[0] = $self->{laser}{baBiao}{y}[0] - $self->{laser}{cuoBa};

	$self->{laser}{duiWei}{y}[1] = $self->{laser}{baBiao}{y}[1] + $self->{laser}{cuoBa};

	$self->{laser}{duiWei}{y}[2] = $self->{laser}{baBiao}{y}[2] + $self->{laser}{cuoBa};

	#右下角，丝印孔防呆
	$self->{laser}{duiWei}{y}[3] = $self->{laser}{baBiao}{y}[3] - $self->{laser}{cuoBa};

	if ($self->{laser}{baBiao}{x}){
		return 0;
	}

	#计算x坐标
	$self->{laser}{baBiao}{x}[0] = $self->{SR}{xmin} - $xs + 0.8;
	$self->{laser}{baBiao}{x}[1] = $self->{SR}{xmin} - $xs + 0.8;
	$self->{laser}{baBiao}{x}[2] = $self->{SR}{xmax} + $xs;
	$self->{laser}{baBiao}{x}[3] = $self->{SR}{xmax} + $xs;


	$self->{laser}{duiWei}{x}[0] = $self->{laser}{baBiao}{x}[0];
	$self->{laser}{duiWei}{x}[1] = $self->{laser}{baBiao}{x}[1];
	$self->{laser}{duiWei}{x}[2] = $self->{laser}{baBiao}{x}[2];
	$self->{laser}{duiWei}{x}[3] = $self->{laser}{baBiao}{x}[3];

	return 1;
}

#**********************************************
#名字		:CountLaserBY
#功能		:计算镭射备用靶数据
#参数		:无
#返回值		:1
#使用例子	:$h->CountLaserBY();
#**********************************************
sub CountLaserBY {
	my $self = shift;
	#计算靶标坐标
	my $ys = 5;
	my $xSel = $self->{ccd}{length} + 9;

	#假hdi板
	if ($self->{hdi}{jia} eq 'yes'){
		#假hdi内层
		if ($self->{Layer} =~ /in/){
			#假hdi内层顶层
			if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
				#放在ccda打靶之间
				#左下
				#左下 #如果小于ccd和打靶之间的个数
				if ($self->{$self->{Layer}}{yaheN} <= $self->{laser}{leftNum}){
					$self->{laserBY}{baBiao}{x}[0] = $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};
					$self->{laser}{add}++;
				}
				#打靶还剩余的加在ccd的右边
				else {
					$self->{laserBY}{baBiao}{x}[0] = $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 1 - $self->{laser}{leftNum}) * $self->{laser}{cuoBa} + $self->{FB}{value};
				}

				#计算对位,对位和镭射之间相差一个cuoBa距离
				if ($self->{$self->{Layer}}{yaheN} <= $self->{laser}{leftNum}+1){
					$self->{laserBY}{duiWei}{x}[0] = $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 2) * $self->{laser}{cuoBa};
				}
				#对位剩余的加在ccd的右边
				else {
					$self->{laserBY}{duiWei}{x}[0] = $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 2 - $self->{laser}{leftNum}) * $self->{laser}{cuoBa} + $self->{FB}{value};
				}

				#左上
				$self->{laserBY}{baBiao}{x}[1] = $self->{laserBY}{baBiao}{x}[0];

				#右上
				$self->{laserBY}{baBiao}{x}[2] = $self->{SR}{xmax} - 6  - $self->{laser}{length} + $self->{laser}{hight}/2 + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};

				#右下
				#在ccd的右边
				$self->{laserBY}{baBiao}{x}[3] = $self->{SR}{xmax}  - 5.5 - $self->{ccd}{length} - $self->{laser}{length} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa} + $self->{laser}{hight}/2;
			}
			#假hdi内层底层
			else {
				#如果为真hdi，则第一次锣边加在第一个位置，否则，加在第二个位置
				#左下，镭射靶，在ccd和打靶的中间
				if ($self->{$self->{Layer}}{yaheN} <= $self->{laser}{leftNum}){
					$self->{laserBY}{baBiao}{x}[0] = $self->{laser}{hight} + $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};
					$self->{laser}{add}++;
				}
				#镭射靶，在ccd的右边
				else {
					$self->{laserBY}{baBiao}{x}[0] = $self->{laser}{hight} + $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 1 - $self->{laser}{leftNum}) * $self->{laser}{cuoBa} + $self->{FB}{value};
				}

				#计算对位，ccd和打靶中间
				if ($self->{$self->{Layer}}{yaheN} <= $self->{laser}{leftNum}+1){
					$self->{laserBY}{duiWei}{x}[0] = $self->{laser}{hight} + $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 2) * $self->{laser}{cuoBa};
				}
				#对位，ccd的右边
				else {
					$self->{laserBY}{duiWei}{x}[0] = $self->{laser}{hight} + $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 2 - $self->{laser}{leftNum}) * $self->{laser}{cuoBa} + $self->{FB}{value};
				}

				#左上
				$self->{laserBY}{baBiao}{x}[1] = $self->{laserBY}{baBiao}{x}[0];

				#右上
				#在ccd的右边
				$self->{laserBY}{baBiao}{x}[2] = $self->{laser}{hight} + $self->{SR}{xmax} - 6  - $self->{laser}{length} + $self->{laser}{hight}/2 + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};

				#右下
				#$self->{laserBY}{baBiao}{x}[3] = $self->{laser}{hight} + $self->{daba}{x2FangDai} + $self->{ccd}{length} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};
				$self->{laserBY}{baBiao}{x}[3] = $self->{laser}{hight} + $self->{SR}{xmax}  - 5.5 - $self->{ccd}{length} - $self->{laser}{length} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa} + $self->{laser}{hight}/2;
			}
		}
		#假hdi，次外层镭射靶标
		else {
			#假hdi次外层顶层
			if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
				#如果为真hdi，则第一次锣边加在第一个位置，否则，加在第二个位置
				#左下
				if ($self->{$self->{Layer}}{yaheN} < $self->{laser}{leftNum}){
					$self->{laserBY}{baBiao}{x}[0] = $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa};
					$self->{laser}{add}++;
				}
				#打靶还剩余的加在ccd的右边
				else {
					$self->{laserBY}{baBiao}{x}[0] = $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - $self->{laser}{leftNum}) * $self->{laser}{cuoBa} + $self->{FB}{value};
				}

				#计算对位,对位和镭射之间相差一个cuoBa距离
				if ($self->{$self->{Layer}}{yaheN} < $self->{laser}{leftNum}+1){
					$self->{laserBY}{duiWei}{x}[0] = $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};
				}
				#对位剩余的加在ccd的右边
				else {
					$self->{laserBY}{duiWei}{x}[0] = $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 1 - $self->{laser}{leftNum}) * $self->{laser}{cuoBa} + $self->{FB}{value};
				}

				#左上
				$self->{laserBY}{baBiao}{x}[1] = $self->{laserBY}{baBiao}{x}[0];

				#右上
				$self->{laserBY}{baBiao}{x}[2] = $self->{SR}{xmax} - 6  - $self->{laser}{length} + $self->{laser}{hight}/2 + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa};

				#右下
				#在ccd的右边
				#$self->{laserBY}{baBiao}{x}[3] = $self->{daba}{x2FangDai} + $self->{ccd}{length} + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa};
				$self->{laserBY}{baBiao}{x}[3] = $self->{SR}{xmax}  - 5.5 - $self->{ccd}{length} - $self->{laser}{length} + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa} + $self->{laser}{hight}/2;
			}
			#假hdi次外层底层
			else {
				#如果为真hdi，则第一次锣边加在第一个位置，否则，加在第二个位置
				#左下
				if ($self->{$self->{Layer}}{yaheN} < $self->{laser}{leftNum}){
					$self->{laserBY}{baBiao}{x}[0] = $self->{laser}{hight} + $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa};
					$self->{laser}{add}++;
				}
				#镭射靶，在ccd的右边
				else {
					$self->{laserBY}{baBiao}{x}[0] = $self->{laser}{hight} + $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - $self->{laser}{leftNum}) * $self->{laser}{cuoBa} + $self->{FB}{value};
				}

				#计算对位，ccd和打靶中间
				if ($self->{$self->{Layer}}{yaheN} < $self->{laser}{leftNum}+1){
					$self->{laserBY}{duiWei}{x}[0] = $self->{laser}{hight} + $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};
				}
				#对位，ccd的右边
				else {
					$self->{laserBY}{duiWei}{x}[0] = $self->{laser}{hight} + $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 1 - $self->{laser}{leftNum}) * $self->{laser}{cuoBa} + $self->{FB}{value};
				}

				#左上
				$self->{laserBY}{baBiao}{x}[1] = $self->{laserBY}{baBiao}{x}[0];

				#右上
				$self->{laserBY}{baBiao}{x}[2] = $self->{laser}{hight} + $self->{SR}{xmax} - 6  - $self->{laser}{length} + $self->{laser}{hight}/2 + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa};

				#右下
				#$self->{laserBY}{baBiao}{x}[3] = $self->{laser}{hight} + $self->{daba}{x2FangDai} + $self->{ccd}{length} + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa};
				$self->{laserBY}{baBiao}{x}[3] = $self->{laser}{hight} + $self->{SR}{xmax}  - 5.5 - $self->{ccd}{length} - $self->{laser}{length} + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa} + $self->{laser}{hight}/2;
			}
		}

		#假hdi，计算symbol
		if ($self->{Layer} =~ /in/){
			$self->{laserBY}{baBiao}{symbol} = "h-laser-babiao"."$self->{$self->{Layer}}{yaheN}"."-by";
		}
		else {
			my $num = $self->{$self->{Layer}}{yaheN} + 1;
			$self->{laserBY}{baBiao}{symbol} = "h-laser-babiao"."$num"."-by";
		}
	}
	#真hdi，真hdi，镭射靶第一次锣边加在第一个位置，否则，加在第二个位置
	else {
		if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
			#左下 #如果小于ccd和打靶之间的个数
			if ($self->{$self->{Layer}}{yaheN} <= $self->{laser}{leftNum}){
				$self->{laserBY}{baBiao}{x}[0] = $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};
				$self->{laser}{add}++;
			}
			#打靶还剩余的加在ccd的右边
			else {
				$self->{laserBY}{baBiao}{x}[0] = $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 1 - $self->{laser}{leftNum}) * $self->{laser}{cuoBa} + $self->{FB}{value};
			}

			#计算对位,对位和镭射之间相差一个cuoBa距离
			if ($self->{$self->{Layer}}{yaheN} <= $self->{laser}{leftNum}+1){
				$self->{laserBY}{duiWei}{x}[0] = $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 2) * $self->{laser}{cuoBa};
			}
			#对位剩余的加在ccd的右边
			else {
				$self->{laserBY}{duiWei}{x}[0] = $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 2 - $self->{laser}{leftNum}) * $self->{laser}{cuoBa} + $self->{FB}{value};
			}

			#左上
			$self->{laserBY}{baBiao}{x}[1] = $self->{laserBY}{baBiao}{x}[0];

			#右上
			#在ccd的右边
			$self->{laserBY}{baBiao}{x}[2] = $self->{SR}{xmax} - 6  - $self->{laser}{length} + $self->{laser}{hight}/2 + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};

			#右下
			#在ccd的右边
			#$self->{laserBY}{baBiao}{x}[3] = $self->{daba}{x2FangDai} + $self->{ccd}{length} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};
			$self->{laserBY}{baBiao}{x}[3] = $self->{SR}{xmax}  - 5.5 - $self->{ccd}{length} - $self->{laser}{length} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa} + $self->{laser}{hight}/2;
		}
		#真hdi，底层
		else {
			#左下，镭射靶，在ccd和打靶的中间
			if ($self->{$self->{Layer}}{yaheN} <= $self->{laser}{leftNum}){
				$self->{laserBY}{baBiao}{x}[0] = $self->{laser}{hight} + $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};
				$self->{laser}{add}++;
			}
			#镭射靶，在ccd的右边
			else {
				$self->{laserBY}{baBiao}{x}[0] = $self->{laser}{hight} + $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 1 - $self->{laser}{leftNum}) * $self->{laser}{cuoBa} + $self->{FB}{value};
			}

			#计算对位，ccd和打靶中间
			if ($self->{$self->{Layer}}{yaheN} <= $self->{laser}{leftNum}+1){
				$self->{laserBY}{duiWei}{x}[0] = $self->{laser}{hight} + $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 2) * $self->{laser}{cuoBa};
			}
			#对位，ccd的右边
			else {
				$self->{laserBY}{duiWei}{x}[0] = $self->{laser}{hight} + $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 2 - $self->{laser}{leftNum}) * $self->{laser}{cuoBa} + $self->{FB}{value};
			}

			#左上
			$self->{laserBY}{baBiao}{x}[1] = $self->{laserBY}{baBiao}{x}[0];

			#右上
			#在ccd的右边
			$self->{laserBY}{baBiao}{x}[2] = $self->{laser}{hight} + $self->{SR}{xmax} - 6  - $self->{laser}{length} + $self->{laser}{hight}/2 + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};

			#右下
			#ccd打靶中间
			#$self->{laserBY}{baBiao}{x}[3] = $self->{laser}{hight} + $self->{daba}{x2FangDai} + $self->{ccd}{length} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};
			$self->{laserBY}{baBiao}{x}[3] = $self->{laser}{hight} + $self->{SR}{xmax}  - 5.5 - $self->{ccd}{length} - $self->{laser}{length} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa} + $self->{laser}{hight}/2;
		}

		#计算symbol
		$self->{laserBY}{baBiao}{symbol} = "h-laser-babiao"."$self->{$self->{Layer}}{yaheN}"."-by";
	}

	#如果是一阶假HDI板，镭射向右移动
	if ($self->{hdi}{jieShu} == 0){
		$self->{laserBY}{baBiao}{x}[0] = $self->{laserBY}{baBiao}{x}[1] + 4.5;
		$self->{laserBY}{baBiao}{x}[1] = $self->{laserBY}{baBiao}{x}[1] + 4.5;
		$self->{laserBY}{duiWei}{x}[0] = $self->{laserBY}{duiWei}{x}[0] + 4.5;
		$self->{laserBY}{duiWei}{x}[1] = $self->{laserBY}{duiWei}{x}[1] + 4.5;
	}


	#添加对位点
	#$self->{laserBY}{duiWei}{x}[0] = $self->{laserBY}{baBiao}{x}[0] - $self->{laser}{cuoBa};

	$self->{laserBY}{duiWei}{x}[1] = $self->{laserBY}{duiWei}{x}[0];

	$self->{laserBY}{duiWei}{x}[2] = $self->{laserBY}{baBiao}{x}[2] - $self->{laser}{cuoBa};

	$self->{laserBY}{duiWei}{x}[3] = $self->{laserBY}{baBiao}{x}[3] - $self->{laser}{cuoBa};


	#计算避铜
	if ($self->{laserBY}{angle}){
		return 0;
	}

	#计算y轴坐标
	$self->{laserBY}{baBiao}{y}[0] = $self->{SR}{ymin} - $ys + 0.7;
	$self->{laserBY}{baBiao}{y}[1] = $self->{SR}{ymax} + $ys - 0.7;
	$self->{laserBY}{baBiao}{y}[2] = $self->{laserBY}{baBiao}{y}[1];
	$self->{laserBY}{baBiao}{y}[3] = $self->{laserBY}{baBiao}{y}[0];


	$self->{laserBY}{duiWei}{y}[0] = $self->{laserBY}{baBiao}{y}[0];
	$self->{laserBY}{duiWei}{y}[1] = $self->{laserBY}{baBiao}{y}[1];
	$self->{laserBY}{duiWei}{y}[2] = $self->{laserBY}{baBiao}{y}[2];
	$self->{laserBY}{duiWei}{y}[3] = $self->{laserBY}{baBiao}{y}[3];

	#计算角度
	@{$self->{laserBY}{angle}} = qw(270 90 90 270);

	return 1;
}

#**********************************************
#名字		:CountLaserBY
#功能		:计算备用镭射数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountLaserBY();
#**********************************************
sub CountLaserBYOld {
	my $self = shift;

	#计算symbol

	#3.5为ccd的大小一半，3.8为负片线的一半
	#计算靶标坐标
	my $ys = 5;
	my $xs = 3.5 + 3.8;
	my $xSel = 60;

	if ($self->{hdi}{jia} eq 'yes'){
		#假hdi内层
		if ($self->{Layer} =~ /in/){
			#假hdi内层顶层
			if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
				#如果为真hdi，则第一次锣边加在第一个位置，否则，加在第二个位置
				#左下
				$self->{laserBY}{baBiao}{x}[0] = $self->{SR}{xmin} + $xSel + ($self->{daba}{num} - 1)*($self->{layerBaBiaoJianJu}) + 8.9 + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};

				#左上
				$self->{laserBY}{baBiao}{x}[1] = $self->{laserBY}{baBiao}{x}[0];

				#右上
				#假hdi在ccd的右边
				if ($self->{residue}{topRight} - 7.5 - 7.7 > $self->{laser}{length}){
					$self->{laserBY}{baBiao}{x}[2] = $self->{ccd}{topEnd}{x} + $xs;
				}
				#在ccd的左边
				else {
					$self->{laserBY}{baBiao}{x}[2] = $self->{ccd}{topStart}{x} - $xs - $self->{laser}{length} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa} - 8;
				}

				#右下
				#在ccd的右边
				if ($self->{rightDownResidue} > $self->{laser}{length} + 7.5){
					$self->{laserBY}{baBiao}{x}[3] = $self->{daba}{x2FangDai} + $xs + $self->{hdi}{jieShu} * $self->{layerBaBiaoJianJu} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};
				}
				#在ccd的左边
				else {
					$self->{laserBY}{baBiao}{x}[3] = $self->{daba}{bottomStart}{x} - $xs - 1 - $self->{laser}{length} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};
				}
			}
			#假hdi内层底层
			else {
				#如果为真hdi，则第一次锣边加在第一个位置，否则，加在第二个位置
				#左下
				$self->{laserBY}{baBiao}{x}[0] = $self->{laser}{hight} + $self->{SR}{xmin} + $xSel + ($self->{daba}{num} - 1)*($self->{layerBaBiaoJianJu}) + 8.9 + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};

				#左上
				$self->{laserBY}{baBiao}{x}[1] = $self->{laserBY}{baBiao}{x}[0];

				#右上
				#在ccd的右边
				if ($self->{residue}{topRight} - 7.5 - 7.7 > $self->{laser}{length}){
					$self->{laserBY}{baBiao}{x}[2] = $self->{laser}{hight} + $self->{ccd}{topEnd}{x} + $xs;
				}
				#在ccd的左边
				else {
					$self->{laserBY}{baBiao}{x}[2] = $self->{laser}{hight} + $self->{ccd}{topStart}{x} - $xs - $self->{laser}{length} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa} - 8;
				}

				#右下
				if ($self->{rightDownResidue} > $self->{laser}{length} +7.5){
					$self->{laserBY}{baBiao}{x}[3] = $self->{laser}{hight} + $self->{daba}{x2FangDai} + $xs + $self->{hdi}{jieShu} * $self->{layerBaBiaoJianJu} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};
				}
				else {
					$self->{laserBY}{baBiao}{x}[3] = $self->{laser}{hight} + $self->{daba}{bottomStart}{x} - $xs - 1 - $self->{laser}{length} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};
				}
			}

		}
		#假hdi，次外层镭射靶标
		else {
			#假hdi次外层顶层
			if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
				#如果为真hdi，则第一次锣边加在第一个位置，否则，加在第二个位置
				#左下
				$self->{laserBY}{baBiao}{x}[0] = $self->{SR}{xmin} + $xSel + ($self->{daba}{num} - 1)*$self->{layerBaBiaoJianJu} + 8.9 + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa};

				#左上
				$self->{laserBY}{baBiao}{x}[1] = $self->{laserBY}{baBiao}{x}[0];

				#右上
				#在ccd的右边
				if ($self->{residue}{topRight} - 7.5 - 7.7 > $self->{laser}{length}){
					$self->{laserBY}{baBiao}{x}[2] = $self->{ccd}{topEnd}{x} + $xs + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa};
				}
				#在ccd的左边
				else {
					$self->{laserBY}{baBiao}{x}[2] = $self->{ccd}{topStart}{x} - $xs - $self->{laser}{length} + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa} - 8;
				}

				#右下
				#在ccd的右边
				if ($self->{rightDownResidue} > $self->{laser}{length} + 7.5){
					$self->{laserBY}{baBiao}{x}[3] = $self->{daba}{x2FangDai} + $xs + $self->{hdi}{jieShu} * $self->{layerBaBiaoJianJu} + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa};
				}
				#在ccd的左边
				else {
					$self->{laserBY}{baBiao}{x}[3] = $self->{daba}{bottomStart}{x} - $xs - 1 - $self->{laser}{length} + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa};
				}
			}
			#假hdi次外层底层
			else {
				#如果为真hdi，则第一次锣边加在第一个位置，否则，加在第二个位置
				#左下
				$self->{laserBY}{baBiao}{x}[0] = $self->{laser}{hight} + $self->{SR}{xmin} + $xSel + ($self->{daba}{num} - 1)*($self->{layerBaBiaoJianJu}) + 8.9 + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa};

				#左上
				$self->{laserBY}{baBiao}{x}[1] = $self->{laserBY}{baBiao}{x}[0];

				#右上
				#在ccd的右边
				if ($self->{residue}{topRight} - 7.5 - 7.7 > $self->{laser}{length}){
					$self->{laserBY}{baBiao}{x}[2] = $self->{laser}{hight} + $self->{ccd}{topEnd}{x} + $xs + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa};
				}
				#在ccd的左边
				else {
					$self->{laserBY}{baBiao}{x}[2] = $self->{laser}{hight} + $self->{ccd}{topStart}{x} - $xs - $self->{laser}{length} + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa} - 8;
				}

				#右下
				if ($self->{rightDownResidue} > $self->{laser}{length} + 7.5){
					$self->{laserBY}{baBiao}{x}[3] = $self->{laser}{hight} + $self->{daba}{x2FangDai} + $xs + $self->{hdi}{jieShu} * $self->{layerBaBiaoJianJu} + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa};
				}
				else {
					$self->{laserBY}{baBiao}{x}[3] = $self->{laser}{hight} + $self->{daba}{bottomStart}{x} - $xs - 1 - $self->{laser}{length} + ($self->{$self->{Layer}}{yaheN}) * $self->{laser}{cuoBa};
				}
			}

		}

		#假hdi，计算symbol
		if ($self->{Layer} =~ /in/){
			$self->{laserBY}{baBiao}{symbol} = "h-laser-babiao"."$self->{$self->{Layer}}{yaheN}"."-by";
		}
		else {
			my $num = $self->{$self->{Layer}}{yaheN} + 1;
			$self->{laserBY}{baBiao}{symbol} = "h-laser-babiao"."$num"."-by";
		}
	}
	#真hdi
	else {
		if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
			#如果为真hdi，则第一次锣边加在第一个位置，否则，加在第二个位置
			#左下
			$self->{laserBY}{baBiao}{x}[0] = $self->{SR}{xmin} + $xSel + ($self->{daba}{num} - 1)*($self->{layerBaBiaoJianJu}) + 8.9 + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};

			#左上
			$self->{laserBY}{baBiao}{x}[1] = $self->{laserBY}{baBiao}{x}[0];

			#右上
			#在ccd的右边
			if ($self->{residue}{topRight} - 7.5 - 7.7 > $self->{laser}{length}){
				$self->{laserBY}{baBiao}{x}[2] = $self->{ccd}{topEnd}{x} + $xs + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};
			}
			#在ccd的左边
			else {
				$self->{laserBY}{baBiao}{x}[2] = $self->{ccd}{topStart}{x} - $xs - $self->{laser}{length} - 1 + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa} - 8;
			}

			#右下
			#在ccd的右边
			if ($self->{rightDownResidue} > $self->{laser}{length} + 7.5){
				$self->{laserBY}{baBiao}{x}[3] = $self->{daba}{x2FangDai} + $xs + $self->{hdi}{jieShu} * $self->{layerBaBiaoJianJu} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};
			}
			#在ccd的左边
			else {
				$self->{laserBY}{baBiao}{x}[3] = $self->{daba}{bottomStart}{x} - $xs - 1 - $self->{laser}{length} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};
			}
		}
		#真hdi，底层，内层core数不为0
		else {
			#左下
			$self->{laserBY}{baBiao}{x}[0] = $self->{laser}{hight} + $self->{SR}{xmin} + $xSel + ($self->{daba}{num} - 1)*($self->{layerBaBiaoJianJu}) + 8.9 + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};

			#左上
			$self->{laserBY}{baBiao}{x}[1] = $self->{laserBY}{baBiao}{x}[0];

			#右上
			#在ccd的右边
			if ($self->{residue}{topRight} - 7.5 - 7.7 > $self->{laser}{length}){
				$self->{laserBY}{baBiao}{x}[2] = $self->{laser}{hight} + $self->{ccd}{topEnd}{x} + $xs + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};
			}
			#在ccd的左边
			else {
				$self->{laserBY}{baBiao}{x}[2] = $self->{laser}{hight} + $self->{ccd}{topStart}{x} - $xs - $self->{laser}{length} - 1 + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa} - 8;
			}

			#右下
			#ccd打靶中间
			if ($self->{rightDownResidue} > $self->{laser}{length} + 7.5){
				$self->{laserBY}{baBiao}{x}[3] = $self->{laser}{hight} + $self->{daba}{x2FangDai} + $xs + $self->{hdi}{jieShu} * $self->{layerBaBiaoJianJu} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};
			}
			#ccd左边
			else {
				$self->{laserBY}{baBiao}{x}[3] = $self->{laser}{hight} + $self->{daba}{bottomStart}{x} - $xs - 1 - $self->{laser}{length} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{laser}{cuoBa};
			}
		}


		#计算symbol
		$self->{laserBY}{baBiao}{symbol} = "h-laser-babiao"."$self->{$self->{Layer}}{yaheN}"."-by";
	}

	#计算y轴坐标
	$self->{laserBY}{baBiao}{y}[0] = $self->{SR}{ymin} - $ys + 0.7;
	if ($self->{hdi}{jieShu} >= 3 
			and $self->{liuBian}{ySize} > 19){
		$self->{laserBY}{baBiao}{y}[1] = $self->{SR}{ymax} + $ys - 0.7 + 15;
	}
	else {
		$self->{laserBY}{baBiao}{y}[1] = $self->{SR}{ymax} + $ys - 0.7;
	}
	$self->{laserBY}{baBiao}{y}[2] = $self->{laserBY}{baBiao}{y}[1];
	$self->{laserBY}{baBiao}{y}[3] = $self->{laserBY}{baBiao}{y}[0];

	#添加对位点
	$self->{laserBY}{duiWei}{x}[0] = $self->{laserBY}{baBiao}{x}[0] - $self->{laser}{cuoBa};
	$self->{laserBY}{duiWei}{y}[0] = $self->{laserBY}{baBiao}{y}[0];

	$self->{laserBY}{duiWei}{x}[1] = $self->{laserBY}{duiWei}{x}[0];
	$self->{laserBY}{duiWei}{y}[1] = $self->{laserBY}{baBiao}{y}[1];

	$self->{laserBY}{duiWei}{x}[2] = $self->{laserBY}{baBiao}{x}[2] - $self->{laser}{cuoBa};
	$self->{laserBY}{duiWei}{y}[2] = $self->{laserBY}{baBiao}{y}[2];

	$self->{laserBY}{duiWei}{x}[3] = $self->{laserBY}{baBiao}{x}[3] - $self->{laser}{cuoBa};
	$self->{laserBY}{duiWei}{y}[3] = $self->{laserBY}{baBiao}{y}[3];


	#计算避铜
	if ($self->{laserBY}{biTong}){
		return 0;
	}

	#避铜长度
	if ($self->{coreNum} == 0){
		$self->{laserBY}{biTong}{xs}[0] = $self->{daba}{baBiao}{x}[0] + 8.5;
	}
	else {
		$self->{laserBY}{biTong}{xs}[0] = $self->{daba}{baBiao}{x}[0] + ($self->{daba}{num} - 1)*($self->{layerBaBiaoJianJu}) + 8.5;

	}

	$self->{laserBY}{biTong}{xs}[1] = $self->{laserBY}{biTong}{xs}[0];
	$self->{laserBY}{biTong}{ys}[0] = $self->{SR}{ymin} - $ys;

	#镭射孔层的个数-7.7(线本身所占宽度)
	$self->{laserBY}{biTong}{xe}[0] = $self->{laserBY}{biTong}{xs}[0] + $self->{laser}{length};
	$self->{laserBY}{biTong}{ye}[0] = $self->{SR}{ymin} - $ys;


	#左上
	#右上,如果防呆后的剩余值，左边大于右边，则放左边，否则放右边。
	if ($self->{hdi}{jieShu} >= 3 
			and $self->{liuBian}{ySize} > 19){
		$self->{laserBY}{biTong}{ys}[1] = $self->{SR}{ymax} + $ys + 15;
	}
	else {
		$self->{laserBY}{biTong}{ys}[1] = $self->{SR}{ymax} + $ys;
	}

	$self->{laserBY}{biTong}{xe}[1] = $self->{laserBY}{biTong}{xs}[1] + $self->{laser}{length};
	$self->{laserBY}{biTong}{ye}[1] = $self->{laserBY}{biTong}{ys}[1];
	#镭射孔层的个数-7.7(线本身所占宽度)


	#7.5为ccd和二次元的宽度和，7.7为线宽
	#放右边
	if ($self->{residue}{topRight} - 7.5 - 7.7 > $self->{laser}{length}){
		$self->{laserBY}{biTong}{xs}[2] = $self->{ccd}{topEnd}{x} + $xs + 1;
		$self->{laserBY}{biTong}{xe}[2] = $self->{laserBY}{biTong}{xs}[2] + $self->{laser}{length};
	}
	#放左边
	else {
		$self->{laserBY}{biTong}{xs}[2] = $self->{ccd}{topStart}{x} - $xs - 0.5 - 8;
		$self->{laserBY}{biTong}{xe}[2] = $self->{laserBY}{biTong}{xs}[2] - $self->{laser}{length};
	}

	#如果四阶以上板，并且留边足够，往上移动
	$self->{laserBY}{biTong}{ys}[2] = $self->{laserBY}{biTong}{ys}[1];
	$self->{laserBY}{biTong}{ye}[2] = $self->{laserBY}{biTong}{ys}[2];

	#右下
	#ccd 右边
	if ($self->{rightDownResidue} > $self->{laser}{length} + 7.5){
		$self->{laserBY}{biTong}{xs}[3] = $self->{daba}{bottomStart}{x} + $self->{ccd}{length} + 1;
		$self->{laserBY}{biTong}{xe}[3] = $self->{laserBY}{biTong}{xs}[3] + $self->{laser}{length};
	}
	else {
		$self->{laserBY}{biTong}{xs}[3] = $self->{daba}{bottomStart}{x} - $xs - 1;
		$self->{laserBY}{biTong}{xe}[3] = $self->{laserBY}{biTong}{xs}[3] - $self->{laser}{length};
	}

	$self->{laserBY}{biTong}{ys}[3] = $self->{SR}{ymin} - $ys;
	$self->{laserBY}{biTong}{ye}[3] = $self->{SR}{ymin} - $ys;

	#计算角度
	@{$self->{laserBY}{angle}} = qw(270 90 90 270);

	return 1;
}


sub CountTwoPinTongXinYuan
{
	my $self = shift;
	
	my $minHole = 508;
	my $addValue = 0;
	if ($self->{$self->{Layer}}{copperThick} <= 0.5)
	{
		$addValue = 0.5;
	}
	elsif ($self->{$self->{Layer}}{copperThick} == 1)
	{
		$addValue = 2;
	}
	elsif($self->{$self->{Layer}}{copperThick} == 2)
	{
		$addValue = 3;
	}
	elsif($self->{$self->{Layer}}{copperThick} > 2)
	{
		$addValue = 4.5;
	}
	
	if ($self->{layerType} eq "via")
	{
		$self->{twoPinTongXinYuan}{symbol} = "r$minHole";
	}
	elsif ($self->{layerType} eq "inner")
	{
		$self->{twoPinTongXinYuan}{symbol} = "donut_r" . ($minHole + 76.2 * 2 + 127 * 2 + $addValue * 25.4 + ($self->{$self->{Layer}}{layNum} - 2) * (50.8 * 2 + 127 *2)) . "x" . ($minHole + 76.2 * 2 - $addValue  * 25.4 + ($self->{$self->{Layer}}{layNum} - 2) * (50.8 * 2 + 127 *2));
		$self->{twoPinTongXinYuan}{backSymbol} = "r" . ($minHole + 76.2 * 2 + 127 * 2  + $addValue * 25.4 + 400 + (scalar(@{$self->{inner}{layer}}) - 1) * (50.8 * 2 + 127 *2)); 
	}
}

sub CountNewTongXinYuan
{
	my $self = shift;
	my $minHole = 508;
	my $addValue = 0;
	if ($self->{$self->{Layer}}{copperThick} <= 0.5)
	{
		$addValue = 0.5;
	}
	elsif ($self->{$self->{Layer}}{copperThick} == 1)
	{
		$addValue = 2;
	}
	elsif($self->{$self->{Layer}}{copperThick} == 2)
	{
		$addValue = 3;
	}
	elsif($self->{$self->{Layer}}{copperThick} > 2)
	{
		$addValue = 4.5;
	}
	
	$self->{newTongXinYuan}{symbol} = "donut_r" . ($minHole + 76.2 * 2 + 127 * 2 + $addValue * 25.4 + ($self->{$self->{Layer}}{layNum} - 2) * (50.8 * 2 + 127 *2)) . "x" . ($minHole + 76.2 * 2 - $addValue  * 25.4 + ($self->{$self->{Layer}}{layNum} - 2) * (50.8 * 2 + 127 *2));
	$self->{newTongXinYuan}{backSymbol} = "r" . ($minHole + 76.2 * 2 + 127 * 2  + $addValue * 25.4 + 400 + (scalar(@{$self->{inner}{layer}}) - 1) * (50.8 * 2 + 127 *2)); 

}


#**********************************************
#名字		:CountTongXinYuan
#功能		:计算同心圆数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountTongXinYuan();
#**********************************************
sub CountTongXinYuan {
	my $self = shift;
	
	#计算放在第几个

	#计算symbol
	my $symbol = (($self->{$self->{Layer}}{layNum} - 3)*350 + 1362).'x'.(($self->{$self->{Layer}}{layNum} - 3)*350 + 1112);
	if ($self->{ERP}{isInnerHT} eq "yes") {
		$symbol = (($self->{$self->{Layer}}{layNum} - 3)*508 + 1362).'x'.(($self->{$self->{Layer}}{layNum} - 3)*508 + 854);
	}
	
	$self->{tongXinYuan}{symbol} = 'donut_r'."$symbol";

	if ($self->{tongXinYuan}{firstX}){
		return 0;
	}


	#同心圆大小
	$self->{tongXinYuan}{biTongSize} = 1012 + ($self->{signalLayer}{num} - 2)*350;
	$self->{tongXinYuan}{size} = (1012 + ($self->{signalLayer}{num} - 2)*350)/1000;
	if ($self->{ERP}{isInnerHT} eq "yes") {
		$self->{tongXinYuan}{biTongSize} = 1012 + ($self->{signalLayer}{num} - 2)*508;
		$self->{tongXinYuan}{size} = (1012 + ($self->{signalLayer}{num} - 2)*508)/1000;	
	}
	

	#计算第一个的位置
	#if ($self->{liuBian}{xSize} > 7.2+$self->{tongXinYuan}{size}) {
	if ($self->{liuBian}{xSize} > 7+$self->{tongXinYuan}{size}) {
		#计算第一个的位置
		$self->{tongXinYuan}{firstX}[0] = $self->{SR}{xmin} - 7 - $self->{tongXinYuan}{size}/2;
		$self->{tongXinYuan}{firstY}[0] = $self->{SR}{ymin};

		$self->{tongXinYuan}{firstX}[1] = $self->{tongXinYuan}{firstX}[0];
		$self->{tongXinYuan}{firstY}[1] = $self->{SR}{ymax};

		$self->{tongXinYuan}{firstX}[2] = $self->{SR}{xmax} + 7 + $self->{tongXinYuan}{size}/2;
		$self->{tongXinYuan}{firstY}[2] = $self->{SR}{ymax};

		$self->{tongXinYuan}{firstX}[3] = $self->{tongXinYuan}{firstX}[2];

		$self->{tongXinYuan}{firstY}[3] = $self->{SR}{ymin} + 2.5;

		#如果方向孔间距(+8才是真实间距)能放得下同心圆，则在里面放同心圆.5 方向孔大小。
		if ($self->{fangXiangKong}{jianJuValue} + 8 > 5+4+$self->{tongXinYuan}{length}){
			$self->{tongXinYuan}{firstX}[3] = $self->{tongXinYuan}{firstX}[2] - 5;
		}

		if ($#{$self->{laser}{drillTop}} < 0
				and $#{$self->{laser}{drillBottom}} < 0){
			#$self->{tongXinYuan}{firstX}[0] = $self->{tongXinYuan}{firstX}[0] + 3;
			#$self->{tongXinYuan}{firstX}[1] = $self->{tongXinYuan}{firstX}[1] + 3;
			#$self->{tongXinYuan}{firstX}[2] = $self->{tongXinYuan}{firstX}[2] - 3;
		}

		$self->{tongXinYuan}{nx} = 1;
		$self->{tongXinYuan}{dx} = 0;
		$self->{tongXinYuan}{ny} = $self->{tongXinYuan}{num} - 1;
		$self->{tongXinYuan}{dy} = 1;
	}
	#y方向留边较大
	elsif ($self->{liuBian}{ySize} > 9+$self->{tongXinYuan}{size}){
		#计算第一个的位置
		$self->{tongXinYuan}{firstX}[0] = $self->{ccd}{baBiao}{x}[0] + $self->{ccd}{length};
		$self->{tongXinYuan}{firstY}[0] = $self->{liuBian}{ymin} + 3.2;

		$self->{tongXinYuan}{firstX}[1] = $self->{tongXinYuan}{firstX}[0];
		$self->{tongXinYuan}{firstY}[1] = $self->{liuBian}{ymax} - 2.5;

		$self->{tongXinYuan}{firstX}[2] = $self->{ccd}{baBiao}{x}[2] + 7;
		$self->{tongXinYuan}{firstY}[2] = $self->{liuBian}{ymax} - 2.5;

		$self->{tongXinYuan}{firstX}[3] = $self->{ccd}{baBiao}{x}[3] - $self->{ccd}{length} - $self->{tongXinYuan}{length} + 3;
		$self->{tongXinYuan}{firstY}[3] = $self->{liuBian}{ymin} + 2.5;

		$self->{tongXinYuan}{fangXiang} = 'heng';
		$self->{tongXinYuan}{ny} = 1;
		$self->{tongXinYuan}{dy} = 1;
		$self->{tongXinYuan}{nx} = $self->{tongXinYuan}{num} - 1;
		$self->{tongXinYuan}{dx} = 5000;
	}
	#$self->{ccdBY}{baBiao}{y}[1] - $self->{ccd}{length}，以ccd的靶标作为参考点。198 - $self->{PROF}{yCenter}中心到铆钉孔距离，-2，一阶板边锣板定位孔在ccd下面。
	elsif (($self->{coreNum} < 2 and $self->{tongXinYuan}{chang} eq 'yes')
			or $self->{tongXinYuan}{length} < $self->{ccdBY}{baBiao}{y}[1] - $self->{ccd}{length} - 198 - $self->{PROF}{yCenter} - 2){
		#if ($self->{liuBian}{xSize} > 14) {
		$self->{tongXinYuan}{firstX}[0] = $self->{SR}{xmin} - 4;
		$self->{tongXinYuan}{firstY}[0] = $self->{ccdBY}{baBiao}{y}[0] + $self->{ccd}{length} - ($self->{daba}{size} - $self->{tongXinYuan}{size})/2;

		$self->{tongXinYuan}{firstX}[1] = $self->{SR}{xmin} - 4;
		$self->{tongXinYuan}{firstY}[1] = $self->{ccdBY}{baBiao}{y}[1] - $self->{ccd}{length} + ($self->{daba}{size} - $self->{tongXinYuan}{size})/2;

		$self->{tongXinYuan}{firstX}[2] = $self->{SR}{xmax} + 4;
		$self->{tongXinYuan}{firstY}[2] = $self->{ccdBY}{baBiao}{y}[2] - $self->{ccd}{length} + ($self->{daba}{size} - $self->{tongXinYuan}{size})/2;

		$self->{tongXinYuan}{firstX}[3] = $self->{SR}{xmax} + 4;
		$self->{tongXinYuan}{firstY}[3] = $self->{ccdBY}{baBiao}{y}[3] + $self->{ccd}{length}/2;

		$self->{tongXinYuan}{nx} = 1;
		$self->{tongXinYuan}{dx} = 0;
		$self->{tongXinYuan}{ny} = $self->{tongXinYuan}{num} - 1;
		$self->{tongXinYuan}{dy} = 1;

		#如果方向孔间距(+8才是真实间距)能放得下同心圆，则在里面放同心圆.5 方向孔大小。
		if ($self->{fangXiangKong}{jianJuValue} + 8 > 5+4+$self->{tongXinYuan}{length}){
			$self->{tongXinYuan}{firstY}[3] = $self->{SR}{ymin} + 2.5;
		}

	}
	#放在ccd及打靶之间，以最后一次锣边尺寸为参考点
	else {
		#计算第一个的位置
		$self->{tongXinYuan}{firstX}[0] = $self->{ccd}{baBiao}{x}[0] + $self->{ccd}{length};
		$self->{tongXinYuan}{firstY}[0] = $self->{liuBian}{ymin} + 5;

		$self->{tongXinYuan}{firstX}[1] = $self->{tongXinYuan}{firstX}[0];
		$self->{tongXinYuan}{firstY}[1] = $self->{liuBian}{ymax} - 5;

		$self->{tongXinYuan}{firstX}[2] = $self->{ccd}{baBiao}{x}[2] + 7;
		$self->{tongXinYuan}{firstY}[2] = $self->{liuBian}{ymax} - 5;

		$self->{tongXinYuan}{firstX}[3] = $self->{ccd}{baBiao}{x}[3] - $self->{ccd}{length} - $self->{tongXinYuan}{length} + 3;
		$self->{tongXinYuan}{firstY}[3] = $self->{liuBian}{ymin} + 5;

		$self->{tongXinYuan}{fangXiang} = 'heng';
		$self->{tongXinYuan}{ny} = 1;
		$self->{tongXinYuan}{dy} = 1;
		$self->{tongXinYuan}{nx} = $self->{tongXinYuan}{num} - 1;
		$self->{tongXinYuan}{dx} = 5000;
	}


	return 1;
}

#**********************************************
#名字		:CountMaoDingYingFeiDrill
#功能		:计算铆钉孔数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountMaoDingYingFeiDrill();
#**********************************************
sub CountMaoDingYingFeiDrill {
	my $self = shift;
	
	#计算坐标
	my $xs = 6 + 2.5 + 1 + 0.5;
	my $ys = 190 + 3.5;

	$self->{maoDingYingFeiDrill}{x}[0] = $self->{PROF}{xmin} + $xs;
	$self->{maoDingYingFeiDrill}{y}[0] = $self->{PROF}{yCenter} - $ys;

	$self->{maoDingYingFeiDrill}{x}[1] = $self->{maoDingYingFeiDrill}{x}[0];
	$self->{maoDingYingFeiDrill}{y}[1] = $self->{PROF}{yCenter} + $ys;

	$self->{maoDingYingFeiDrill}{x}[2] = $self->{PROF}{xmax} - $xs;
	$self->{maoDingYingFeiDrill}{y}[2] = $self->{PROF}{yCenter} + $ys;
	
	$self->{maoDingYingFeiDrill}{x}[3] = $self->{maoDingYingFeiDrill}{x}[2];
	$self->{maoDingYingFeiDrill}{y}[3] = $self->{PROF}{yCenter} - $ys;

	return 1;
}

#**********************************************
#名字		:CountMaoDing
#功能		:计算铆钉孔数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountMaoDing();
#**********************************************
sub CountMaoDing {
	my $self = shift;

	#计算symbol
	if ($self->{layerType} eq 'inner'){
		$self->{maoDing}{symbol} = 'h-maoding-pad';
	}
	elsif ($self->{layerType} eq 'via'){
		$self->{maoDing}{symbol} = 'r5900';
	}
	else{
		$self->{maoDing}{symbol} = 'undef';
	}

	#计算坐标
	my $xs = 6;
	my $ys = 190 + 3.5;

	$self->{maoDing}{x}[0] = $self->{liuBian}{xmin} + $xs;
	$self->{maoDing}{y}[0] = $self->{PROF}{yCenter} - $ys;

	$self->{maoDing}{x}[1] = $self->{maoDing}{x}[0];
	$self->{maoDing}{y}[1] = $self->{PROF}{yCenter} + $ys;

	$self->{maoDing}{x}[2] = $self->{liuBian}{xmax}  - $xs;
	$self->{maoDing}{y}[2] = $self->{PROF}{yCenter} + $ys;
	
	$self->{maoDing}{x}[3] = $self->{maoDing}{x}[2];
	$self->{maoDing}{y}[3] = $self->{PROF}{yCenter} - $ys;

	return 1;
}

#**********************************************
#名字		:CountPEChongKong
#功能		:计算PE冲孔数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountPEChongKong();
#**********************************************
sub CountPEChongKong {
	my $self = shift;

	#计算PE冲孔Symbol
	if ($self->{layerType} eq 'inner'){
		if ($self->{Layer} =~ /^in\d{1,2}t$/){
			$self->{PE}{symbol} = 'h-pe';
			$self->{PE}{smallSymbol} = 'h-pe-small';
			$self->{PE}{polarity} = 'positive';
			if ($self->{ERP}{isInnerHT} eq "yes") {
				$self->{PE}{symbol} = 'h-pe-ht';
				$self->{PE}{smallSymbol} = 'h-pe-small-ht';
			}
		}
		elsif ($self->{Layer} =~ /^in\d{1,2}b$/){
			$self->{PE}{symbol} = 'r10000';
			$self->{PE}{polarity} = 'negative';
		}
	}

	#计算靶距
	if ($self->{PE}{x}){
		return 0;
	}

	#if ($self->{SR}{ValidX} < 326.39){
	#	$self->{PE}{xDis} = 336.55;
	#}
	#elsif ($self->{SR}{ValidX} < 351.79){
	#	$self->{PE}{xDis} = 361.95;
	#}
	#elsif ($self->{SR}{ValidX} < 377.19){
	#	$self->{PE}{xDis} = 387.35;
	#}
	#elsif ($self->{SR}{ValidX} < 402.59){
	#	$self->{PE}{xDis} = 412.75;
	#}
	#elsif ($self->{SR}{ValidX} < 427.99){
	#	$self->{PE}{xDis} = 438.15;
	#}
	#elsif ($self->{SR}{ValidX} < 453.39){
	#	$self->{PE}{xDis} = 463.55;
	#}
	#elsif ($self->{SR}{ValidX} < 478.79){
	#	$self->{PE}{xDis} = 488.95;
	#}
	#else {
	#	$self->{PE}{yesNo} = 'no';
	#}

	#y
	#if ($self->{SR}{ValidY} <  427.99){
	#	$self->{PE}{yDis} = 438.15;
	#}
	#elsif ($self->{SR}{ValidY} < 453.39){
	#	$self->{PE}{yDis} = 463.55;
	#}
	#elsif ($self->{SR}{ValidY} < 478.79){

	#	$self->{PE}{yDis} = 488.95;
	#}
	#elsif ($self->{SR}{ValidY} < 504.19){
	#	$self->{PE}{yDis} =514.35;
	#}
	#elsif ($self->{SR}{ValidY} < 529.59){
	#	$self->{PE}{yDis} = 539.75;
	#}
	#elsif ($self->{SR}{ValidY} < 554.99){
	#	$self->{PE}{yDis} = 565.15;
	#}
	#elsif ($self->{SR}{ValidY} < 580.39){
	#	$self->{PE}{yDis} = 590.55;
	#}
	#else {
	#	$self->{PE}{yesNo} = 'no';
	#}

	#拼板尺寸小于14
	#if ($self->{PROF}{xmax}/25.4 < 14
	#		or $self->{PROF}{ymax}/25.4 < 14) {
	#	$self->{PE}{yesNo} = 'no';
	#	return 0;
	#}

	my $xValue = $self->{PROF}{xmax} / 25.4;
	my $yu = sprintf "%d", $xValue * 100 % 50;
	if ($yu > 0) {
		$xValue = ((sprintf "%d", $xValue *100 - $yu))/100;
	}
	else {
		$xValue = (sprintf "%d", $xValue *100 - $yu)/100;
	}

	my $XA;
	my $XB;
	my $pianX;
	if (substr ($xValue, 3, 1) =~ /5/){
		$XA = (($xValue - 0.5 - 0.75)/2 + 0.5)*25.4;
		$XB = (($xValue - 0.5 - 0.75)/2)*25.4;
		$pianX = 6.35;
	}
	else {
		$XB = $XA = ($xValue - 0.75)/2*25.4;
		$pianX = 0;
	}


	my $yValue = $self->{PROF}{ymax} / 25.4;
	$yu = sprintf "%d", $yValue * 100 % 50;
	if ($yu > 0) {
		$yValue = ((sprintf "%d", $yValue *100 - $yu))/100;
	}
	else {
		$yValue = (sprintf "%d", $yValue *100 - $yu)/100;
	}

	my $YA;
	my $YB;
	my $pianY;
	if (substr ($yValue, 3, 1) =~ /5/){
		$YA = (($yValue - 0.5 - 0.75)/2 + 0.5)*25.4;
		$YB = (($yValue - 0.5 - 0.75)/2)*25.4;
		$pianY = 6.35;
	}
	else {
		$YB = $YA = ($yValue - 0.75)/2*25.4;
		$pianY = 0;
	}


	#计算坐标
	my $sX = 38.1;
	my $sY = 38.1;

    #左
	$self->{PE}{x}[0] = $self->{PROF}{xCenter} + $pianX - $XA;
	$self->{PE}{y}[0] = $self->{PROF}{yCenter} + $pianY - 42.875;

	$self->{PE}{x}[1] = $self->{PROF}{xCenter} + $pianX - $sX;
	$self->{PE}{y}[1] = $self->{PROF}{yCenter} + $pianY + $YB;
    #右
	$self->{PE}{x}[2] = $self->{PROF}{xCenter} + $pianX + $XB;
	$self->{PE}{y}[2] = $self->{PROF}{yCenter}  + $pianY - $sY;

	$self->{PE}{x}[3] = $self->{PROF}{xCenter} + $pianX - $sX;
	$self->{PE}{y}[3] = $self->{PROF}{yCenter} + $pianY - $YA;
	
	#判断X是否进单元
	if ($self->{SR}{xmin} - $self->{PE}{x}[0] < 5
			or $self->{PE}{x}[2] - $self->{SR}{xmax} < 5
			or $self->{PE}{x}[0] > 12) {
		#$self->{endMsg} .= "PE冲孔机无法满足条件,没有跑出来,请向MI确认！\n";
		#$self->{msgSwitch} = "yes";
		$xValue = $xValue + 0.5;

		if (substr ($xValue, 3, 1) =~ /5/){
			$XA = (($xValue - 0.5 - 0.75)/2 + 0.5)*25.4;
			$XB = (($xValue - 0.5 - 0.75)/2)*25.4;
			$pianX = 6.35;
		}
		else {
			$XB = $XA = ($xValue - 0.75)/2*25.4;
			$pianX = 0;
		}

		#重新计算x轴坐标
		$self->{PE}{x}[0] = $self->{PROF}{xCenter} + $pianX - $XA;
		$self->{PE}{x}[1] = $self->{PROF}{xCenter} + $pianX - $sX;
		$self->{PE}{x}[2] = $self->{PROF}{xCenter} + $pianX + $XB;
		$self->{PE}{x}[3] = $self->{PROF}{xCenter} + $pianX - $sX;

		#判断X是否进单元
		if ($self->{SR}{xmin} - $self->{PE}{x}[0] < 4
			or $self->{PE}{x}[2] - $self->{SR}{xmax} < 4) {
			$self->{PE_X}{yesNo} = 'no';
			#return 0;
		}

		if ($self->{PE}{x}[0] - $self->{PROF}{xmin}  < 4
				or $self->{PROF}{xmax} - $self->{PE}{x}[2] < 4){
			$self->{PE_X}{yesNo} = 'no';
		}
	}

	#判断Y是否进单元
	if ($self->{PE}{y}[1] - $self->{SR}{ymax} < 4
			or $self->{SR}{ymin} - $self->{PE}{y}[3] < 4
			or $self->{PE}{y}[3] > 12) {
		#$self->{endMsg} .= "PE冲孔机无法满足条件,没有跑出来,请向MI确认！\n";
		#$self->{msgSwitch} = "yes";
		#取+0.5值
		$yValue = $yValue + 0.5;

		if (substr ($yValue, 3, 1) =~ /5/){
			$YA = (($yValue - 0.5 - 0.75)/2 + 0.5)*25.4;
			$YB = (($yValue - 0.5 - 0.75)/2)*25.4;
			$pianY = 6.35;
		}
		else {
			$YB = $YA = ($yValue - 0.75)/2*25.4;
			$pianY = 0;
		}

		#重新计算y轴坐标
		$self->{PE}{y}[0] = $self->{PROF}{yCenter} + $pianY - 42.875;
		$self->{PE}{y}[1] = $self->{PROF}{yCenter} + $pianY + $YB;
		$self->{PE}{y}[2] = $self->{PROF}{yCenter}  + $pianY - $sY;
		$self->{PE}{y}[3] = $self->{PROF}{yCenter} + $pianY - $YA;

		#判断Y是否进单元
		if ($self->{PE}{y}[1] - $self->{SR}{ymax} < 4
				or $self->{SR}{ymin} - $self->{PE}{y}[3] < 4) {
			$self->{PE_Y}{yesNo} = 'no';
			#return 0;
		}

		if ($self->{PROF}{ymax} - $self->{PE}{y}[1]  < 4
				or $self->{PE}{y}[3] - $self->{PROF}{ymin} < 4) {
			#$self->{endMsg} .= "PE冲孔机无法满足条件,没有跑出来,请向MI确认！\n";
			#$self->{msgSwitch} = "yes";
			$self->{PE_Y}{yesNo} = 'no';

			#return 0;
		}
	}

	#判断是否出prof
	#if ($self->{PE}{x}[0] - $self->{PROF}{xmin}  < 5.2
	#		or $self->{PROF}{xmax} - $self->{PE}{x}[2] < 5.2
	#		or $self->{PROF}{ymax} - $self->{PE}{y}[1]  < 5.2
	#		or $self->{PE}{y}[3] - $self->{PROF}{ymin} < 5.2) {

	#	#$self->{endMsg} .= "PE冲孔机无法满足条件,没有跑出来,请向MI确认！\n";
	#	#$self->{msgSwitch} = "yes";
	#	$self->{PE}{yesNo} = 'no';

	#	return 0;
	#}

	#计算辅助图标坐标
	#四个角落
	my $peS = 215.9;
	$self->{PE_S}{x}[0] = $self->{PROF}{xCenter} + $pianX - $XA;
	$self->{PE_S}{y}[0] = $self->{PROF}{yCenter} + $pianY- $peS;

	$self->{PE_S}{x}[1] = $self->{PROF}{xCenter} + $pianX - $XA;
	$self->{PE_S}{y}[1] = $self->{PROF}{yCenter} + $pianY +  $peS;

	$self->{PE_S}{x}[2] = $self->{PROF}{xCenter} + $pianX + $XB;
	$self->{PE_S}{y}[2] = $self->{PROF}{yCenter} + $pianY + $peS;

	$self->{PE_S}{x}[3] = $self->{PROF}{xCenter} + $pianX + $XB;
	$self->{PE_S}{y}[3] = $self->{PROF}{yCenter} + $pianY - $peS;

	#中间
	#左边防呆
	#$self->{PE_S}{x}[4] = $self->{PROF}{xCenter} + $pianX - $XA;
	#$self->{PE_S}{y}[4] = $self->{PROF}{yCenter} + $pianY - 4.775;

	#$self->{PE_S}{x}[5] = $self->{PROF}{xCenter} + $pianX - $XA;
	#$self->{PE_S}{y}[5] = $self->{PROF}{yCenter} + $pianY + 8.687;

	##上面
	#$self->{PE_S}{x}[6] = $self->{PROF}{xCenter} + $pianX;
	#$self->{PE_S}{y}[6] = $self->{PROF}{yCenter} + $pianY + $YB;

	#$self->{PE_S}{x}[7] = $self->{PROF}{xCenter} + $pianX + 13.462;
	#$self->{PE_S}{y}[7] = $self->{PROF}{yCenter} + $pianY + $YB;

	##右边
	#$self->{PE_S}{x}[8] = $self->{PROF}{xCenter} + $pianX + $XB;
	#$self->{PE_S}{y}[8] = $self->{PROF}{yCenter} + $pianY;

	#$self->{PE_S}{x}[9] = $self->{PROF}{xCenter} + $pianX + $XB;
	#$self->{PE_S}{y}[9] = $self->{PROF}{yCenter} + $pianY + 13.462;

	##下面
	#$self->{PE_S}{x}[10] = $self->{PROF}{xCenter} + $pianX;
	#$self->{PE_S}{y}[10] = $self->{PROF}{yCenter} + $pianY - $YA;

	#$self->{PE_S}{x}[11] = $self->{PROF}{xCenter} + $pianX + 13.462;
	#$self->{PE_S}{y}[11] = $self->{PROF}{yCenter} + $pianY - $YA;

	
	#if ($self->{PE_X}{yesNo} eq 'no' and $self->{PE_Y}{yesNo} ne 'no') {
	#	#@{$self->{PE_S}{x}} = ($self->{PROF}{xCenter} + $pianX, $self->{PROF}{xCenter} + $pianX);
	#	#@{$self->{PE_S}{y}} = ();
	#	#上
	#	push @{$self->{PE_S}{x}}, $self->{PROF}{xCenter} + $pianX;
	#	push @{$self->{PE_S}{x}}, $self->{PROF}{xCenter} + $pianX + 13.462;
	#	$self->{rongHeDingWei}{PadSkip} = $self->{PROF}{xCenter} + $pianX + 13.462;
	#
	#	push @{$self->{PE_S}{y}}, $self->{PROF}{yCenter} + $pianY + $YB;
	#	push @{$self->{PE_S}{y}}, $self->{PROF}{yCenter} + $pianY + $YB;
	#
	#	#下
	#	push @{$self->{PE_S}{x}}, $self->{PROF}{xCenter} + $pianX;
	#	push @{$self->{PE_S}{x}}, $self->{PROF}{xCenter} + $pianX + 13.462;
	#
	#	push @{$self->{PE_S}{y}}, $self->{PROF}{yCenter} + $pianY - $YA;
	#	push @{$self->{PE_S}{y}}, $self->{PROF}{yCenter} + $pianY - $YA;
	#
	#} elsif ($self->{PE_X}{yesNo} ne 'no' and $self->{PE_Y}{yesNo} eq 'no') {
	#	#@{$self->{PE_S}{x}} = ($self->{PROF}{xCenter} + $pianX - $XA, $self->{PROF}{xCenter} + $pianX + $XB);
	#	#@{$self->{PE_S}{y}} = ($self->{PROF}{yCenter} + $pianY + $YB, $self->{PROF}{yCenter} + $pianY - $YA)
	#	#左
	#	push @{$self->{PE_S}{x}}, $self->{PROF}{xCenter} + $pianX - $XA;
	#	push @{$self->{PE_S}{x}}, $self->{PROF}{xCenter} + $pianX - $XA;
	#
	#	push @{$self->{PE_S}{y}}, $self->{PROF}{yCenter} + $pianY - 4.775;
	#	push @{$self->{PE_S}{y}}, $self->{PROF}{yCenter} + $pianY + 8.687;
	#
	#	#右
	#	push @{$self->{PE_S}{x}}, $self->{PROF}{xCenter} + $pianX + $XB;
	#	push @{$self->{PE_S}{x}}, $self->{PROF}{xCenter} + $pianX + $XB;
	#
	#	push @{$self->{PE_S}{y}}, $self->{PROF}{yCenter} + $pianY;
	#	push @{$self->{PE_S}{y}}, $self->{PROF}{yCenter} + $pianY + 13.462;
	#
	#} elsif ($self->{PE_X}{yesNo} ne 'no' and $self->{PE_Y}{yesNo} ne 'no') {
		#上
		push @{$self->{PE_S}{x}}, $self->{PROF}{xCenter} + $pianX;
		push @{$self->{PE_S}{x}}, $self->{PROF}{xCenter} + $pianX + 13.462;
		$self->{rongHeDingWei}{PadSkip} = $self->{PROF}{xCenter} + $pianX + 13.462;

		push @{$self->{PE_S}{y}}, $self->{PROF}{yCenter} + $pianY + $YB;
		push @{$self->{PE_S}{y}}, $self->{PROF}{yCenter} + $pianY + $YB;

		#下
		push @{$self->{PE_S}{x}}, $self->{PROF}{xCenter} + $pianX;
		push @{$self->{PE_S}{x}}, $self->{PROF}{xCenter} + $pianX + 13.462;

		push @{$self->{PE_S}{y}}, $self->{PROF}{yCenter} + $pianY - $YA;
		push @{$self->{PE_S}{y}}, $self->{PROF}{yCenter} + $pianY - $YA;

		#左
		push @{$self->{PE_S}{x}}, $self->{PROF}{xCenter} + $pianX - $XA;
		push @{$self->{PE_S}{x}}, $self->{PROF}{xCenter} + $pianX - $XA;

		push @{$self->{PE_S}{y}}, $self->{PROF}{yCenter} + $pianY - 4.775;
		push @{$self->{PE_S}{y}}, $self->{PROF}{yCenter} + $pianY + 8.687;

		#右
		push @{$self->{PE_S}{x}}, $self->{PROF}{xCenter} + $pianX + $XB;
		push @{$self->{PE_S}{x}}, $self->{PROF}{xCenter} + $pianX + $XB;

		push @{$self->{PE_S}{y}}, $self->{PROF}{yCenter} + $pianY;
		push @{$self->{PE_S}{y}}, $self->{PROF}{yCenter} + $pianY + 13.462;

	#}

	if ($self->{PE}{x}[0] > 12
			or $self->{PE}{y}[3] > 12) {
		$self->{endMsg} .= "PE冲孔机无法满足条件,没有跑出来,请向MI确认！\n";
		$self->{msgSwitch} = "yes";
		$self->{PE}{yesNo} = 'no';
	}

	if (($self->{SR}{xmin} - $self->{PE}{x}[0] - 2.95) < 2 || ($self->{PROF}{ymax} - $self->{SR}{ymax} - $self->{PE}{y}[3] - 2.95) < 2) {
		$self->{endMsg} .= "5.9mm的孔边距板内距离小于2mm！\n";
		$self->{msgSwitch} = "yes";
	}

	return 1;
}


#**********************************************
#名字		:CountRongHeDingWei
#功能		:计算备用熔合定位孔数据
#参数		:无
#返回值		:如果已经计算坐标，返回为0，否则返回1
#使用例子	:$self->CountRongHeDingWei();
#**********************************************
sub CountRongHeDingWeiBy {
	my $self = shift;

	#计算Symbol
	if ($self->{layerType} eq 'inner'){
		$self->{rongHeDingWeiBy}{symbol} = 'h-rh-drill';
		if ($self->{ERP}{isInnerHT} eq "yes") {
			$self->{rongHeDingWeiBy}{symbol} = 'h-rh-drill+ht';
		}
	}

	#如果已经计算坐标，返回为0
	if ($self->{rongHeDingWeiBy}{x}){
		return 0;
	}

	#熔合定位孔坐标计算
	if ($self->{PE}{yesNo} eq 'no'){
		my $s = 6;
		#左
		$self->{rongHeDingWeiBy}{x}[0] = $self->{PROF}{xmin} + $s;
		$self->{rongHeDingWeiBy}{y}[0] = $self->{PROF}{yCenter};

		#上
		$self->{rongHeDingWeiBy}{x}[1] = $self->{PROF}{xCenter};
		$self->{rongHeDingWeiBy}{y}[1] = $self->{PROF}{ymax} - $s;
		

		#右
		$self->{rongHeDingWeiBy}{x}[2] = $self->{PROF}{xmax} - $s;
		$self->{rongHeDingWeiBy}{y}[2] = $self->{PROF}{yCenter};

		#下
		$self->{rongHeDingWeiBy}{x}[3] = $self->{PROF}{xCenter};
		$self->{rongHeDingWeiBy}{y}[3] = $self->{PROF}{ymin} + $s;
	}
	else {
	
		push(@{$self->{rongHeDingWeiBy}{x}},$self->{PE_S}{x}[0]);
		push(@{$self->{rongHeDingWeiBy}{y}},$self->{PE_S}{y}[0] - 10);
		
		push(@{$self->{rongHeDingWeiBy}{x}},$self->{PE_S}{x}[1]);
		push(@{$self->{rongHeDingWeiBy}{y}},$self->{PE_S}{y}[1] + 10);
		
		push(@{$self->{rongHeDingWeiBy}{x}},$self->{PE_S}{x}[2]);
		push(@{$self->{rongHeDingWeiBy}{y}},$self->{PE_S}{y}[2] + 10);
		
		push(@{$self->{rongHeDingWeiBy}{x}},$self->{PE_S}{x}[3]);
		push(@{$self->{rongHeDingWeiBy}{y}},$self->{PE_S}{y}[3] - 10);
		
		
		
		if (@{$self->{PE_S}{x}} > 8)
		{
			#短方向中间两个
			push(@{$self->{rongHeDingWeiBy}{x}},$self->{PE_S}{x}[4] - 11);
			push(@{$self->{rongHeDingWeiBy}{y}},$self->{PE_S}{y}[4]);
		
			push(@{$self->{rongHeDingWeiBy}{x}},$self->{PE_S}{x}[6] - 11);
			push(@{$self->{rongHeDingWeiBy}{y}},$self->{PE_S}{y}[6]);
			
			#长方向中间两个
			push(@{$self->{rongHeDingWeiBy}{x}},$self->{PE_S}{x}[9] );
			push(@{$self->{rongHeDingWeiBy}{y}},$self->{PE_S}{y}[9] + 10);
			
			push(@{$self->{rongHeDingWeiBy}{x}},$self->{PE_S}{x}[11] );
			push(@{$self->{rongHeDingWeiBy}{y}},$self->{PE_S}{y}[11] + 10);
			
			
		}
		elsif (@{$self->{PE_S}{x}} > 6)
		{
			#长方向中间两个
			push(@{$self->{rongHeDingWeiBy}{x}},$self->{PE_S}{x}[4]-10);
			push(@{$self->{rongHeDingWeiBy}{y}},$self->{PE_S}{y}[4]);
		
			push(@{$self->{rongHeDingWeiBy}{x}},$self->{PE_S}{x}[6] - 10);
			push(@{$self->{rongHeDingWeiBy}{y}},$self->{PE_S}{y}[6]);
		}
	}

	return 1;
}




#**********************************************
#名字		:CountRongHeDingWei
#功能		:计算熔合定位孔数据
#参数		:无
#返回值		:如果已经计算坐标，返回为0，否则返回1
#使用例子	:$self->CountRongHeDingWei();
#**********************************************
sub CountRongHeDingWei {
	my $self = shift;
	
	#计算Symbol
	if ($self->{layerType} eq 'inner'){
		$self->{rongHeDingWei}{symbol} = 'h-rh-drill';
		if ($self->{ERP}{isInnerHT} eq "yes") {
			$self->{rongHeDingWei}{symbol} = 'h-rh-drill+ht';
		}
		
	}
	elsif ($self->{layerType} eq 'via'
		or $self->{layerType} eq 'bury'){
		$self->{rongHeDingWei}{symbol} = 'r5900';
	}
	elsif ($self->{layerType} eq 'outer')
	{
		$self->{rongHeDingWei}{symbol} = 'r6408';
	}
	else{
		$self->{rongHeDingWei}{symbol} = 'undef';
	}

	#如果已经计算坐标，返回为0
	#if ($self->{rongHeDingWei}{x}){
	#	return 0;
	#}

	#熔合定位孔坐标计算
	#if ($self->{PE_X}{yesNo} ne 'yes' and $self->{PE_Y}{yesNo} ne 'yes'){
	if ($self->{PE}{yesNo} eq 'no'){
		my $s = 6;
		#左
		$self->{rongHeDingWei}{x}[0] = $self->{PROF}{xmin} + $s;
		$self->{rongHeDingWei}{y}[0] = $self->{PROF}{yCenter};

		#上
		$self->{rongHeDingWei}{x}[1] = $self->{PROF}{xCenter};
		$self->{rongHeDingWei}{y}[1] = $self->{PROF}{ymax} - $s;
		

		#右
		$self->{rongHeDingWei}{x}[2] = $self->{PROF}{xmax} - $s;
		$self->{rongHeDingWei}{y}[2] = $self->{PROF}{yCenter};

		#下
		$self->{rongHeDingWei}{x}[3] = $self->{PROF}{xCenter};
		$self->{rongHeDingWei}{y}[3] = $self->{PROF}{ymin} + $s;
	}
	else {
		if (@{$self->{PE_S}{x}} > 8)
		{
			#上
			$self->{rongHeDingWei}{x}[0] = $self->{PE_S}{x}[4];
			$self->{rongHeDingWei}{y}[0] = $self->{PE_S}{y}[4];
	
	
			#下
			$self->{rongHeDingWei}{x}[1] = $self->{PE_S}{x}[6];
			$self->{rongHeDingWei}{y}[1] = $self->{PE_S}{y}[6];
			
			#左
			$self->{rongHeDingWei}{x}[2] = $self->{PE_S}{x}[8];
			$self->{rongHeDingWei}{y}[2] = $self->{PE_S}{y}[8];
	
			#右   
			$self->{rongHeDingWei}{x}[3] = $self->{PE_S}{x}[10];
			$self->{rongHeDingWei}{y}[3] = $self->{PE_S}{y}[10];
			
	
	
			$self->{rongHeDingWei}{x}[4] = $self->{PE_S}{x}[0];
			$self->{rongHeDingWei}{y}[4] = $self->{PE_S}{y}[0];
	
			$self->{rongHeDingWei}{x}[5] = $self->{PE_S}{x}[1];
			$self->{rongHeDingWei}{y}[5] = $self->{PE_S}{y}[1];
	
			$self->{rongHeDingWei}{x}[6] = $self->{PE_S}{x}[2];
			$self->{rongHeDingWei}{y}[6] = $self->{PE_S}{y}[2];
	
			$self->{rongHeDingWei}{x}[7] = $self->{PE_S}{x}[3];
			$self->{rongHeDingWei}{y}[7] = $self->{PE_S}{y}[3];
			if ($self->{layerType} ne 'via' && $self->{layerType} ne 'bury' && $self->{layerType} ne 'outer'){
				$self->{rongHeDingWei}{x}[8] = $self->{PE_S}{x}[5] - 13.462 - 10;
				$self->{rongHeDingWei}{y}[8] = $self->{PE_S}{y}[5];
		
				$self->{rongHeDingWei}{x}[9] = $self->{PE_S}{x}[7] - 13.462 - 10;
				$self->{rongHeDingWei}{y}[9] = $self->{PE_S}{y}[7];
			}
			else
			{
				$self->{rongHeDingWei}{x}[8] = $self->{PE_S}{x}[5];
				$self->{rongHeDingWei}{y}[8] = $self->{PE_S}{y}[5];
		
				$self->{rongHeDingWei}{x}[9] = $self->{PE_S}{x}[7];
				$self->{rongHeDingWei}{y}[9] = $self->{PE_S}{y}[7];	
			}
			#左中上
			$self->{rongHeDingWei}{x}[10] = $self->{PE_S}{x}[9];
			$self->{rongHeDingWei}{y}[10] = $self->{PE_S}{y}[9];
	
			#右中上
			$self->{rongHeDingWei}{x}[11] = $self->{PE_S}{x}[11];
			$self->{rongHeDingWei}{y}[11] = $self->{PE_S}{y}[11];
		}
		else
		{
		#左下角
			$self->{rongHeDingWei}{x}[0] = $self->{PE_S}{x}[0];
			$self->{rongHeDingWei}{y}[0] = $self->{PE_S}{y}[0];
	
	
			#左上角
			$self->{rongHeDingWei}{x}[1] = $self->{PE_S}{x}[1];
			$self->{rongHeDingWei}{y}[1] = $self->{PE_S}{y}[1];
			
			#右上角
			$self->{rongHeDingWei}{x}[2] = $self->{PE_S}{x}[2];
			$self->{rongHeDingWei}{y}[2] = $self->{PE_S}{y}[2];
	
			#右下角
			$self->{rongHeDingWei}{x}[3] = $self->{PE_S}{x}[3];
			$self->{rongHeDingWei}{y}[3] = $self->{PE_S}{y}[3];
			
	
			#上面中间左边
			$self->{rongHeDingWei}{x}[4] = $self->{PE_S}{x}[4];
			$self->{rongHeDingWei}{y}[4] = $self->{PE_S}{y}[4];
	
			#下面中间左边
			$self->{rongHeDingWei}{x}[5] = $self->{PE_S}{x}[6];
			$self->{rongHeDingWei}{y}[5] = $self->{PE_S}{y}[6];
	
			if ($self->{layerType} ne 'via' && $self->{layerType} ne 'bury' && $self->{layerType} ne 'outer'){
				#上面中间右边
				$self->{rongHeDingWei}{x}[6] = $self->{PE_S}{x}[5] - 13.462 - 10;
				$self->{rongHeDingWei}{y}[6] = $self->{PE_S}{y}[5];
				#上面中间右边
				$self->{rongHeDingWei}{x}[7] = $self->{PE_S}{x}[7] - 13.462 - 10;
				$self->{rongHeDingWei}{y}[7] = $self->{PE_S}{y}[7];
			}
			else
			{
				#上面中间右边
				$self->{rongHeDingWei}{x}[6] = $self->{PE_S}{x}[5];
				$self->{rongHeDingWei}{y}[6] = $self->{PE_S}{y}[5];
				#上面中间右边
				$self->{rongHeDingWei}{x}[7] = $self->{PE_S}{x}[7];
				$self->{rongHeDingWei}{y}[7] = $self->{PE_S}{y}[7];
			}
		}




		#@{$self->{rongHeDingWei}{x}} = @{$self->{PE_S}{x}};
		#@{$self->{rongHeDingWei}{y}} = @{$self->{PE_S}{y}};



		#if ($self->{layerType} eq 'inner'){
		#	#上
		#	push(@{$self->{rongHeDingWei}{x}}, $self->{PE_S}{x}[4] - 11);
		#	push(@{$self->{rongHeDingWei}{y}},$self->{PE_S}{y}[4]);
		#	#下
		#	push(@{$self->{rongHeDingWei}{x}},$self->{PE_S}{x}[4] - 11);
		#	push(@{$self->{rongHeDingWei}{y}},$self->{PE_S}{y}[6]);
		#	$self->{skip} = $self->{PE_S}{x}[4] - 11;
		#}
		#	push @{$self->{PE_S}{x}}, $self->{PROF}{xCenter} + $pianX + $XB;
		#	push @{$self->{PE_S}{x}}, $self->{PROF}{xCenter} + $pianX + $XB;

		#	push @{$self->{PE_S}{y}}, $self->{PROF}{yCenter} + $pianY;
		#	push @{$self->{PE_S}{y}}, $self->{PROF}{yCenter} + $pianY + 13.462;
	}

	return 1;
}

#**********************************************
#名字		:CountRongHeDingWeiPadYingFeiDrill
#功能		:添加熔合定位pad
#参数		:无
#返回值		:1
#使用例子	:$h->CountRongHeDingWeiPadYingFeiDrill();
#**********************************************
sub CountRongHeDingWeiPadYingFeiDrill {
	my $self = shift;
	
	#计算symbol
	if ($self->{rongHeDingWeiPadYingFeiDrill}{x}){
		return 0;
	}

	#计算坐标
	my $s = 2.5 + 1.5 + 0.5;

	$self->{rongHeDingWeiPadYingFeiDrill}{x}[0] = $self->{rongHeDingWei}{x}[0] + $s; 
	$self->{rongHeDingWeiPadYingFeiDrill}{y}[0] = $self->{rongHeDingWei}{y}[0]; 


	$self->{rongHeDingWeiPadYingFeiDrill}{x}[1] = $self->{rongHeDingWei}{x}[1]; 
	$self->{rongHeDingWeiPadYingFeiDrill}{y}[1] = $self->{rongHeDingWei}{y}[1] - $s; 

	$self->{rongHeDingWeiPadYingFeiDrill}{x}[2] = $self->{rongHeDingWei}{x}[2] - $s; 
	$self->{rongHeDingWeiPadYingFeiDrill}{y}[2] = $self->{rongHeDingWei}{y}[2]; 


	$self->{rongHeDingWeiPadYingFeiDrill}{x}[3] = $self->{rongHeDingWei}{x}[3]; 
	$self->{rongHeDingWeiPadYingFeiDrill}{y}[3] = $self->{rongHeDingWei}{y}[3] + $s; 

	@{$self->{rongHeDingWeiPadYingFeiDrill}{angle}} = qw(0 90 0 90);

	return 1;
}

#**********************************************
#名字		:addRongHeDingWeiPad
#功能		:添加熔合定位pad
#参数		:无
#返回值		:1
#使用例子	:$h->addRongHeDingWeiPad();
#**********************************************
sub CountRongHeDingWeiPad {
	my $self = shift;
	
	#计算symbol
	if ($self->{SRToPROF}{y} < 18.5){
		if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
			$self->{rongHeDingWeiPad}{symbol}[0] =  'h-rhccd-'."2";
			$self->{rongHeDingWeiPad}{symbol}[1] =  'h-rhccd-'."$self->{$self->{Layer}}{layNum}";
			if ($self->{ERP}{isInnerHT} eq "yes") {
				$self->{rongHeDingWeiPad}{symbol}[0] =  'h-rhccd-'."2-ht";
				$self->{rongHeDingWeiPad}{symbol}[1] =  'h-rhccd-'."$self->{$self->{Layer}}{layNum}" . "-ht";	
			}
			
			$self->{rongHeDingWeiPad}{polarity} = 'positive';
		}
		else {
			$self->{rongHeDingWeiPad}{symbol}[0] = 'h-rhccd-bitong';
			$self->{rongHeDingWeiPad}{symbol}[1] = 'h-rhccd-bitong';
			$self->{rongHeDingWeiPad}{polarity} = 'positive';
		}
	}
	else {
		if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
			$self->{rongHeDingWeiPad}{symbol}[0] =  'rhccd-'."2";
			$self->{rongHeDingWeiPad}{symbol}[1] =  'rhccd-'."$self->{$self->{Layer}}{layNum}";
			if ($self->{ERP}{isInnerHT} eq "yes") {
				$self->{rongHeDingWeiPad}{symbol}[0] =  'rhccd-'."2-ht";
				$self->{rongHeDingWeiPad}{symbol}[1] =  'rhccd-'."$self->{$self->{Layer}}{layNum}" . "-ht";	
			}
			
			$self->{rongHeDingWeiPad}{polarity} = 'positive';
		}
		else {
			$self->{rongHeDingWeiPad}{symbol}[0] = 'r13762';
			$self->{rongHeDingWeiPad}{symbol}[1] = 'r13762';
			$self->{rongHeDingWeiPad}{polarity} = 'negative';
		}
	}

	if ($self->{rongHeDingWeiPad}{x}){
		return 0;
	}

	#计算坐标
	if ($self->{SRToPROF}{y} < 14.5){
		$self->{rongHeDingWeiPad}{y}[0] = $self->{SR}{ymin} - 5; 
		$self->{rongHeDingWeiPad}{y}[1] = $self->{SR}{ymax} + 5; 
	}
	elsif ($self->{SRToPROF}{y} < 16.5){
		$self->{rongHeDingWeiPad}{y}[0] = $self->{SR}{ymin} - 6.5; 
		$self->{rongHeDingWeiPad}{y}[1] = $self->{SR}{ymax} + 6.5; 
	}
	else{
		$self->{rongHeDingWeiPad}{y}[0] = $self->{PROF}{ymin} + 10; 
		$self->{rongHeDingWeiPad}{y}[1] = $self->{PROF}{ymax} - 10; 
	}

	$self->{rongHeDingWeiPad}{x}[0] = $self->{PROF}{xCenter} + 15;
	$self->{rongHeDingWeiPad}{x}[1] = $self->{rongHeDingWeiPad}{x}[0];

	@{$self->{rongHeDingWeiPad}{angle}} = qw(0 180);

	return 1;
}


#**********************************************
#名字		:CountSanRe
#功能		:
#参数		:无
#返回值		:1
#使用例子	:$h->CountSanRe();
#**********************************************
sub CountSanRe {
	my $self = shift;
	
	if ($self->{sanRe}{x}){
		return 0;
	}

	$self->{sanRe}{xNum} = sprintf("%d", ($self->{SR}{xmax} - $self->{SR}{xmin} + 4)/20);

	$self->{sanRe}{yNum} = sprintf("%d", ($self->{SR}{ymax} - $self->{SR}{ymin} + 4)/20);


	$self->{sanRe}{x}[0] = $self->{SR}{xmin} + ($self->{SR}{xmax} - $self->{SR}{xmin} - ($self->{sanRe}{xNum} - 1)*20)/2;
	$self->{sanRe}{y}[0] = $self->{SR}{ymin} - 3;


	$self->{sanRe}{x}[1] = $self->{sanRe}{x}[0];
	$self->{sanRe}{y}[1] = $self->{SR}{ymax} + 3;

	$self->{sanRe}{x}[2] = $self->{SR}{xmin} - 3;
	$self->{sanRe}{y}[2] = $self->{SR}{ymin} + ($self->{SR}{ymax} - $self->{SR}{ymin} - ($self->{sanRe}{yNum} - 1)*20)/2;

	$self->{sanRe}{x}[3] = $self->{SR}{xmax} + 3;
	$self->{sanRe}{y}[3] = $self->{sanRe}{y}[2];


	return 1;
}

#**********************************************
#名字		:CountRongHeKuai
#功能		:计算熔合块数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountRongHeKuai();
#**********************************************
sub CountRongHeKuai {
	my $self = shift;
	
	if ($self->{rongHeKuai}{x}){
		return 0;
	}

	@{$self->{rongHeKuai}{mirror}} = qw(yes yes yes yes no no no no);
	$self->{rongHeKuai}{x}[0] = $self->{PROF}{xmin} + 3.5;
	$self->{rongHeKuai}{y}[0] = $self->{PROF}{yCenter} - 170;

	$self->{rongHeKuai}{x}[1] = $self->{PROF}{xmin} + 3.5;
	$self->{rongHeKuai}{y}[1] = $self->{PROF}{yCenter} - 100;

	$self->{rongHeKuai}{x}[2] = $self->{PROF}{xmin} + 3.5;
	$self->{rongHeKuai}{y}[2] = $self->{PROF}{yCenter} + 100;

	$self->{rongHeKuai}{x}[3] = $self->{PROF}{xmin} + 3.5;
	$self->{rongHeKuai}{y}[3] = $self->{PROF}{yCenter} + 170;

	$self->{rongHeKuai}{x}[4] = $self->{PROF}{xmax} - 3.5;
	$self->{rongHeKuai}{y}[4] = $self->{PROF}{yCenter} + 170;

	$self->{rongHeKuai}{x}[5] = $self->{PROF}{xmax} - 3.5;
	$self->{rongHeKuai}{y}[5] = $self->{PROF}{yCenter} + 100;

	$self->{rongHeKuai}{x}[6] = $self->{PROF}{xmax} - 3.5;
	$self->{rongHeKuai}{y}[6] = $self->{PROF}{yCenter} - 100;

	$self->{rongHeKuai}{x}[7] = $self->{PROF}{xmax} - 3.5;
	$self->{rongHeKuai}{y}[7] = $self->{PROF}{yCenter} - 170;

	return 1;
}


#**********************************************
#名字		:CountRongHeKuaiNew
#功能		:计算熔合块数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountRongHeKuaiNew();
#**********************************************
sub CountRongHeKuaiNew {
	my $self = shift;

	if ($self->{layerType} eq 'via') {
		#钻孔层symbol
		@{$self->{rongHeKuai}{symbol}} = qw(h-ronghekuai-g-drill h-ronghekuai-g-drill h-ronghekuai-g-drill h-ronghekuai-g-drill h-ronghekuai-g-drill h-ronghekuai-g-drill h-ronghekuai-g-drill h-ronghekuai-g-drill h-ronghekuai-g-drill h-ronghekuai-g-drill h-ronghekuai-g-drill h-ronghekuai-g-drill h-ronghekuai-g-drill h-ronghekuai-g-drill h-ronghekuai-g-drill h-ronghekuai-g-drill);
	} else {
		#正常情况
		@{$self->{rongHeKuai}{symbol}} = qw(h-ronghekuai-g-type1 h-ronghekuai-g-type1 h-ronghekuai-g-type2 h-ronghekuai-g-type2 h-ronghekuai-g-type1 h-ronghekuai-g-type1 h-ronghekuai-g-type1 h-ronghekuai-g-type1 h-ronghekuai-g-type2 h-ronghekuai-g-type2 h-ronghekuai-g-type1 h-ronghekuai-g-type1);

		#如果大于540
		if (($self->{SR}{ymax} - $self->{SR}{ymin}) >= 540) {
			@{$self->{rongHeKuai}{symbol}} = qw(h-ronghekuai-g-type1 h-ronghekuai-g-type1 h-ronghekuai-g-type2 h-ronghekuai-g-type2 h-ronghekuai-g-type1 h-ronghekuai-g-type1 h-ronghekuai-g-type1 h-ronghekuai-g-type1 h-ronghekuai-g-type2 h-ronghekuai-g-type2 h-ronghekuai-g-type1 h-ronghekuai-g-type1 h-ronghekuai-g-type2 h-ronghekuai-g-type2 h-ronghekuai-g-type2 h-ronghekuai-g-type2);
		}
	}

	if ($self->{rongHeKuai}{x}){
		return 0;
	}

	@{$self->{rongHeKuai}{mirror}} = qw(no no no no no no yes yes yes yes yes yes);
	@{$self->{rongHeKuai}{symbol}} = qw(h-ronghekuai-g-type1 h-ronghekuai-g-type1 h-ronghekuai-g-type2 h-ronghekuai-g-type2 h-ronghekuai-g-type1 h-ronghekuai-g-type1 h-ronghekuai-g-type1 h-ronghekuai-g-type1 h-ronghekuai-g-type2 h-ronghekuai-g-type2 h-ronghekuai-g-type1 h-ronghekuai-g-type1);


	#左边
	$self->{rongHeKuai}{x}[0] = $self->{SR}{xmin} - $self->{PROF}{xmin} >= 16 ? $self->{PROF}{xmin} + 6 : $self->{SR}{xmin} - 10;
	$self->{rongHeKuai}{y}[0] = $self->{PE_S}{y}[9] + 63;

	$self->{rongHeKuai}{x}[1] = $self->{SR}{xmin} - $self->{PROF}{xmin} >= 16 ? $self->{PROF}{xmin} + 6 : $self->{SR}{xmin} - 10;
	$self->{rongHeKuai}{y}[1] = $self->{PE_S}{y}[9] + 108;

	$self->{rongHeKuai}{x}[2] = $self->{SR}{xmin} - $self->{PROF}{xmin} >= 16 ? $self->{PROF}{xmin} + 6 : $self->{SR}{xmin} - 10;
	$self->{rongHeKuai}{y}[2] = $self->{PE_S}{y}[9] + 154;

	$self->{rongHeKuai}{x}[3] = $self->{SR}{xmin} - $self->{PROF}{xmin} >= 16 ? $self->{PROF}{xmin} + 6 : $self->{SR}{xmin} - 10;
	$self->{rongHeKuai}{y}[3] = $self->{PE_S}{y}[9] - 83;

	$self->{rongHeKuai}{x}[4] = $self->{SR}{xmin} - $self->{PROF}{xmin} >= 16 ? $self->{PROF}{xmin} + 6 : $self->{SR}{xmin} - 10;
	$self->{rongHeKuai}{y}[4] = $self->{PE_S}{y}[9] - 129;

	$self->{rongHeKuai}{x}[5] = $self->{SR}{xmin} - $self->{PROF}{xmin} >= 16 ? $self->{PROF}{xmin} + 6 : $self->{SR}{xmin} - 10;
	$self->{rongHeKuai}{y}[5] = $self->{PE_S}{y}[9] - 174;

	#右边
	$self->{rongHeKuai}{x}[6] = $self->{SR}{xmin} - $self->{PROF}{xmin} >= 16 ? $self->{PROF}{xmax} - 6 : $self->{SR}{xmax} + 10;
	$self->{rongHeKuai}{y}[6] = $self->{PE_S}{y}[11] + 58;

	$self->{rongHeKuai}{x}[7] = $self->{SR}{xmin} - $self->{PROF}{xmin} >= 16 ? $self->{PROF}{xmax} - 6 : $self->{SR}{xmax} + 10;
	$self->{rongHeKuai}{y}[7] = $self->{PE_S}{y}[11] + 103;

	$self->{rongHeKuai}{x}[8] = $self->{SR}{xmin} - $self->{PROF}{xmin} >= 16 ? $self->{PROF}{xmax} - 6 : $self->{SR}{xmax} + 10;
	$self->{rongHeKuai}{y}[8] = $self->{PE_S}{y}[11] + 149;

	$self->{rongHeKuai}{x}[9] = $self->{SR}{xmin} - $self->{PROF}{xmin} >= 16 ? $self->{PROF}{xmax} - 6 : $self->{SR}{xmax} + 10;
	$self->{rongHeKuai}{y}[9] = $self->{PE_S}{y}[11] - 88;

	$self->{rongHeKuai}{x}[10] = $self->{SR}{xmin} - $self->{PROF}{xmin} >= 16 ? $self->{PROF}{xmax} - 6 : $self->{SR}{xmax} + 10;
	$self->{rongHeKuai}{y}[10] = $self->{PE_S}{y}[11] - 134;

	$self->{rongHeKuai}{x}[11] = $self->{SR}{xmin} - $self->{PROF}{xmin} >= 16 ? $self->{PROF}{xmax} - 6 : $self->{SR}{xmax} + 10;
	$self->{rongHeKuai}{y}[11] = $self->{PE_S}{y}[11] - 179;

	if (($self->{SR}{ymax} - $self->{SR}{ymin}) >= 540)
	{
		@{$self->{rongHeKuai}{mirror}} = qw(no no no no no no yes yes yes yes yes yes no no yes yes);
		@{$self->{rongHeKuai}{symbol}} = qw(h-ronghekuai-g-type1 h-ronghekuai-g-type1 h-ronghekuai-g-type2 h-ronghekuai-g-type2 h-ronghekuai-g-type1 h-ronghekuai-g-type1 h-ronghekuai-g-type1 h-ronghekuai-g-type1 h-ronghekuai-g-type2 h-ronghekuai-g-type2 h-ronghekuai-g-type1 h-ronghekuai-g-type1 h-ronghekuai-g-type2 h-ronghekuai-g-type2 h-ronghekuai-g-type2 h-ronghekuai-g-type2);
		#左边
		$self->{rongHeKuai}{x}[12] = $self->{SR}{xmin} - $self->{PROF}{xmin} >= 16 ? $self->{PROF}{xmin} + 6 : $self->{SR}{xmin} - 10;
		$self->{rongHeKuai}{y}[12] = $self->{PE_S}{y}[9] + 245;
		$self->{rongHeKuai}{x}[13] = $self->{SR}{xmin} - $self->{PROF}{xmin} >= 16 ? $self->{PROF}{xmin} + 6 : $self->{SR}{xmin} - 10;
		$self->{rongHeKuai}{y}[13] = $self->{PE_S}{y}[9] - 265;
		#右边
		$self->{rongHeKuai}{x}[14] = $self->{SR}{xmin} - $self->{PROF}{xmin} >= 16 ? $self->{PROF}{xmax} - 6 : $self->{SR}{xmax} + 10;
		$self->{rongHeKuai}{y}[14] = $self->{PE_S}{y}[11] + 240;
		$self->{rongHeKuai}{x}[15] = $self->{SR}{xmin} - $self->{PROF}{xmin} >= 16 ? $self->{PROF}{xmax} - 6 : $self->{SR}{xmax} + 10;
		$self->{rongHeKuai}{y}[15] = $self->{PE_S}{y}[11] - 270;
	}

	return 1;
}

#**********************************************
#名字		:CountYingFeiRongHeKuai
#功能		:计算熔合块数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountYingFeiRongHeKuai();
#**********************************************
sub CountYingFeiRongHeKuai {
	my $self = shift;
	
	if ($self->{yingFeiRongHeKuai}{x}){
		return 0;
	}

	@{$self->{yingFeiRongHeKuai}{mirror}} = qw(yes yes yes yes no no no no);
	$self->{yingFeiRongHeKuai}{x}[0] = $self->{PROF}{xmin} + 3.5;
	$self->{yingFeiRongHeKuai}{y}[0] = $self->{PROF}{yCenter} - 165;

	$self->{yingFeiRongHeKuai}{x}[1] = $self->{PROF}{xmin} + 3.5;
	$self->{yingFeiRongHeKuai}{y}[1] = $self->{PROF}{yCenter} - 75;

	$self->{yingFeiRongHeKuai}{x}[2] = $self->{PROF}{xmin} + 3.5;
	$self->{yingFeiRongHeKuai}{y}[2] = $self->{PROF}{yCenter} + 75;

	$self->{yingFeiRongHeKuai}{x}[3] = $self->{PROF}{xmin} + 3.5;
	$self->{yingFeiRongHeKuai}{y}[3] = $self->{PROF}{yCenter} + 165;

	$self->{yingFeiRongHeKuai}{x}[4] = $self->{PROF}{xmax} - 3.5;
	$self->{yingFeiRongHeKuai}{y}[4] = $self->{PROF}{yCenter} + 165;

	$self->{yingFeiRongHeKuai}{x}[5] = $self->{PROF}{xmax} - 3.5;
	$self->{yingFeiRongHeKuai}{y}[5] = $self->{PROF}{yCenter} + 75;

	$self->{yingFeiRongHeKuai}{x}[6] = $self->{PROF}{xmax} - 3.5;
	$self->{yingFeiRongHeKuai}{y}[6] = $self->{PROF}{yCenter} - 75;

	$self->{yingFeiRongHeKuai}{x}[7] = $self->{PROF}{xmax} - 3.5;
	$self->{yingFeiRongHeKuai}{y}[7] = $self->{PROF}{yCenter} - 165;

	return 1;
}


#**********************************************
#名字		:CountRongHeKuai
#功能		:计算熔合块数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountRongHeKuai();
#**********************************************
sub CountRongHeKuaiNew1 {
	my $self = shift;
	
	if ($self->{rongHeKuaiNew}{x}){
		return 0;
	}

	@{$self->{rongHeKuaiNew}{mirror}} = qw(yes yes yes yes no no no no);
	$self->{rongHeKuaiNew}{x}[0] = $self->{SR}{xmin} - 10;
	$self->{rongHeKuaiNew}{y}[0] = $self->{PROF}{ymin} + 125;

	$self->{rongHeKuaiNew}{x}[1] = $self->{SR}{xmin} - 10;
	$self->{rongHeKuaiNew}{y}[1] = $self->{PROF}{ymin} + 125 + 45;

	$self->{rongHeKuaiNew}{x}[2] = $self->{SR}{xmin} - 10;
	$self->{rongHeKuaiNew}{y}[2] = $self->{PROF}{ymin} + 371;

	$self->{rongHeKuaiNew}{x}[3] = $self->{SR}{xmin} - 10;
	$self->{rongHeKuaiNew}{y}[3] = $self->{PROF}{ymin} + 371 + 45;

	$self->{rongHeKuaiNew}{x}[4] = $self->{SR}{xmax} + 10;
	$self->{rongHeKuaiNew}{y}[4] = $self->{rongHeKuaiNew}{y}[0];

	$self->{rongHeKuaiNew}{x}[5] = $self->{SR}{xmax} + 10;
	$self->{rongHeKuaiNew}{y}[5] = $self->{rongHeKuaiNew}{y}[1];

	$self->{rongHeKuaiNew}{x}[6] = $self->{SR}{xmax} + 10;
	$self->{rongHeKuaiNew}{y}[6] = $self->{rongHeKuaiNew}{y}[2];

	$self->{rongHeKuaiNew}{x}[7] = $self->{SR}{xmax} + 10;
	$self->{rongHeKuaiNew}{y}[7] = $self->{rongHeKuaiNew}{y}[3];

	return 1;
}


#**********************************************
#名字		:CountYingFeiRongHeKuaiDrill
#功能		:计算熔合块数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountYingFeiRongHeKuaiDrill();
#**********************************************
sub CountYingFeiRongHeKuaiDrill {
	my $self = shift;
	
	if ($self->{yingFeiRongHeKuaiDrill}{x}){
		return 0;
	}

	my $xs = 3.5 + 1 + 2.5 + 0.5;
	@{$self->{yingFeiRongHeKuaiDrill}{mirror}} = qw(yes yes yes yes no no no no);
	$self->{yingFeiRongHeKuaiDrill}{x}[0] = $self->{SR}{xmin} + $xs;
	$self->{yingFeiRongHeKuaiDrill}{y}[0] = $self->{PROF}{yCenter} - 165;

	$self->{yingFeiRongHeKuaiDrill}{x}[1] = $self->{PROF}{xmin} + $xs;
	$self->{yingFeiRongHeKuaiDrill}{y}[1] = $self->{PROF}{yCenter} - 75;

	$self->{yingFeiRongHeKuaiDrill}{x}[2] = $self->{PROF}{xmin} + $xs;
	$self->{yingFeiRongHeKuaiDrill}{y}[2] = $self->{PROF}{yCenter} + 75;

	$self->{yingFeiRongHeKuaiDrill}{x}[3] = $self->{PROF}{xmin} + $xs;
	$self->{yingFeiRongHeKuaiDrill}{y}[3] = $self->{PROF}{yCenter} + 165;

	$self->{yingFeiRongHeKuaiDrill}{x}[4] = $self->{PROF}{xmax} - $xs;
	$self->{yingFeiRongHeKuaiDrill}{y}[4] = $self->{PROF}{yCenter} + 165;

	$self->{yingFeiRongHeKuaiDrill}{x}[5] = $self->{PROF}{xmax} - $xs;
	$self->{yingFeiRongHeKuaiDrill}{y}[5] = $self->{PROF}{yCenter} + 75;

	$self->{yingFeiRongHeKuaiDrill}{x}[6] = $self->{PROF}{xmax} - $xs;
	$self->{yingFeiRongHeKuaiDrill}{y}[6] = $self->{PROF}{yCenter} - 75;

	$self->{yingFeiRongHeKuaiDrill}{x}[7] = $self->{PROF}{xmax} - $xs;
	$self->{yingFeiRongHeKuaiDrill}{y}[7] = $self->{PROF}{yCenter} - 165;

	return 1;
}


#**********************************************
#名字		:CountJobInfo
#功能		:计算料号信息，包括料号名，层别名，时间等数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountJobInfo();
#**********************************************
sub CountJobInfo {
	my $self = shift;
	
	if ($self->{layerType} eq 'inner'
		or $self->{layerType} eq 'second'
		or ($self->{layerType} eq 'outer'
			and $self->{cfg}{hdi}{zhengFuPian} eq '正??')){
		$self->{checkListSig}{polarity} = 'positive';
	}
	else
	{
		$self->{checkListSig}{polarity} = 'positive';
	}
	
	#计算添加的文字
	my $time = strftime("%Y%m%d", localtime(time));
	$self->{jobLayerName}{text} = '$$job '.uc("$self->{Layer} ").substr($time, 2);

	$self->{checkListSig}{text} = ' $$.layer_operater'.' $$.layer_check';
	#$self->{checkListSig}{text} = '';
	#$self->{checkListSig}{text} = strftime("%Y/%m/%d", localtime(time)) . " $self->{User}";

	$self->{layerMark}{symbol} = "i$self->{$self->{Layer}}{layNum}";
	$self->{jobLayerName}{w_factor} = "0.985";
	if ($self->{ERP}{isInnerHT} eq "yes" || $self->{ERP}{isOuterHT} eq "yes") {
		$self->{jobLayerName}{w_factor} = "1.4"
	}
	
	


	$self->{jobLayerName}{xSize} = 2.3;
	$self->{jobLayerName}{ySize} = 2.5;

    $self->{jobLayerName}{y} = $self->{SR}{ymin} - 10;
    $self->{checkListSig}{y} = $self->{SR}{ymax} + 5.3;
	#计算是否镜像
	if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/) {
		$self->{jobLayerName}{mirror} = 'no';
        #计算料号名坐标
        $self->{jobLayerName}{x} = $self->{PROF}{xmin} + ($self->{PROF}{xmax} - $self->{PROF}{xmin}) * 0.5 + 25;
		$self->{checkListSig}{x} = $self->{SR}{xmax} - 130;
	}
	else {
		$self->{jobLayerName}{mirror} = 'yes';
        #计算料号名坐标
        $self->{jobLayerName}{x} = $self->{PROF}{xmin} + ($self->{PROF}{xmax} - $self->{PROF}{xmin}) * 0.5 + 25 + 65;
		$self->{checkListSig}{x} = $self->{SR}{xmax} - 130 + 30;
	}

	my $dis = 4;
	if ($self->{jobLayerName}{biTong}{xs}){
		return 0;
	}
	
	$self->{jobLayerName}{biTong}{xs} = $self->{PROF}{xmin} + ($self->{PROF}{xmax} - $self->{PROF}{xmin}) * 0.5 + 25;
	$self->{jobLayerName}{biTong}{ys} = $self->{SR}{ymin} - 8.8;

	$self->{jobLayerName}{biTong}{xe} = $self->{PROF}{xmin} + ($self->{PROF}{xmax} - $self->{PROF}{xmin}) * 0.5 + 25  + 65;
	$self->{jobLayerName}{biTong}{ye} = $self->{SR}{ymin} - 8.8;
	
	$self->{checkListSig}{biTong}{xs} = $self->{SR}{xmax} - 130;
	$self->{checkListSig}{biTong}{ys} = $self->{SR}{ymax} + 6.544;
	$self->{checkListSig}{biTong}{xe} = $self->{SR}{xmax} - 130 + 30;
	$self->{checkListSig}{biTong}{ye} = $self->{SR}{ymax} + 6.544;


	return 1;
}

sub CountInnerErciyuan
{
	my $self = shift;
	
	if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/)
	{
		$self->{innerErciyuan}{symbol} = "inner-erciyuan-" . int($self->{$self->{Layer}}{layNum}  * 0.5) ;
	}
	else
	{
		$self->{innerErciyuan}{symbol} = "inner-erciyuan";
	}
	
	
	
	#上面
	$self->{innerErciyuan}{up}{x} = $self->{SR}{xmin} + 75 + (int($self->{$self->{Layer}}{layNum} * 0.5) - 1) * 5.2;
	$self->{innerErciyuan}{up}{y} = $self->{SR}{ymax} + 4.6;
	$self->{innerErciyuan}{up}{start}{x} = $self->{SR}{xmin} + 75;
	$self->{innerErciyuan}{up}{start}{y} = $self->{SR}{ymax} + 5.1;
	#下面
	$self->{innerErciyuan}{down}{x} = $self->{SR}{xmin} + 75 + (int($self->{$self->{Layer}}{layNum} * 0.5) - 1) * 5.2;
	$self->{innerErciyuan}{down}{y} = $self->{SR}{ymin} - 4.6;
	$self->{innerErciyuan}{down}{start}{x} = $self->{SR}{xmin} + 75;
	$self->{innerErciyuan}{down}{start}{y} = $self->{SR}{ymin} - 5.1;
	#左边
	$self->{innerErciyuan}{left}{x} = $self->{SR}{xmin} - 4.6;
	$self->{innerErciyuan}{left}{y} = $self->{PE_S}{y}[9] + 46.5 - (int($self->{$self->{Layer}}{layNum} * 0.5) - 1) * 5.2;
	$self->{innerErciyuan}{left}{start}{x} = $self->{SR}{xmin} - 5.1;
	$self->{innerErciyuan}{left}{start}{y} = $self->{PE_S}{y}[9] + 46.5;
	#右边
	$self->{innerErciyuan}{right}{x} = $self->{SR}{xmax} + 4.6;
	$self->{innerErciyuan}{right}{y} = $self->{PE_S}{y}[9] + 46.5 - (int($self->{$self->{Layer}}{layNum} * 0.5) - 1) * 5.2;
	$self->{innerErciyuan}{right}{start}{x} = $self->{SR}{xmax} + 5.1;
	$self->{innerErciyuan}{right}{start}{y} = $self->{PE_S}{y}[9] + 46.5;
	
	#上面的数据
	$self->{innerEriciyuan}{up}{text}{value} = sprintf("%.3f",$self->{SR}{ymax} + 4.6 - ($self->{SR}{ymin} - 4.6));
	$self->{innerEriciyuan}{up}{text}{xs} = $self->{SR}{xmin} + 75 - 1;
	$self->{innerEriciyuan}{up}{text}{ys} =  $self->{SR}{ymax} + 9.95;
	$self->{innerEriciyuan}{up}{text}{xe} = $self->{SR}{xmin} + 75 - 1 + 25;
	$self->{innerEriciyuan}{up}{text}{ye} =  $self->{SR}{ymax} + 9.95;
	$self->{innerEriciyuan}{up}{text}{x} = $self->{SR}{xmin} + 75 ;
	$self->{innerEriciyuan}{up}{text}{y} = $self->{SR}{ymax} + 9.95 - 1.4;
	#左边的数据
	$self->{innerEriciyuan}{left}{text}{value} = sprintf("%.3f",$self->{SR}{xmax} + 4.6 - ($self->{SR}{xmin} - 4.6));
	$self->{innerEriciyuan}{left}{text}{xs} = $self->{SR}{xmin} -9.95;
	$self->{innerEriciyuan}{left}{text}{ys} =  $self->{PE_S}{y}[9] + 47.5;
	$self->{innerEriciyuan}{left}{text}{xe} = $self->{SR}{xmin} -9.95;
	$self->{innerEriciyuan}{left}{text}{ye} =  $self->{PE_S}{y}[9] + 47.5 - 25;
	$self->{innerEriciyuan}{left}{text}{x} = $self->{SR}{xmin} -9.95 - 1.4;
	$self->{innerEriciyuan}{left}{text}{y} = $self->{PE_S}{y}[9] + 47.5 - 1;
	
}
#**********************************************
#名字		:CountFilmId
#功能		:计算料号信息，包括料号名，层别名，时间等数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountFilmId();
#**********************************************
sub CountFilmId {
	my $self = shift;
	
	if (($self->{layerType} eq 'outer'
			and $self->{cfg}{hdi}{zhengFuPian} eq '正片') or $self->{layerType} ne "inner"){
		$self->{filmId}{polarity} = 'positive';
	}
	else {
		$self->{filmId}{polarity} = 'negative';
	}
	
	#计算是否镜像
	if ($self->{Layer} =~ /.*t.*/){
		$self->{filmId}{x} =  $self->{PROF}{xmin} - 5 - 7.61;
		$self->{filmId}{y} =  $self->{PROF}{yCenter} + 23.5 + 80;
		$self->{filmId}{mirror} = 'no';
		$self->{filmId}{angle} = 90;
	}
	else {
		$self->{filmId}{x} =  $self->{PROF}{xmin} - 5 - 7.61;
		$self->{filmId}{y} =  $self->{PROF}{yCenter} + 23.5 - 41.656 + 80;
		$self->{filmId}{mirror} = 'yes';
		$self->{filmId}{angle} = 270;
	}

	return 1;
}

#**********************************************
#名字		:CountLayerMarki
#功能		:计算层别标识数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountLayerMarki();
#**********************************************
sub CountLayerMarki {
	my $self = shift;

	#计算symbol
	my $xs = 18;
	$self->{layerMarki}{symbol} = "i$self->{$self->{Layer}}{layNum}-sz-new";
	

	#如果y的留边足够大，则可直接放在华为防错靶的下面，否则，层别标识向右移动，移动的距离5x(core数+1)
	#my $yiDong = 5*($self->{coreNum}*2 + 1) + 2;

	if ($self->{layerMarki}{biTong}{xs}){
		#重新计算层别标识，-3为本身宽度的一半
		$self->{layerMarki}{x} =  $self->{jobLayerName}{x} = $self->{PROF}{xmin} + ($self->{PROF}{xmax} - $self->{PROF}{xmin}) * 0.5 + 26.25 + ($self->{$self->{Layer}}{layNum}-1) * (4.5) ;
		return 0;
	}


	#计算坐标
	#if ($self->{SRToPROF}{y} > 14){
	#	$self->{layerMarki}{biTong}{xs} = $self->{PROF}{xCenter} + $xs + 8;
	#	$self->{layerMarki}{biTong}{xe} = $self->{layerMarki}{biTong}{xs} + ($self->{signalLayer}{num} - 1) * 6;
	#	$self->{layerMarki}{x} = $self->{PROF}{xCenter} + $xs + ($self->{$self->{Layer}}{layNum}-1) * (6) - 3 + 8;
	#}
	#else {
		$self->{layerMarki}{biTong}{xs} = $self->{jobLayerName}{x} = $self->{PROF}{xmin} + ($self->{PROF}{xmax} - $self->{PROF}{xmin}) * 0.5 + 26.25;
		$self->{layerMarki}{biTong}{xe} = $self->{layerMarki}{biTong}{xs} + ($self->{signalLayer}{num} - 1) * 4.5;
		$self->{layerMarki}{x} = $self->{jobLayerName}{x} = $self->{PROF}{xmin} + ($self->{PROF}{xmax} - $self->{PROF}{xmin}) * 0.5 + 26.25 + ($self->{$self->{Layer}}{layNum}-1) * (4.5);
	#}

	$self->{layerMarki}{biTong}{ys} = $self->{SR}{ymin} - 4.65;
	$self->{layerMarki}{biTong}{ye} = $self->{SR}{ymin} - 4.65;
	$self->{layerMarki}{y} = $self->{SR}{ymin} - 4.65;

	return 1;
}

#**********************************************
#名字		:CountWenZiPenMo
#功能		:计算文字喷墨
#参数		:无
#返回值		:1
#使用例子	:$self->CountWenZiPenMo();
#**********************************************
sub CountWenZiPenMo {
	my $self = shift;

	#计算symbol
	if ($self->{layerType} eq 'via'){
		$self->{wenZiPenMo}{symbol} = 'r3175';
	}
	elsif ($self->{layerType} eq 'ss') {
		$self->{wenZiPenMo}{symbol} = 'donut_r3504.79x3200'
	}
	elsif ($self->{layerType} eq 'sm'){
		$self->{wenZiPenMo}{symbol} = 'r3675';
	}
	elsif ($self->{layerType} eq 'outer'){
		$self->{wenZiPenMo}{symbol} = 'r2000';
	}

	#计算坐标
	if ($self->{wenZiPenMo}{x}){
		return 0;
	}
	
	my $s1 = 12;
	my $s2 = 5;

	$self->{wenZiPenMo}{x}[0] = $self->{SR}{xmin} - $s2;
	$self->{wenZiPenMo}{y}[0] = $self->{PROF}{yCenter} - $s1;

	$self->{wenZiPenMo}{x}[1] = $self->{PROF}{xCenter} + $s1;
	$self->{wenZiPenMo}{y}[1] = $self->{SR}{ymax} + $s2;

	$self->{wenZiPenMo}{x}[2] = $self->{SR}{xmax} + $s2;
	$self->{wenZiPenMo}{y}[2] = $self->{wenZiPenMo}{y}[0];

	$self->{wenZiPenMo}{x}[3] = $self->{wenZiPenMo}{x}[1];
	$self->{wenZiPenMo}{y}[3] = $self->{SR}{ymin} - $s2;
	
	return 1;
}

#**********************************************
#名字		:CountXYScale
#功能		:计算XY系数数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountXYScale();
#**********************************************
sub CountXYScaleOld {
	my $self = shift;
	
	#计算坐标
	if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
		$self->{xYScale}{mirror} = 'no';
		$self->{xYScale}{x} = $self->{SR}{xmin} - 3.5;
	}
	else {
		$self->{xYScale}{mirror} = 'yes';
		$self->{xYScale}{x} = $self->{SR}{xmin} - 3.5 + 2.6;
	}

	if ($self->{xYScale}{y}){
		return 0;
	}
	$self->{xYScale}{y} = $self->{PROF}{yCenter} - 49;

	return 1;
}

#**********************************************
#名字		:CountXYScale
#功能		:计算XY系数数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountXYScale();
#**********************************************
sub CountXYScale {
	my $self = shift;

	$self->{xYScale}{w_factor} = "0.6667";
	if ($self->{ERP}{isInnerHT} eq "yes" || $self->{ERP}{isOuterHT} eq "yes") {
		$self->{xYScale}{w_factor} = "1.08333";
	}
	#计算symbol
	if ($self->{layerType} eq 'second'
			or $self->{layerType} eq 'outer'){
		$self->{xYScale}{symbol} = 'scale-y-jing-new-ldi';
		if ($self->{ERP}{isInnerHT} eq "yes" || $self->{ERP}{isOuterHT} eq "yes") {
			$self->{xYScale}{symbol} = 'scale-y-jing-new-ldi-ht';
		}
		
	}
	else {
		$self->{xYScale}{symbol} = 'scale-y-jing-new';
		if ($self->{ERP}{isInnerHT} eq "yes" || $self->{ERP}{isOuterHT} eq "yes") {
			$self->{xYScale}{symbol} = 'scale-y-jing-new-ht';
		}
	}
	$self->{xYScale}{angle} = 0;
	#计算坐标
	if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
		$self->{xYScale}{mirror} = 'no';
		$self->{xYScale}{x} = $self->{SR}{xmin} - 3.75;
		$self->{xYScale}{textX}{x} = $self->{SR}{xmin} - 3.75-1.2;
		$self->{xYScale}{textY}{x} = $self->{xYScale}{textX}{x};
		if ($self->{layerType} eq 'inner')
		{
			$self->{xYScale}{x} = $self->{SR}{xmax} - 126;
			$self->{xYScale}{textX}{x} = $self->{xYScale}{x} + 2;
			$self->{xYScale}{textY}{x} = $self->{xYScale}{x} + 14;
			$self->{xYScale}{angle} = 270;
		}
	}
	else {
		$self->{xYScale}{mirror} = 'yes';
		$self->{xYScale}{x} = $self->{SR}{xmin} - 3.75;
		$self->{xYScale}{textX}{x} = $self->{SR}{xmin} - 3.75 - 0.65 + 1.53+0.48;
		$self->{xYScale}{textY}{x} = $self->{xYScale}{textX}{x};
		if ($self->{layerType} eq 'inner')
		{
			$self->{xYScale}{x} = $self->{SR}{xmax} - 102;
			$self->{xYScale}{textX}{x} = $self->{xYScale}{x} - 2;
			$self->{xYScale}{textY}{x} = $self->{xYScale}{x} - 14;
			$self->{xYScale}{angle} = 270;
		}
	}

	#计算系数坐标


	$self->{xYScale}{y} = $self->{PROF}{yCenter} - 50 + 100;
	$self->{xYScale}{textX}{y} = $self->{PROF}{yCenter} - 52 + 100;
	$self->{xYScale}{textY}{y} = $self->{PROF}{yCenter} - 52 - 12 + 100;
	
	if ($self->{layerType} eq 'inner')
	{
		$self->{xYScale}{y} = $self->{SR}{ymax} + 3.75;
		$self->{xYScale}{textX}{y} = $self->{SR}{ymax} + 3.75 - 1.25;
		$self->{xYScale}{textY}{y} = $self->{SR}{ymax} + 3.75 - 1.25;
	}

	return 1;
}

#**********************************************
#名字		:CountJingWei
#功能		:计算经纬向数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountJingWei();
#**********************************************
sub CountJingWei {
	my $self = shift;

	#计算是否镜像
	if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
		$self->{jing}{mirror} = $self->{wei}{mirror} = 'no';
		$self->{jing}{symbol} = 'dg_jing_top';
		$self->{wei}{symbol} = 'dg_wei_top';
	}
	else {
		$self->{jing}{mirror} = $self->{wei}{mirror} = 'yes';
		$self->{jing}{symbol} = 'dg_jing_bot';
		$self->{wei}{symbol} = 'dg_wei_bot';
	}



	my $xs = 7;

	my $ys = 7;

	if ($#{$self->{laser}{drillTop}} < 0
			and $#{$self->{laser}{drillBottom}} < 0){
		$ys = 3;
	}

	my $laser = 0;
	if ($self->{liuBian}{ySize} < 9.5){
		if ($#{$self->{laser}{drillTop}} > 0
				or $#{$self->{laser}{drillBottom}} > 0){
			$laser = 16 * 2;
		}
		else {
			$laser = 16;
		}
	}
	if ($self->{cfg}{jingWei}{fangXiang} eq  "长经短纬"){
		#计算经向坐标
		$self->{jing}{x} = $self->{SR}{xmin} - $xs;
        $self->{jing}{y} = $self->{PROF}{yCenter} - 58;
        if ($self->{Layer} =~ /in\d+/)
        {
            $self->{jing}{y} = $self->{PROF}{yCenter} - 58 + 40;
        }


		#计算纬向坐标
		if ($self->{hdi}{jieShu} > 1){
			$self->{wei}{x} = $self->{SR}{xmin} + 150 + $laser;
		}
		else {
			$self->{wei}{x} = $self->{SR}{xmin} + 110 + $laser;
		}

		$self->{wei}{y} = $self->{liuBian}{ymin} + $ys;
		$self->{jing}{angle} = '180';
		$self->{wei}{angle} = '90';
	}
	else {
		#计算经向坐标
		$self->{wei}{x} = $self->{SR}{xmin} - $xs;
        $self->{wei}{y} = $self->{PROF}{yCenter} - 58 ;
        if ($self->{Layer} =~ /in\d+/)
        {
            $self->{wei}{y} = $self->{PROF}{yCenter} - 58 + 40;
        }


		#计算纬向坐标
		if ($self->{hdi}{jieShu} > 1){
			$self->{jing}{x} = $self->{SR}{xmin} + 150;
		}
		else {
			$self->{jing}{x} = $self->{SR}{xmin} + 110;
		}
		$self->{jing}{y} = $self->{liuBian}{ymin} + $ys;

		$self->{jing}{angle} = '90';
		$self->{wei}{angle} = '180';
	}

	return 1;
}



#**********************************************
#名字		:CountFangCuoBa
#功能		:计算防错靶数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountFangCuoBa();
#**********************************************
sub CountFangCuoBa {
	my $self = shift;
	
	#计算避铜数据
	$self->{fangCuoBa}{biTong}{xs} = $self->{PROF}{xCenter} + 26;
	$self->{fangCuoBa}{biTong}{ys} = $self->{PROF}{ymax} - 3;

	$self->{fangCuoBa}{biTong}{xe} = $self->{PROF}{xCenter} + 26 + ($self->{coreNum}*2) * 5;
	$self->{fangCuoBa}{biTong}{ye} = $self->{PROF}{ymax} - 3;

	#计算添加矩形Pad数据
	$self->{fangCuoBa}{x} = $self->{fangCuoBa}{biTong}{xs} + 5*($self->{$self->{Layer}}{layNum} - $self->{hdi}{jieShu} - 2) + 10/4;
	$self->{fangCuoBa}{y} = $self->{PROF}{ymax} - 3;

	return 1;
}


#**********************************************
#名字		:CountDaba
#功能		:计算打靶数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountDaba();
#**********************************************
sub CountDaba {
	my $self = shift;

	#计算打靶symbol
	$self->{daba}{baBiao}{symbol} = 'h-daba';
	$self->{daba}{baBiao}{duiWei} = 'h-chongkong-duiwei';
	if ($self->{ERP}{isInnerHT} eq "yes") {
		$self->{daba}{baBiao}{symbol} = 'h-daba-ht';
	}
	if ($self->{ERP}{isOuterHT} eq "yes") {
		$self->{daba}{baBiao}{duiWei} = 'h-chongkong-duiwei-ht';
	}
	
	if ($self->{layerType} eq 'outer'
			and $self->{cfg}{hdi}{zhengFuPian} eq '正片'){
		$self->{daba}{duiWei}{polarity} = 'negative';
		$self->{daba}{baBiao}{duiWei} = 's5600';
	}
	else {
		$self->{daba}{duiWei}{polarity} = 'positive';
	}

	my $xSel = 59;

	#x距离做板边最小50个mm,内层算第一次压合
	if ($self->{Layer} =~ /in/){
		if ($self->{signalLayer}{num} == 4)
		{
			$self->{daba}{baBiao}{x}[0] = $self->{PROF}{xmin} + ($self->{PROF}{xmax} - $self->{PROF}{xmin}) * 0.5 ;
			$self->{daba}{baBiao}{x}[1] = $self->{PROF}{xmin} + ($self->{PROF}{xmax} - $self->{PROF}{xmin}) * 0.5 ;
		}
		else
		{
			$self->{daba}{baBiao}{x}[0] = $self->{SR}{xmin} + $xSel;
			$self->{daba}{baBiao}{x}[1] = $self->{SR}{xmin} + $xSel;	
		}

		$self->{daba}{baBiao}{y}[0] = $self->{SR}{ymin} - $self->{dabaMain}{outer}{toSR} - ($self->{hdi}{jieShu}*0.5);	
		$self->{daba}{baBiao}{y}[1] = $self->{SR}{ymax} + $self->{dabaMain}{outer}{toSR} + ($self->{hdi}{jieShu}*0.5);
	}
	else {
		if ($self->{signalLayer}{num} == 4)
		{
			$self->{daba}{baBiao}{x}[0] = $self->{PROF}{xmin} + ($self->{PROF}{xmax} - $self->{PROF}{xmin}) * 0.5 + $self->{$self->{Layer}}{yaheN} * $self->{layerBaBiaoJianJu};
			$self->{daba}{baBiao}{x}[1] = $self->{daba}{baBiao}{x}[0];		
		}
		else
		{
			$self->{daba}{baBiao}{x}[0] = $self->{SR}{xmin} + $xSel + $self->{$self->{Layer}}{yaheN} * $self->{layerBaBiaoJianJu};
			$self->{daba}{baBiao}{x}[1] = $self->{daba}{baBiao}{x}[0];	
		}

		$self->{daba}{baBiao}{y}[0] = $self->{SR}{ymin} - $self->{dabaMain}{outer}{toSR} - ($self->{hdi}{jieShu}*0.5) + ($self->{$self->{Layer}}{yaheN})*0.5;
		$self->{daba}{baBiao}{y}[1] = $self->{SR}{ymax} + $self->{dabaMain}{outer}{toSR} + ($self->{hdi}{jieShu}*0.5) - ($self->{$self->{Layer}}{yaheN})*0.5;
	}
	
	#打靶据最后一次锣边距离大于50mm时，移动打靶到距锣边小于50mm   2016-2-26 
	my $ytoluobian = $self->{daba}{baBiao}{y}[0] - ($self->{PROF}{ymax} - $self->{PROF}{ymin} - $self->{cfg}{luoBianSize}{lastY})*0.5;
	if ($ytoluobian > 50)
	{
		$self->{daba}{baBiao}{y}[0] = $self->{daba}{baBiao}{y}[0] - ($ytoluobian - 48);
		$self->{daba}{baBiao}{y}[1] = $self->{daba}{baBiao}{y}[1] + ($ytoluobian - 48);
	}
	
	#右下
	#右上

	if ($self->{Layer} =~ /in/){
		$self->{daba}{baBiao}{x}[2] = $self->{daba}{x2FangDai};
		$self->{daba}{baBiao}{y}[2] = $self->{daba}{baBiao}{y}[0]
	}
	else {
		$self->{daba}{baBiao}{x}[2] = $self->{daba}{x2FangDai} + ($self->{$self->{Layer}}{yaheN}) * $self->{layerBaBiaoJianJu};
		$self->{daba}{baBiao}{y}[2] = $self->{daba}{baBiao}{y}[0];
	}
	#$self->{daba}{baBiao}{y}[2] = $self->{SR}{ymin} - 5;

	#计算标识
	$self->{daba}{biaoShi}{x}[0] = $self->{daba}{baBiao}{x}[0];
	$self->{daba}{biaoShi}{x}[1] = $self->{daba}{baBiao}{x}[1];
	$self->{daba}{biaoShi}{x}[2] = $self->{daba}{baBiao}{x}[2];

	my $yBiaoShi = 4.7;
	$self->{daba}{biaoShi}{y}[0] = $self->{daba}{baBiao}{y}[0] - $yBiaoShi;
	$self->{daba}{biaoShi}{y}[1] = $self->{daba}{baBiao}{y}[1] + $yBiaoShi;
	$self->{daba}{biaoShi}{y}[2] = $self->{daba}{baBiao}{y}[2] - $yBiaoShi;

	if ($self->{Layer} =~ /in/){
		$self->{daba}{biaoShi}{symbol} = "zh-0".$self->{$self->{Layer}}{yaheN};
		if ($self->{ERP}{isInnerHT} eq "yes") {
			$self->{daba}{biaoShi}{symbol} = "zh-0".$self->{$self->{Layer}}{yaheN} . "-ht";
		}
		
	}
	else {
		my $num = $self->{$self->{Layer}}{yaheN} + 1;
		$self->{daba}{biaoShi}{symbol} = "zh-0". $num;
		if ($self->{ERP}{isOuterHT} eq "yes") {
			$self->{daba}{biaoShi}{symbol} = "zh-0". $num . "-ht";
		}
		
	}

	#计算对位
	if ($self->{signalLayer}{num} == 4)
	{
		$self->{daba}{duiWei}{x}[0] = $self->{PROF}{xmin} + ($self->{PROF}{xmax} - $self->{PROF}{xmin}) * 0.5 + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{layerBaBiaoJianJu};
		$self->{daba}{duiWei}{x}[1] = $self->{daba}{duiWei}{x}[0];
	}
	else
	{
		$self->{daba}{duiWei}{x}[0] = $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{layerBaBiaoJianJu};
		$self->{daba}{duiWei}{x}[1] = $self->{daba}{duiWei}{x}[0];	
	}

	$self->{daba}{duiWei}{y}[0] = $self->{SR}{ymin} - $self->{dabaMain}{outer}{toSR} - ($self->{hdi}{jieShu}*0.5) + ($self->{$self->{Layer}}{yaheN} - 1)*0.5;
	$self->{daba}{duiWei}{y}[1] = $self->{SR}{ymax} + $self->{dabaMain}{outer}{toSR} + ($self->{hdi}{jieShu}*0.5) - ($self->{$self->{Layer}}{yaheN} - 1)*0.5;
	$self->{daba}{duiWei}{x}[2] = $self->{daba}{x2FangDai} + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{layerBaBiaoJianJu};
	$self->{daba}{duiWei}{y}[2] = $self->{daba}{duiWei}{y}[0];

	#右下角第一个和最后一个打靶坐标
	$self->{daba}{bottomStart}{x} = $self->{daba}{x2FangDai};
	$self->{daba}{bottomEnd}{x}  = $self->{daba}{x2FangDai};


	return 1;
}

#**********************************************
#名字		:CountDaba
#功能		:计算打靶数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountDaba();
#**********************************************
sub CountDabaOld {
	my $self = shift;
	
	#计算打靶symbol
	$self->{daba}{baBiao}{symbol} = 'h-daba';
	$self->{daba}{baBiao}{duiWei} = 'h-chongkong-duiwei';
	if ($self->{ERP}{isInnerHT} eq "yes") {
		$self->{daba}{baBiao}{symbol} = 'h-daba-ht';
	}
	if ($self->{ERP}{isOuterHT} eq "yes")
	{
		$self->{daba}{baBiao}{duiWei} = 'h-chongkong-duiwei-ht';
	}
	#$self->{daba}{baBiao}{duiWei} = 'df-zh-zdh';

	if ($self->{layerType} eq 'outer'
			and $self->{cfg}{hdi}{zhengFuPian} eq '正片'){
		$self->{daba}{duiWei}{polarity} = 'negative';
	}
	else {
		$self->{daba}{duiWei}{polarity} = 'positive';
	}

	#x距离做板边最小50个mm,内层算第一次压合
	if ($self->{Layer} =~ /in/){
		$self->{daba}{baBiao}{x}[0] = $self->{SR}{xmin} + 54;
		$self->{daba}{baBiao}{x}[1] = $self->{SR}{xmin} + 54;
		$self->{daba}{baBiao}{y}[0] = $self->{SR}{ymin} - 4.5 - ($self->{hdi}{jieShu}*0.5);
		$self->{daba}{baBiao}{y}[1] = $self->{SR}{ymax} + 4.5 + ($self->{hdi}{jieShu}*0.5);
	}
	else {
		$self->{daba}{baBiao}{x}[0] = $self->{SR}{xmin} + 54 + $self->{$self->{Layer}}{yaheN} * 10;
		$self->{daba}{baBiao}{x}[1] = $self->{daba}{baBiao}{x}[0];
		$self->{daba}{baBiao}{y}[0] = $self->{SR}{ymin} - 4.5 - ($self->{hdi}{jieShu}*0.5) + ($self->{$self->{Layer}}{yaheN})*0.5;
		$self->{daba}{baBiao}{y}[1] = $self->{SR}{ymax} + 4.5 + ($self->{hdi}{jieShu}*0.5) - ($self->{$self->{Layer}}{yaheN})*0.5;
	}
	
	#右下
	#右上
	if ($self->{Layer} =~ /in/){
		$self->{daba}{baBiao}{x}[2] = $self->{daba}{x2FangDai};
		$self->{daba}{baBiao}{y}[2] = $self->{daba}{baBiao}{y}[0]
	}
	else {
		$self->{daba}{baBiao}{x}[2] = $self->{daba}{x2FangDai} + ($self->{$self->{Layer}}{yaheN}) * 10;
		$self->{daba}{baBiao}{y}[2] = $self->{daba}{baBiao}{y}[0];
	}
	#$self->{daba}{baBiao}{y}[2] = $self->{SR}{ymin} - 5;

	#计算对位
	$self->{daba}{duiWei}{x}[0] = $self->{SR}{xmin} + 54 + ($self->{$self->{Layer}}{yaheN} - 1) * 10;
	$self->{daba}{duiWei}{x}[1] = $self->{daba}{duiWei}{x}[0];
	$self->{daba}{duiWei}{y}[0] = $self->{SR}{ymin} - 4.5 - ($self->{hdi}{jieShu}*0.5) + ($self->{$self->{Layer}}{yaheN} - 1)*0.5;
	$self->{daba}{duiWei}{y}[1] = $self->{SR}{ymax} + 4.5 + ($self->{hdi}{jieShu}*0.5) - ($self->{$self->{Layer}}{yaheN} - 1)*0.5;
	$self->{daba}{duiWei}{x}[2] = $self->{daba}{x2FangDai} + ($self->{$self->{Layer}}{yaheN} - 1) * 10;
	$self->{daba}{duiWei}{y}[2] = $self->{daba}{duiWei}{y}[0];

	#右下角第一个和最后一个打靶坐标
	$self->{daba}{bottomStart}{x} = $self->{daba}{x2FangDai};
	$self->{daba}{bottomEnd}{x}  = $self->{daba}{x2FangDai};


	return 1;
}

#**********************************************
#名字		:CountIfAddCCDDrill
#功能		:计算是否添加CCD孔
#参数		:无
#返回值		:1
#使用例子	:$self->CountIfAddCCDDrill();
#**********************************************
sub CountIfAddCCDDrill {
	my $self = shift;
	
	#截取该埋孔的第二个字符
	my $layerNum = substr ("$self->{Layer}", 1);
	
	#算出信号层
	my $layer = "sec"."$layerNum"."t";

	#算出第几次压合
	my $yaHeNum = $self->{$self->{Layer}}{yaheN};

	if ($yaHeNum == 1){
		$self->{addCCDDrill} = 'yes';
	}
	else {
		$self->{addCCDDrill} = 'no';
	}

	return 1;
}

#**********************************************
#名字		:CountdabaBY
#功能		:计算最小线距，芯板铜厚添加位置
#参数		:无
#返回值		:1
#使用例子	:$self->Countdaba();
#**********************************************
sub CountSpaceAndCopperThick
{
	my $self = shift;
	
	if ($self->{Layer} =~ /.*t.*/i)
	{
		$self->{scSymbol}{mirror} = "no";
	}
	else
	{
		$self->{scSymbol}{mirror} = "yes";
	}
	#计算坐标
	my $width = $self->{SR}{ymin} - $self->{PROF}{ymin};

	$self->{scSymbol}{y} = $self->{SR}{ymin} - $width * 0.5;
	
	if (! defined($self->{PE}{yesNo}) || $self->{PE}{yesNo} eq 'no')
	{
		$self->{scSymbol}{x} = $self->{PROF}{xCenter} + 50;
	}
	else {

		$self->{scSymbol}{x} = $self->{PE_S}{x}[10] + 50;
	}
	
	$self->{scSymbol}{x1} = $self->{scSymbol}{mirror} eq "no" ? $self->{scSymbol}{x} - 13.5 : $self->{scSymbol}{x} + 14.2;
	$self->{scSymbol}{y1} = $self->{scSymbol}{y} - 1.2;
	
	$self->{scSymbol}{x2} = $self->{scSymbol}{mirror} eq "no" ? $self->{scSymbol}{x} + 11.3 : $self->{scSymbol}{x} - 11;
	$self->{scSymbol}{y2} = $self->{scSymbol}{y} - 1.2;
	
	$self->INFO(entity_type => 'layer',
           entity_path => "$self->{Job}/$self->{Step}/$self->{Layer}",
           data_type => 'TYPE');
	if ($self->{layerType} eq "inner" || $self->{layerType} eq "second")
	{
		$self->{scSymbol}{polarity} = $self->{doinfo}{gTYPE} eq "power_ground"  ? "negative" : "positive";
	}

	return 1;	
	
}
#**********************************************
#名字		:CountdabaBY
#功能		:计算打靶数据
#参数		:无
#返回值		:1
#使用例子	:$self->Countdaba();
#**********************************************
sub CountDabaBYOld {
	my $self = shift;
	
	#计算打靶symbol
	
	$self->{dabaBY}{baBiao}{symbol} = 'h-daba-by';
	
	if ($self->{ERP}{isInnerHT} eq "yes") {
		$self->{dabaBY}{baBiao}{symbol} = 'h-daba-by-ht';
	}

	if ($self->{layerType} eq 'outer'
			and $self->{cfg}{hdi}{zhengFuPian} eq '正片'){
		$self->{dabaBY}{duiWei}{polarity} = 'negative';
	}
	else {
		$self->{dabaBY}{duiWei}{polarity} = 'positive';
	}

	#计算打靶坐标
	#长边
	#如果小于两张core，或者是空间足够大，则加在同心圆的下面
	#内层和第一个次外层压合次数相同，都是1
	if ($self->{Layer} =~ /in/){
		$self->{dabaBY}{baBiao}{x}[0] = $self->{SR}{xmin} - 4.5 - ($self->{hdi}{jieShu}*0.5);
		$self->{dabaBY}{baBiao}{x}[1] = $self->{dabaBY}{baBiao}{x}[0];
		$self->{dabaBY}{baBiao}{x}[2] = $self->{SR}{xmax} + 4.5 + ($self->{hdi}{jieShu}*0.5);
		if ($self->{coreNum} < 2){
			$self->{dabaBY}{baBiao}{y}[0] = $self->{tongXinYuan}{firstY}[0] + $self->{tongXinYuan}{length} + $self->{ccd}{length};
			$self->{dabaBY}{baBiao}{y}[1] = $self->{tongXinYuan}{firstY}[1] - $self->{tongXinYuan}{length} - 3;
			$self->{dabaBY}{baBiao}{y}[2] = $self->{tongXinYuan}{firstY}[2] - $self->{tongXinYuan}{length} - 3;
		}
		else {
			#左下
			$self->{dabaBY}{baBiao}{y}[0] = $self->{PROF}{yCenter} - 124;

			#左上
			$self->{dabaBY}{baBiao}{y}[1] = $self->{PROF}{yCenter} + 147;

			#右上
			$self->{dabaBY}{baBiao}{y}[2] = $self->{PROF}{yCenter} + 147;
		}
	}
	else {

		#x
		$self->{dabaBY}{baBiao}{x}[0] = $self->{SR}{xmin} - 4.5 - ($self->{hdi}{jieShu}*0.5) + ($self->{$self->{Layer}}{yaheN}*0.5);
		$self->{dabaBY}{baBiao}{x}[1] = $self->{dabaBY}{baBiao}{x}[0];
		$self->{dabaBY}{baBiao}{x}[2] = $self->{SR}{xmax} + 4.5 + ($self->{hdi}{jieShu}*0.5) - ($self->{$self->{Layer}}{yaheN}*0.5);

		#y
		if ($self->{coreNum} < 2){
			$self->{dabaBY}{baBiao}{y}[0] = $self->{tongXinYuan}{firstY}[0] + $self->{tongXinYuan}{length} + $self->{ccd}{length} - $self->{$self->{Layer}}{yaheN}*10;
			$self->{dabaBY}{baBiao}{y}[1] = $self->{tongXinYuan}{firstY}[1] - $self->{tongXinYuan}{length} - 3 - $self->{$self->{Layer}}{yaheN}*10;
			$self->{dabaBY}{baBiao}{y}[2] = $self->{dabaBY}{baBiao}{y}[1];
		}
		else {
			#左下
			$self->{dabaBY}{baBiao}{y}[0] = $self->{PROF}{yCenter} - 124 - $self->{$self->{Layer}}{yaheN}*10;

			#左上
			$self->{dabaBY}{baBiao}{y}[1] = $self->{PROF}{yCenter} + 147 - $self->{$self->{Layer}}{yaheN}*10;

			#右上
			$self->{dabaBY}{baBiao}{y}[2] = $self->{dabaBY}{baBiao}{y}[1];
		}
	}

	#计算对位
	$self->{dabaBY}{duiWei}{x}[0] = $self->{dabaBY}{baBiao}{x}[0] - 0.5;
	$self->{dabaBY}{duiWei}{x}[1] = $self->{dabaBY}{duiWei}{x}[0];
	$self->{dabaBY}{duiWei}{x}[2] = $self->{dabaBY}{baBiao}{x}[2] + 0.5;

	$self->{dabaBY}{duiWei}{y}[0] = $self->{dabaBY}{baBiao}{y}[0] + 10;
	$self->{dabaBY}{duiWei}{y}[1] = $self->{dabaBY}{baBiao}{y}[1] + 10;
	$self->{dabaBY}{duiWei}{y}[2] = $self->{dabaBY}{duiWei}{y}[1];

	return 1;
}

#**********************************************
#名字		:CountdabaBY
#功能		:计算打靶数据
#参数		:无
#返回值		:1
#使用例子	:$self->Countdaba();
#**********************************************
sub CountDabaBY {
	my $self = shift;
	
	#计算打靶symbol
	$self->{dabaBY}{baBiao}{symbol} = 'h-daba-by';
	if ($self->{ERP}{isInnerHT} eq "yes") {
		$self->{dabaBY}{baBiao}{symbol} = 'h-daba-by-ht';
	}
	

	if ($self->{layerType} eq 'outer'
			and $self->{cfg}{hdi}{zhengFuPian} eq '正片'){
		$self->{dabaBY}{duiWei}{polarity} = 'negative';
	}
	else {
		$self->{dabaBY}{duiWei}{polarity} = 'positive';
	}

	#计算打靶坐标
	#长边
	#如果小于两张core，或者是空间足够大，则加在同心圆的下面
	#内层和第一个次外层压合次数相同，都是1
	if ($self->{Layer} =~ /in/){
		$self->{dabaBY}{baBiao}{x}[0] = $self->{SR}{xmin} - $self->{dabaSub}{outer}{toSR} - ($self->{hdi}{jieShu}*0.5);
		$self->{dabaBY}{baBiao}{x}[1] = $self->{dabaBY}{baBiao}{x}[0];
		$self->{dabaBY}{baBiao}{x}[2] = $self->{SR}{xmax} + $self->{dabaSub}{outer}{toSR} + ($self->{hdi}{jieShu}*0.5);
#		if ($self->{coreNum} < 2){
#			$self->{dabaBY}{baBiao}{y}[0] = $self->{ccdBY}{baBiao}{y}[0] + $self->{FB}{value};
#			$self->{dabaBY}{baBiao}{y}[1] = $self->{ccdBY}{baBiao}{y}[1] - $self->{FB}{value};
#			$self->{dabaBY}{baBiao}{y}[2] = $self->{dabaBY}{baBiao}{y}[1];
#		}
#		else {
#			#左下
#			$self->{dabaBY}{baBiao}{y}[0] = $self->{PROF}{yCenter} - 124;
#
#			#左上
#			$self->{dabaBY}{baBiao}{y}[1] = $self->{PROF}{yCenter} + 147;
#
#			#右上
#			$self->{dabaBY}{baBiao}{y}[2] = $self->{PROF}{yCenter} + 147;
#		}
	}
	else {

		#x
		$self->{dabaBY}{baBiao}{x}[0] = $self->{SR}{xmin} - $self->{dabaSub}{outer}{toSR} - ($self->{hdi}{jieShu}*0.5) + ($self->{$self->{Layer}}{yaheN}*0.5);
		$self->{dabaBY}{baBiao}{x}[1] = $self->{dabaBY}{baBiao}{x}[0];
		$self->{dabaBY}{baBiao}{x}[2] = $self->{SR}{xmax} + $self->{dabaSub}{outer}{toSR} + ($self->{hdi}{jieShu}*0.5) - ($self->{$self->{Layer}}{yaheN}*0.5);

		#y
#		if ($self->{coreNum} < 2){
#			$self->{dabaBY}{baBiao}{y}[0] = $self->{tongXinYuan}{firstY}[0] + $self->{tongXinYuan}{num}*5 + $self->{ccd}{length} - $self->{$self->{Layer}}{yaheN}*10;
#			$self->{dabaBY}{baBiao}{y}[1] = $self->{tongXinYuan}{firstY}[1] - $self->{tongXinYuan}{num}*5 - 3 - $self->{$self->{Layer}}{yaheN}*10;
#			$self->{dabaBY}{baBiao}{y}[2] = $self->{dabaBY}{baBiao}{y}[1];
#		}
#		else {
#			#左下
#			$self->{dabaBY}{baBiao}{y}[0] = $self->{PROF}{yCenter} - 124 - $self->{$self->{Layer}}{yaheN}*10;
#
#			#左上
#			$self->{dabaBY}{baBiao}{y}[1] = $self->{PROF}{yCenter} + 147 - $self->{$self->{Layer}}{yaheN}*10;
#
#			#右上
#			$self->{dabaBY}{baBiao}{y}[2] = $self->{dabaBY}{baBiao}{y}[1];
#		}
	}

	#小于2张core
	if ($self->{coreNum} < 2){
		if ($self->{Layer} =~ /in/){
			#ccd的靶标坐标+(ccd的数量-第几次压合)*10(最后一个ccd的靶标位置) + $self->{FB}{value}(ccd和打靶之间$self->{FB}{value}) - 压合次数*10
			$self->{dabaBY}{baBiao}{y}[0] = $self->{ccdBY}{baBiao}{y}[0] + ($self->{daba}{num} - $self->{$self->{Layer}}{yaheN})*$self->{layerBaBiaoJianJu}  + $self->{FB}{value} - ($self->{$self->{Layer}}{yaheN}-1)*$self->{layerBaBiaoJianJu};
		}
		else {
			$self->{dabaBY}{baBiao}{y}[0] = $self->{ccdBY}{baBiao}{y}[0] + ($self->{daba}{num} - $self->{$self->{Layer}}{yaheN})*$self->{layerBaBiaoJianJu}  + $self->{FB}{value} - ($self->{$self->{Layer}}{yaheN}-1)*$self->{layerBaBiaoJianJu} - 2*$self->{layerBaBiaoJianJu};
		}

		$self->{dabaBY}{baBiao}{y}[1] = $self->{ccdBY}{baBiao}{y}[1] - $self->{FB}{value};
		$self->{dabaBY}{baBiao}{y}[2] = $self->{dabaBY}{baBiao}{y}[1];
	}
	#大于两张core以上的
	else {
		#内层
		if ($self->{Layer} =~ /in/){
			#左下
			$self->{dabaBY}{baBiao}{y}[0] = $self->{PROF}{yCenter} - 189;

			#左上
			$self->{dabaBY}{baBiao}{y}[1] = $self->{PROF}{yCenter} + 146;

			#右上
			$self->{dabaBY}{baBiao}{y}[2] = $self->{PROF}{yCenter} + 146;
		}
		#次外层
		else {
			#左下
			$self->{dabaBY}{baBiao}{y}[0] = $self->{PROF}{yCenter} - 189 - $self->{$self->{Layer}}{yaheN}*$self->{layerBaBiaoJianJu};

			#左上
			$self->{dabaBY}{baBiao}{y}[1] = $self->{PROF}{yCenter} + 146 - $self->{$self->{Layer}}{yaheN}*$self->{layerBaBiaoJianJu};

			#右上
			$self->{dabaBY}{baBiao}{y}[2] = $self->{dabaBY}{baBiao}{y}[1];
		}
	}

	#计算对位
	$self->{dabaBY}{duiWei}{x}[0] = $self->{dabaBY}{baBiao}{x}[0] - 0.5;
	$self->{dabaBY}{duiWei}{x}[1] = $self->{dabaBY}{duiWei}{x}[0];
	$self->{dabaBY}{duiWei}{x}[2] = $self->{dabaBY}{baBiao}{x}[2] + 0.5;

	$self->{dabaBY}{duiWei}{y}[0] = $self->{dabaBY}{baBiao}{y}[0] + $self->{layerBaBiaoJianJu};
	$self->{dabaBY}{duiWei}{y}[1] = $self->{dabaBY}{baBiao}{y}[1] + $self->{layerBaBiaoJianJu};
	$self->{dabaBY}{duiWei}{y}[2] = $self->{dabaBY}{duiWei}{y}[1];

	return 1;
}

#**********************************************
#名字		:CountCCD
#功能		:计算CCD数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountCCD();
#**********************************************
sub CountCCD {
	my $self = shift;

	#$xSel调整现举例
	my $xSel = 9;
	my $ccdX = 8.5;
	#if ($self->{hdi}{jieShu} > 0){
#		$ccdX = 8.5;
#	}
#	else {
#		$ccdX = 12;
#	}

	#计算Symbol
	$self->{ccd}{symbol} = 'h-ccd';

	if ($self->{layerType} eq 'outer'
			and $self->{cfg}{hdi}{zhengFuPian} eq '正片'){
		$self->{ccd}{duiWei}{polarity} = 'negative';
	}
	else {
		$self->{ccd}{duiWei}{polarity} = 'positive';
	}

	if ($self->{Layer} =~ /in/){
		#左下
		$self->{ccd}{baBiao}{x}[0] = $self->{SR}{xmin} + $xSel;
		$self->{ccd}{baBiao}{y}[0] = $self->{SR}{ymin} - $self->{dabaMain}{outer}{toSR} - ($self->{hdi}{jieShu}*0.5);

		#左上
		$self->{ccd}{baBiao}{x}[1] = $self->{SR}{xmin} + $xSel;
		$self->{ccd}{baBiao}{y}[1] = $self->{SR}{ymax} + $self->{dabaMain}{outer}{toSR} + ($self->{hdi}{jieShu}*0.5);

		#x轴方向由于防呆，在计算打靶的时候已经计算完毕
		#右上
		$self->{ccd}{baBiao}{x}[2] = $self->{ccd}{x2FangDai} + ($self->{daba}{num} - $self->{$self->{Layer}}{yaheN})*$self->{layerBaBiaoJianJu};
		$self->{ccd}{baBiao}{y}[2] = $self->{ccd}{baBiao}{y}[1];

		#右下
		#$self->{ccd}{baBiao}{x}[3] = $self->{ccd}{x3FangDai} - ($self->{$self->{Layer}}{yaheN} - 1) * 10;
		$self->{ccd}{baBiao}{x}[3] = $self->{SR}{xmax} - $ccdX;
		$self->{ccd}{baBiao}{y}[3] = $self->{ccd}{baBiao}{y}[0];

	}
	else {
		#左下
		$self->{ccd}{baBiao}{x}[0] = $self->{SR}{xmin} + $xSel + $self->{$self->{Layer}}{yaheN} * $self->{layerBaBiaoJianJu};
		$self->{ccd}{baBiao}{y}[0] = $self->{SR}{ymin} - $self->{dabaMain}{outer}{toSR} - ($self->{hdi}{jieShu}*0.5) + ($self->{$self->{Layer}}{yaheN})*0.5;

		#左上
		$self->{ccd}{baBiao}{x}[1] = $self->{SR}{xmin} + $xSel + $self->{$self->{Layer}}{yaheN} * $self->{layerBaBiaoJianJu};
		$self->{ccd}{baBiao}{y}[1] = $self->{SR}{ymax} + $self->{dabaMain}{outer}{toSR} + ($self->{hdi}{jieShu}*0.5) - ($self->{$self->{Layer}}{yaheN})*0.5;

		#x轴方向由于防呆，在计算打靶的时候已经计算完毕
		#右上
		$self->{ccd}{baBiao}{x}[2] = $self->{ccd}{x2FangDai} + ($self->{daba}{num} - $self->{$self->{Layer}}{yaheN} - 1)*$self->{layerBaBiaoJianJu};
		$self->{ccd}{baBiao}{y}[2] = $self->{ccd}{baBiao}{y}[1];

		#右下
		$self->{ccd}{baBiao}{x}[3] = $self->{SR}{xmax} - $ccdX - ($self->{$self->{Layer}}{yaheN}) * $self->{layerBaBiaoJianJu};
		$self->{ccd}{baBiao}{y}[3] = $self->{ccd}{baBiao}{y}[0];
	}

	#计算标识
	$self->{ccd}{biaoShi}{x}[0] = $self->{ccd}{baBiao}{x}[0];
	$self->{ccd}{biaoShi}{x}[1] = $self->{ccd}{baBiao}{x}[1];
	$self->{ccd}{biaoShi}{x}[2] = $self->{ccd}{baBiao}{x}[2];
	$self->{ccd}{biaoShi}{x}[3] = $self->{ccd}{baBiao}{x}[3];

	my $yBiaoShi = 4.7;
	$self->{ccd}{biaoShi}{y}[0] = $self->{ccd}{baBiao}{y}[0] - $yBiaoShi;
	$self->{ccd}{biaoShi}{y}[1] = $self->{ccd}{baBiao}{y}[1] + $yBiaoShi;
	$self->{ccd}{biaoShi}{y}[2] = $self->{ccd}{baBiao}{y}[2] + $yBiaoShi;
	$self->{ccd}{biaoShi}{y}[3] = $self->{ccd}{baBiao}{y}[3] - $yBiaoShi;

	if ($self->{Layer} =~ /in/){
		$self->{ccd}{biaoShi}{symbol} = "zh-0".$self->{$self->{Layer}}{yaheN};
		if ($self->{ERP}{isInnerHT} eq "yes") {
			$self->{ccd}{biaoShi}{symbol} = "zh-0".$self->{$self->{Layer}}{yaheN} . "-ht";
		}
		
	}
	else {
		my $num = $self->{$self->{Layer}}{yaheN} + 1;
		$self->{ccd}{biaoShi}{symbol} = "zh-0". $num;
		if ($self->{ERP}{isOuterHT} eq "yes") {
			$self->{ccd}{biaoShi}{symbol} = "zh-0". $num . "-ht";
		}
		
	}

	#计算对位
	$self->{ccd}{duiWei}{x}[0] = $self->{SR}{xmin} + $xSel + ($self->{$self->{Layer}}{yaheN} - 1) * $self->{layerBaBiaoJianJu};
	$self->{ccd}{duiWei}{x}[1] = $self->{ccd}{duiWei}{x}[0];
	$self->{ccd}{duiWei}{y}[0] = $self->{SR}{ymin} - $self->{dabaMain}{outer}{toSR} - ($self->{hdi}{jieShu}*0.5) + ($self->{$self->{Layer}}{yaheN} - 1)*0.5;
	$self->{ccd}{duiWei}{y}[1] = $self->{SR}{ymax} + $self->{dabaMain}{outer}{toSR} + ($self->{hdi}{jieShu}*0.5) - ($self->{$self->{Layer}}{yaheN} - 1)*0.5;
	$self->{ccd}{duiWei}{x}[2] = $self->{ccd}{x2FangDai} + ($self->{daba}{num} - $self->{$self->{Layer}}{yaheN})*$self->{layerBaBiaoJianJu};
	$self->{ccd}{duiWei}{y}[2] = $self->{ccd}{duiWei}{y}[1];

	$self->{ccd}{duiWei}{x}[3] = $self->{SR}{xmax} - $ccdX - ($self->{$self->{Layer}}{yaheN} - 1) * $self->{layerBaBiaoJianJu};
	$self->{ccd}{duiWei}{y}[3] = $self->{ccd}{duiWei}{y}[0];

	#计算防呆后，左右剩余值
	if ($self->{residue}{topLeft}){
		return 0;
	}

	$self->{ccd}{topEnd}{x} = $self->{ccd}{x2FangDai} + ($self->{daba}{num} - 1)*$self->{layerBaBiaoJianJu};
	$self->{ccd}{topStart}{x} = $self->{ccd}{x2FangDai};
	$self->{ccd}{bottomEnd}{x} = $self->{SR}{xmax} - 7;
	$self->{residue}{topLeft} = $self->{ccd}{x2FangDai} - $self->{layerMarki}{biTong}{xe};
	$self->{residue}{topRight} = $self->{SR}{xmax} - 23 - $self->{ccd}{baBiao}{x}[2];

	$self->{residue}{bottomLeft} = $self->{daba}{bottomStart}{x} - $self->{PROF}{xCenter};
	$self->{residue}{bottomRight} = ${$self->{erCiYuan}{x}}[3] - $self->{ccd}{x3FangDai};

	return 1;
}


#**********************************************
#名字		:CountCCDBY
#功能		:计算CCDBY数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountCCDBY();
#**********************************************
sub CountCCDBY {
	my $self = shift;
	
	#计算Symbol
	$self->{ccdBY}{symbol} = 'h-ccd-by';

	if ($self->{layerType} eq 'outer'
			and $self->{cfg}{hdi}{zhengFuPian} eq '正片'){
		$self->{ccdBY}{duiWei}{polarity} = 'negative';
	}
	else {
		$self->{ccdBY}{duiWei}{polarity} = 'positive';
	}

	my	$ys;
	if ($self->{hdi}{jieShu} == 0){
		$ys = 10;
	}
	else {
		$ys = 7;
	}

	if ($self->{Layer} =~ /in/){
		#左下
		$self->{ccdBY}{baBiao}{x}[0] = $self->{SR}{xmin} - $self->{dabaSub}{outer}{toSR} - ($self->{hdi}{jieShu}*0.5) - ($self->{$self->{Layer}}{yaheN} - 1)*0.5;
		$self->{ccdBY}{baBiao}{y}[0] = $self->{SR}{ymin} + $self->{laser}{length} + $ys;

		#左上
		$self->{ccdBY}{baBiao}{x}[1] = $self->{SR}{xmin} - $self->{dabaSub}{outer}{toSR} - ($self->{hdi}{jieShu}*0.5) - ($self->{$self->{Layer}}{yaheN} - 1)*0.5;
		$self->{ccdBY}{baBiao}{y}[1] = $self->{SR}{ymax} - $self->{laser}{length} - $ys;

		#x轴方向由于防呆，在计算打靶的时候已经计算完毕
		#右上
		$self->{ccdBY}{baBiao}{x}[2] = $self->{SR}{xmax} + $self->{dabaSub}{outer}{toSR} + ($self->{hdi}{jieShu}*0.5) - ($self->{$self->{Layer}}{yaheN} - 1)*0.5;
		$self->{ccdBY}{baBiao}{y}[2] = $self->{SR}{ymax} - $self->{laser}{length} - $ys;

#	#右下
		$self->{ccdBY}{baBiao}{x}[3] = $self->{SR}{xmax} + $self->{dabaSub}{outer}{toSR} + ($self->{hdi}{jieShu}*0.5) - ($self->{$self->{Layer}}{yaheN} - 1)*0.5;
		#13,丝印孔高度
		$self->{ccdBY}{baBiao}{y}[3] = ${$self->{screenHole}{y}}[3] + $self->{laser}{length} + 2 + 2.5 + 1;
	}
	else {
		#左下
		$self->{ccdBY}{baBiao}{x}[0] = $self->{SR}{xmin} - $self->{dabaSub}{outer}{toSR} - ($self->{hdi}{jieShu})*0.5 + ($self->{$self->{Layer}}{yaheN})*0.5;
		$self->{ccdBY}{baBiao}{y}[0] = $self->{SR}{ymin} + $self->{laser}{length} + $ys + $self->{$self->{Layer}}{yaheN}*$self->{layerBaBiaoJianJu};

		#左上
		$self->{ccdBY}{baBiao}{x}[1] = $self->{ccdBY}{baBiao}{x}[0];
		$self->{ccdBY}{baBiao}{y}[1] = $self->{SR}{ymax} - $self->{laser}{length} - $ys - $self->{$self->{Layer}}{yaheN}*$self->{layerBaBiaoJianJu};

		#x轴方向由于防呆，在计算打靶的时候已经计算完毕
		#右上
		$self->{ccdBY}{baBiao}{x}[2] = $self->{SR}{xmax} + $self->{dabaSub}{outer}{toSR} + ($self->{hdi}{jieShu}*0.5) - ($self->{$self->{Layer}}{yaheN})*0.5;
		$self->{ccdBY}{baBiao}{y}[2] = $self->{ccdBY}{baBiao}{y}[1];

#	#右下
		$self->{ccdBY}{baBiao}{x}[3] = $self->{ccdBY}{baBiao}{x}[2];
		#13,丝印孔高度, 2为半个镭射，2.5为半个孔
		$self->{ccdBY}{baBiao}{y}[3] = ${$self->{screenHole}{y}}[3] + $self->{laser}{length} + 2 + 2.5 + $self->{$self->{Layer}}{yaheN}*$self->{layerBaBiaoJianJu} + 1;

	}

	#计算对位
	$self->{ccdBY}{duiWei}{x}[0] = $self->{ccdBY}{baBiao}{x}[0] - 0.5;
	$self->{ccdBY}{duiWei}{x}[1] = $self->{ccdBY}{baBiao}{x}[1] - 0.5;
	$self->{ccdBY}{duiWei}{y}[0] = $self->{ccdBY}{baBiao}{y}[0] - $self->{layerBaBiaoJianJu};
	$self->{ccdBY}{duiWei}{y}[1] = $self->{ccdBY}{baBiao}{y}[1] + $self->{layerBaBiaoJianJu};
	$self->{ccdBY}{duiWei}{x}[2] = $self->{ccdBY}{baBiao}{x}[2] + 0.5;
	$self->{ccdBY}{duiWei}{y}[2] = $self->{ccdBY}{duiWei}{y}[1];
	$self->{ccdBY}{duiWei}{x}[3] = $self->{ccdBY}{baBiao}{x}[3] + 0.5;
	$self->{ccdBY}{duiWei}{y}[3] = $self->{ccdBY}{baBiao}{y}[3] - $self->{layerBaBiaoJianJu};

	return 1;
}

#**********************************************
#名字		:CountCCDDrill
#功能		:计算CCD孔数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountCCDDrill();
#**********************************************
sub CountCCDDrill {
	my $self = shift;

	if (($self->{hdi}{jieShu} == 0 and $self->{hdi}{jia} eq 'no')
			and ($self->{layerType} eq 'via' or $self->{layerType} eq 'sm')){
		$self->{addCCDDrill} = 'yes';
	}
	elsif ($self->{hdi}{jieShu} > 0
			and $self->{layerType} eq 'bury') {
		#截取该埋孔的第二个字符
		my $layerNum = substr ("$self->{Layer}", 1, 1);

		#算出信号层
		my $layer = "sec"."$layerNum"."t";

		#算出第几次压合
		my $yaHeNum = $self->{$layer}{yaheN};

		if ($yaHeNum == 1){
			$self->{addCCDDrill} = 'yes';
		}
		else {
			$self->{addCCDDrill} = 'no';
		}
	}
	else {
		$self->{addCCDDrill} = 'no';
	}

	my $xSel = 9;
	my $ccdX = 8.5;

	if($self->{addCCDDrill} eq 'yes') {
		#计算symbol
		if ($self->{layerType} eq 'via'
				or $self->{layerType} eq 'bury'){
			$self->{ccd}{drill}{symbol} = 'r2000';
		}
		else {
			$self->{ccd}{drill}{symbol} = 'r3403.19';
		}

		#左下
		$self->{ccd}{drill}{x}[0] = $self->{SR}{xmin} + $xSel;
		$self->{ccd}{drill}{y}[0] = $self->{SR}{ymin} - $self->{dabaMain}{outer}{toSR} - ($self->{hdi}{jieShu}*0.5);


		#左上
		$self->{ccd}{drill}{x}[1] = $self->{ccd}{drill}{x}[0];
		$self->{ccd}{drill}{y}[1] = $self->{SR}{ymax} + $self->{dabaMain}{outer}{toSR} + ($self->{hdi}{jieShu}*0.5);

		#x轴方向由于防呆，在计算打靶的时候已经计算完毕
		#右上
		$self->{ccd}{drill}{x}[2] = $self->{ccd}{x2FangDai} + ($self->{daba}{num} - 1)*$self->{layerBaBiaoJianJu};
		$self->{ccd}{drill}{y}[2] = $self->{ccd}{drill}{y}[1];

		#右下
		$self->{ccd}{drill}{x}[3] = $self->{SR}{xmax} - $ccdX;
		$self->{ccd}{drill}{y}[3] = $self->{ccd}{drill}{y}[0];

		#备用
		my $ys;
		if ($self->{hdi}{jieShu} == 0){
			$ys = 10;
		}
		else {
			$ys = 7;
		}
		#左下
		$self->{ccd}{drill}{x}[4] = $self->{SR}{xmin} - $self->{dabaSub}{outer}{toSR} - ($self->{hdi}{jieShu}*0.5);
		$self->{ccd}{drill}{y}[4] = $self->{SR}{ymin} + $self->{laser}{length} + $ys;

		#左上
		$self->{ccd}{drill}{x}[5] = $self->{SR}{xmin} - $self->{dabaSub}{outer}{toSR} - ($self->{hdi}{jieShu}*0.5);
		$self->{ccd}{drill}{y}[5] = $self->{SR}{ymax} - $self->{laser}{length} - $ys;

		#x轴方向由于防呆，在计算打靶的时候已经计算完毕
		#右上
		$self->{ccd}{drill}{x}[6] = $self->{SR}{xmax} + $self->{dabaSub}{outer}{toSR} + ($self->{hdi}{jieShu}*0.5);
		$self->{ccd}{drill}{y}[6] = $self->{SR}{ymax} - $self->{laser}{length} - $ys;

		#右下
		$self->{ccd}{drill}{x}[7] = $self->{SR}{xmax} + $self->{dabaSub}{outer}{toSR} + ($self->{hdi}{jieShu}*0.5);
		#13,丝印孔高度
		$self->{ccd}{drill}{y}[7] = ${$self->{screenHole}{y}}[3] + $self->{laser}{length} + 2 + 2.5 + $self->{$self->{Layer}}{yaheN}*$self->{layerBaBiaoJianJu} + 1;
	}

	return 1;
}

#**********************************************
#名字		:CountTongQiePian
#功能		:计算通孔切片孔数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountTongQiePian();
#**********************************************
sub CountTongQiePianOld {
	my $self = shift;

	#计算symbol
	if ($self->{layerType} eq 'inner'
			or $self->{layerType} eq 'second'
			or $self->{layerType} eq 'outer') {
		$self->{tong}{qiePian}{symbol} = 'h-tong-qiepian-pad';
		if ($self->{ERP}{isInnerHT} eq "yes") {
			$self->{tong}{qiePian}{symbol} = 'h-tong-qiepian-pad-ht';
		}
		
	}
	elsif ($self->{layerType} eq 'sm') {
		$self->{tong}{qiePian}{symbol} = 'h-tong-qiepian-fanghan';
	}
	elsif ($self->{layerType} eq 'via'){
		$self->{tong}{qiePian}{symbol} = 'r'.$self->{cfg}{minVia};
	}

	if ($self->{layerType} ne 'via'){
		$self->{tong}{qiePian}{nx} = 1,
		$self->{tong}{qiePian}{ny} = 1,
		$self->{tong}{qiePian}{dx} = 0,
		$self->{tong}{qiePian}{dy} = 0,
	}
	else {
		if ($self->{liuBian}{xSize} > $self->{liuBian}{ySize}
				or $self->{hdi}{jieShu} >= 4){
			$self->{tong}{qiePian}{nx} = 1,
			$self->{tong}{qiePian}{ny} = 6,
			$self->{tong}{qiePian}{dx} = 0,
			$self->{tong}{qiePian}{dy} = -2000,

			$self->{tong}{qiePianR1000}{nx} = 1,
			$self->{tong}{qiePianR1000}{ny} = 2,
			$self->{tong}{qiePianR1000}{dx} = 0,
			$self->{tong}{qiePianR1000}{dy} = -16000,

		}
		else {
			$self->{tong}{qiePian}{nx} = 6,
			$self->{tong}{qiePian}{ny} = 1,
			$self->{tong}{qiePian}{dx} = 2000,
			$self->{tong}{qiePian}{dy} = 0,


			$self->{tong}{qiePianR1000}{nx} = 2,
			$self->{tong}{qiePianR1000}{ny} = 1,
			$self->{tong}{qiePianR1000}{dx} = 16000,
			$self->{tong}{qiePianR1000}{dy} = 0,
		}
	}
	
	#计算坐标
	#如果x的留边大于8，则，按照最后一次锣边为参考点，否则，以SR为参考点
	if ($self->{tong}{qiePian}{x}){
		return 0;
	}

	#放在留边较大的边
	if ($self->{liuBian}{xSize} > $self->{liuBian}{ySize}
			or $self->{hdi}{jieShu} >= 4){
		#if ($self->{liuBian}{ySize} > 11){
			#$self->{tong}{qiePian}{x} = $self->{liuBian}{xmax} - 4;
		#}
		#else {
			$self->{tong}{qiePian}{x} = $self->{SR}{xmax} + 6;
		#}

		$self->{tong}{qiePian}{y} = $self->{PROF}{yCenter} + 75;
		$self->{tong}{qiePian}{angle} = 90;
		$self->{tong}{qiePianR1000}{x} = $self->{tong}{qiePian}{x};
		$self->{tong}{qiePianR1000}{y} = $self->{tong}{qiePian}{y} + 3;
	}
	else {
		#考虑到PE冲孔, 四阶以下的，稍微往前挪点
		#通孔
		#没有镭射靶标，往前挪
		if ($self->{laser}{drillBottom} < 0
				and $self->{laser}{drillTop} < 0){
			$self->{tong}{qiePian}{x} = $self->{SR}{xmin} + 80;
			$self->{tong}{qiePian}{y} = $self->{SR}{ymax} + 6;
			$self->{tong}{qiePian}{angle} = 0;
		}
		#小于4阶的hdi
		else {
			$self->{tong}{qiePian}{x} = $self->{SR}{xmin} + 135;
			$self->{tong}{qiePian}{y} = $self->{SR}{ymax} + 6;
			$self->{tong}{qiePian}{angle} = 0;
		}

		#if ($self->{liuBian}{ySize} > 11){
			#$self->{tong}{qiePian}{y} = $self->{liuBian}{ymax} - 4;
		#}
		#else {
			$self->{tong}{qiePian}{y} = $self->{SR}{ymax} + 6;
		#}

		$self->{tong}{qiePianR1000}{x} = $self->{tong}{qiePian}{x} - 3;
		$self->{tong}{qiePianR1000}{y} = $self->{tong}{qiePian}{y};
	}

	return 1;
}

sub CountTongQiePianRight {
	my $self = shift;

	#计算symbol
	if ($self->{layerType} eq 'inner'
			or $self->{layerType} eq 'second'
			or $self->{layerType} eq 'outer') {
		$self->{tong}{qiePianRight}{symbol} = 'h-tong-qiepian-pad-g';
		#if ($self->{ERP}{isInnerHT} eq "yes" || $self->{ERP}{isOuterHT} eq "yes") {
		#	$self->{tong}{qiePianRight}{symbol} = 'h-tong-qiepian-pad-ht';
		#}
		
	}
	elsif ($self->{layerType} eq 'sm') {
		$self->{tong}{qiePianRight}{symbol} = 'h-tong-qiepian-fanghan';
	}
	elsif ($self->{layerType} eq 'via'){
		$self->{tong}{qiePianRight}{symbol} = 'r'.$self->{cfg}{minVia};
	}

	if ($self->{layerType} ne 'via'){
		$self->{tong}{qiePianRight}{nx} = 1,
		$self->{tong}{qiePianRight}{ny} = 1,
		$self->{tong}{qiePianRight}{dx} = 0,
		$self->{tong}{qiePianRight}{dy} = 0,
	}
	else {
			$self->{tong}{qiePianRight}{nx} = 1,
			$self->{tong}{qiePianRight}{ny} = 6,
			$self->{tong}{qiePianRight}{dx} = 0,
			$self->{tong}{qiePianRight}{dy} = -2000,

			$self->{tong}{qiePianRightR1000}{nx} = 1,
			$self->{tong}{qiePianRightR1000}{ny} = 2,
			$self->{tong}{qiePianRightR1000}{dx} = 0,
			$self->{tong}{qiePianRightR1000}{dy} = -16000,
	}
	
	#计算坐标
	#如果x的留边大于8，则，按照最后一次锣边为参考点，否则，以SR为参考点
	if ($self->{tong}{qiePianRight}{x}){
		return 0;
	}


	$self->{tong}{qiePianRight}{x} = $self->{SR}{xmax} + 6;

	if (defined($self->{PE_S}{y}))
	{
		$self->{tong}{qiePianRight}{y} = $self->{PE_S}{y}[11] - 106.5;
	}
	else
	{
		$self->{tong}{qiePianRight}{y} = $self->{PROF}{yCenter} + 75;
	}
	$self->{tong}{qiePianRight}{angle} = 90;
	$self->{tong}{qiePianRightR1000}{x} = $self->{tong}{qiePianRight}{x};
	$self->{tong}{qiePianRightR1000}{y} = $self->{tong}{qiePianRight}{y} + 3;

	return 1;
}


sub CountTongQiePianTop {
	my $self = shift;

	#计算symbol
	if ($self->{layerType} eq 'inner'
			or $self->{layerType} eq 'second'
			or $self->{layerType} eq 'outer') {
		$self->{tong}{qiePianTop}{symbol} = 'h-tong-qiepian-pad-g';
		#if ($self->{ERP}{isInnerHT} eq "yes" || $self->{ERP}{isOuterHT} eq "yes") {
		#	$self->{tong}{qiePianTop}{symbol} = 'h-tong-qiepian-pad-ht';
		#}
	}
	elsif ($self->{layerType} eq 'sm') {
		$self->{tong}{qiePianTop}{symbol} = 'h-tong-qiepian-fanghan';
	}
	elsif ($self->{layerType} eq 'via'){
		$self->{tong}{qiePianTop}{symbol} = 'r'.$self->{cfg}{minVia};
	}

	if ($self->{layerType} ne 'via'){
		$self->{tong}{qiePianTop}{nx} = 1,
		$self->{tong}{qiePianTop}{ny} = 1,
		$self->{tong}{qiePianTop}{dx} = 0,
		$self->{tong}{qiePianTop}{dy} = 0,
	}
	else {
			$self->{tong}{qiePianTop}{nx} = 6,
			$self->{tong}{qiePianTop}{ny} = 1,
			$self->{tong}{qiePianTop}{dx} = 2000,
			$self->{tong}{qiePianTop}{dy} = 0,


			$self->{tong}{qiePianTopR1000}{nx} = 2,
			$self->{tong}{qiePianTopR1000}{ny} = 1,
			$self->{tong}{qiePianTopR1000}{dx} = 16000,
			$self->{tong}{qiePianTopR1000}{dy} = 0,
	}
	
	#计算坐标
	#如果x的留边大于8，则，按照最后一次锣边为参考点，否则，以SR为参考点
	if ($self->{tong}{qiePianTop}{x}){
		return 0;
	}


	$self->{tong}{qiePianTop}{x} = $self->{SR}{xmax} - 90;
	$self->{tong}{qiePianTop}{y} = $self->{SR}{ymax} + 6;
	$self->{tong}{qiePianTop}{angle} = 0;

	$self->{tong}{qiePianTop}{y} = $self->{SR}{ymax} + 6;
	#}

	$self->{tong}{qiePianTopR1000}{x} = $self->{tong}{qiePianTop}{x} - 3;
	$self->{tong}{qiePianTopR1000}{y} = $self->{tong}{qiePianTop}{y};


	return 1;
}

#**********************************************
#名字		:CountBuryQiePian
#功能		:计算埋孔切片孔
#参数		:无
#返回值		:1
#使用例子	:$self->CountBuryQiePian();
#**********************************************
sub CountBuryQiePian {
	my $self = shift;

	if ($self->{layerType} eq 'second'
			or $self->{layerType} eq 'inner'){
		$self->{bury}{qiePian}{symbol} = 'h-bury-qiepian-pad';
	}
	else {
		$self->{bury}{qiePian}{symbol} = "r$self->{cfg}{minBury}";
	}

	#计算坐标
	if ($self->{bury}{qiePian}{0}{x}){
		return 0;
	}

	foreach my $i (0..$#{$self->{bury}{layer}}){
		#放在留边较大的边
		#x留边加大，放在长方向，右边
		if ($self->{liuBian}{xSize} > $self->{liuBian}{ySize}
				or $self->{hdi}{jieShu} >= 4){
			#if ($self->{liuBian}{ySize} > 11){
				#$self->{bury}{qiePian}{$i}{x} = $self->{liuBian}{xmax} - 4;
			#}
			#else {
				$self->{bury}{qiePian}{$i}{x} = $self->{SR}{xmax} + 6;
			#}

			#17为通孔切片孔的长度，14为埋孔切片孔长度，5为两通孔的间距值
			$self->{bury}{qiePian}{$i}{y} = $self->{tong}{qiePian}{y} - 17 - 5 - (14+5)*$i;
			$self->{bury}{qiePian}{angle} = 90;
			$self->{bury}{qiePian}{nx} = 1,
			$self->{bury}{qiePian}{ny} = 6,
			$self->{bury}{qiePian}{dx} = 0,
			$self->{bury}{qiePian}{dy} = -2000,
		}
		else {
			#考虑到PE冲孔, 四阶以下的，稍微往前挪点
			#17为通孔切片孔的长度，14为埋孔切片孔长度，5为两通孔的间距值
			$self->{bury}{qiePian}{$i}{x} = $self->{tong}{qiePian}{x} + 17 + 5 + (14+5)*$i;
			#if ($self->{liuBian}{ySize} > 11){
				#$self->{bury}{qiePian}{$i}{y} = $self->{liuBian}{ymax} - 4;
			#}
			#else {
				$self->{bury}{qiePian}{$i}{y} = $self->{SR}{ymax} + 6;
			#}

			$self->{bury}{qiePian}{angle} = 0;
			$self->{bury}{qiePian}{nx} = 6,
			$self->{bury}{qiePian}{ny} = 1,
			$self->{bury}{qiePian}{dx} = 2000,
			$self->{bury}{qiePian}{dy} = 0,
		}
	}

	return 1;
}



#**********************************************
#名字		:CountLaserQiePian
#功能		:计算镭射切片数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountLaserQiePian();
#**********************************************
sub CountLaserQiePian {
	my $self = shift;

	#计算symbol
	if ($self->{layerType} eq 'second'
			or $self->{layerType} eq 'outer'){
		$self->{laser}{qiePian}{symbol} = 'h-laser-qiepian-pad';
		@{$self->{laser}{qiePian}{nx}} = qw(1 1 1 1);
		@{$self->{laser}{qiePian}{ny}} = qw(1 1 1 1);
		@{$self->{laser}{qiePian}{dx}} = qw(0 0 0 0);
		@{$self->{laser}{qiePian}{dy}} = qw(0 0 0 0);
	}
	elsif ($self->{layerType} eq 'laser') {
		$self->{laser}{qiePian}{symbol} = 'r100';
		@{$self->{laser}{qiePian}{nx}} = qw(7 2 7 2);
		@{$self->{laser}{qiePian}{ny}} = qw(2 7 2 7);
		@{$self->{laser}{qiePian}{dx}} = qw(2000 1000 2000 1000);
		@{$self->{laser}{qiePian}{dy}} = qw(-1000 2000 -1000 2000);
	}
	elsif ($self->{layerType} eq 'sm') {
		$self->{laser}{qiePian}{symbol} = 'h-laser-qiepian-fanghan';
		@{$self->{laser}{qiePian}{nx}} = qw(1 1 1 1);
		@{$self->{laser}{qiePian}{ny}} = qw(1 1 1 1);
		@{$self->{laser}{qiePian}{dx}} = qw(0 0 0 0);
		@{$self->{laser}{qiePian}{dy}} = qw(0 0 0 0);
	}

	#计算坐标
	if ($self->{laser}{qiePian}{x}){
		return 0;
	}

	my $ys;
	$ys = 4;
	$self->{laser}{qiePian}{x}[0] = $self->{SR}{xmin} + 143;
	$self->{laser}{qiePian}{y}[0] = $self->{liuBian}{ymin} + $ys;

	#$self->{laser}{qiePian}{x}[1] = $self->{SR}{xmax} + 6.5;
	$self->{laser}{qiePian}{x}[1] = $self->{SR}{xmax} + 6;
	$self->{laser}{qiePian}{y}[1] = $self->{PROF}{yCenter} - 77 - 36;

	$self->{laser}{qiePian}{angle}[0] = 0;
	$self->{laser}{qiePian}{angle}[1] = 270;

	#如果镭射2层以上，则为2个
	if ($#{$self->{laser}{drillTop}} > 0
			or $#{$self->{laser}{drillBottom}} > 0){
		$self->{laser}{qiePian}{x}[2] = $self->{laser}{qiePian}{x}[0] + 16 + 2;
		$self->{laser}{qiePian}{y}[2] = $self->{laser}{qiePian}{y}[0];

		$self->{laser}{qiePian}{x}[3] = $self->{laser}{qiePian}{x}[1];
		$self->{laser}{qiePian}{y}[3] = $self->{laser}{qiePian}{y}[1] + 16 + 2;

		$self->{laser}{qiePian}{angle}[2] = 0;
		$self->{laser}{qiePian}{angle}[3] = 270;
	}

	return 1;
}

#**********************************************
#名字		:CountLaserCeShi
#功能		:计算镭射测试数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountLaserCeShi();
#**********************************************
sub CountLaserCeShi {
	my $self = shift;

	#计算symbol
	if ($self->{$self->{laser}{ceShi}{symbol}}){
		return 0;
	}

	$self->{laser}{ceShi}{symbol}[0] = 'h-cupon_l';
	$self->{laser}{ceShi}{symbol}[1] = 'h-cupon_ud';
	$self->{laser}{ceShi}{symbol}[2] = "r$self->{cfg}{minLaser}";
	$self->{laser}{ceShi}{symbol}[3] = "h-cupon_sm";

	#计算坐标
	my $xs;
	if ($self->{liuBian}{xSize} > 10) {
		$xs = 4;
	}
	else {
		$xs = 1.8;
	}

	$self->{laser}{ceShi}{x}[0] = $self->{liuBian}{xmax} - $xs;
	$self->{laser}{ceShi}{x}[1] = $self->{liuBian}{xmax} - $xs - 2;

	$self->{laser}{ceShi}{y} = $self->{PROF}{yCenter} - 74;

	return 1;
}

#**********************************************
#名字		:CountFangHanCCD
#功能		:计算防焊CCD数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountFangHanCCD();
#**********************************************
sub CountFangHanCCD {
	my $self = shift;

	#计算symbol
	if ($self->{layerType} eq 'outer'){
		$self->{fangHanCCD}{symbol} = 'wcfh-ccd';
	}
	elsif ($self->{layerType} eq 'sm'){
		$self->{fangHanCCD}{symbol} = 'fh-ccd';
	}

	#计算坐标
	my $xSel = 6;
	
	#通孔板
	if ($self->{hdi}{jieShu} == 0){
		${$self->{fangHanCCD}{x}}[0] = $self->{SR}{xmin} + $xSel + $self->{ccd}{length} + 3;
	}
	#hdi板
	else {
		${$self->{fangHanCCD}{x}}[0] = $self->{SR}{xmin} + $xSel + 3;
	}
	${$self->{fangHanCCD}{x}}[1] = ${$self->{fangHanCCD}{x}}[0];

	#通孔板
	if ($self->{hdi}{jieShu} == 0){
		${$self->{fangHanCCD}{x}}[2] = $self->{ccd}{x2FangDai} + 7;
		#假hdi板，向左移动
		#if ($self->{})
		if ($#{$self->{laser}{drillTop}} < 0
				and $#{$self->{laser}{drillBottom}} < 0){
			${$self->{fangHanCCD}{x}}[3] = $self->{SR}{xmax} - $self->{ccd}{length} - 8;
		}
		else {
			${$self->{fangHanCCD}{x}}[3] = $self->{SR}{xmax} - 8.5 - $self->{daba}{size}/2 - $self->{laser}{length} - 3.5;
		}
	}

	#hdi板
	else {
		${$self->{fangHanCCD}{x}}[2] = $self->{ccd}{x2FangDai} + $self->{ccd}{length} - 5.5;
		${$self->{fangHanCCD}{x}}[3] = $self->{SR}{xmax} -  8.5;
	}

	my $ys = 3.5;
	if ($self->{hdi}{jieShu} >= 4){
		$ys = 17;
	}

	${$self->{fangHanCCD}{y}}[0] = $self->{SR}{ymin} - $ys;
	${$self->{fangHanCCD}{y}}[1] = $self->{SR}{ymax} + $ys;
	${$self->{fangHanCCD}{y}}[2] = $self->{SR}{ymax} + $ys;
	${$self->{fangHanCCD}{y}}[3] = $self->{SR}{ymin} - $ys;

	return 1;
}

#**********************************************
#名字		:CountFangHanCCD
#功能		:计算防焊CCD数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountFangHanCCD();
#**********************************************
sub CountFangHanCCDBY {
	my $self = shift;
	
	#计算symbol
	if ($self->{layerType} eq 'outer'){
		$self->{fangHanCCDBY}{symbol} = 'wcfh-ccd';
	}
	elsif ($self->{layerType} eq 'sm'){
		$self->{fangHanCCDBY}{symbol} = 'fh-ccd';
	}

	#计算坐标
	my $xs = 4.5;

	if ($self->{fangHanCCDBY}{x}){
		return 0;
	}
	${$self->{fangHanCCDBY}{x}}[0] = $self->{SR}{xmin} - $xs;
	${$self->{fangHanCCDBY}{x}}[1] = ${$self->{fangHanCCDBY}{x}}[0];

	${$self->{fangHanCCDBY}{x}}[2] = $self->{SR}{xmax} + $xs;
	${$self->{fangHanCCDBY}{x}}[3] = ${$self->{fangHanCCDBY}{x}}[2];

	my $ys = 180;
	#如果是一阶，则加在熔合块上面
	if (($#{$self->{laser}{drillTop}} <= 0 or $#{$self->{laser}{drillBottom}} <= 0)
			and ($self->{hdi}{jieShu} == 1 or $self->{hdi}{jieShu} == 0)){
		${$self->{fangHanCCDBY}{y}}[0] = $self->{PROF}{yCenter} - $ys;
		${$self->{fangHanCCDBY}{y}}[1] = $self->{PROF}{yCenter} + $ys;
		${$self->{fangHanCCDBY}{y}}[2] = ${$self->{fangHanCCDBY}{y}}[1];
		${$self->{fangHanCCDBY}{y}}[3] = ${$self->{fangHanCCDBY}{y}}[0] - 7.5;
	}
	#如果不是一阶，则加在镭射定位上面
	else {
		${$self->{fangHanCCDBY}{y}}[0] = $self->{SR}{ymin} + 3.5;
		${$self->{fangHanCCDBY}{y}}[1] = $self->{SR}{ymax} - 3.5;
		${$self->{fangHanCCDBY}{y}}[2] = ${$self->{fangHanCCDBY}{y}}[1];
		${$self->{fangHanCCDBY}{y}}[3] = ${$self->{screenHole}{y}}[3] + 8;
	}

	return 1;
}

#**********************************************
#名字		:CountCustomerCode
#功能		:计算客户大妈数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountCustomerCode();
#**********************************************
sub CountCustomerCode {
	my $self = shift;
	
	#计算坐标
	if ($self->{customerCode}{x}){
		return 0;
	}

	$self->{customerCode}{x} = $self->{PROF}{xmax} + 4;
	$self->{customerCode}{y} = $self->{PROF}{xmin} + 107;
	return 1;
}

#**********************************************
#名字		:CountHWSymbol
#功能		:计算华为symbol数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountHWSymbol();
#**********************************************
sub CountHWSymbol {
	my $self = shift;

	#计算坐标
	if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
		$self->{huaWei}{x} = $self->{SR}{xmin} - 3.2;
		$self->{huaWei}{y} = $self->{PROF}{yCenter} + 70 + 27;
		$self->{huaWei}{mirror} = 'no';
	}
	else {
		$self->{huaWei}{x} = $self->{SR}{xmin} - 3.2;
		$self->{huaWei}{y} = $self->{PROF}{yCenter} + 70 + 27;
		$self->{huaWei}{mirror} = 'yes';
	}

	#计算symbol
	if ($self->{huaWei}{symbol}){
		return 0;
	}
	
	if ($self->{cfg}{customerCode}{num} eq '6005'){
		$self->{huaWei}{symbol} = 'hwzd';
	}
	elsif ($self->{cfg}{customerCode}{num} eq '6169' || $self->{cfg}{customerCode}{num} eq '6004'){
		$self->{huaWei}{symbol} = 'hwjs';
	}
	
	return 1;
}

#**********************************************
#名字		:CountOutMark
#功能		:计算out-mark symbol
#参数		:无
#返回值		:1
#使用例子	:$self->CountOutMark();
#**********************************************
sub CountOutMark {
	my $self = shift;

	if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
		$self->{outMark}{mirror} = 'no';
	}
	else {
		$self->{outMark}{mirror} = 'yes';
	}
	
	#计算坐标
	if ($self->{outMark}{x}){
		return 0;
	}
	

	if ($self->{hdi}{jieShu} >= 4
			and $self->{liuBian}{xSize} > 19){
		$self->{outMark}{x} = $self->{SR}{xmax} + 14.8;
	}
	else {
		$self->{outMark}{x} = $self->{SR}{xmax} + 5.7;
	}

	$self->{outMark}{y} = $self->{PROF}{yCenter} - 138;

	return 1;
}

#**********************************************
#名字		:CountAuthSymbol
#功能		:计算Auth Symbol 数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountAuthSymbol();
#**********************************************
sub CountAuthSymbol {
	my $self = shift;

	#计算镜像
	if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
		$self->{authText}{mirror} = 'no';
	}
	else {
		$self->{authText}{mirror} = 'yes';
	}

	#计算symbol
	if ($self->{layerType} eq 'outer'){
		$self->{authPad}{symbol} = 'hc-authpad';
	}
	elsif ($self->{layerType} eq 'sm'){
		$self->{authPad}{symbol} = 'hc-authpadmask';
	}

	if ($self->{authPad}{x}){
		return 0;
	}

	#计算数据
	#如果大于两张core，放在熔合块上面，否则CCD和打靶的中间，如果是4阶以上，往外放
	my $xs = 4.5;
	$xs = 170;
	if ($self->{coreNum} > 2){
		${$self->{authPad}{x}}[0] = $self->{SR}{xmin} - 4.5;
		${$self->{authPad}{y}}[0] = $self->{PROF}{yCenter} - 170;

		${$self->{authPad}{x}}[1] = $self->{SR}{xmax} + 4.5;
		${$self->{authPad}{y}}[1] = $self->{PROF}{yCenter} + 170;
	}
	else {
		if ($self->{hdi}{jieShu} >= 4
				and $self->{liuBian}{xSize} > 15){
			${$self->{authPad}{x}}[0] = $self->{SR}{xmin} - 11.5;
			${$self->{authPad}{y}}[0] = $self->{ccdBY}{baBiao}{y}[0] + ($self->{daba}{num} - $self->{$self->{Layer}}{yaheN})*10  + 10;

			${$self->{authPad}{x}}[1] = $self->{SR}{xmax} + 11.5;
			${$self->{authPad}{y}}[1] = $self->{ccdBY}{baBiao}{y}[1] - ($self->{daba}{num} - $self->{$self->{Layer}}{yaheN})*10  - 10;
		}
		else {
			${$self->{authPad}{x}}[0] = $self->{SR}{xmin} - 4.5;
			${$self->{authPad}{x}}[1] = $self->{SR}{xmax} + 4.5;

			if ($self->{hdi}{jieShu} >= 2){
				${$self->{authPad}{y}}[0] = $self->{SR}{ymin} + $self->{laser}{length} + 12;
				${$self->{authPad}{y}}[1] = $self->{SR}{ymax} - $self->{laser}{length} - 12;
			}
			else {
				${$self->{authPad}{y}}[0] = $self->{PROF}{yCenter} - 170;
				${$self->{authPad}{y}}[1] = $self->{PROF}{yCenter} + 170;
			}

		}
	}


	#计算text symbol数据
	${$self->{authText}{x}}[0] = ${$self->{authPad}{x}}[0] - 2.5;
	${$self->{authText}{y}}[0] = ${$self->{authPad}{y}}[0];

	${$self->{authText}{x}}[1] = ${$self->{authPad}{x}}[1] + 2.5;
	${$self->{authText}{y}}[1] = ${$self->{authPad}{y}}[1];

	@{$self->{authText}{angle}} = qw(90 270);

	return 1;
}

#**********************************************
#名字		:CountBigSurface
#功能		:计算次外层大铜块数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountBigSurface();
#**********************************************
sub CountBigSurface {
	my $self = shift;
	
	#计算坐标
	$self->{bigSurface}{xStart}[0] = $self->{PROF}{xCenter} - 4;
	$self->{bigSurface}{xEnd}[0] = $self->{PROF}{xCenter} - 75;
	$self->{bigSurface}{yStart}[0] = $self->{SR}{ymax} + 2;
	$self->{bigSurface}{yEnd}[0] = $self->{PROF}{ymax} - 3;

	$self->{bigSurface}{xStart}[1] = $self->{PROF}{xCenter} - 4;
	$self->{bigSurface}{xEnd}[1] = $self->{PROF}{xCenter} - 75;
	$self->{bigSurface}{yStart}[1] = $self->{SR}{ymin} - 2;
	$self->{bigSurface}{yEnd}[1] = $self->{PROF}{ymin} + 3;

	return 1;
}

#**********************************************
#名字		:Count3Rect
#功能		:计算外形三个矩形
#参数		:无
#返回值		:1
#使用例子	:$self->Count3Rect();
#**********************************************
sub Count3Rect {
	my $self = shift;
	
	#计算数据
	if ($self->{rect3}{x}){
		return 0;
	}

	$self->{rect3}{x} = $self->{PROF}{xCenter} - 60;
	$self->{rect3}{y} = $self->{SR}{ymax} + 6;

	return 1;
}

#**********************************************
#名字		:CountBuryPianKongDuiWei
#功能		:计算埋孔偏孔对位
#参数		:无
#返回值		:1
#使用例子	:$self->CountBuryPianKongDuiWei();
#**********************************************
sub CountBuryPianKongDuiWei {
	my $self = shift;

	if ($self->{layerType} eq 'second'
			or $self->{layerType} eq 'outer'
			or $self->{layerType} eq 'inner'){
		$self->{pianKong}{bury}{symbol} = 's1016';
	}
	elsif ($self->{layerType} eq 'bury'){
		$self->{pianKong}{bury}{symbol} = 'r500';
	}
	
	#计算坐标
	if ($self->{pianKong}{bury}{x}){
		return 0;
	}

	my $xSel;
	#if (($self->{hdi}{jieShu} < 1 and $self->{liuBian}{xSize} < 30)
	if ($self->{hdi}{jieShu} < 1
			or ($self->{hdi}{jieShu} > 0 and $self->{liuBian}{xSize} < 12)){
		$xSel = 0;
	}
	else {
		$xSel = 0;
	}

	my $xs = 3.8;
	my $ys = 3.5;
	$self->{pianKong}{bury}{x}[0] = $self->{SR}{xmin} + $xSel + $xs;
	$self->{pianKong}{bury}{y}[0] = $self->{SR}{ymin} - $ys;

	$self->{pianKong}{bury}{x}[1] = $self->{pianKong}{bury}{x}[0];
	$self->{pianKong}{bury}{y}[1] = $self->{SR}{ymax} + $ys;

	$self->{pianKong}{bury}{x}[2] = $self->{SR}{xmax} - $xSel - $xs;
	$self->{pianKong}{bury}{y}[2] = $self->{SR}{ymax} + $ys;

	$self->{pianKong}{bury}{x}[3] = $self->{pianKong}{bury}{x}[2];
	$self->{pianKong}{bury}{y}[3] = $self->{SR}{ymin} - $ys;

	@{$self->{pianKong}{bury}{dy}} = qw(-1016 1016 1016 -1016);

	return 1;
}

#**********************************************
#名字		:CountTongPianKongDuiWei1
#功能		:计算偏孔对位第一组
#参数		:无
#返回值		:1
#使用例子	:$self->CountTongPianKongDuiWei1();
#**********************************************
sub CountTongPianKongDuiWei1 {
	my $self = shift;

	if ($self->{layerType} ne  'via'){
		$self->{pianKong}{tong1}{symbol} = 's1270';
	}
	else {
		$self->{pianKong}{tong1}{symbol} = 'r500';
	}

	#计算坐标
	if ($self->{pianKong}{tong1}{x}){
		return 0;
	}

	my $xs = 2.7;
	my $ys = 0.5;

	${$self->{pianKong}{tong1}{x}}[0] = $self->{SR}{xmin} - $xs;
	${$self->{pianKong}{tong1}{y}}[0] = $self->{SR}{ymin} - $ys;

	${$self->{pianKong}{tong1}{x}}[1] = $self->{SR}{xmin} - $xs;
	${$self->{pianKong}{tong1}{y}}[1] = $self->{SR}{ymax} + $ys;

	${$self->{pianKong}{tong1}{x}}[2] = $self->{SR}{xmax} + $xs;
	${$self->{pianKong}{tong1}{y}}[2] = $self->{SR}{ymax} + $ys;

	${$self->{pianKong}{tong1}{x}}[3] = $self->{SR}{xmax} + $xs;
	${$self->{pianKong}{tong1}{y}}[3] = $self->{SR}{ymin} - $ys;

	@{$self->{pianKong}{tong1}{dx}} = qw(-1270 -1270 1270 1270);

	return 1;
}

#**********************************************
#名字		:CountTongPianKongDuiWei2
#功能		:计算埋孔偏孔对位
#参数		:无
#返回值		:1
#使用例子	:$self->CountTongPianKongDuiWei2();
#**********************************************
sub CountTongPianKongDuiWei2 {
	my $self = shift;


	if ($self->{layerType} ne  'via'){
		$self->{pianKong}{tong2}{symbol} = 'r652.4';
	}
	else {
		$self->{pianKong}{tong2}{symbol} = 'r500';
	}
	
	#计算坐标
	if ($self->{pianKong}{tong2}{x}){
		return 0;
	}

	my $xs = 1.27;
	my $ys = 0.508;
	$self->{pianKong}{tong2}{x}[0] = $self->{pianKong}{bury}{x}[0] + $xs;
	$self->{pianKong}{tong2}{y}[0] = $self->{pianKong}{bury}{y}[0] - $ys;

	$self->{pianKong}{tong2}{x}[1] = $self->{pianKong}{tong2}{x}[0];
	$self->{pianKong}{tong2}{y}[1] = $self->{pianKong}{bury}{y}[1];

	$self->{pianKong}{tong2}{x}[2] = $self->{pianKong}{bury}{x}[2] - $xs;
	$self->{pianKong}{tong2}{y}[2] = $self->{pianKong}{bury}{y}[2];

	$self->{pianKong}{tong2}{x}[3] = $self->{pianKong}{bury}{x}[3] - $xs;
	$self->{pianKong}{tong2}{y}[3] = $self->{pianKong}{bury}{y}[3] - $ys;

	@{$self->{pianKong}{tong2}{dy}} = qw(-1270 1270 1270 -1270);

	return 1;
}

#**********************************************
#名字		:CountLaserDuiWei
#功能		:计算镭射对位数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountLaserDuiWei();
#**********************************************
sub CountLaserDuiWei {
	my $self = shift;
	
	if ($self->{layerType} eq  'second' 
			or $self->{layerType} eq 'outer'
			or $self->{layerType} eq 'inner'){
		$self->{pianKong}{laser}{symbol} = 'r328.19';
	}
	elsif ($self->{layerType} eq 'laser') {
		$self->{pianKong}{laser}{symbol} = "r$self->{cfg}{minLaser}";
	}
	
	#计算坐标
	if ($self->{pianKong}{laser}{x}){
		return 0;
	}

	my $ys = 0.635;
	$self->{pianKong}{laser}{x}[0] = $self->{pianKong}{tong2}{x}[0];
	$self->{pianKong}{laser}{y}[0] = $self->{pianKong}{tong2}{y}[0] + $ys;

	$self->{pianKong}{laser}{x}[1] = $self->{pianKong}{laser}{x}[0];
	$self->{pianKong}{laser}{y}[1] = $self->{pianKong}{tong2}{y}[1] + $ys;

	$self->{pianKong}{laser}{x}[2] = $self->{pianKong}{tong2}{x}[2];
	$self->{pianKong}{laser}{y}[2] = $self->{pianKong}{tong2}{y}[2] + $ys;

	$self->{pianKong}{laser}{x}[3] = $self->{pianKong}{tong2}{x}[3];
	$self->{pianKong}{laser}{y}[3] = $self->{pianKong}{tong2}{y}[3] + $ys;

	@{$self->{pianKong}{laser}{dy}} = qw(-1270 1270 1270 -1270);

	return 1;
}

#**********************************************
#名字		:CountMangKongDuiWei
#功能		:计算盲孔对位数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountMangKongDuiWei();
#**********************************************
sub CountMangKongDuiWei {
	my $self = shift;

	#计算symbol
	if ($self->{layerType} eq 'laser'){
		$self->{mangKongDuiWei}{symbol} = "r$self->{cfg}{minLaser}";
	}
	elsif ($self->{layerType} eq 'outer'
			or $self->{layerType} eq 'second'){
		$self->{mangKongDuiWei}{symbol} = "h-mangkongduiwei";
	}
	
	#计算坐标
	if ($self->{mangKongDuiWei}{x}){
		return 0;
	}

	$self->{mangKongDuiWei}{x}[0] = $self->{liuBian}{xmin} + 1;
	$self->{mangKongDuiWei}{y}[0] = $self->{liuBian}{ymin} + 1;

	$self->{mangKongDuiWei}{x}[1] = $self->{liuBian}{xmin} + 1;
	$self->{mangKongDuiWei}{y}[1] = $self->{liuBian}{ymax} - 3.5;

	$self->{mangKongDuiWei}{x}[2] = $self->{liuBian}{xmax} - 3.5;
	$self->{mangKongDuiWei}{y}[2] = $self->{liuBian}{ymax} - 3.5;

	$self->{mangKongDuiWei}{x}[3] = $self->{liuBian}{xmax} - 3.5;
	$self->{mangKongDuiWei}{y}[3] = $self->{liuBian}{ymin} + 1;

	return 1;
}

#**********************************************
#名字		:CountBaKongJianTou
#功能		:添加靶孔箭头
#参数		:无
#返回值		:1
#使用例子	:$self->CountBaKongJianTou();
#**********************************************
sub CountBaKongJianTou {
	my $self = shift;
	
	if ($self->{baKongJianTou}{x}){
		return 0;
	}
	if ($self->{hdi}{jieShu} > 2) {
		$self->{baKongJianTou}{x} = $self->{daba}{baBiao}{x}[0] + $self->{hdi}{jieShu}*($self->{layerBaBiaoJianJu}) + 8.5 + ($self->{hdi}{jieShu} - 2)*$self->{laser}{cuoBa};
	}
	else {
		$self->{baKongJianTou}{x} = $self->{daba}{baBiao}{x}[0] + $self->{hdi}{jieShu}*($self->{layerBaBiaoJianJu}) + 7;
	}
	$self->{baKongJianTou}{y} = $self->{daba}{baBiao}{y}[0];

	return 1;
}

#**********************************************
#名字		:CountJsSymbol
#功能		:计算js symbol数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountJsSymbol();
#**********************************************
sub CountJsSymbol {
	my $self = shift;
	
	#计算坐标
	$self->{jsSymbol}{x} = $self->{PROF}{xmax} + 5;
	$self->{jsSymbol}{y} = $self->{PROF}{ymax} - 30;

	return 1;
}

#**********************************************
#名字		:CountFdjtSymbol
#功能		:计算防呆箭头数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountFdjtSymbol();
#**********************************************
sub CountFdjtSymbol {
	my $self = shift;
	
	$self->{fdjt}{x}[0] = $self->{PROF}{xmax} * 0.2;
	$self->{fdjt}{x}[1] = $self->{fdjt}{x}[0];

	$self->{fdjt}{y}[0] = $self->{PROF}{ymax} + 3.1;
	$self->{fdjt}{y}[1] = -12;

	return 1;
}

#**********************************************
#名字		:CountLayerDuiWei
#功能		:计算层别对位数据
#参数		:无
#返回值		:1
#使用例子	:$h->CountLayerDuiWei();
#**********************************************
sub CountLayerDuiWei {
	my $self = shift;
	
	$self->INFO(entity_type => 'layer',
			entity_path => "$self->{Job}/$self->{Step}/$self->{Layer}",
			data_type => 'TYPE');
	if ($self->{doinfo}{gTYPE} eq 'power_ground')
	{
		$self->{layer}{duiWei}{polarity} = 'negative';
	}
	else {
		$self->{layer}{duiWei}{polarity} = 'positive';
	}

	#计算symbol
	if ($self->{layerType} eq 'inner')
	{
		$self->{layer}{duiWei}{workLayer} = "___tmp___i";
	}
	elsif($self->{layerType} eq 'outer')
	{
		if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
			$self->{layer}{duiWei}{workLayer} = "___tmp___t";
		}
		else {
			$self->{layer}{duiWei}{workLayer} = "___tmp___b";
		}
		
	}
	elsif ($self->{layerType} eq 'sm')
	{
		$self->{layer}{duiWei}{workLayer} = "___tmp___s";
	}
	elsif ($self->{layerType} eq 'via' && $self->{Layer} =~ /^d1\d+$/i)
	{
		$self->{layer}{duiWei}{workLayer} = "___tmp___d";
	}
	#计算坐标

	#
	unless ($self->{layer}{duiWei}{workLayer})
	{
		return 0;
	}
	
	if ($self->{layerType} eq 'inner')
	{
		my $layerIndex = $self->{Layer} ;
		$layerIndex =~ s/^(in|l)(\d+)[-_]?[tb]$/$2/g;
		
		$self->{layer}{duiWei}{firstX}[0] = $self->{layer}{duiWei}{x}[0] - ($layerIndex - 2) * 1.1;
		$self->{layer}{duiWei}{firstY}[0] = $self->{layer}{duiWei}{y}[0];
	
		$self->{layer}{duiWei}{firstX}[1] = $self->{layer}{duiWei}{x}[1] + ($layerIndex - 2) * 1.1;
		$self->{layer}{duiWei}{firstY}[1] = $self->{layer}{duiWei}{y}[1];
		
		$self->{layer}{duiWei}{firstX}[2] = $self->{layer}{duiWei}{x}[2] + ($layerIndex - 2) * 1.1;
		$self->{layer}{duiWei}{firstY}[2] = $self->{layer}{duiWei}{y}[2];
		$self->{layer}{duiWei}{firstX}[3] = $self->{layer}{duiWei}{x}[3] - ($layerIndex - 2) * 1.1;
		$self->{layer}{duiWei}{firstY}[3] = $self->{layer}{duiWei}{y}[3];	
	}

	return 1;
}

#**********************************************
#名字		:CountLayerDuiWei
#功能		:计算层别对位数据
#参数		:无
#返回值		:1
#使用例子	:$h->CountLayerDuiWei();
#**********************************************
sub CountLayerDuiWeiPre {
	my $self = shift;
	my $layer = shift;
	#计算symbol
	if ($layer eq '___tmp___i')
	{
		$self->{layer}{duiwei}{symbol} = 'h-layer-duiwei'."$self->{signalLayer}{num}" . "-bya-new+1";
	}
	elsif($layer eq "___tmp___t")
	{
		$self->{layer}{duiwei}{symbol} = 'h-layer-duiwei'."$self->{signalLayer}{num}" . "-out-new+1";
	}
	elsif ($layer eq "___tmp___b")
	{
		$self->{layer}{duiwei}{symbol} = 'h-layer-duiwei'."$self->{signalLayer}{num}" . "-out-bot-new+1";
	}
	else
	{
		$self->{layer}{duiwei}{symbol} = 'h-layer-duiwei'."$self->{signalLayer}{num}" . "-sm-new+1";
	}
	$self->{layer}{duiwei}{drlSize} = 400;
	#计算坐标
	$self->{layer}{duiWei}{x}[0] = $self->{SR}{xmin} + 27.5;
	$self->{layer}{duiWei}{x}[1] = $self->{layer}{duiWei}{x}[0];
	$self->{layer}{duiWei}{x}[2] = $self->{ccd}{duiWei}{x}[2] - 36;
	my $number = $self->{signalLayer}{num} <= 8 ? 8 : $self->{signalLayer}{num};
	#C靶和防旱CCD之间可以放下就放之间，否则放到C靶左边
	if (($self->{SR}{xmax} - $self->{daba}{baBiao}{x}[2] - 23) > (13.85 + ($number - 8) * 2.2 ))
	{
		$self->{layer}{duiWei}{x}[3] =   $self->{SR}{xmax} - 18 - (13.85 + ($number - 8) * 2.2 ) + 4.5;
	}
	else
	{
		$self->{layer}{duiWei}{x}[3] =   $self->{daba}{baBiao}{x}[2] - 10 - (13.85 + ($number - 8) * 2.2 ) + 4.5;
	}
	
	$self->{layer}{duiWei}{y}[0] = $self->{SR}{ymin} - 5.72;
	$self->{layer}{duiWei}{y}[1] = $self->{SR}{ymax} + 4.5;
	$self->{layer}{duiWei}{y}[2] = $self->{layer}{duiWei}{y}[1];
	$self->{layer}{duiWei}{y}[3] = $self->{layer}{duiWei}{y}[0];
	
	$self->{layer}{duiWei}{angle}[0] = 180;
	$self->{layer}{duiWei}{angle}[1] = 0;
	$self->{layer}{duiWei}{angle}[2] = 0;
	$self->{layer}{duiWei}{angle}[3] = 180;

	return 1;
}


#**********************************************
#名字		:CountXiaoYe
#功能		:计算小野十字架数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountXiaoYe();
#**********************************************
sub CountXiaoYe {
	my $self = shift;
	

	#计算正负片
	if ( $self->{cfg}{hdi}{zhengFuPian} eq '正片' or $self->{layerType} eq "sm"){
		$self->{xiaoYe}{polarity} = 'negative';
	}
	else {
		$self->{xiaoYe}{polarity} = 'positive';
	}

	#计算坐标
	$self->{xiaoYe}{x}[0] = $self->{PROF}{xmin} - 12.446;
	$self->{xiaoYe}{x}[1] = $self->{PROF}{xmax} / 2;
	$self->{xiaoYe}{x}[2] = $self->{PROF}{xmax} + 12.446;
	$self->{xiaoYe}{x}[3] = $self->{PROF}{xmax} / 2;

	$self->{xiaoYe}{y}[0] = $self->{PROF}{ymax} / 2;
	$self->{xiaoYe}{y}[1] = $self->{PROF}{ymax} + 12.46;
	$self->{xiaoYe}{y}[2] = $self->{PROF}{ymax} / 2;
	$self->{xiaoYe}{y}[3] = $self->{PROF}{ymin} - 12.46;

	return 1;
}

#**********************************************
#名字		:CountSuanJian
#功能		:计算酸碱数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountSuanJian();
#**********************************************
sub CountSuanJian {
	my $self = shift;

	if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
		$self->{suanJian}{mirror} = 'no';
	}
	else {
		$self->{suanJian}{mirror} = 'yes';
	}

	if ($self->{suanJian}{symbol}){
		return 0;
	}
	
	#计算symbol
	if ($self->{cfg}{hdi}{zhengFuPian} eq '正片'){
		$self->{suanJian}{symbol} = 'ia_jian';
		$self->{suanJian}{poloarity} = 'negative';
	}
	else {
		$self->{suanJian}{symbol} = 'ia_suan';
		$self->{suanJian}{poloarity} = 'positive';
	}

	#计算坐标
	$self->{suanJian}{x} = $self->{SR}{xmin} - 4;
	$self->{suanJian}{y} = $self->{PROF}{yCenter} - 19;

	return 1;
}

#**********************************************
#名字		:CountCuArea
#功能		:计算铜面积数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountCuArea();
#**********************************************
sub CountCuArea {
	my $self = shift;

	if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
		$self->{cuArea}{mirror} = "no";
		$self->{cuArea}{x} = $self->{PROF}{xCenter} - 25;
	}
	else {
		$self->{cuArea}{mirror} = "yes";
		$self->{cuArea}{x} = $self->{PROF}{xCenter} - 6;
	}
	
	$self->{cuArea}{y} = $self->{SR}{ymin} - 6.7;

	return 1;
}

#**********************************************
#名字		:CountZhengPianNum
#功能		:计算正片数字序号
#参数		:无
#返回值		:1
#使用例子	:$self->CountZhengPianNum();
#**********************************************
sub CountZhengPianNum {
	my $self = shift;

	#计算mirror
	if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
		$self->{zhengPianNum}{mirror} = 'no';
		$self->{zhengPianNum}{x} = $self->{SR}{xmax} + 2.54 + 2.54;
	}
	else {
		$self->{zhengPianNum}{mirror} = 'yes';
		$self->{zhengPianNum}{x} = $self->{SR}{xmax} + 2.54;
	}

	#计算坐标
	$self->{zhengPianNum}{y} = $self->{PROF}{yCenter} - 160;
	
	return 1;
}

#**********************************************
#名字		:CountFilmTime
#功能		:计算菲林时间
#参数		:无
#返回值		:1
#使用例子	:$self->CountFilmTime();
#**********************************************
sub CountFilmTime {
	my $self = shift;
	
	#计算mirror
	if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
		$self->{filmTime}{mirror} = 'no';
	}
	else {
		$self->{filmTime}{mirror} = 'yes';
	}

	if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
		$self->{filmTime}{x} = $self->{PROF}{xmin} - 3;
	}
	else {
		$self->{filmTime}{x} = $self->{PROF}{xmin} - 3 - 2.54;
	}


	if ($self->{filmTime}{y}){
		return 0;
	}

	@{$self->{filmTime}{text}} = qw($$plot_machine DD-MMM-YY HH:MM STRETCHX STRETCHY);
	$self->{filmTime}{y} = 127;

	return 1;
}

#**********************************************
#名字		:CountLuoBanDingWei
#功能		:计算锣板定位孔数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountLuoBanDingWei();
#**********************************************
sub CountLuoBanDingWei {
	my $self = shift;

	#计算symbol
	if ($self->{layerType} eq 'via'){
		$self->{luoBanDingWei}{symbol} = 'r2000';
		$self->{luoBanDingWei}{polarity} = 'positive';
	}
	elsif ($self->{layerType} eq 'sm'){
		$self->{luoBanDingWei}{symbol} = 'r2152.4';
		$self->{luoBanDingWei}{polarity} = 'positive';
	}
	elsif ($self->{layerType} eq 'outer'){
		$self->{luoBanDingWei}{symbol} = 'r2508';
		$self->{luoBanDingWei}{polarity} = 'negative';
	}

	if ($self->{luoBanDingWei}{x}){
		return 0;
	}
	
	#通孔板
	if ($self->{hdi}{jieShu} == 0){
		if ($#{$self->{laser}{drillBottom}} < 0
				and $#{$self->{laser}{drillTop}} < 0){
			$self->{luoBanDingWei}{x}[0] = ${$self->{fangHanCCD}{x}}[2] - 12;
			$self->{luoBanDingWei}{x}[1] = ${$self->{erCiYuan}{x}}[2] - 4;
			#放在CCD和二次元数值的中间
			if ($self->{luoBanDingWei}{x}[1] - $self->{luoBanDingWei}{x}[0] > 60){
				$self->{luoBanDingWei}{x}[2] = $self->{luoBanDingWei}{x}[0] + 30;
			}
			else {
				$self->{luoBanDingWei}{x}[2] = $self->{luoBanDingWei}{x}[0] - 30;
			}

			$self->{luoBanDingWei}{y}[3] = $self->{SR}{ymax} - 5.5;
			$self->{luoBanDingWei}{y}[4] = $self->{PROF}{yCenter} + 199;
			$self->{luoBanDingWei}{y}[5] = $self->{PROF}{yCenter} + 157;
		}
		#假hdi板
		else {
			$self->{luoBanDingWei}{x}[0] = $self->{SR}{xmax} - 6  - $self->{laser}{length} - 1.5;
			$self->{luoBanDingWei}{x}[1] = ${$self->{fangHanCCD}{x}}[2] - $self->{ccd}{length} - 10;
			if ($self->{luoBanDingWei}{x}[0] - $self->{luoBanDingWei}{x}[1] < 60){
				$self->{luoBanDingWei}{x}[2] = $self->{luoBanDingWei}{x}[1] - 30;
			}
			else {
				$self->{luoBanDingWei}{x}[2] = $self->{luoBanDingWei}{x}[1] + 30;
			}

			$self->{luoBanDingWei}{y}[3] = $self->{SR}{ymax} - 12;
			$self->{luoBanDingWei}{y}[4] = $self->{PROF}{yCenter} + 199;
			$self->{luoBanDingWei}{y}[5] = $self->{PROF}{yCenter} + 157;
		}
	}
	#hdi板
	else {
		$self->{luoBanDingWei}{x}[0] = $self->{SR}{xmax} - 6  - $self->{laser}{length} - 1.5;
		$self->{luoBanDingWei}{x}[1] = ${$self->{fangHanCCD}{x}}[2] - $self->{ccd}{length} - 1;
		if ($self->{luoBanDingWei}{x}[0] - $self->{luoBanDingWei}{x}[1] < 60){
			$self->{luoBanDingWei}{x}[2] = $self->{luoBanDingWei}{x}[1] - 30;
		}
		else {
			$self->{luoBanDingWei}{x}[2] = $self->{luoBanDingWei}{x}[1] + 30;
		}

		$self->{luoBanDingWei}{y}[3] = $self->{SR}{ymax} - $self->{laser}{length} - 3;
		#core小于2张
		if ($self->{coreNum} < 2) {
			$self->{luoBanDingWei}{y}[4] = $self->{luoBanDingWei}{y}[3] - 50;
		}
		else {
			$self->{luoBanDingWei}{y}[4] = $self->{PROF}{yCenter} + 199;
		}
		$self->{luoBanDingWei}{y}[5] = $self->{PROF}{yCenter} + 157;
	}

	$self->{luoBanDingWei}{y}[0] = $self->{SR}{ymax} + 5;
	$self->{luoBanDingWei}{y}[1] = $self->{luoBanDingWei}{y}[0];
	$self->{luoBanDingWei}{y}[2] = $self->{luoBanDingWei}{y}[0];

	$self->{luoBanDingWei}{x}[3] = $self->{SR}{xmax} + 5;
	$self->{luoBanDingWei}{x}[4] = $self->{luoBanDingWei}{x}[3];
	$self->{luoBanDingWei}{x}[5] = $self->{luoBanDingWei}{x}[3];

	return 1;
}

#**********************************************
#名字		:CountJiaoKong
#功能		:计算角孔
#参数		:无
#返回值		:1
#使用例子	:$self->CountJiaoKong();
#**********************************************
sub CountJiaoKong {
	my $self = shift;

	#计算坐标
	if ($self->{jiaoKong}{x}){
		return 0;
	}

	my $s = 1.2044925;

	$self->{jiaoKong}{x}[0] = $self->{SR}{xmin} - $s;
	$self->{jiaoKong}{y}[0] = $self->{SR}{ymin} - $s;


	$self->{jiaoKong}{x}[1] = $self->{SR}{xmin} - $s;
	$self->{jiaoKong}{y}[1] = $self->{SR}{ymax} + $s;	

	$self->{jiaoKong}{x}[2] = $self->{SR}{xmax} + $s;
	$self->{jiaoKong}{y}[2] = $self->{SR}{ymax} + $s;	


	$self->{jiaoKong}{x}[3] = $self->{SR}{xmax} + $s;
	$self->{jiaoKong}{y}[3] = $self->{SR}{ymin} - $s;

	#$self->{jiaoKong}{x}[3] = $self->{PROF}{xCenter} + 10.4;
	#$self->{jiaoKong}{y}[3] = $self->{SR}{ymax} + 3.2;	

	return 1;
}

#**********************************************
#名字		:CountFangHanBanZiDong
#功能		:计算防焊半自动数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountFangHanBanZiDong();
#**********************************************
sub CountFangHanBanZiDong {
	my $self = shift;
	
	if ($self->{layerType} eq 'via'){
		$self->{fangHanBanZiDong}{symbol} = 'r3175';
	}
	elsif ($self->{layerType} eq 'sm') {
		$self->{fangHanBanZiDong}{symbol} = 'r3454.4';
	}

	#计算坐标
	if ($self->{fangHanBanZiDong}{x}){
		return 0;
	}

	$self->{fangHanBanZiDong}{x}[0] = $self->{liuBian}{xmin} + 4.5;
	$self->{fangHanBanZiDong}{x}[1] = $self->{fangHanBanZiDong}{x}[0];

	$self->{fangHanBanZiDong}{y}[0] = $self->{PROF}{yCenter} - 114.5;
	$self->{fangHanBanZiDong}{y}[1] = $self->{PROF}{yCenter} + 109.5;

	return 1;
}

#**********************************************
#名字		:CountFangHanBanZiDongNew
#功能		:计算防焊半自动数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountFangHanBanZiDongNew();
#**********************************************
sub CountFangHanBanZiDongNew {
	my $self = shift;
	
	if ($self->{layerType} eq 'via'){
		$self->{fangHanBanZiDongNew}{symbol} = 'r3175';
	}
	elsif ($self->{layerType} eq 'sm') {
		$self->{fangHanBanZiDongNew}{symbol} = 'r3454.4';
	}

	#计算坐标
	if ($self->{fangHanBanZiDongNew}{x}){
		return 0;
	}

	$self->{fangHanBanZiDongNew}{x}[0] = $self->{liuBian}{xmin} + 4.5;
	$self->{fangHanBanZiDongNew}{x}[1] = $self->{fangHanBanZiDongNew}{x}[0];

	$self->{fangHanBanZiDongNew}{y}[0] = $self->{PROF}{yCenter} - 130;
	$self->{fangHanBanZiDongNew}{y}[1] = $self->{PROF}{yCenter} + 125;

	return 1;
}


#**********************************************
#名字		:CountPenQiGuaKong
#功能		:计算喷漆挂孔数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountPenQiGuaKong();
#**********************************************
sub CountPenQiGuaKong {
	my $self = shift;
	if ($self->{layerType} eq 'outer'){
		$self->{penQieGuaKong}{symbol} = 'r2000';
	}
	elsif ($self->{layerType} eq 'via'){
		$self->{penQieGuaKong}{symbol} = 'r3175';
	}

	#计算坐标
	if ($self->{penQieGuaKong}{x}){
		return 0;
	}

	$self->{penQieGuaKong}{x}[0] = $self->{PROF}{xCenter} - 20;
	$self->{penQieGuaKong}{x}[1] = $self->{penQieGuaKong}{x}[0];

	$self->{penQieGuaKong}{y}[0] = $self->{liuBian}{ymin} + 4.5;
	$self->{penQieGuaKong}{y}[1] = $self->{liuBian}{ymax} - 4.5;

	return 1;
}

#**********************************************
#名字		:CountyymmddSymbol
#功能		:计算yymmdd数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountyymmddSymbol();
#**********************************************
sub CountyymmddSymbol {
	my $self = shift;
	
	#计算坐标

	$self->{yymmdd}{x} = $self->{SR}{xmax} + 4;
	$self->{yymmdd}{y} = $self->{PROF}{yCenter} + 15.5;
	if ($self->{layerType} eq 'inner')
	{
		$self->{yymmdd}{y} = $self->{PROF}{yCenter} - 18;
	}

	return 1;
}

#**********************************************
#名字		:CountBaoGuangCiShu
#功能		:计算曝光次数
#参数		:无
#返回值		:1
#使用例子	:$self->CountBaoGuangCiShu();
#**********************************************
sub CountBaoGuangCiShu {
	my $self = shift;

	#计算极性
	if ($self->{layerType} eq 'inner'
			or $self->{layerType} eq 'outer'
			or $self->{layerType} eq 'second'){
		if ($self->{cfg}{hdi}{zhengFuPian} eq '正片'){
			$self->{baoGuangCiShu}{polarity} = 'negative';
		}
		else {
			$self->{baoGuangCiShu}{polarity} = 'positive';
		}
	}
	elsif ($self->{layerType} eq 'sm'){
		$self->{baoGuangCiShu}{polarity} = 'negative';
	}

	if ($self->{Layer} =~ /t/ ){
		$self->{baoGuangCiShu}{mirror} = 'no';
		$self->{baoGuangCiShu}{x} = $self->{PROF}{xmax} + 8.9;
	}
	else {
		$self->{baoGuangCiShu}{mirror} = 'yes';
		$self->{baoGuangCiShu}{x} = $self->{PROF}{xmax} + 0.9;
	}
	
	#计算坐标
	if ($self->{baoGuangCiShu}{y}){
		return 0;
	}
	$self->{baoGuangCiShu}{y} = 133;

	return 1;
}

#**********************************************
#名字		:CountWeek
#功能		:计算周期数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountWeek();
#**********************************************
sub CountWeek {
	my $self = shift;

	#计算镜像
	if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
		$self->{week}{mirror} = 'no';
	}
	else {
		$self->{week}{mirror} = 'yes';
	}

	if ($self->{week}{x}) {
		return 0;
	}

	#计算周期symbol
	if ($self->{cfg}{week}{mode} eq 'WWYY'){
		$self->{week}{symbol} = 'week_year';
	}
	elsif ($self->{cfg}{week}{mode} eq 'YYWW') {
		$self->{week}{symbol} = 'year_week';
	}

	#计算正负片
	#如果是外层走正片，周期加在外层，则用负性
	if ($self->{cfg}{hdi}{zhengFuPian} eq '正片' 
			and ($self->{cfg}{week}{layer} eq 'gtl'
			or $self->{cfg}{week}{layer} eq 'gbl')){
		$self->{week}{polarity} = 'negative';
	}
	else {
		$self->{week}{polarity} = 'positive';
	}

	
	#计算周期位置
	$self->{week}{x} = $self->{PROF}{xCenter} + 50;
	$self->{week}{y} = $self->{SR}{ymax} + 7;

	return 1;
}

#**********************************************
#名字		:CountSilkNum
#功能		:计算文字编号数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountSilkNum();
#**********************************************
sub CountSilkNum {
	my $self = shift;
	
	#计算mirror
	if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
		$self->{silkNum}{mirror} = 'no';
		$self->{silkNum}{x} = $self->{SR}{xmax} + 2.54 + 2.54;
	}
	else {
		$self->{silkNum}{mirror} = 'yes';
		$self->{silkNum}{x} = $self->{SR}{xmax} + 2.54;
	}

	#计算坐标
	$self->{silkNum}{y} = $self->{PROF}{yCenter} - 100;

	return 1;
}

#**********************************************
#名字		:CountDateCode
#功能		:计算datecode symbol
#参数		:无
#返回值		:1
#使用例子	:$self->CountDateCode();
#**********************************************
sub CountDateCodeSymbol {
	my $self = shift;

	#计算mirror
	if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
		$self->{dateCode}{mirror} = 'no';
		$self->{dateCode}{x} = $self->{week}{x} - 20;
	}
	else {
		$self->{dateCode}{mirror} = 'yes';
		$self->{dateCode}{x} = $self->{week}{x} - 10;
	}
	
	#计算坐标
	$self->{dateCode}{y} = $self->{week}{y} + 1;

	return 1;
}

#**********************************************
#名字		:CountCSText
#功能		:计算文字数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountCSText();
#**********************************************
sub CountCSText {
	my $self = shift;

	#计算symbol
	#计算mirror
	if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
		if ($self->{Layer} =~ /dot/) {
            $self->{CSText}{symbol} = "dot_text_t";
        }
		else
		{
			$self->{CSText}{symbol} = 'wz-c';
		}
        
		
	}
	else {
		if ($self->{Layer} =~ /dot/) {
            $self->{CSText}{symbol} = "dot_text_b";
        }
		else
		{
			$self->{CSText}{symbol} = 'wz-s';
		}
	}
	
	#计算坐标
	$self->{CSText}{x} = $self->{SR}{xmin} - 3;
	$self->{CSText}{y} = $self->{PROF}{yCenter} + 85;
	if ($self->{Layer} =~ /dot/) {
		$self->{CSText}{x} = $self->{SR}{xmin} - 4;
		$self->{CSText}{y} = $self->{PROF}{yCenter} + 85 + 48;
	}

    

	return 1;
}

#**********************************************
#名字		:CountPanelInSymbol
#功能		:计算panel-in数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountPanelInSymbol();
#**********************************************
sub CountPanelInSymbol {
	my $self = shift;

	my $index = 0;
	my %pos;
	map { $pos{$_} = $index++ } @{$self->{cfg}{lineLayers}};
	if (exists $pos{$self->{Layer}}){
		$self->{panelIn}{symbol} = 'orc-top';
	}
	else {
		$self->{panelIn}{symbol} = 'orc-bot';
	}

	if ($self->{panelIn}{symbolX}){
		return 0;
	}

	$self->{panelIn}{symbolX} = 11.5 * 25.4;
	$self->{panelIn}{symbolY} = 0.8 * 25.4;

	return 1;
}



#**********************************************
#名字		:CountPanelInText
#功能		:计算panelIn文字数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountPanelInText();
#**********************************************
sub CountPanelInText {
	my $self = shift;
	
	if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
		$self->{panelIn}{textX} = 0.7 * 25.4;
		$self->{panelIn}{mirror} = 'no';
	}
	else {
		$self->{panelIn}{textX} = 0.3 * 25.4;
		$self->{panelIn}{mirror} = 'yes';
	}
	$self->{panelIn}{textY} = 17.5 *25.4;
	$self->{panelIn}{angel} = 270;

	return 1;
}

#**********************************************
#名字		:CountPanelCbSymbol
#功能		:计算panel-in数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountPanelCbSymbol();
#**********************************************
sub CountPanelCbSymbol {
	my $self = shift;

	my $index = 0;
	my %pos;
	map { $pos{$_} = $index++ } @{$self->{cfg}{lineLayers}};
	if (exists $pos{$self->{Layer}}){
		$self->{panelCb}{symbol} = 'cb-top-new-bm';
	}
	else {
		$self->{panelCb}{symbol} = 'cb-bot-new-bm';
	}

	if ($self->{panelCb}{symbolX}){
		return 0;
	}

	$self->{panelCb}{symbolX} = 0;
	$self->{panelCb}{symbolY} = 0;

	return 1;
}

#**********************************************
#名字		:CountPanelCbText
#功能		:计算panelCb文字数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountPanelCbText();
#**********************************************
sub CountPanelCbText {
	my $self = shift;
	
	if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
		$self->{panelCb}{textX} = 25 + $self->{PROF}{xmax} + 20;
		$self->{panelCb}{mirror} = 'no';
	}
	else {
		$self->{panelCb}{textX} = 25 + $self->{PROF}{xmax} + 10;
		$self->{panelCb}{mirror} = 'yes';
	}
	$self->{panelCb}{textY} = 16.5 *25.4;
	$self->{panelCb}{angel} = 270;

	return 1;
}

#**********************************************
#名字		:CountPanelBhSymbol
#功能		:计算panel-in数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountPanelBhSymbol();
#**********************************************
sub CountPanelBhSymbol {
	my $self = shift;

	my $index = 0;
	my %pos;
	map { $pos{$_} = $index++ } @{$self->{cfg}{lineLayers}};
	if (exists $pos{$self->{Layer}}){
		$self->{panelBh}{symbol} = 'bh-top';
	}
	else {
		$self->{panelBh}{symbol} = 'bh-bot';
	}

	if ($self->{panelBh}{symbolX}){
		return 0;
	}

	$self->{panelBh}{symbolX} = 604.52/2;
	$self->{panelBh}{symbolY} = 706.12/2;

	return 1;
}

#**********************************************
#名字		:CountPanelBhRect
#功能		:计算bh symbol数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountPanelBhRect();
#**********************************************
sub CountPanelBhRect {
	my $self = shift;

	if ($self->{panelBh}{rect}{x}){
		return 0;
	}

	$self->INFO(entity_type => 'step',
				entity_path => "$self->{Job}/$self->{panelBhStep}", 
				units 		=> 'mm',
				type 		=> 'SR_LIMITS');
	$self->{BhSR}{xmin} = $self->{doinfo}{gSR_LIMITSxmin};
	$self->{BhSR}{ymin} = $self->{doinfo}{gSR_LIMITSymin};
	$self->{BhSR}{xmax} = $self->{doinfo}{gSR_LIMITSxmax};
	$self->{BhSR}{ymax} = $self->{doinfo}{gSR_LIMITSymax};	

	$self->{panelBh}{rect}{x}[0] = $self->{BhSR}{xmin} - 8;
	$self->{panelBh}{rect}{y}[0] = 706.12/2 + 35;

	$self->{panelBh}{rect}{x}[1] = 604.52/2 - 105;
	$self->{panelBh}{rect}{y}[1] = $self->{BhSR}{ymax} + 8;

	$self->{panelBh}{rect}{x}[2] = $self->{BhSR}{xmax} + 8;
	$self->{panelBh}{rect}{y}[2] = 706.12/2 - 35;

	$self->{panelBh}{rect}{x}[3] = 604.52/2 + 105;
	$self->{panelBh}{rect}{y}[3] = $self->{BhSR}{ymin} - 8;

	$self->{panelBh}{rect}{symbol}[0] = $self->{panelBh}{rect}{symbol}[2] = 'rect20000x50000';
	$self->{panelBh}{rect}{symbol}[1] = $self->{panelBh}{rect}{symbol}[3] = 'rect50000x20000';

	return 1;
}

#**********************************************
#名字		:CountPanelBhText
#功能		:计算panelBh文字数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountPanelBhText();
#**********************************************
sub CountPanelBhText {
	my $self = shift;

	if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/){
		$self->{panelBh}{textX} = 0.7 * 25.4;
		$self->{panelBh}{mirror} = 'no';
	}
	else {
		$self->{panelBh}{textX} = 0.3 * 25.4;
		$self->{panelBh}{mirror} = 'yes';
	}
	$self->{panelBh}{textY} = 16.5 *25.4;
	$self->{panelBh}{angel} = 270;

	return 1;
}

#**********************************************
#名字		:CountPanelOutOldLine
#功能		:计算防焊全自动数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountPanelOutOldLine();
#**********************************************
sub CountPanelOutOldLine {
	my $self = shift;
	
	#计算坐标
	if ($self->{panelOutOldLine}{x}){
		return 0;
	}
	$self->{panelOutOldLine}{x}[0] = 0;
	$self->{panelOutOldLine}{y}[0] = 0;

	$self->{panelOutOldLine}{x}[1] = 21.8*25.4;
	$self->{panelOutOldLine}{y}[1] = 25.8*25.4;

	return 1;
}

#**********************************************
#名字		:CountPanelOutSdLine
#功能		:计算防焊全自动数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountPanelOutSdLine();
#**********************************************
sub CountPanelOutSdLine {
	my $self = shift;
	
	#计算坐标
	if ($self->{panelOutSdLine}{x}){
		return 0;
	}
	$self->{panelOutSdLine}{x}[0] = 0;
	$self->{panelOutSdLine}{y}[0] = 0;

	$self->{panelOutSdLine}{x}[1] = 23.8*25.4;
	$self->{panelOutSdLine}{y}[1] = 27.8*25.4;

	return 1;
}

#**********************************************
#名字		:CountPanelOutNewLine
#功能		:计算防焊全自动数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountPanelOutNewLine();
#**********************************************
sub CountPanelOutNewLine {
	my $self = shift;
	
	#计算坐标
	if ($self->{panelOutNewLine}{x}){
		return 0;
	}
	$self->{panelOutNewLine}{x}[0] = 0;
	$self->{panelOutNewLine}{y}[0] = 0;

	$self->{panelOutNewLine}{x}[1] = 23.8*25.4;
	$self->{panelOutNewLine}{y}[1] = 27.8*25.4;

	return 1;
}

#**********************************************
#名字		:CountPanelOutOldShiZiJia
#功能		:计算panel-out十字架
#参数		:无
#返回值		:1
#使用例子	:$self->CountPanelOutOldShiZiJia();
#**********************************************
sub CountPanelOutOldShiZiJia {
	my $self = shift;

	#计算symbol
	if ($self->{panelOutOldShiZiJia}{symbol}){
		return 0;
	}

	$self->{panelOutOldShiZiJia}{symbol}[0] = 'mark-lgp-h';
	$self->{panelOutOldShiZiJia}{symbol}[1] = 'mark-lgp-v';
	
	#计算坐标
	$self->{panelOutOldShiZiJia}{x} = 21.8*25.4/2;
	$self->{panelOutOldShiZiJia}{y} = 25.8*25.4/2;


	return 1;
}

#**********************************************
#名字		:CountPanelOutNewShiZiJia
#功能		:计算panel-out十字架
#参数		:无
#返回值		:1
#使用例子	:$self->CountPanelOutNewShiZiJia();
#**********************************************
sub CountPanelOutNewShiZiJia {
	my $self = shift;

	#计算symbol
	if ($self->{panelOutNewShiZiJia}{symbol}){
		return 0;
	}

	$self->{panelOutNewShiZiJia}{symbol}[0] = 'mark-lgp-h';
	$self->{panelOutNewShiZiJia}{symbol}[1] = 'mark-lgp-v';
	
	#计算坐标
	$self->{panelOutNewShiZiJia}{x} = 23.8*25.4/2;
	$self->{panelOutNewShiZiJia}{y} = 27.8*25.4/2;


	return 1;
}

#**********************************************
#名字		:CountBzdSymbol
#功能		:计算Bzd symbol 数据
#参数		:无
#返回值		:1
#使用例子	:$self->CountBzdSymbol();
#**********************************************
sub CountBzdSymbol {
	my $self = shift;
	
	if ($self->{bzd}{x}){
		return 0;
	}

	#
	$self->{bzd}{x} = 32.4 + $self->{PROF}{xmax} + 35;
	$self->{bzd}{y} = 38.1;
	return 1;
}

#**********************************************
#名字		:CountFangDai
#功能		:
#参数		:无
#返回值		:1
#使用例子	:$self->CountFangDai();
#**********************************************
sub CountFangDai {
	my $self = shift;
	#计算bc靶距值
	my $bc = sprintf("%.2f",$self->getBCFangDai());
	#如果没有找到，默认添加45%
	if ($bc == 0){
		$self->{endMsg} .= "尺寸太小，无法满足靶距大于60%的要求，跑完后请检查修改！";
		$self->{msgSwitch} = "yes";
		$bc = $self->{SR}{ValidX} * 45/100;
	}
	my $cd = sprintf("%.2f",$self->getCDFangDai($bc));
	
	if ($self->{Target}{getType} == 1)
	{
		eval
		{
			my $bd = $bc + $cd;
			while ($self->GetFangDaiBdDate($bd))
			{
				$self->{Target}{getType} = 1;
				$bc = sprintf("%.2f",$self->getBCFangDai());
				$cd = sprintf("%.2f",$self->getCDFangDai($bc));
				$bd = $bc + $cd;
				$self->{Target}{getType} = 0;
			}
		}
	}


	$self->{baju}{value} = $bc;
	$self->{daba}{x2FangDai} = $self->{SR}{xmin} + 60 + $self->{baju}{value};

	#$self->{SR}{xmax} - 9.5最后一个ccd，
	my $fangDaiMax =  $self->{SR}{xmax} - 9.5 -  $self->{daba}{x2FangDai} - $self->{hdi}{jieShu} * $self->{layerBaBiaoJianJu}*3 - 5;

	my $ccdfangDai = 0.5 * (sprintf "%1.0f", rand($fangDaiMax/0.5));

	$self->{ccd}{x2FangDai} = $cd + $self->{daba}{x2FangDai} + $self->{hdi}{jieShu}*$self->{layerBaBiaoJianJu} + 5;

	#7为打靶大小,5为防焊ccd大小
	$self->{rightDownResidue} = $self->{SR}{xmax} - 9.5 -  $self->{daba}{x2FangDai} - $self->{hdi}{jieShu} * $self->{layerBaBiaoJianJu}*2 - 5 - 7;

	$self->{ccd}{length} = $self->{hdi}{jieShu}*$self->{layerBaBiaoJianJu} + 6.5;

	#计算个数，阶数+2
	$self->{tongXinYuan}{num} = $self->{hdi}{jieShu} + 2;
	$self->{tongXinYuan}{length} = (1012 + ($self->{signalLayer}{num} - 2)*350 + ($self->{tongXinYuan}{num} - 1)*1812)/1000;
	
	#计算右下方向孔防呆
	#求出剩余值
	my $shengYu = $self->{PROF}{yCenter} - 200 - $self->{SR}{ymin} - 2.5 - 3 - 3;
	#求出总长度
	my $allLength = $self->{ccd}{length} + $self->{laser}{length} + 7.5 + $self->{tongXinYuan}{length};
	
	#core数大于2，考虑同心圆，否则有足够空间
	if ($self->{coreNum} > 2){
		if ($self->{liuBian}{xSize} > 14 or $self->{liuBian}{ySize} > 17.5){
			$self->{fangXiangKong}{jianJuMax} = $shengYu - $allLength +  $self->{tongXinYuan}{length};
		}
		elsif ($shengYu > $allLength) {
			$self->{fangXiangKong}{jianJuMax} = $shengYu - $allLength;
			$self->{tongXinYuan}{chang} = 'yes';
		}
		#留边小，剩余值小，不考虑同心圆
		else {
			$self->{fangXiangKong}{jianJuMax} = $shengYu - $allLength -  $self->{tongXinYuan}{length};
		}
	}
	else {
		$self->{fangXiangKong}{jianJuMax} = 28;
	}

	#如果防呆间距值足够大，不能超过28
	if ($self->{fangXiangKong}{jianJuMax} > 28){
		$self->{fangXiangKong}{jianJuMax} = 28;
	}
	#不过放靶标，取孔间距的极限值8
	elsif ($self->{fangXiangKong}{jianJuMax} < 0) {
		$self->{fangXiangKong}{jianJuMax} = 8;
	}

	#求出防呆间距
	#$self->{fangXiangKong}{jianJuValue} = sprintf "%1.2f",rand($self->{fangXiangKong}{jianJuMax} - 8);
	$self->{fangXiangKong}{jianJuValue} = $self->getSMFangDai();

	return 1;
}

#**********************************************
#名字		:CountFilmSizeTestPad
#功能		: 大菲林二次元尺寸测试。
#参数		:无
#返回值		:1
#使用例子	:$self->CountFilmSizeTestPad();
#**********************************************
sub CountFilmSizeTestPad{
	my $self=shift;
	
	if ($self->{FilmSizeTestPad}{x}[0]){
		return 1;
	}
	#pad的symbol
	$self->{FilmSizeTestPad}{symbol}='film_mark';
	#pad坐标
	$self->{FilmSizeTestPad}{x}[0]= $self->{PROF}{xmin}+($self->{SR}{xmin}-$self->{PROF}{xmin})/2;
	$self->{FilmSizeTestPad}{y}[0]= $self->{PROF}{ymax}-50;
	$self->{FilmSizeTestPad}{x}[1]= $self->{FilmSizeTestPad}{x}[0];
	$self->{FilmSizeTestPad}{y}[1]= $self->{PROF}{yCenter}-1.5;
	$self->{FilmSizeTestPad}{x}[2]= $self->{FilmSizeTestPad}{x}[0];
	$self->{FilmSizeTestPad}{y}[2]= $self->{PROF}{ymin}+50;
	#
	$self->{FilmSizeTestPad}{x}[3]= $self->{PROF}{xmax}-($self->{PROF}{xmax}-$self->{SR}{xmax})/2;
	$self->{FilmSizeTestPad}{y}[3]= $self->{PROF}{ymax}-50;
	$self->{FilmSizeTestPad}{x}[4]= $self->{FilmSizeTestPad}{x}[3];
	$self->{FilmSizeTestPad}{y}[4]= $self->{PROF}{yCenter}-1.5;
	$self->{FilmSizeTestPad}{x}[5]= $self->{FilmSizeTestPad}{x}[3];
	$self->{FilmSizeTestPad}{y}[5]= $self->{PROF}{ymin}+50;
	#加坐标文字的坐标 x y
	$self->{FilmSizeText}{x}[0]=$self->{FilmSizeTestPad}{x}[0]-0.3;
	$self->{FilmSizeText}{y}[0]=$self->{FilmSizeTestPad}{y}[0]-3.2;
	$self->{FilmSizeText}{x}[1]=$self->{FilmSizeTestPad}{x}[1]-0.3;
	$self->{FilmSizeText}{y}[1]=$self->{FilmSizeTestPad}{y}[1]-3.2;
	$self->{FilmSizeText}{x}[2]=$self->{FilmSizeTestPad}{x}[2]-0.3;
	$self->{FilmSizeText}{y}[2]=$self->{FilmSizeTestPad}{y}[2]-3.2;
	#
	$self->{FilmSizeText}{x}[3]=$self->{FilmSizeTestPad}{x}[3]-0.3;
	$self->{FilmSizeText}{y}[3]=$self->{FilmSizeTestPad}{y}[3]-3.2;
	$self->{FilmSizeText}{x}[4]=$self->{FilmSizeTestPad}{x}[4]-0.3;
	$self->{FilmSizeText}{y}[4]=$self->{FilmSizeTestPad}{y}[4]-3.2;
	$self->{FilmSizeText}{x}[5]=$self->{FilmSizeTestPad}{x}[5]-0.3;
	$self->{FilmSizeText}{y}[5]=$self->{FilmSizeTestPad}{y}[5]-3.2;
	#尺寸衬底
	$self->{FilmSizeCD}{x}=$self->{PROF}{xmin}+64;
	$self->{FilmSizeCD}{y}=($self->{SR}{ymin}-$self->{PROF}{ymin})/2+$self->{PROF}{ymin};
	$self->{FilmSizeCD}{textx}=$self->{PROF}{xmin}+46.5;
	$self->{FilmSizeCD}{texty}=$self->{FilmSizeCD}{y}-0.5;
	my $x=sprintf("%.2f",$self->{FilmSizeTestPad}{x}[3]-$self->{FilmSizeTestPad}{x}[0]);
	my $y1=sprintf("%.2f",$self->{FilmSizeTestPad}{y}[0]-$self->{FilmSizeTestPad}{y}[1]);
	my $y2=sprintf("%.2f",$self->{FilmSizeTestPad}{y}[1]-$self->{FilmSizeTestPad}{y}[2]);
	
	$self->{FilmSizeCD}{text}="1->1:$x 1->2:$y1 2->3:$y2";
	
	
	
	
	
	
	
}

#sub CountFangDaiOld {
#	my $self = shift;
#	$self->{daba}{x2FangDai} = $self->{SR}{xmin} + 60 + $self->{baju}{value};
#
#	#$self->{SR}{xmax} - 9.5最后一个ccd，
#	my $fangDaiMax =  $self->{SR}{xmax} - 9.5 -  $self->{daba}{x2FangDai} - $self->{hdi}{jieShu} * $self->{layerBaBiaoJianJu}*3 - 5;
#
#	my $ccdfangDai = 0.5 * (sprintf "%1.0f", rand($fangDaiMax/0.5));
#
#	$self->{ccd}{x2FangDai} = $self->getCDFangDai($self->{baju}{value}) + $self->{daba}{x2FangDai} + $self->{hdi}{jieShu}*$self->{layerBaBiaoJianJu} + 5;
#
#	#7为打靶大小,5为防焊ccd大小
#	$self->{rightDownResidue} = $self->{SR}{xmax} - 9.5 -  $self->{daba}{x2FangDai} - $self->{hdi}{jieShu} * $self->{layerBaBiaoJianJu}*2 - 5 - 7;
#
#	$self->{ccd}{length} = $self->{hdi}{jieShu}*$self->{layerBaBiaoJianJu} + 6.5;
#
#	#计算个数，阶数+2
#	$self->{tongXinYuan}{num} = $self->{hdi}{jieShu} + 2;
#	$self->{tongXinYuan}{length} = (1012 + ($self->{signalLayer}{num} - 2)*350 + ($self->{tongXinYuan}{num} - 1)*1812)/1000;
#	
#	#计算右下方向孔防呆
#	#求出剩余值
#	my $shengYu = $self->{PROF}{yCenter} - 200 - $self->{SR}{ymin} - 2.5 - 3 - 3;
#	#求出总长度
#	my $allLength = $self->{ccd}{length} + $self->{laser}{length} + 7.5 + $self->{tongXinYuan}{length};
#	
#	#core数大于2，考虑同心圆，否则有足够空间
#	if ($self->{coreNum} > 2){
#		if ($self->{liuBian}{xSize} > 14 or $self->{liuBian}{ySize} > 17.5){
#			$self->{fangXiangKong}{jianJuMax} = $shengYu - $allLength +  $self->{tongXinYuan}{length};
#		}
#		elsif ($shengYu > $allLength) {
#			$self->{fangXiangKong}{jianJuMax} = $shengYu - $allLength;
#			$self->{tongXinYuan}{chang} = 'yes';
#		}
#		#留边小，剩余值小，不考虑同心圆
#		else {
#			$self->{fangXiangKong}{jianJuMax} = $shengYu - $allLength -  $self->{tongXinYuan}{length};
#		}
#	}
#	else {
#		$self->{fangXiangKong}{jianJuMax} = 28;
#	}
#
#	#如果防呆间距值足够大，不能超过28
#	if ($self->{fangXiangKong}{jianJuMax} > 28){
#		$self->{fangXiangKong}{jianJuMax} = 28;
#	}
#	#不过放靶标，取孔间距的极限值8
#	elsif ($self->{fangXiangKong}{jianJuMax} < 0) {
#		$self->{fangXiangKong}{jianJuMax} = 8;
#	}
#
#	#求出防呆间距
#	#$self->{fangXiangKong}{jianJuValue} = sprintf "%1.2f",rand($self->{fangXiangKong}{jianJuMax} - 8);
#	$self->{fangXiangKong}{jianJuValue} = $self->getSMFangDai();
#
#	return 1;
#}






1;
__END__
