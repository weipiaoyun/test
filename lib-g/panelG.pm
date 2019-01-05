#!/usr/bin/perl
#源码名称: panel.pm
#功能描述: 为封边提供类操作
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
#修改日期: 2015.2.19
#修改内容: 删除文字板边14个h-chongkong-duiwei及1个out-mark

package panelG;

#导入模块
use strict;
use warnings;
#use lib qw(/gen_db/odb2/.hc/lib-g);
use lib qw(/gen_db/workfile/cam/lw/tmp/lib-g);
use panelCalcG;
use HC;
use FangDaiG;
use POSIX qw(strftime);
use utf8;
use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter panelCalcG HC FangDaiG);

#设置程式名称
my $appName = 'panel';

#设置版本号
my $version = 1.1;

#new方法
sub new {
    my $caller = shift;
    my $class  = ref($caller) || $caller;
    my $self   = new Genesis;
    bless $self, $class;

    #初始化JOB名
    $self->{Job} = $ENV{JOB} if defined $ENV{JOB};

    #初始化tk界面配置
    $self->{'_tb_col'} = '#009298';
    $self->{'_hb_col'} = '#face9c';
    $self->{'_tf_col'} = '#ffffff';
    $self->{'_nb_col'} = '#ececec';
    $self->{'_lb_col'} = '#6ec3c9';
    $self->{'_t_font'} = 'application 12';
    $self->{'_n_font'} = 'application 10';
    $self->{'_nf_col'} = '#000000';
    $self->{'_wf_col'} = '#ff0000';
    $self->{'_wb_col'} = '#ffff00';
    $self->{'_sb_col'} = '#cae5e8';
    $self->{'_logo'}   = '/gen_db/odb2/.hc/image/hc_logo.png';
    $self->{'_icon'}   = '/gen_db/odb2/.hc/image/icon.png';

    return $self;
}

#名字		:GetInfo
#功能		:程序前计算
#参数		:
#返回值		:1
#使用例子	:
sub GetInfo {
    my $self = shift;

    #设置PID
    $self->{PID} = $$;

    #设置板边的各个Step
    $self->setStepName();

    #获取矩阵
    #$self->GetJobMatrix();

    #获取料号中的所有层
    #@{$self->{allLayers}} =  keys %{$self->{matrix}};

    #获取信号层, 孔层
    $self->INFO(
        entity_type => 'matrix',
        entity_path => "$self->{Job}/matrix",
        data_type   => 'ROW',
        parameters  => "context+layer_type+name+polarity"
    );

    foreach my $i ( 0 .. $#{ $self->{doinfo}{gROWname} } ) {
        if (    ${ $self->{doinfo}{gROWcontext} }[$i] eq 'board'
            and ${ $self->{doinfo}{gROWlayer_type} }[$i] eq 'signal' )
        {
            push @{ $self->{signalLayer}{layer} },
              ${ $self->{doinfo}{gROWname} }[$i];
            push @{ $self->{board}{layer} }, ${ $self->{doinfo}{gROWname} }[$i];
            if ( ${ $self->{doinfo}{gROWname} }[$i] =~ /^in/ ) {
                push @{ $self->{inner}{layer} },
                  ${ $self->{doinfo}{gROWname} }[$i];
            }
            elsif ( ${ $self->{doinfo}{gROWname} }[$i] =~ /^sec/ ) {
                push @{ $self->{second}{layer} },
                  ${ $self->{doinfo}{gROWname} }[$i];
            }
            elsif ( ${ $self->{doinfo}{gROWname} }[$i] =~ /^g[tb]l/ ) {
                push @{ $self->{outer}{layer} },
                  ${ $self->{doinfo}{gROWname} }[$i];
            }

        }
        if (    ${ $self->{doinfo}{gROWcontext} }[$i] eq 'board'
            and ${ $self->{doinfo}{gROWlayer_type} }[$i] eq 'drill' )
        {
            push @{ $self->{drillLayer} }, ${ $self->{doinfo}{gROWname} }[$i];
            push @{ $self->{board}{layer} }, ${ $self->{doinfo}{gROWname} }[$i];
            if ( ${ $self->{doinfo}{gROWname} }[$i] =~ /^d\d{2,3}/ ) {
                push @{ $self->{via}{layer} },
                  ${ $self->{doinfo}{gROWname} }[$i];
            }
            elsif ( ${ $self->{doinfo}{gROWname} }[$i] =~ /^l\d{2,4}/ ) {
                push @{ $self->{laser}{layer} },
                  ${ $self->{doinfo}{gROWname} }[$i];
            }
            elsif ( ${ $self->{doinfo}{gROWname} }[$i] =~ /^m\d{2,4}/ ) {
                push @{ $self->{bury}{layer} },
                  ${ $self->{doinfo}{gROWname} }[$i];
            }

        }
        if (    ${ $self->{doinfo}{gROWcontext} }[$i] eq 'board'
            and ${ $self->{doinfo}{gROWlayer_type} }[$i] eq 'solder_mask' )
        {
            push @{ $self->{sm}{layer} },    ${ $self->{doinfo}{gROWname} }[$i];
            push @{ $self->{board}{layer} }, ${ $self->{doinfo}{gROWname} }[$i];
        }
        if (    ${ $self->{doinfo}{gROWcontext} }[$i] eq 'board'
            and ${ $self->{doinfo}{gROWlayer_type} }[$i] eq 'silk_screen' )
        {
            push @{ $self->{ss}{layer} },    ${ $self->{doinfo}{gROWname} }[$i];
            push @{ $self->{board}{layer} }, ${ $self->{doinfo}{gROWname} }[$i];
        }
        if (    ${ $self->{doinfo}{gROWcontext} }[$i] eq 'board'
            and ${ $self->{doinfo}{gROWlayer_type} }[$i] eq 'solder_paste' )
        {
            push @{ $self->{sp}{layer} },    ${ $self->{doinfo}{gROWname} }[$i];
            push @{ $self->{board}{layer} }, ${ $self->{doinfo}{gROWname} }[$i];
        }
    }

    #获取信号层层数
    $self->{signalLayer}{num} = $self->{Job};
    $self->{signalLayer}{num} =~ s/^\D+(\d{1,2})(\D)?\d{4}.*/$1/;
    #if ( $self->{signalLayer}{num} == 1 ) {
     #   $self->{signalLayer}{num} = $self->{Job};
      #  $self->{signalLayer}{num} =~ s/^\D+(\d{2}).*/$1/;
   # }
    if ($self->{Job} =~ /^\D{2}\D\d\D(\d{1,2})\D?\d{4,5}\D\d{1,2}/)
    {
        $self->{signalLayer}{num} = $self->{Job};
        $self->{signalLayer}{num} =~ s/^\D{2}\D\d\D(\d{1,2})\D?\d{4,5}\D\d{1,2}.*/$1/;
    }
	if ($self->{signalLayer}{num} =~ /^0/)
	{
		$self->{signalLayer}{num} = substr($self->{signalLayer}{num},1);
	}

    #$self->{signalLayer}{num} =~ s/^\D+(\d).*/$1/;
    #if ($self->{signalLayer}{num} == 1){
    #	$self->{signalLayer}{num} = $self->{Job};
    #	$self->{signalLayer}{num} =~ s/^\D+(\d{2}).*/$1/;
    #}

    #计算量产还是样品
    $self->{hdi}{jobType} = $self->{Job};
    $self->{hdi}{jobType} =~ s/^(\w)\D+.*/$1/;

    $self->{coreNum} = 0;
    $self->{hdi}{jieShu} = 0;
    my $i = 1;
    foreach ( @{ $self->{signalLayer}{layer} } ) {
        $self->{$_}{layNum} = $i;

        if ( $_ =~ /^in\d{1,2}t$/ ) {
            $self->{coreNum}++;
        }

        #计算阶数
        if ( $_ =~ /^sec\d{1,2}t$/ ) {
            $self->{hdi}{jieShu}++;
        }

        $i++;
    }
    $self->{daba}{num} = $self->{ccd}{num} = $self->{hdi}{jieShu} + 1;


    #信号层层数如果不跟料号名计算出来的层数相同，则退出
    my $ceng = $i - 1;
    if ($self->{signalLayer}{num} == 0)
	{
		$self->{signalLayer}{num} = $ceng;
	}
    if ($self->{Job} !~ /^\D+l/ &&  $self->{signalLayer}{num} != $i - 1 ) {
        my $checkMsg =
"该料号的为$self->{signalLayer}{num}层板，但信号层层数为$ceng 层!\n请修改正确后再跑，谢谢！";
        $self->StopMsgBox( 'error', $checkMsg );
        exit;
    }

    #判断是否hdi板
    $self->{hdi}{yesNo} = 'no';
    my $quZhi = substr( $self->{Job}, 2, 1 );
    if ( $quZhi eq 'h' ) {
        $self->{hdi}{yesNo} = 'yes';
    }

    #判断选印层数是否正确
    if ( $self->{xuanYin} ) {
        if ( $self->{xuanYin} eq "单面" ) {
            $self->{xuanYinNum} = 1;
        }
        elsif ( $self->{xuanYin} eq "双面" ) {
            $self->{xuanYinNum} = 2;
        }
    }
    else {
        $self->{xuanYinNum} = 0;
    }

    #对孔层分类
    $self->DevideDrill();

    #获取最小通孔，镭射孔，埋孔
    if ( $self->{tong}{drill} ) {
        $self->GetMinVia();
    }
    else {
        $self->{cfg}{minVia} = '300';
    }

    if ( $#{ $self->{laser}{drill} } >= 0 ) {
        $self->GetMinLaser();
    }
    else {
        $self->{cfg}{minLaser} = '100';
    }

    if ( $#{ $self->{bury}{drill} } >= 0 ) {
        $self->GetMinMind();
    }
    else {
        $self->{cfg}{minBury} = '275';
    }

    #获取内层每层的铜面积
    foreach my $layer(@{ $self->{inner}{layer} })
    {
		if ($self->{userName} ne 'lw') {
			$self->COM("copper_area,layer1=$layer,layer2=,drills=yes,consider_rout=no,ignore_pth_no_pad=no,drills_source=matrix,thickness=0,resolution_value=1,x_boxes=3,y_boxes=3,area=no,dist_map=yes");
			$self->{$layer}{copper}{persent} = (split(/\s+/,$self->{COMANS}))[-1];

		}
    }
    return 1;
}

#**********************************************
#名字		:setStepName
#功能		:设置step的名字
#参数		:无
#返回值		:1
#使用例子	:$self->setStepName();
#**********************************************
sub setStepName {
    my $self = shift;

    #edit Step
    $self->{editStep} = 'edit';

    #内层ORC Step
    $self->{panelInStep} = 'panel-in';

    #志圣川宝Step
    $self->{panelCbStep} = 'panel-cb';

    #巴赫Step
    $self->{panelBhStep} = 'panel-bh';

    #正片板边避光Step
    $self->{panelZpStep} = 'panel-zp';

    #防焊自动Step
    $self->{panelOutOldStep} = 'panel-out';

    #防焊自动新机Step
    $self->{panelOutNewStep} = 'panel-out-new';

    #防焊半自动Step
    $self->{panelOutSdStep} = 'panel-out-sd';

    return 1;
}

#**********************************************
#名字		:devideDrill
#功能		:获取孔层名，及对孔进行分类
#参数		:无
#返回值		:1
#使用例子	:$self->devideDrill();
#**********************************************
sub DevideDrill {
    my $self = shift;

    #获取所有孔层
    my @allDrill = $self->GetTypeLayer('drill');

    #区分通孔，埋孔，盲孔
    foreach my $drill (@allDrill) {
        if ( $drill =~ /^d1\d{1,2}$/ ) {
            $self->{tong}{drill} = $drill;
        }
        elsif ( $drill =~ /^m\d{2,4}$/ ) {
            push @{ $self->{bury}{drill} }, $drill;
        }
        elsif ( $drill =~ /^l\d{2,4}$/ ) {
            push @{ $self->{laser}{drill} }, $drill;
        }
    }

    #区分镭射顶层和底层
    foreach my $laser ( @{ $self->{laser}{drill} } ) {
        $self->INFO(
            entity_type => 'layer',
            entity_path => "$self->{Job}/$self->{editStep}/$laser",
            data_type   => 'DRL_START'
        );

        if (   $self->{doinfo}{gDRL_START} eq 'gtl'
            or $self->{doinfo}{gDRL_START} =~ /^(sec|in)\d{1,2}t/ )
        {
            push @{ $self->{laser}{drillTop} }, $laser;
        }
        else {
            push @{ $self->{laser}{drillBottom} }, $laser;
        }
    }

    return 1;
}

#**********************************************
#名字		:getMinVia
#功能		:设置step的名字
#参数		:无
#返回值		:1
#使用例子	:$self->getMinVia();
#**********************************************
sub GetMinVia {
    my $self = shift;

    #获取pcs Step
    $self->getAllStep("$self->{panelStep}");
    foreach ( @{ $self->{allStep} } ) {
        if ( $_ =~ /^edit/ ) {
            push @{ $self->{allPcs} }, $_;
        }
    }

    #在各个pcs获取最小孔径
    foreach my $pcs ( @{ $self->{allPcs} } ) {
        $self->INFO(
            entity_type => 'step',
            entity_path => "$self->{Job}/$pcs",
            data_type   => 'ATTR'
        );

    #如果有阴阳拼或者旋转角度的，pcs为其没旋转和阴阳的pcs
        foreach my $i ( 0 .. $#{ $self->{doinfo}{gATTRname} } ) {
            if ( ${ $self->{doinfo}{gATTRname} }[$i] =~
                /(.flipped_of)|(.rotated_of)/ )
            {
                if ( ${ $self->{doinfo}{gATTRval} }[$i] ) {
                    $pcs = $self->{doinfo}{gATTRval}[$i];
                }
            }
        }

        #获取孔层信息，孔的形状+孔的大小
        $self->INFO(
            entity_type => 'layer',
            units       => 'mm',
            entity_path => "$self->{Job}/$pcs/$self->{tong}{drill}",
            data_type   => 'TOOL',
            parameters  => "drill_size+shape"
        );
        my @toolShape     = @{ $self->{doinfo}{gTOOLshape} };
        my @toolDrillSize = @{ $self->{doinfo}{gTOOLdrill_size} };

        #获取最小孔径
        foreach my $i ( 0 .. $#toolShape ) {
            if ( $toolShape[$i] eq 'hole' ) {
                if ( $self->{cfg}{minVia} ) {
                    if ( $toolDrillSize[$i] < $self->{cfg}{minVia} ) {
                        $self->{cfg}{minVia} = $toolDrillSize[$i];
                    }
                }
                else {
                    $self->{cfg}{minVia} = $toolDrillSize[$i];
                }
            }
        }
    }

    unless ( $self->{cfg}{minVia} ) {
        $self->{cfg}{minVia} = 300;
    }

    return 1;
}

#**********************************************
#名字		:getLaserVia
#功能		:设置step的名字
#参数		:无
#返回值		:1
#使用例子	:$self->getLaserVia();
#**********************************************
sub GetMinLaser {
    my $self = shift;

    #获取pcs Step
    $self->getAllStep("$self->{panelStep}");
    foreach ( @{ $self->{allStep} } ) {
        if ( $_ =~ /^edit/ ) {
            push @{ $self->{allPcs} }, $_;
        }
    }

    #在各个pcs获取最小孔径
    foreach my $pcs ( @{ $self->{allPcs} } ) {
        $self->INFO(
            entity_type => 'step',
            entity_path => "$self->{Job}/$pcs",
            data_type   => 'ATTR'
        );

    #如果有阴阳拼或者旋转角度的，pcs为其没旋转和阴阳的pcs
        foreach my $i ( 0 .. $#{ $self->{doinfo}{gATTRname} } ) {
            if ( ${ $self->{doinfo}{gATTRname} }[$i] =~
                /(.flipped_of)|(.rotated_of)/ )
            {
                if ( ${ $self->{doinfo}{gATTRval} }[$i] ) {
                    $pcs = $self->{doinfo}{gATTRval}[$i];
                }
            }
        }

        foreach my $laser ( @{ $self->{laser}{drill} } ) {

            #获取孔层信息，孔的形状+孔的大小
            $self->INFO(
                entity_type => 'layer',
                units       => 'mm',
                entity_path => "$self->{Job}/$pcs/$laser",
                data_type   => 'TOOL',
                parameters  => "drill_size+shape"
            );
            my @toolShape     = @{ $self->{doinfo}{gTOOLshape} };
            my @toolDrillSize = @{ $self->{doinfo}{gTOOLdrill_size} };

            #获取最小孔径
            foreach my $i ( 0 .. $#toolShape ) {
                if ( $toolShape[$i] eq 'hole' ) {
                    if ( $self->{cfg}{minLaser} ) {
                        if ( $toolDrillSize[$i] < $self->{cfg}{minLaser} ) {
                            $self->{cfg}{minLaser} = $toolDrillSize[$i];
                        }
                    }
                    else {
                        $self->{cfg}{minLaser} = $toolDrillSize[$i];
                    }
                }
            }
        }

    }

    unless ( $self->{cfg}{minLaser} ) {
        $self->{cfg}{minLaser} = 100;
    }

    return 1;
}

#**********************************************
#名字		:getMindVia
#功能		:设置step的名字
#参数		:无
#返回值		:1
#使用例子	:$self->getMindVia();
#**********************************************
sub GetMinMind {
    my $self = shift;

    #获取pcs Step
    $self->getAllStep("$self->{panelStep}");
    foreach ( @{ $self->{allStep} } ) {
        if ( $_ =~ /^edit/ ) {
            push @{ $self->{allPcs} }, $_;
        }
    }

    #在各个pcs获取最小孔径
    foreach my $pcs ( @{ $self->{allPcs} } ) {
        $self->INFO(
            entity_type => 'step',
            entity_path => "$self->{Job}/$pcs",
            data_type   => 'ATTR'
        );

    #如果有阴阳拼或者旋转角度的，pcs为其没旋转和阴阳的pcs
        foreach my $i ( 0 .. $#{ $self->{doinfo}{gATTRname} } ) {
            if ( ${ $self->{doinfo}{gATTRname} }[$i] =~
                /(.flipped_of)|(.rotated_of)/ )
            {
                if ( ${ $self->{doinfo}{gATTRval} }[$i] ) {
                    $pcs = $self->{doinfo}{gATTRval}[$i];
                }
            }
        }

        foreach my $laser ( @{ $self->{bury}{drill} } ) {

            #获取孔层信息，孔的形状+孔的大小
            $self->INFO(
                entity_type => 'layer',
                units       => 'mm',
                entity_path => "$self->{Job}/$pcs/$laser",
                data_type   => 'TOOL',
                parameters  => "drill_size+shape"
            );
            my @toolShape     = @{ $self->{doinfo}{gTOOLshape} };
            my @toolDrillSize = @{ $self->{doinfo}{gTOOLdrill_size} };

            if (    $pcs eq $self->{editStep}
                and $#toolShape < 0 )
            {
                $self->{$laser}{minBury}{find} = 'no';
            }

            #获取最小孔径
            foreach my $i ( 0 .. $#toolShape ) {
                if ( $toolShape[$i] eq 'hole' ) {
                    if ( $self->{cfg}{minBury} ) {
                        if ( $toolDrillSize[$i] < $self->{cfg}{minBury} ) {
                            $self->{cfg}{minBury} = $toolDrillSize[$i];
                        }
                    }
                    else {
                        $self->{cfg}{minBury} = $toolDrillSize[$i];
                    }
                }
            }
        }

    }

    unless ( $self->{cfg}{minBury} ) {
        $self->{cfg}{minBury} = 275;
    }

    return 1;
}

#**********************************************
#名字		:getAllStep
#功能		:设置step的名字
#参数		:无
#返回值		:1
#使用例子	:$self->getAllStep();
#**********************************************
sub getAllStep {
    my $self = shift;
    my $step = shift;

    $self->INFO(
        entity_type => 'step',
        entity_path => "$self->{Job}/$step",
        data_type   => 'REPEAT'
    );
    my @SRStep = @{ $self->{doinfo}{gREPEATstep} };
    my %diff;
    my @diff = grep( !$diff{$_}++, @SRStep );
    if ( $#diff >= 0 ) {
        foreach (@diff) {
            $self->getAllStep($_);
        }
    }
    else {
        push @{ $self->{allStep} }, $step;
    }

    return 1;
}

#**********************************************
#名字		:GetJobType
#功能		:获取料号的类型
#参数		:无
#返回值		:1
#使用例子	:$self->GetJobType();
#**********************************************
sub GetJobType {
    my $self = shift;

    return 1;
}

sub InnerFillCuNewest {
    my $self = shift;
    $self->ClearAll();
    $self->VOF();
    $self->DeleteLayer("h-fillcut$self->{PID}");
    $self->DeleteLayer("h-fillcub$self->{PID}");
    $self->CreateLayer("h-fillcut$self->{PID}");
    $self->CreateLayer("h-fillcub$self->{PID}");
    $self->VON();

    $self->AffectedLayer("h-fillcut$self->{PID}");
    $self->COM( "units", type => "mm" );
    $self->COM(
        "add_pad",
        attributes => "no",
        x          => $self->{SR}{xmin} - 2,
        y          => $self->{PROF}{ymin},
        symbol     => "inner-zuliutiao",
        polarity   => "positive",
        angle      => "0",
        mirror     => "no",
        nx         => "1",
        ny         => "1",
        dx         => "0",
        dy         => "0",
        xscale     => "1",
        yscale     => "1"
    );
    $self->COM(
        "add_pad",
        attributes => "no",
        x          => $self->{SR}{xmax} + 2,
        y          => $self->{PROF}{ymax},
        symbol     => "inner-zuliutiao",
        polarity   => "positive",
        angle      => "180",
        mirror     => "no",
        nx         => "1",
        ny         => "1",
        dx         => "0",
        dy         => "0",
        xscale     => "1",
        yscale     => "1"
    );

    $self->COM("sel_break");
    $self->COM("clip_area_strt");
    $self->COM(
        "clip_area_xy",
        x => $self->{PROF}{xmin} + 6,
        y => $self->{SR}{ymax} + 1
    );
    $self->COM(
        "clip_area_xy",
        x => $self->{PROF}{xmax} - 6,
        y => $self->{SR}{ymin} - 1
    );
    $self->COM(
        "clip_area_end",
        layers_mode => "affected_layers",
        layer       => "",
        area        => "manual",
        area_type   => "rectangle",
        inout       => "outside",
        contour_cut => "yes",
        margin      => "0",
        feat_types  => "line;pad;surface;arc;text"
    );
    
    $self->COM(
        "add_pad",
        attributes => "no",
        x          => $self->{PROF}{xmax},
        y          => $self->{SR}{ymin} - 2,
        symbol     => "inner-zuliutiao",
        polarity   => "positive",
        angle      => "270",
        mirror     => "no",
        nx         => "1",
        ny         => "1",
        dx         => "0",
        dy         => "0",
        xscale     => "1",
        yscale     => "1"
    );
    $self->COM(
        "add_pad",
        attributes => "no",
        x          => $self->{PROF}{xmin},
        y          => $self->{SR}{ymax} + 2,
        symbol     => "inner-zuliutiao",
        polarity   => "positive",
        angle      => "90",
        mirror     => "no",
        nx         => "1",
        ny         => "1",
        dx         => "0",
        dy         => "0",
        xscale     => "1",
        yscale     => "1"
    );

    $self->COM("sel_break");
    $self->COM("clip_area_strt");
    $self->COM(
        "clip_area_xy",
        x => $self->{PROF}{xmin} + 6,
        y => $self->{PROF}{ymax} - 6
    );
    $self->COM(
        "clip_area_xy",
        x => $self->{PROF}{xmax} - 6,
        y => $self->{PROF}{ymin} + 6
    );
    $self->COM(
        "clip_area_end",
        layers_mode => "affected_layers",
        layer       => "",
        area        => "manual",
        area_type   => "rectangle",
        inout       => "outside",
        contour_cut => "yes",
        margin      => "0",
        feat_types  => "line;pad;surface;arc;text"
    );
    $self->COM(
        "fill_params",
        type           => "solid",
        origin_type    => "datum",
        solid_type     => "fill",
        std_type       => "line",
        min_brush      => "500",
        use_arcs       => "yes",
        symbol         => "",
        dx             => "2.54",
        dy             => "2.54",
        std_angle      => "45",
        std_line_width => "254",
        std_step_dist  => "1270",
        std_indent     => "odd",
        break_partial  => "yes",
        cut_prims      => "no",
        outline_draw   => "no",
        outline_width  => "0",
        outline_invert => "no"
    );
    $self->COM("sel_fill");
    $self->COM(
        "sel_contourize",
        accuracy         => "6.35",
        break_to_islands => "yes",
        clean_hole_size  => "76.2",
        clean_hole_mode  => "x_and_y"
    );


    #反面
    $self->ClearAll();
    $self->AffectedLayer("h-fillcub$self->{PID}");
    $self->COM( "units", type => "mm" );
    $self->COM(
        "add_pad",
        attributes => "no",
        x          => $self->{SR}{xmin} - 3.25,
        y          => $self->{PROF}{ymin},
        symbol     => "inner-zuliutiao",
        polarity   => "positive",
        angle      => "0",
        mirror     => "no",
        nx         => "1",
        ny         => "1",
        dx         => "0",
        dy         => "0",
        xscale     => "1",
        yscale     => "1"
    );
    $self->COM(
        "add_pad",
        attributes => "no",
        x          => $self->{SR}{xmax} + 3.25,
        y          => $self->{PROF}{ymax},
        symbol     => "inner-zuliutiao",
        polarity   => "positive",
        angle      => "180",
        mirror     => "no",
        nx         => "1",
        ny         => "1",
        dx         => "0",
        dy         => "0",
        xscale     => "1",
        yscale     => "1"
    );

    $self->COM("sel_break");
    $self->COM("clip_area_strt");
    $self->COM(
        "clip_area_xy",
        x => $self->{PROF}{xmin} + 6,
        y => $self->{SR}{ymax} + 2.25
    );
    $self->COM(
        "clip_area_xy",
        x => $self->{PROF}{xmax} - 6,
        y => $self->{SR}{ymin} - 2.25
    );
    $self->COM(
        "clip_area_end",
        layers_mode => "affected_layers",
        layer       => "",
        area        => "manual",
        area_type   => "rectangle",
        inout       => "outside",
        contour_cut => "yes",
        margin      => "0",
        feat_types  => "line;pad;surface;arc;text"
    );
    
    $self->COM(
        "add_pad",
        attributes => "no",
        x          => $self->{PROF}{xmax},
        y          => $self->{SR}{ymin} - 3.25,
        symbol     => "inner-zuliutiao",
        polarity   => "positive",
        angle      => "270",
        mirror     => "no",
        nx         => "1",
        ny         => "1",
        dx         => "0",
        dy         => "0",
        xscale     => "1",
        yscale     => "1"
    );
    $self->COM(
        "add_pad",
        attributes => "no",
        x          => $self->{PROF}{xmin},
        y          => $self->{SR}{ymax} + 3.25,
        symbol     => "inner-zuliutiao",
        polarity   => "positive",
        angle      => "90",
        mirror     => "no",
        nx         => "1",
        ny         => "1",
        dx         => "0",
        dy         => "0",
        xscale     => "1",
        yscale     => "1"
    );

    $self->COM("sel_break");
    $self->COM("clip_area_strt");
    $self->COM(
        "clip_area_xy",
        x => $self->{PROF}{xmin} + 6,
        y => $self->{PROF}{ymax} - 6
    );
    $self->COM(
        "clip_area_xy",
        x => $self->{PROF}{xmax} - 6,
        y => $self->{PROF}{ymin} + 6
    );
    $self->COM(
        "clip_area_end",
        layers_mode => "affected_layers",
        layer       => "",
        area        => "manual",
        area_type   => "rectangle",
        inout       => "outside",
        contour_cut => "yes",
        margin      => "0",
        feat_types  => "line;pad;surface;arc;text"
    );
    $self->COM(
        "fill_params",
        type           => "solid",
        origin_type    => "datum",
        solid_type     => "fill",
        std_type       => "line",
        min_brush      => "500",
        use_arcs       => "yes",
        symbol         => "",
        dx             => "2.54",
        dy             => "2.54",
        std_angle      => "45",
        std_line_width => "254",
        std_step_dist  => "1270",
        std_indent     => "odd",
        break_partial  => "yes",
        cut_prims      => "no",
        outline_draw   => "no",
        outline_width  => "0",
        outline_invert => "no"
    );
    $self->COM("sel_fill");
    $self->COM(
        "sel_contourize",
        accuracy         => "6.35",
        break_to_islands => "yes",
        clean_hole_size  => "76.2",
        clean_hole_mode  => "x_and_y"
    );
    #以t层为基准层，先铺5mm的实铜。
    $self->ClearAll();
    $self->AffectedLayer("h-fillcut$self->{PID}");
    $self->AffectedLayer("h-fillcub$self->{PID}");
    $self->COM(
        'fill_params',
        type           => 'solid',
        origin_type    => 'datum',
        solid_type     => 'surface',
        std_type       => 'line',
        min_brush      => '25.4',
        use_arcs       => 'yes',
        symbol         => 'new_fill_v',
        dx             => 5,
        dy             => 4,
        std_angle      => 45,
        std_line_width => 10,
        std_step_dist  => 50,
        std_indent     => 'odd',
        break_partial  => 'yes',
        cut_prims      => 'no',
        outline_draw   => 'no',
        outline_width  => 0,
        outline_invert => 'no'
    );
    $self->COM(
        'sr_fill',
        polarity        => 'positive',
        step_margin_x   => 0,
        step_margin_y   => 0,
        step_max_dist_x => 5,
        step_max_dist_y => 5,
        sr_margin_x     => '2.5',
        sr_margin_y     => '2.5',
        sr_max_dist_x   => 0,
        sr_max_dist_y   => 0,
        nest_sr         => 'no',
        consider_feat   => 'no',
        consider_drill  => 'no',
        consider_rout   => 'no',
        dest            => 'affected_layers',
        attributes      => 'no',
    );
    $self->SelectContourize();
    $self->ClearAll();
    
    #计算流胶口个数
    my $liujiaoXcount = int(($self->{PROF}{xmax} - $self->{PROF}{xmin} - 50) * 0.5 / 100);
    my $liujiaoYcount = int(($self->{PROF}{ymax} - $self->{PROF}{ymin} - 50) * 0.5 / 100);
    
    $self->ClearAll();
    $self->AffectedLayer("h-fillcut$self->{PID}");
    $self->SetLayer("h-fillcut$self->{PID}");
    
    #上面左边
    for (my $i = 1;$i <= $liujiaoXcount;$i++)
    {
        $self->COM(
            "add_pad",
            attributes => "no",
            x          => $self->{PROF}{xmin} + 100 * $i,
            y          => $self->{PROF}{ymax},
            symbol     => "inner-liujiaocao",
            polarity   => "negative",
            angle      => "90",
            mirror     => "no",
            nx         => "1",
            ny         => "1",
            dx         => "0",
            dy         => "0",
            xscale     => "1",
            yscale     => "1"
        );
    }
    #上面右边
    for (my $i = 1;$i <= $liujiaoXcount;$i++)
    {
        $self->COM(
            "add_pad",
            attributes => "no",
            x          => $self->{PROF}{xmax} - 100 * $i,
            y          => $self->{PROF}{ymax},
            symbol     => "inner-liujiaocao",
            polarity   => "negative",
            angle      => "0",
            mirror     => "no",
            nx         => "1",
            ny         => "1",
            dx         => "0",
            dy         => "0",
            xscale     => "1",
            yscale     => "1"
        );
    }
    #下面左边
    for (my $i = 1;$i <= $liujiaoXcount;$i++)
    {
        $self->COM(
            "add_pad",
            attributes => "no",
            x          => $self->{PROF}{xmin} + 100 * $i,
            y          => $self->{PROF}{ymin},
            symbol     => "inner-liujiaocao",
            polarity   => "negative",
            angle      => "0",
            mirror     => "no",
            nx         => "1",
            ny         => "1",
            dx         => "0",
            dy         => "0",
            xscale     => "1",
            yscale     => "1"
        );
    }
    #下面右边
    for (my $i = 1;$i <= $liujiaoXcount;$i++)
    {
        $self->COM(
            "add_pad",
            attributes => "no",
            x          => $self->{PROF}{xmax} - 100 * $i,
            y          => $self->{PROF}{ymin},
            symbol     => "inner-liujiaocao",
            polarity   => "negative",
            angle      => "90",
            mirror     => "no",
            nx         => "1",
            ny         => "1",
            dx         => "0",
            dy         => "0",
            xscale     => "1",
            yscale     => "1"
        );
    }
    
    #左边上面
    for (my $i = 1;$i <= $liujiaoYcount;$i++)
    {
        $self->COM(
            "add_pad",
            attributes => "no",
            x          => $self->{PROF}{xmin},
            y          => $self->{PROF}{ymax} - $i * 100,
            symbol     => "inner-liujiaocao",
            polarity   => "negative",
            angle      => "90",
            mirror     => "no",
            nx         => "1",
            ny         => "1",
            dx         => "0",
            dy         => "0",
            xscale     => "1",
            yscale     => "1"
        );
    }
    #左边下面
    for (my $i = 1;$i <= $liujiaoYcount;$i++)
    {
        $self->COM(
            "add_pad",
            attributes => "no",
            x          => $self->{PROF}{xmin},
            y          => $self->{PROF}{ymin} + $i * 100,
            symbol     => "inner-liujiaocao",
            polarity   => "negative",
            angle      => "0",
            mirror     => "no",
            nx         => "1",
            ny         => "1",
            dx         => "0",
            dy         => "0",
            xscale     => "1",
            yscale     => "1"
        );
    }
    
    #右边上面
    for (my $i = 1;$i <= $liujiaoYcount;$i++)
    {
        $self->COM(
            "add_pad",
            attributes => "no",
            x          => $self->{PROF}{xmax},
            y          => $self->{PROF}{ymax} - $i * 100,
            symbol     => "inner-liujiaocao",
            polarity   => "negative",
            angle      => "0",
            mirror     => "no",
            nx         => "1",
            ny         => "1",
            dx         => "0",
            dy         => "0",
            xscale     => "1",
            yscale     => "1"
        );
    }
    #右边下面
    for (my $i = 1;$i <= $liujiaoYcount;$i++)
    {
        $self->COM(
            "add_pad",
            attributes => "no",
            x          => $self->{PROF}{xmax},
            y          => $self->{PROF}{ymin} + $i * 100,
            symbol     => "inner-liujiaocao",
            polarity   => "negative",
            angle      => "90",
            mirror     => "no",
            nx         => "1",
            ny         => "1",
            dx         => "0",
            dy         => "0",
            xscale     => "1",
            yscale     => "1"
        );
    }
    $self->COM( "filter_reset", filter_name => "popup" );
    $self->COM(
        "filter_set",
        filter_name  => "popup",
        update_popup => "no",
        polarity     => "negative"
    );
    $self->COM("filter_area_strt");
    $self->COM(
        "filter_area_end",
        layer          => "",
        filter_name    => "popup",
        operation      => "select",
        area_type      => "none",
        inside_area    => "no",
        intersect_area => "no"
    );
    $self->COM( "filter_reset", filter_name => "popup" );
    if ($self->GetSelectNumber() > 0)
    {
        $self->COM(
            "sel_copy_other",
            dest         => "layer_name",
            target_layer => "h-fillcub$self->{PID}",
            invert       => "no",
            dx           => "0",
            dy           => "0",
            size         => "0",
            x_anchor     => "0",
            y_anchor     => "0",
            rotation     => "0",
            mirror       => "none"
        );
    }
    $self->ClearAll();
    $self->AffectedLayer("h-fillcub$self->{PID}");
    
    $self->COM( "filter_reset", filter_name => "popup" );
    $self->COM(
        "filter_set",
        filter_name  => "popup",
        update_popup => "no",
        polarity     => "negative"
    );
    $self->COM("filter_area_strt");
    $self->COM(
        "filter_area_end",
        layer          => "",
        filter_name    => "popup",
        operation      => "select",
        area_type      => "none",
        inside_area    => "no",
        intersect_area => "no"
    );
    $self->COM( "filter_reset", filter_name => "popup" );
    if ($self->GetSelectNumber() > 0)
    {
        $self->COM(
            "sel_transform",
            mode      => "axis",
            oper      => "rotate",
            duplicate => "no",
            x_anchor  => "0",
            y_anchor  => "0",
            angle     => "90",
            x_scale   => "1",
            y_scale   => "1",
            x_offset  => "0",
            y_offset  => "0"
        );
    }
    
    $self->ClearAll();
    $self->AffectedLayer("h-fillcut$self->{PID}");
    $self->AffectedLayer("h-fillcub$self->{PID}");
    
    #左上角
    $self->COM(
        "add_pad",
        attributes => "no",
        x          => $self->{PROF}{xmin},
        y          => $self->{PROF}{ymax},
        symbol     => "inner-liujiaocao",
        polarity   => "negative",
        angle      => "90",
        mirror     => "no",
        nx         => "1",
        ny         => "1",
        dx         => "0",
        dy         => "0",
        xscale     => "1",
        yscale     => "1"
    );
    #右上角
    $self->COM(
        "add_pad",
        attributes => "no",
        x          => $self->{PROF}{xmax},
        y          => $self->{PROF}{ymax},
        symbol     => "inner-liujiaocao",
        polarity   => "negative",
        angle      => "0",
        mirror     => "no",
        nx         => "1",
        ny         => "1",
        dx         => "0",
        dy         => "0",
        xscale     => "1",
        yscale     => "1"
    );
    
    #左下角
    $self->COM(
        "add_pad",
        attributes => "no",
        x          => $self->{PROF}{xmin},
        y          => $self->{PROF}{ymin},
        symbol     => "inner-liujiaocao",
        polarity   => "negative",
        angle      => "0",
        mirror     => "no",
        nx         => "1",
        ny         => "1",
        dx         => "0",
        dy         => "0",
        xscale     => "1",
        yscale     => "1"
    );
    #右下角
    $self->COM(
        "add_pad",
        attributes => "no",
        x          => $self->{PROF}{xmax},
        y          => $self->{PROF}{ymin},
        symbol     => "inner-liujiaocao",
        polarity   => "negative",
        angle      => "90",
        mirror     => "no",
        nx         => "1",
        ny         => "1",
        dx         => "0",
        dy         => "0",
        xscale     => "1",
        yscale     => "1"
    );

    #中间
    $self->COM(
        "add_line",
        attributes    => "no",
        xs            => $self->{PROF}{xmin} + ($self->{PROF}{xmax} - $self->{PROF}{xmin}) * 0.5 + 1,
        ys            => $self->{PROF}{ymax} + 20,
        xe            => $self->{PROF}{xmin} + ($self->{PROF}{xmax} - $self->{PROF}{xmin}) * 0.5 + 1,
        ye            => $self->{PROF}{ymin} - 20,
        symbol        => "r1000",
        polarity      => "negative",
        bus_num_lines => "0",
        bus_dist_by   => "pitch",
        bus_distance  => "0",
        bus_reference => "left"
    );
    
    $self->COM(
        "add_line",
        attributes    => "no",
        xs            => $self->{PROF}{xmin} - 20,
        ys            => $self->{PROF}{ymin} + ($self->{PROF}{ymax} - $self->{PROF}{ymin}) * 0.5,
        xe            => $self->{PROF}{xmax} + 20,
        ye            => $self->{PROF}{ymin} + ($self->{PROF}{ymax} - $self->{PROF}{ymin}) * 0.5,
        symbol        => "r1000",
        polarity      => "negative",
        bus_num_lines => "0",
        bus_dist_by   => "pitch",
        bus_distance  => "0",
        bus_reference => "left"
    );

    $self->COM("clip_area_strt");
    $self->COM(
        "clip_area_xy",
        x => $self->{PROF}{xmin} + 5.1,
        y => $self->{PROF}{ymax} - 5.1
    );
    $self->COM(
        "clip_area_xy",
        x => $self->{PROF}{xmax} - 5.1,
        y => $self->{PROF}{ymin} + 5.1
    );
    $self->COM(
        "clip_area_end",
        layers_mode => "affected_layers",
        layer       => "",
        area        => "manual",
        area_type   => "rectangle",
        inout       => "inside",
        contour_cut => "yes",
        margin      => "0",
        feat_types  => "pad;line"
    );
    
    $self->COM("clip_area_strt");
    $self->COM(
        "clip_area_xy",
        x => $self->{PROF}{xmin} - 0.1,
        y => $self->{PROF}{ymax} + 0.1
    );
    $self->COM(
        "clip_area_xy",
        x => $self->{PROF}{xmax} + 0.1,
        y => $self->{PROF}{ymin} - 0.1
    );
    $self->COM(
        "clip_area_end",
        layers_mode => "affected_layers",
        layer       => "",
        area        => "manual",
        area_type   => "rectangle",
        inout       => "outside",
        contour_cut => "yes",
        margin      => "0",
        feat_types  => "line;pad;surface;arc;text"
    );
    
    $self->COM(
        "fill_params",
        type           => "pattern",
        origin_type    => "datum",
        solid_type     => "surface",
        std_type       => "line",
        min_brush      => "25.4",
        use_arcs       => "yes",
        symbol         => "r1000",
        dx             => "1.5",
        dy             => "1.5",
        x_off          => "0",
        y_off          => "0",
        std_angle      => "45",
        std_line_width => "10",
        std_step_dist  => "50",
        std_indent     => "odd",
        break_partial  => "yes",
        cut_prims      => "no",
        outline_draw   => "no",
        outline_width  => "0",
        outline_invert => "no"
    );
    $self->COM(
        "sr_fill",
        polarity        => "positive",
        step_margin_x   => $self->{SR}{xmin} - $self->{PROF}{xmin},
        step_margin_y   => $self->{SR}{ymin} - $self->{PROF}{ymin},
        step_max_dist_x => "2540",
        step_max_dist_y => "2540",
        sr_margin_x     => "2",
        sr_margin_y     => "2",
        sr_max_dist_x   => "0",
        sr_max_dist_y   => "0",
        nest_sr         => "no",
        consider_feat   => "no",
        consider_drill  => "no",
        consider_rout   => "no",
        dest            => "affected_layers",
        attributes      => "no"
    );
    
    $self->ClearAll();
    $self->DisplayLayer( "h-fillcut$self->{PID}", '1' );
    $self->WorkLayer("h-fillcut$self->{PID}");
    foreach ( @{ $self->{signalLayer}{layer} } ) {
        if ( $_ =~ /(in|sec)\d{1,2}t/ ) {
            $self->AffectedLayer("$_");
        }
    }

    $self->COM(
        'sel_copy_other',
        dest   => 'affected_layers',
        invert => 'no',
        size   => 0
    );

    $self->ClearAll();
    $self->DisplayLayer( "h-fillcub$self->{PID}", '1' );
    $self->WorkLayer("h-fillcub$self->{PID}");
    foreach ( @{ $self->{signalLayer}{layer} } ) {
        if ( $_ =~ /(in|sec)\d{1,2}b/ ) {
            $self->AffectedLayer("$_");
        }
    }

    $self->COM(
        'sel_copy_other',
        dest   => 'affected_layers',
        invert => 'no',
        size   => 0
    );
    $self->ClearAll();

    if ( $self->LayerExists( "$self->{panelStep}", "h-fillcut$self->{PID}" ) ) {
        $self->DeleteLayer("h-fillcut$self->{PID}");
    }

    if ( $self->LayerExists( "$self->{panelStep}", "h-fillcub$self->{PID}" ) ) {
        $self->DeleteLayer("h-fillcub$self->{PID}");
    }

    return 1;


}

#**********************************************
#名字		:fillCu
#功能		:内层铺阻流边
#参数		:无
#返回值		:1
#使用例子	:$self->fillCu();
#**********************************************
sub InnerFillCu {
    my $self = shift;

    #获取内层铜厚

    $self->{fillCuMode} = 'bigCu';    #内层铺铜模式 大铜皮 默认模式

    foreach my $coreValue ( %{ $self->{ERP}{InnerCuThk} } ) {
        if ( defined $self->{ERP}{InnerCuThk}{$coreValue}
            and $self->{ERP}{InnerCuThk}{$coreValue} =~ /(.*)\/(.*)/ )
        {
            if ( $1 >= 2 or $2 >= 2 ) { #内层铜厚任意一面大于等于2oz
                $self->{fillCuMode} = 'zuLiuTiao';    #阻流条
            }
        }
    }

#新增的条件：如果内层铜厚大于等于1oz的样品直接切入最新的内层铺铜方式设计。
#判断铜厚
#	my $cuhou=0;
#	my $sample=0;
#	foreach my $coreValue (%{$self->{ERP}{InnerCuThk}}){
#		if (defined $self->{ERP}{InnerCuThk}{$coreValue} and $self->{ERP}{InnerCuThk}{$coreValue} =~ /(.*)\/(.*)/){
#			if ($1 >= 1 or $2 >= 1){ #内层铜厚任意一面大于等于1oz
#				$cuhou=1;
#			}
#		}
#	}
#	#判断样品量产
#	if ($self->{Job} =~ /^t/){
#		$sample=1;
#	}
#
#	if($cuhou == '1' and $sample == '1' ){
    $self->{fillCuMode} = 'new_fillcu'
      ;    #铜厚大于1oz的所有样品，切入最新的铺铜方式。

    #	}

    #创建新层
    $self->CreateLayer("h-fillcut$self->{PID}");
    $self->CreateLayer("h-fillcub$self->{PID}");

    if ( $self->{fillCuMode} eq 'zuLiuTiao' ) {

        #prof线层，用来clip靠近prof的线
        $self->COM(
            'profile_to_rout',
            layer => 'h-prof',
            width => 3600
        );

        #加阻流边层
        $self->SetLayer("h-fillcut$self->{PID}");
        $self->CountFillCu();

        #添加铜
        $self->ClearAll();
        $self->AffectedLayer("h-fillcut$self->{PID}");
        foreach my $i ( 0 .. $#{ $self->{fillCu}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{fillCu}{x}[$i],
                y          => $self->{fillCu}{y}[$i],
                symbol     => $self->{fillCu}{symbol}[$i],
                polarity   => 'positive',
                angle      => 0,
                mirror     => 'no',
                nx         => $self->{fillCu}{countX}[$i],
                ny         => $self->{fillCu}{countY}[$i],
                dx         => $self->{fillCu}{distanceX}[$i],
                dy         => $self->{fillCu}{distanceY}[$i],
                xscale     => 1,
                yscale     => 1
            );
        }

        #底层阻流口
        $self->SetLayer("h-fillcub$self->{PID}");
        $self->CountFillCu();

        #添加铜
        $self->ClearAll();
        $self->AffectedLayer("h-fillcub$self->{PID}");
        foreach my $i ( 0 .. $#{ $self->{fillCu}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{fillCu}{x}[$i],
                y          => $self->{fillCu}{y}[$i],
                symbol     => $self->{fillCu}{symbol}[$i],
                polarity   => 'positive',
                angle      => 0,
                mirror     => 'no',
                nx         => $self->{fillCu}{countX}[$i],
                ny         => $self->{fillCu}{countY}[$i],
                dx         => $self->{fillCu}{distanceX}[$i],
                dy         => $self->{fillCu}{distanceY}[$i],
                xscale     => 1,
                yscale     => 1
            );
        }

        $self->AffectedLayer("h-fillcut$self->{PID}");
        $self->COM('sel_break');

        #加铜点
        $self->COM(
            'fill_params',
            type           => 'pattern',
            origin_type    => 'datum',
            solid_type     => 'surface',
            std_type       => 'line',
            min_brush      => 25.4,
            use_arcs       => 'yes',
            symbol         => 'r1000',
            dx             => '1.5',
            dy             => '1.5',
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

        $self->COM(
            'sr_fill',
            polarity        => 'positive',
            step_margin_x   => 2,
            step_margin_y   => 2,
            step_max_dist_x => 254,
            step_max_dist_y => 254,
            sr_margin_x     => 2,
            sr_margin_y     => 2,
            sr_max_dist_x   => 0,
            sr_max_dist_y   => 0,
            nest_sr         => 'no',
            consider_feat   => 'yes',
            feat_margin     => '2',
            consider_drill  => 'no',
            consider_rout   => 'no',
            dest            => 'affected_layers',
            attributes      => 'no'
        );

        #碰prof线，如果碰到，删掉
        $self->COM(
            'sel_ref_feat',
            layers  => "h-prof",
            use     => 'filter',
            mode    => 'touch',
            pads_as => 'shape',
        );

        if ( $self->GetSelectNumber() ) {
            $self->COM('sel_delete');
        }

        #切掉profile外面的
        $self->COM(
            'clip_area_end',
            layers_mode => 'affected_layers',
            layer       => '',
            area        => 'profile',
            area_type   => 'rectangle',
            inout       => 'outside',
            contour_cut => 'no',
            margin      => 0,
            feat_types  => 'line;pad;surface;arc;text'
        );

        #把内层4mil的profile线拷贝到阻流边
        $self->ClearAll();
        $self->AffectedLayer( "h-prof", '1' );
        $self->COM( 'sel_resize_poly', size => 6000 );
        $self->COM(
            'sel_change_sym',
            symbol        => 'r101.6',
            'reset_angle' => 'no'
        );
        $self->COM(
            'sel_copy_other',
            dest         => 'layer_name',
            target_layer => "h-fillcut$self->{PID}",
            invert       => 'no'
        );

        $self->COM(
            'sel_copy_other',
            dest         => 'layer_name',
            target_layer => "h-fillcub$self->{PID}",
            invert       => 'no'
        );

        #}
    }
    elsif ( $self->{fillCuMode} eq 'bigCu' ) {
        $self->ClearAll();
        $self->AffectedLayer("h-fillcut$self->{PID}");
        $self->AffectedLayer("h-fillcub$self->{PID}");
        $self->COM(
            'fill_params',
            type           => 'solid',
            origin_type    => 'datum',
            solid_type     => 'surface',
            std_type       => 'line',
            min_brush      => 1,
            use_arcs       => 'yes',
            symbol         => '',
            dx             => '0.1',
            dy             => '0.1',
            std_angle      => 45,
            std_line_width => 10,
            std_step_dist  => 50,
            std_indent     => 'odd',
            break_partial  => 'yes',
            cut_prims      => 'no',
            outline_draw   => 'no',
            outline_width  => 0,
            outline_invert => 'no'
        );

        $self->COM(
            'sr_fill',
            polarity        => 'positive',
            step_margin_x   => '2.5',
            step_margin_y   => '2.5',
            step_max_dist_x => 2540,
            step_max_dist_y => 2540,
            sr_margin_x     => '2.5',
            sr_margin_y     => '2.5',
            sr_max_dist_x   => 0,
            sr_max_dist_y   => 0,
            nest_sr         => 'no',
            consider_feat   => 'no',
            consider_drill  => 'no',
            consider_rout   => 'no',
            dest            => 'affected_layers',
            attributes      => 'no'
        );
        $self->ClearAll();
        $self->SetLayer("h-fillcut$self->{PID}");
        $self->CountLayerType();
        $self->CountFillCu();
        $self->AffectedLayer("h-fillcut$self->{PID}");

        #添加铜
        foreach my $i ( 0 .. $#{ $self->{liuJiao}{Start}{x} } ) {
            $self->COM(
                'add_line',
                attributes    => 'no',
                xs            => $self->{liuJiao}{Start}{x}[$i],
                ys            => $self->{liuJiao}{Start}{y}[$i],
                xe            => $self->{liuJiao}{End}{x}[$i],
                ye            => $self->{liuJiao}{End}{y}[$i],
                symbol        => 'r2540',
                polarity      => 'negative',
                bus_num_lines => 1,
                bus_dist_by   => 'pitch',
                bus_distance  => 0,
                bus_reference => 'left'
            );
        }

        $self->ClearAll();
        $self->SetLayer("h-fillcub$self->{PID}");
        $self->CountLayerType();
        $self->CountFillCu();
        $self->AffectedLayer("h-fillcub$self->{PID}");

        #添加流胶口
        foreach my $i ( 0 .. $#{ $self->{liuJiao}{Start}{x} } ) {
            $self->COM(
                'add_line',
                attributes    => 'no',
                xs            => $self->{liuJiao}{Start}{x}[$i],
                ys            => $self->{liuJiao}{Start}{y}[$i],
                xe            => $self->{liuJiao}{End}{x}[$i],
                ye            => $self->{liuJiao}{End}{y}[$i],
                symbol        => 'r2540',
                polarity      => 'negative',
                bus_num_lines => 1,
                bus_dist_by   => 'pitch',
                bus_distance  => 0,
                bus_reference => 'left'
            );
        }

        $self->ClearAll();
        $self->AffectedLayer("h-fillcut$self->{PID}");
        $self->AffectedLayer("h-fillcub$self->{PID}");
        $self->SelectContourize();

        #添加
        $self->COM('add_polyline_strt');
        $self->COM(
            'add_polyline_xy',
            x => $self->{out_line}{x}[0],
            y => $self->{out_line}{y}[0]
        );
        $self->COM(
            'add_polyline_xy',
            x => $self->{out_line}{x}[1],
            y => "$self->{out_line}{y}[0]"
        );
        $self->COM(
            'add_polyline_xy',
            x => $self->{out_line}{x}[1],
            y => $self->{out_line}{y}[1]
        );
        $self->COM(
            'add_polyline_xy',
            x => $self->{out_line}{x}[0],
            y => $self->{out_line}{y}[1]
        );
        $self->COM(
            'add_polyline_xy',
            x => $self->{out_line}{x}[0],
            y => $self->{out_line}{y}[0]
        );
        $self->COM(
            'add_polyline_end',
            attributes    => 'no',
            symbol        => 'r101.6',
            polarity      => 'positive',
            bus_num_lines => 1,
            bus_dist_by   => 'pitch',
            bus_distance  => 0,
            bus_reference => 'right'
        );
    }
    elsif ( $self->{fillCuMode} eq 'new_fillcu' )
    {    #新增的铺铜方式 add by wxl 20170104
        $self->InnerFillCu_new( "h-fillcut$self->{PID}",
            "h-fillcub$self->{PID}" );
    }

    $self->ClearAll();
    $self->DisplayLayer( "h-fillcut$self->{PID}", '1' );
    $self->WorkLayer("h-fillcut$self->{PID}");
    foreach ( @{ $self->{signalLayer}{layer} } ) {
        if ( $_ =~ /(in|sec)\d{1,2}t/ ) {
            $self->AffectedLayer("$_");
        }
    }

    $self->COM(
        'sel_copy_other',
        dest   => 'affected_layers',
        invert => 'no',
        size   => 0
    );

    $self->ClearAll();
    $self->DisplayLayer( "h-fillcub$self->{PID}", '1' );
    $self->WorkLayer("h-fillcub$self->{PID}");
    foreach ( @{ $self->{signalLayer}{layer} } ) {
        if ( $_ =~ /(in|sec)\d{1,2}b/ ) {
            $self->AffectedLayer("$_");
        }
    }

    $self->COM(
        'sel_copy_other',
        dest   => 'affected_layers',
        invert => 'no',
        size   => 0
    );
    $self->ClearAll();

    if ( $self->LayerExists( "$self->{panelStep}", "h-fillcut$self->{PID}" ) ) {
        $self->DeleteLayer("h-fillcut$self->{PID}");
    }

    if ( $self->LayerExists( "$self->{panelStep}", "h-fillcub$self->{PID}" ) ) {
        $self->DeleteLayer("h-fillcub$self->{PID}");
    }

    return 1;
}

#**********************************************
#名字		:InnerFillCu_new
#功能		:新增的内层铺铜方式
#参数		:无
#返回值		:1
#使用例子	:$self->InnerFillCu_new();
#**********************************************
sub InnerFillCu_new {
    my $self    = shift;
    my $layer_t = shift;
    my $layer_b = shift;

    #以t层为基准层，先铺5mm的实铜。
    $self->ClearAll();
    $self->AffectedLayer("$layer_t");
    $self->AffectedLayer("$layer_b");
    $self->COM(
        'fill_params',
        type           => 'solid',
        origin_type    => 'datum',
        solid_type     => 'surface',
        std_type       => 'line',
        min_brush      => '25.4',
        use_arcs       => 'yes',
        symbol         => 'new_fill_v',
        dx             => 5,
        dy             => 4,
        std_angle      => 45,
        std_line_width => 10,
        std_step_dist  => 50,
        std_indent     => 'odd',
        break_partial  => 'yes',
        cut_prims      => 'no',
        outline_draw   => 'no',
        outline_width  => 0,
        outline_invert => 'no'
    );
    $self->COM(
        'sr_fill',
        polarity        => 'positive',
        step_margin_x   => 0,
        step_margin_y   => 0,
        step_max_dist_x => 5,
        step_max_dist_y => 5,
        sr_margin_x     => '2.5',
        sr_margin_y     => '2.5',
        sr_max_dist_x   => 0,
        sr_max_dist_y   => 0,
        nest_sr         => 'no',
        consider_feat   => 'no',
        consider_drill  => 'no',
        consider_rout   => 'no',
        dest            => 'affected_layers',
        attributes      => 'no',

        #use_profile     => 'use_profile'
    );
    $self->ClearAll();
    $self->AffectedLayer("$layer_t");
    $self->SetLayer("$layer_t");

    #铜皮上添加流胶槽
    $self->CountFillCu();

    #添加流胶口
    foreach my $i ( 0 .. $#{ $self->{liuJiao}{Start}{x} } ) {
        $self->COM(
            'add_line',
            attributes    => 'no',
            xs            => $self->{liuJiao}{Start}{x}[$i],
            ys            => $self->{liuJiao}{Start}{y}[$i],
            xe            => $self->{liuJiao}{End}{x}[$i],
            ye            => $self->{liuJiao}{End}{y}[$i],
            symbol        => 'r2000',
            polarity      => 'negative',
            bus_num_lines => 1,
            bus_dist_by   => 'pitch',
            bus_distance  => 0,
            bus_reference => 'left'
        );
    }
    $self->SelectContourize();

    $self->ClearAll();
    $self->AffectedLayer("$layer_b");
    $self->SetLayer("$layer_b");

    #铜皮上添加流胶槽
    $self->CountFillCu();

    #添加流胶口
    foreach my $i ( 0 .. $#{ $self->{liuJiao}{Start}{x} } ) {
        $self->COM(
            'add_line',
            attributes    => 'no',
            xs            => $self->{liuJiao}{Start}{x}[$i],
            ys            => $self->{liuJiao}{Start}{y}[$i],
            xe            => $self->{liuJiao}{End}{x}[$i],
            ye            => $self->{liuJiao}{End}{y}[$i],
            symbol        => 'r2000',
            polarity      => 'negative',
            bus_num_lines => 1,
            bus_dist_by   => 'pitch',
            bus_distance  => 0,
            bus_reference => 'left'
        );
    }
    $self->SelectContourize();

    #新建一个临时层铺上方距离板边5mm，距离sr 2.5mm的铜皮。
    my $topLayer1 = "top1$self->{PID}";
    my $topLayer2 = "top2$self->{PID}";
    $self->ClearAll();
    $self->CreateLayer("$topLayer1");
    $self->CreateLayer("$topLayer2");
    $self->DisplayLayer( "$topLayer1", '1' );
    $self->WorkLayer("$topLayer1");

    #上端坐标计算
    my $top_x1 = $self->{PROF}{xmin} + 6.5;
    my $top_y1 = $self->{SR}{ymax} + 2.5;
    my $top_x2 = $self->{PROF}{xmax} - 6.5;
    my $top_y2 = $self->{PROF}{ymax} - 6.5;

    #画上端铜皮
    $self->COM(
        'fill_params',
        type           => 'solid',
        origin_type    => 'datum',
        solid_type     => 'surface',
        std_type       => 'line',
        min_brush      => '25.4',
        use_arcs       => 'yes',
        symbol         => 'new_fill_v',
        dx             => 5,
        dy             => 4,
        std_angle      => 45,
        std_line_width => 10,
        std_step_dist  => 50,
        std_indent     => 'odd',
        break_partial  => 'yes',
        cut_prims      => 'no',
        outline_draw   => 'no',
        outline_width  => 0,
        outline_invert => 'no'
    );
    $self->COM( 'add_surf_strt',      surf_type => 'feature' );
    $self->COM( 'add_surf_poly_strt', x         => $top_x1, y => $top_y1 );
    $self->COM( 'add_surf_poly_seg',  x         => $top_x1, y => $top_y2 );
    $self->COM( 'add_surf_poly_seg',  x         => $top_x2, y => $top_y2 );
    $self->COM( 'add_surf_poly_seg',  x         => $top_x2, y => $top_y1 );
    $self->COM( 'add_surf_poly_seg',  x         => $top_x1, y => $top_y1 );
    $self->COM('add_surf_poly_end');
    $self->COM( 'add_surf_end', attributes => 'no', polarity => 'positive' );

    #铺成铜条
    $self->COM(
        'fill_params',
        type           => 'pattern',
        origin_type    => 'datum',
        solid_type     => 'surface',
        std_type       => 'line',
        min_brush      => '25.4',
        use_arcs       => 'yes',
        symbol         => 'new_fill_h',
        dx             => 4,
        dy             => 5,
        std_angle      => 45,
        std_line_width => 10,
        std_step_dist  => 50,
        std_indent     => 'odd',
        break_partial  => 'yes',
        cut_prims      => 'yes',
        outline_draw   => 'no',
        outline_width  => 0,
        outline_invert => 'no'
    );
    $self->COM('sel_fill');

    #把小于0.1mm的去掉
    $self->COM( 'sel_resize', size => -100, corner_ctl => 'no' );
    $self->COM( 'sel_resize', size => 100,  corner_ctl => 'no' );

    $self->COM(
        'sel_copy_other',
        dest         => 'layer_name',
        target_layer => "$topLayer2",
        invert       => 'no'
    );

    #上向下镜像，保留镜像来源。
    my $xcenter =
      $self->{PROF}{xmin} + ( $self->{PROF}{xmax} - $self->{PROF}{xmin} ) / 2;
    my $ycenter =
      $self->{PROF}{ymin} + ( $self->{PROF}{ymax} - $self->{PROF}{ymin} ) / 2;
    $self->COM(
        'sel_transform',
        mode      => 'anchor',
        oper      => 'y_mirror',
        duplicate => 'yes',
        x_anchor  => $xcenter,
        y_anchor  => $ycenter,
        angle     => 90,
        x_scale   => 1,
        y_scale   => 1,
        x_offset  => 0,
        y_offset  => 0
    );

    #底层的，向上移动1mm，
    $self->DisplayLayer( "$topLayer2", '1' );
    $self->WorkLayer("$topLayer2");
    $self->COM(
        'sel_transform',
        mode      => 'anchor',
        oper      => 'scale',
        duplicate => 'no',
        x_anchor  => $xcenter,
        y_anchor  => $ycenter,
        angle     => 90,
        x_scale   => 1,
        y_scale   => 1,
        x_offset  => 0,
        y_offset  => 1
    );
    $self->COM(
        'sel_transform',
        mode      => 'anchor',
        oper      => 'y_mirror',
        duplicate => 'yes',
        x_anchor  => $xcenter,
        y_anchor  => $ycenter,
        angle     => 90,
        x_scale   => 1,
        y_scale   => 1,
        x_offset  => 0,
        y_offset  => 0
    );

    #把2移动到底层铜皮层
    $self->COM(
        'sel_move_other',
        target_layer => $layer_b,
        invert       => 'no',
        dx           => 0,
        dy           => 0,
        size         => 0,
        x_anchor     => 0,
        y_anchor     => 0,
        rotation     => 0,
        mirror       => 'none'
    );

    #把1移动到顶层铜皮层
    $self->DisplayLayer( "$topLayer1", '1' );
    $self->WorkLayer("$topLayer1");
    $self->COM(
        'sel_move_other',
        target_layer => $layer_t,
        invert       => 'no',
        dx           => 0,
        dy           => 0,
        size         => 0,
        x_anchor     => 0,
        y_anchor     => 0,
        rotation     => 0,
        mirror       => 'none'
    );

    #以上为上下作业完成
    #以下为左右作业，也是在$topLayer1 $topLayer2 里面
    $self->ClearAll();
    $self->DisplayLayer( "$topLayer1", '1' );
    $self->WorkLayer("$topLayer1");

    #左端坐标计算
    my $left_x1 = $self->{PROF}{xmin} + 6.5;
    my $left_y1 = $self->{SR}{ymin} - 1.5;
    my $left_x2 = $self->{SR}{xmin} - 2.5;
    my $left_y2 = $self->{SR}{ymax} + 1.5;

    #画上端铜皮
    $self->COM(
        'fill_params',
        type           => 'solid',
        origin_type    => 'datum',
        solid_type     => 'surface',
        std_type       => 'line',
        min_brush      => '25.4',
        use_arcs       => 'yes',
        symbol         => 'new_fill_v',
        dx             => 5,
        dy             => 4,
        std_angle      => 45,
        std_line_width => 10,
        std_step_dist  => 50,
        std_indent     => 'odd',
        break_partial  => 'yes',
        cut_prims      => 'no',
        outline_draw   => 'no',
        outline_width  => 0,
        outline_invert => 'no'
    );
    $self->COM( 'add_surf_strt',      surf_type => 'feature' );
    $self->COM( 'add_surf_poly_strt', x         => $left_x1, y => $left_y1 );
    $self->COM( 'add_surf_poly_seg',  x         => $left_x1, y => $left_y2 );
    $self->COM( 'add_surf_poly_seg',  x         => $left_x2, y => $left_y2 );
    $self->COM( 'add_surf_poly_seg',  x         => $left_x2, y => $left_y1 );
    $self->COM( 'add_surf_poly_seg',  x         => $left_x1, y => $left_y1 );
    $self->COM('add_surf_poly_end');
    $self->COM( 'add_surf_end', attributes => 'no', polarity => 'positive' );

    #铺成铜条
    $self->COM(
        'fill_params',
        type           => 'pattern',
        origin_type    => 'datum',
        solid_type     => 'surface',
        std_type       => 'line',
        min_brush      => '25.4',
        use_arcs       => 'yes',
        symbol         => 'new_fill_v',
        dx             => 5,
        dy             => 4,
        std_angle      => 45,
        std_line_width => 10,
        std_step_dist  => 50,
        std_indent     => 'odd',
        break_partial  => 'yes',
        cut_prims      => 'yes',
        outline_draw   => 'no',
        outline_width  => 0,
        outline_invert => 'no'
    );
    $self->COM('sel_fill');

    #把小于0.1mm的去掉
    $self->COM( 'sel_resize', size => -100, corner_ctl => 'no' );
    $self->COM( 'sel_resize', size => 100,  corner_ctl => 'no' );

    $self->COM(
        'sel_copy_other',
        dest         => 'layer_name',
        target_layer => "$topLayer2",
        invert       => 'no'
    );

    #左向右镜像，保留镜像来源。
    $xcenter =
      $self->{PROF}{xmin} + ( $self->{PROF}{xmax} - $self->{PROF}{xmin} ) / 2;
    $ycenter =
      $self->{PROF}{ymin} + ( $self->{PROF}{ymax} - $self->{PROF}{ymin} ) / 2;
    $self->COM(
        'sel_transform',
        mode      => 'anchor',
        oper      => 'mirror',
        duplicate => 'yes',
        x_anchor  => $xcenter,
        y_anchor  => $ycenter,
        angle     => 90,
        x_scale   => 1,
        y_scale   => 1,
        x_offset  => 0,
        y_offset  => 0
    );

    #底层的，向左移动1mm，
    $self->DisplayLayer( "$topLayer2", '1' );
    $self->WorkLayer("$topLayer2");
    $self->COM(
        'sel_transform',
        mode      => 'anchor',
        oper      => 'scale',
        duplicate => 'no',
        x_anchor  => $xcenter,
        y_anchor  => $ycenter,
        angle     => 90,
        x_scale   => 1,
        y_scale   => 1,
        x_offset  => -1,
        y_offset  => 0
    );
    $self->COM(
        'sel_transform',
        mode      => 'anchor',
        oper      => 'mirror',
        duplicate => 'yes',
        x_anchor  => $xcenter,
        y_anchor  => $ycenter,
        angle     => 90,
        x_scale   => 1,
        y_scale   => 1,
        x_offset  => 0,
        y_offset  => 0
    );

    #把2移动到底层铜皮层
    $self->COM(
        'sel_move_other',
        target_layer => $layer_b,
        invert       => 'no',
        dx           => 0,
        dy           => 0,
        size         => 0,
        x_anchor     => 0,
        y_anchor     => 0,
        rotation     => 0,
        mirror       => 'none'
    );

    #把1移动到顶层铜皮层
    $self->DisplayLayer( "$topLayer1", '1' );
    $self->WorkLayer("$topLayer1");
    $self->COM(
        'sel_move_other',
        target_layer => $layer_t,
        invert       => 'no',
        dx           => 0,
        dy           => 0,
        size         => 0,
        x_anchor     => 0,
        y_anchor     => 0,
        rotation     => 0,
        mirror       => 'none'
    );
    $self->VOF();
    $self->DeleteLayer($topLayer1);
    $self->DeleteLayer($topLayer2);
    $self->VON();

#在一个临时层里面铺一块比sr大2.5的铜；然后算出四个边角坐标，用chip切除，然后把剩下的铺上铜点，最后把它拷贝到tb铜皮层。
    my $cuLayer = "cu$self->{PID}";
    $self->ClearAll();
    $self->CreateLayer("$cuLayer");
    $self->DisplayLayer( "$cuLayer", '1' );
    $self->WorkLayer("$cuLayer");

    #铺铜皮
    $self->COM(
        'fill_params',
        type           => 'solid',
        origin_type    => 'datum',
        solid_type     => 'surface',
        std_type       => 'line',
        min_brush      => '25.4',
        use_arcs       => 'yes',
        symbol         => 'new_fill_v',
        dx             => 5,
        dy             => 4,
        std_angle      => 45,
        std_line_width => 10,
        std_step_dist  => 50,
        std_indent     => 'odd',
        break_partial  => 'yes',
        cut_prims      => 'no',
        outline_draw   => 'no',
        outline_width  => 0,
        outline_invert => 'no'
    );
    $self->COM(
        'sr_fill',
        polarity        => 'positive',
        step_margin_x   => 0,
        step_margin_y   => 0,
        step_max_dist_x => 2540,
        step_max_dist_y => 2540,
        sr_margin_x     => '2.5',
        sr_margin_y     => '2.5',
        sr_max_dist_x   => 0,
        sr_max_dist_y   => 0,
        nest_sr         => 'no',
        consider_feat   => 'no',
        consider_drill  => 'no',
        consider_rout   => 'no',
        dest            => 'affected_layers',
        attributes      => 'no',

        #use_profile     => 'use_profile'
    );

    #算出四个边角坐标，chip掉不要的部分。
    my $t_x1 = 0;
    my $t_y1 = $self->{SR}{ymax} + 2.4;
    my $t_x2 = $self->{PROF}{xmax};
    my $t_y2 = $self->{PROF}{ymax};

    $self->COM('clip_area_strt');
    $self->COM( 'clip_area_xy', x => $t_x1, y => $t_y1 );
    $self->COM( 'clip_area_xy', x => $t_x2, y => $t_y2 );
    $self->COM(
        'clip_area_end',
        layers_mode => 'affected_layers',
        layer       => '',
        area        => 'manual',
        area_type   => 'rectangle',
        inout       => 'inside',
        contour_cut => 'no',
        margin      => 0,
        feat_types  => 'surface'
    );
    my $b_x1 = 0;
    my $b_y1 = 0;
    my $b_x2 = $self->{PROF}{xmax};
    my $b_y2 = $self->{SR}{ymin} - 2.4;

    $self->COM('clip_area_strt');
    $self->COM( 'clip_area_xy', x => $b_x1, y => $b_y1 );
    $self->COM( 'clip_area_xy', x => $b_x2, y => $b_y2 );
    $self->COM(
        'clip_area_end',
        layers_mode => 'affected_layers',
        layer       => '',
        area        => 'manual',
        area_type   => 'rectangle',
        inout       => 'inside',
        contour_cut => 'no',
        margin      => 0,
        feat_types  => 'surface'
    );

    my $l_x1 = 0;
    my $l_y1 = 0;
    my $l_x2 = $self->{SR}{xmin} - 2.4;
    my $l_y2 = $self->{PROF}{ymax};

    $self->COM('clip_area_strt');
    $self->COM( 'clip_area_xy', x => $l_x1, y => $l_y1 );
    $self->COM( 'clip_area_xy', x => $l_x2, y => $l_y2 );
    $self->COM(
        'clip_area_end',
        layers_mode => 'affected_layers',
        layer       => '',
        area        => 'manual',
        area_type   => 'rectangle',
        inout       => 'inside',
        contour_cut => 'no',
        margin      => 0,
        feat_types  => 'surface'
    );
    my $r_x1 = $self->{SR}{xmax} + 2.4;
    my $r_y1 = $self->{PROF}{ymin};
    my $r_x2 = $self->{PROF}{xmax};
    my $r_y2 = $self->{PROF}{ymax};

    $self->COM('clip_area_strt');
    $self->COM( 'clip_area_xy', x => $r_x1, y => $r_y1 );
    $self->COM( 'clip_area_xy', x => $r_x2, y => $r_y2 );
    $self->COM(
        'clip_area_end',
        layers_mode => 'affected_layers',
        layer       => '',
        area        => 'manual',
        area_type   => 'rectangle',
        inout       => 'inside',
        contour_cut => 'no',
        margin      => 0,
        feat_types  => 'surface'
    );

    #加铜点
    $self->COM(
        'fill_params',
        type           => 'pattern',
        origin_type    => 'datum',
        solid_type     => 'surface',
        std_type       => 'line',
        min_brush      => '25.4',
        use_arcs       => 'yes',
        symbol         => 'r1000',
        dx             => '1.5',
        dy             => '1.5',
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
    $self->COM('sel_fill');

    #把铜点层拷贝到tb铜皮层。
    $self->COM(
        'sel_copy_other',
        dest         => 'layer_name',
        target_layer => "$layer_t",
        invert       => 'no'
    );
    $self->COM(
        'sel_copy_other',
        dest         => 'layer_name',
        target_layer => "$layer_b",
        invert       => 'no'
    );
    $self->DeleteLayer("$cuLayer");
    $self->UnAffectedLayer("$layer_t");
    $self->UnAffectedLayer("$layer_b");
    return 1;
}

#**********************************************
#名字		:addBoardLine
#功能		:添加boardline
#参数		:无
#返回值		:1
#使用例子	:$self->addBoardLine();
#**********************************************
sub addBoardLine {
    my $self = shift;

    #计算boardLine数据
    $self->CountBoardLine();

    #添加boardLine
    foreach my $i ( 0 .. $#{ $self->{boardLine}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{boardLine}{x}[$i],
            y          => $self->{boardLine}{y}[$i],
            symbol     => $self->{boardLine}{symbool},
            polarity   => 'positive',
            angle      => $self->{boardLine}{angle}[$i],
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addSilkBoardLine
#功能		:添加silk_board_line
#参数		:无
#返回值		:1
#使用例子	:$self->addSilkBoardLine();
#**********************************************
sub addSilkBoardLine {
    my $self = shift;

    #计算boardLine数据
    $self->CountBoardLine();

    #添加boardLine
    foreach my $i ( 0 .. $#{ $self->{boardLine}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{boardLine}{x}[$i],
            y          => $self->{boardLine}{y}[$i],
            symbol     => 'silk_board_line',
            polarity   => 'positive',
            angle      => $self->{boardLine}{angle}[$i],
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addLiuJiao
#功能		:添加四个角的流胶
#参数		:无
#返回值		:1
#使用例子	:$self->addLiuJiao();
#**********************************************
sub addLiuJiao {
    my $self = shift;

    #计算流胶
    $self->CountLiuJiao();

    #添加流胶
    foreach my $i ( 0 .. $#{ $self->{liuJiao}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{liuJiao}{x}[$i],
            y          => $self->{liuJiao}{y}[$i],
            symbol     => "zh-inn-corner",
            polarity   => 'positive',
            angle      => $self->{liuJiao}{angle}[$i],
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#名字		:addScreenHole
#功能		:添加丝印孔及其对应其它层别的symbol
#参数		:无
#返回值		:1
#使用例子	:$self->addScreenHole();
sub addScreenHole {
    my $self = shift;

    #计算丝印孔坐标
    $self->CountScreenHole();

    #添加丝印孔
    foreach my $i ( 0 .. $#{ $self->{screenHole}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{screenHole}{x}[$i],
            y          => $self->{screenHole}{y}[$i],
            symbol     => $self->{screenHole}{symbol},
            polarity   => 'positive',
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    if (    $self->{layerType} eq 'ss'
        and $self->{hdi}{yesNo} eq 'yes' )
    {
        foreach my $i ( 0 .. $#{ $self->{screenHole}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{screenHole}{x}[$i],
                y          => $self->{screenHole}{y}[$i],
                symbol     => 'donut_r3504.79x3200',
                polarity   => 'positive',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }

    }

    return 1;
}

#**********************************************
#名字		:addHuaWeiLayerDuiwei
#功能		:添加华为对准度模块
#参数		:无
#返回值		:1
#使用例子	:$self->addHuaWeiLayerDuiwei();
#**********************************************
sub addHuaWeiLayerDuiwei {
    my $self = shift;

    unless ($self->IsJobAddCouponTestHole($self->{Job}))
    {
        return;
    }
    #计算
    $self->CountHuaWeiLayerDuiwei();

    #添加
    foreach my $i (0 .. $#{$self->{HuaWeiLayerDuiwei}{x}}) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{HuaWeiLayerDuiwei}{x}[$i],
            y          => $self->{HuaWeiLayerDuiwei}{y}[$i],
            symbol     => $self->{HuaWeiLayerDuiwei}{symbool},
            polarity   => 'positive',
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1.0001,
            yscale     => 1.0001
        );
    }
}



#**********************************************
#名字		:addErCiYuan
#功能		:添加二次元数据
#参数		:无
#返回值		:1
#使用例子	:$self->addErCiYuan();
#**********************************************
sub addErCiYuan {
    my $self = shift;

    #计算二次元数据
    $self->CountErCiYuan();

    #添加二次元
    foreach my $i ( 0 .. $#{ $self->{erCiYuan}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{erCiYuan}{x}[$i],
            y          => $self->{erCiYuan}{y}[$i],
            symbol     => $self->{erCiYuan}{symbool},
            polarity   => 'positive',
            angle      => $self->{erCiYuan}{angle}[$i],
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    if ( $self->{ERP}{isInnerHT} eq "yes" || $self->{ERP}{isOuterHT} eq "yes" )
    {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{erCiYuanValue}{x},
            y          => $self->{erCiYuanValue}{y},
            symbol     => 'rect14000x5000',
            polarity   => 'negative',
            angle      => 90,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
        $self->COM(
            'add_text',
            attributes => 'no',
            type       => 'string',
            x          => $self->{erCiYuanTextX}{x},
            y          => $self->{erCiYuanTextX}{y},
            text       => "X=$self->{erCiYuanValue}{xSize}",
            x_size     => '1.143',
            y_size     => '1.524',
            W_factor   => '0.9',
            polarity   => 'positive',
            angle      => 90,
            mirror     => $self->{erCiYuanText}{mirror},
            fontname   => 'standard',
            bar_type   => 'UPC39'
        );

        $self->COM(
            'add_text',
            attributes => 'no',
            type       => 'string',
            x          => $self->{erCiYuanTextY}{x},
            y          => $self->{erCiYuanTextY}{y},
            text       => "Y=$self->{erCiYuanValue}{ySize}",
            x_size     => '1.143',
            y_size     => '1.524',
            W_factor   => '0.9',
            polarity   => 'positive',
            angle      => 90,
            mirror     => $self->{erCiYuanText}{mirror},
            fontname   => 'standard',
            bar_type   => 'UPC39'
        );
    }
    else {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{erCiYuanValue}{x},
            y          => $self->{erCiYuanValue}{y},
            symbol     => 'rect8000x4000',
            polarity   => 'negative',
            angle      => 90,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
        $self->COM(
            'add_text',
            attributes => 'no',
            type       => 'string',
            x          => $self->{erCiYuanTextX}{x},
            y          => $self->{erCiYuanTextX}{y},
            text       => "X=$self->{erCiYuanValue}{xSize}",
            x_size     => '0.8',
            y_size     => '1.0',
            W_factor   => '0.5',
            polarity   => 'positive',
            angle      => 90,
            mirror     => $self->{erCiYuanText}{mirror},
            fontname   => 'standard',
            bar_type   => 'UPC39'
        );

        $self->COM(
            'add_text',
            attributes => 'no',
            type       => 'string',
            x          => $self->{erCiYuanTextY}{x},
            y          => $self->{erCiYuanTextY}{y},
            text       => "Y=$self->{erCiYuanValue}{ySize}",
            x_size     => '0.8',
            y_size     => '1.0',
            W_factor   => '0.5',
            polarity   => 'positive',
            angle      => 90,
            mirror     => $self->{erCiYuanText}{mirror},
            fontname   => 'standard',
            bar_type   => 'UPC39'
        );
    }

    return 1;
}

#**********************************************
#名字		:addDaba
#功能		:添加打靶数据
#参数		:无
#返回值		:1
#使用例子	:$self->addDaba();
#**********************************************
sub addDaba {
    my $self = shift;

    #没有内层，返回
    if ( $self->{signalLayer}{num} == 2 ) {
        return 0;
    }

    #计算daba
    $self->CountDaba();

    #如果界面是写的负片，也返回 update by wxl 20161214
    if (    $self->{cfg}{hdi}{zhengFuPian} eq '负片'
        and $self->{layerType} eq 'outer' )
    {
        return 0;
    }

    #添加daba
    if (   $self->{layerType} eq 'inner'
        or $self->{layerType} eq 'second' )
    {
        foreach my $i ( 0 .. $#{ $self->{daba}{baBiao}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{daba}{baBiao}{x}[$i],
                y          => $self->{daba}{baBiao}{y}[$i],
                symbol     => $self->{daba}{baBiao}{symbol},
                polarity   => 'positive',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );

            #添加标识
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{daba}{biaoShi}{x}[$i],
                y          => $self->{daba}{biaoShi}{y}[$i],
                symbol     => $self->{daba}{biaoShi}{symbol},
                polarity   => 'positive',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    #此外层或外层添加对位
    if ( $self->{Layer} !~ /in/ ) {
        foreach my $i ( 0 .. $#{ $self->{daba}{duiWei}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{daba}{duiWei}{x}[$i],
                y          => $self->{daba}{duiWei}{y}[$i],
                symbol     => $self->{daba}{baBiao}{duiWei},
                polarity   => $self->{daba}{duiWei}{polarity},
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );

        }
    }

    #添加负片
    my $dabaX;
    my $dabaY;
    my $num;
    foreach my $i ( 0 .. $#{ $self->{daba}{baBiao}{x} } ) {
        if ( $self->{Layer} =~ /in/ ) {
            $num = $self->{daba}{num} - $self->{ $self->{Layer} }{yaheN};
        }
        else {
            $num = $self->{daba}{num} - $self->{ $self->{Layer} }{yaheN} - 1;
        }
        foreach my $j ( 1 .. $num ) {
            $dabaX =
              $self->{daba}{baBiao}{x}[$i] + $j * $self->{layerBaBiaoJianJu};
            if ( $i == 1 ) {
                $dabaY = $self->{daba}{baBiao}{y}[$i] - $j * 0.5;
            }
            else {
                $dabaY = $self->{daba}{baBiao}{y}[$i] + $j * 0.5;
            }

            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $dabaX,
                y          => $dabaY,
                symbol     => 's5600',
                polarity   => 'negative',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    return 1;
}

#**********************************************
#名字		:addDabaBY
#功能		:添加打靶数据
#参数		:无
#返回值		:1
#使用例子	:$self->addDabaBY();
#**********************************************
sub addDabaBY {
    my $self = shift;

    #计算daba
    $self->CountDabaBY();

    #添加daba
    if (   $self->{layerType} eq 'inner'
        or $self->{layerType} eq 'second' )
    {
        foreach my $i ( 0 .. $#{ $self->{dabaBY}{baBiao}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{dabaBY}{baBiao}{x}[$i],
                y          => $self->{dabaBY}{baBiao}{y}[$i],
                symbol     => "$self->{dabaBY}{baBiao}{symbol}",
                polarity   => 'positive',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );

        }
    }

    #添加对位, 只有此外层和外层添加对位
    if ( $self->{hdi}{jieShu} != 0 and $self->{Layer} !~ /in/ ) {
        foreach my $i ( 0 .. $#{ $self->{dabaBY}{duiWei}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{dabaBY}{duiWei}{x}[$i],
                y          => $self->{dabaBY}{duiWei}{y}[$i],
                symbol     => "h-chongkong-duiwei",
                polarity   => $self->{dabaBY}{duiWei}{polarity},
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    #添加负片
    my $dabaX;
    my $dabaY;
    my $num;
    foreach my $i ( 0 .. $#{ $self->{dabaBY}{baBiao}{x} } ) {
        if ( $self->{Layer} =~ /in/ ) {
            $num = $self->{daba}{num} - $self->{ $self->{Layer} }{yaheN};
        }
        else {
            $num = $self->{daba}{num} - $self->{ $self->{Layer} }{yaheN} - 1;
        }
        foreach my $j ( 1 .. $num ) {
            $dabaY =
              $self->{dabaBY}{baBiao}{y}[$i] - $j * $self->{layerBaBiaoJianJu};
            if ( $i == 2 ) {
                $dabaX = $self->{dabaBY}{baBiao}{x}[$i] - $j * 0.5;
            }
            else {
                $dabaX = $self->{dabaBY}{baBiao}{x}[$i] + $j * 0.5;
            }

            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $dabaX,
                y          => $dabaY,
                symbol     => 's5600',
                polarity   => 'negative',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    return 1;
}

#**********************************************
#名字		:addCCD
#功能		:添加CCD
#参数		:无
#返回值		:1
#使用例子	:$self->addCCD();
#**********************************************
sub addCCD {
    my $self = shift;

    #计算CCD数据
    $self->CountCCD();

    #添加CCD靶标
    if (
        (
               $self->{layerType} eq 'inner'
            or $self->{layerType} eq 'second'
        )
        and ( $self->{hdi}{jieShu} > 0 or $self->{hdi}{jia} eq 'yes' )
      )
    {
        foreach my $i ( 0 .. $#{ $self->{ccd}{baBiao}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{ccd}{baBiao}{x}[$i],
                y          => $self->{ccd}{baBiao}{y}[$i],
                symbol     => $self->{ccd}{symbol},
                polarity   => 'positive',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );

            #添加标识
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{ccd}{biaoShi}{x}[$i],
                y          => $self->{ccd}{biaoShi}{y}[$i],
                symbol     => $self->{ccd}{biaoShi}{symbol},
                polarity   => 'positive',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    #添加对位, 只有此外层和外层添加对位
    if (   $self->{layerType} eq 'second'
        or $self->{layerType} eq 'outer' )
    {
        foreach my $i ( 0 .. $#{ $self->{ccd}{duiWei}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{ccd}{duiWei}{x}[$i],
                y          => $self->{ccd}{duiWei}{y}[$i],
                symbol     => "h-chongkong-duiwei-ht",
                polarity   => $self->{ccd}{duiWei}{polarity},
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    #添加负片
    if (
        (
               $self->{layerType} eq 'inner'
            or $self->{layerType} eq 'second'
        )
        and $self->{hdi}{jieShu} > 0
      )
    {
        my $ccdX;
        my $ccdY;
        my $num;
        foreach my $i ( 0 .. $#{ $self->{ccd}{baBiao}{x} } ) {
            if ( $self->{Layer} =~ /in/ ) {
                $num = $self->{ccd}{num} - $self->{ $self->{Layer} }{yaheN};
            }
            else {
                $num = $self->{ccd}{num} - $self->{ $self->{Layer} }{yaheN} - 1;
            }
            foreach my $j ( 1 .. $num ) {
                if ( $i == 1 or $i == 2 ) {
                    $ccdY = $self->{ccd}{baBiao}{y}[$i] - $j * 0.5;
                }
                else {
                    $ccdY = $self->{ccd}{baBiao}{y}[$i] + $j * 0.5;
                }

                if ( $i == 0 or $i == 1 ) {
                    $ccdX =
                      $self->{ccd}{baBiao}{x}[$i] +
                      $j * $self->{layerBaBiaoJianJu};
                }
                else {
                    $ccdX =
                      $self->{ccd}{baBiao}{x}[$i] -
                      $j * $self->{layerBaBiaoJianJu};
                }

                $self->COM(
                    'add_pad',
                    attributes => 'no',
                    x          => $ccdX,
                    y          => $ccdY,
                    symbol     => 's6502',
                    polarity   => 'negative',
                    angle      => 0,
                    mirror     => 'no',
                    nx         => 1,
                    ny         => 1,
                    dx         => 0,
                    dy         => 0,
                    xscale     => 1,
                    yscale     => 1
                );

                #添加标识
                $self->COM(
                    'add_pad',
                    attributes => 'no',
                    x          => $self->{ccd}{biaoShi}{x}[$i],
                    y          => $self->{ccd}{biaoShi}{y}[$i],
                    symbol     => $self->{ccd}{biaoShi}{symbol},
                    polarity   => 'positive',
                    angle      => 0,
                    mirror     => 'no',
                    nx         => 1,
                    ny         => 1,
                    dx         => 0,
                    dy         => 0,
                    xscale     => 1,
                    yscale     => 1
                );
            }
        }
    }

    return 1;
}

#**********************************************
#名字		:addCCDBY
#功能		:添加打靶数据
#参数		:无
#返回值		:1
#使用例子	:$self->addCCDBY();
#**********************************************
sub addCCDBY {
    my $self = shift;

    #计算CCDBY数据
    $self->CountCCDBY();

    #添加CCD
    if (
        (
               $self->{layerType} eq 'inner'
            or $self->{layerType} eq 'second'
        )
        and ( $self->{hdi}{jieShu} > 0 or $self->{hdi}{jia} eq 'yes' )
      )
    {
        foreach my $i ( 0 .. $#{ $self->{ccdBY}{baBiao}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{ccdBY}{baBiao}{x}[$i],
                y          => $self->{ccdBY}{baBiao}{y}[$i],
                symbol     => $self->{ccdBY}{symbol},
                polarity   => 'positive',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    #添加对位, 只有此外层和外层添加对位
    if (   $self->{layerType} eq 'second'
        or $self->{layerType} eq 'outer' )
    {
        foreach my $i ( 0 .. $#{ $self->{ccd}{duiWei}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{ccdBY}{duiWei}{x}[$i],
                y          => $self->{ccdBY}{duiWei}{y}[$i],
                symbol     => "h-chongkong-duiwei-ht",
                polarity   => $self->{ccdBY}{duiWei}{polarity},
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    #添加负片
    my $ccdX;
    my $ccdY;
    my $num;
    foreach my $i ( 0 .. $#{ $self->{ccdBY}{baBiao}{x} } ) {
        if ( $self->{Layer} =~ /in/ ) {
            $num = $self->{ccd}{num} - $self->{ $self->{Layer} }{yaheN};
        }
        else {
            $num = $self->{ccd}{num} - $self->{ $self->{Layer} }{yaheN} - 1;
        }
        foreach my $j ( 1 .. $num ) {
            if ( $i == 2 or $i == 3 ) {
                $ccdX = $self->{ccdBY}{baBiao}{x}[$i] - $j * 0.5;
            }
            else {
                $ccdX = $self->{ccdBY}{baBiao}{x}[$i] + $j * 0.5;
            }

            if ( $i == 0 or $i == 3 ) {
                $ccdY =
                  $self->{ccdBY}{baBiao}{y}[$i] +
                  $j * $self->{layerBaBiaoJianJu};
            }
            else {
                $ccdY =
                  $self->{ccdBY}{baBiao}{y}[$i] -
                  $j * $self->{layerBaBiaoJianJu};
            }

            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $ccdX,
                y          => $ccdY,
                symbol     => 's5600',
                polarity   => 'negative',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    return 1;
}

#**********************************************
#名字		:addCCDDrill
#功能		:添加CCD钻孔
#参数		:无
#返回值		:1
#使用例子	:$self->addCCDDrill();
#**********************************************
sub addCCDDrill {
    my $self = shift;

    #计算CCD钻孔数据
    $self->CountCCDDrill();

    if ( $self->{addCCDDrill} eq 'yes' ) {

        #添加
        foreach my $i ( 0 .. $#{ $self->{ccd}{drill}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{ccd}{drill}{x}[$i],
                y          => $self->{ccd}{drill}{y}[$i],
                symbol     => $self->{ccd}{drill}{symbol},
                polarity   => 'positive',
                angle      => '0',
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    if ( $self->{layerType} eq 'sm' ) {

    }

    return 1;
}

#**********************************************
#名字		:addLaserBiaoJi
#功能		:添加镭射标记
#参数		:无
#返回值		:1
#使用例子	:$self->addLaserBiaoJi();
#**********************************************
sub addLaserBiaoJiOld {
    my $self = shift;

    #计算镭射标记数据
    $self->CountLaserBiaoJi();

    #添加
    my $dy;
    if (
        (
               $self->{layerType} eq 'inner'
            or $self->{layerType} eq 'second'
        )
        and $self->{laser}{biaoJi}{num} != 0
      )
    {
        foreach my $i ( 0 .. $#{ $self->{laser}{biaoJi}{x} } ) {
            if ( $i == 0 or $i == 3 ) {
                $dy = $self->{laser}{cuoBa} * 1000;
            }
            else {
                $dy = -$self->{laser}{cuoBa} * 1000;
            }

            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{laser}{biaoJi}{x}[$i],
                y          => $self->{laser}{biaoJi}{y}[$i],
                symbol     => 'h-laser-biaoji',
                polarity   => 'positive',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => $self->{laser}{biaoJi}{num},
                dx         => 0,
                dy         => $dy,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    return 1;
}

#**********************************************
#名字		:addLaserBYBiaoJi
#功能		:添加镭射备用标记
#参数		:无
#返回值		:1
#使用例子	:$self->addLaserBYBiaoJi();
#**********************************************
sub addLaserBYBiaoJi {
    my $self = shift;

    #计算镭射标记数据
    $self->CountLaserBYBiaoJi();

    #添加
    my $dy;
    if (   $self->{layerType} eq 'inner'
        or $self->{layerType} eq 'second' )
    {
        foreach my $i ( 0 .. $#{ $self->{laserBY}{biaoJi}{x} } ) {
            foreach my $j ( 1 .. $self->{laser}{drillNum} ) {
                my $symbol = 'h-laser-biaoji' . "$j" . "-by";
                my $x;
                if ( $i == 0 or $i == 1 ) {
                    if ( $j <= $self->{laser}{leftNum} ) {
                        $x = $self->{laserBY}{biaoJi}{x}[$i] +
                          ( $j - 1 ) * $self->{laser}{cuoBa};
                    }

                    #打靶还剩余的加在ccd的右边
                    else {
                        $x =
                          $self->{laserBY}{biaoJi}{x}[$i] +
                          ( $j - 1 - $self->{laser}{leftNum} ) *
                          $self->{laser}{cuoBa} +
                          $self->{FB}{value};
                    }
                }
                else {
                    $x = $self->{laserBY}{biaoJi}{x}[$i] +
                      ( $j - 1 ) * $self->{laser}{cuoBa};

#$x = $self->{laserBY}{biaoJi}{x}[$i] - ($j-1)*$self->{laser}{cuoBa} - $self->{laser}{hight};
                }

                $self->COM(
                    'add_pad',
                    attributes => 'no',
                    x          => $x,
                    y          => $self->{laserBY}{biaoJi}{y}[$i],
                    symbol     => $symbol,
                    polarity   => 'positive',
                    angle      => $self->{laserBY}{biaoJi}{angle}[$i],
                    mirror     => 'no',
                    nx         => 1,
                    ny         => 1,
                    dx         => 0,
                    dy         => 0,
                    xscale     => 1,
                    yscale     => 1
                );
            }
        }
    }

    return 1;
}

#**********************************************
#名字		:addLaserBiaoJi
#功能		:添加镭射标记
#参数		:无
#返回值		:1
#使用例子	:$self->addLaserBiaoJi();
#**********************************************
sub addLaserBiaoJi {
    my $self = shift;

    #计算镭射标记数据
    $self->CountLaserBiaoJi();

    #添加
    my $dy;
    if (   $self->{layerType} eq 'inner'
        or $self->{layerType} eq 'second' )
    {
        foreach my $i ( 0 .. $#{ $self->{laser}{biaoJi}{x} } ) {
            foreach my $j ( 1 .. $self->{laser}{drillNum} ) {
                my $symbol = 'h-laser-biaoji' . "$j";
                my $y      = $self->{laser}{biaoJi}{y}[$i] +
                  ( $j - 1 ) * $self->{laser}{cuoBa};
                if ( $i == 0 or $i == 3 ) {
                    $y = $self->{laser}{biaoJi}{y}[$i] +
                      ( $j - 1 ) * $self->{laser}{cuoBa};
                }
                else {
                    $y =
                      $self->{laser}{biaoJi}{y}[$i] -
                      ( $j - 1 ) * $self->{laser}{cuoBa} -
                      $self->{laser}{hight};
                }

                $self->COM(
                    'add_pad',
                    attributes => 'no',
                    x          => $self->{laser}{biaoJi}{x}[$i],
                    y          => $y,
                    symbol     => $symbol,
                    polarity   => 'positive',
                    angle      => 0,
                    mirror     => 'no',
                    nx         => 1,
                    ny         => 1,
                    dx         => 0,
                    dy         => 0,
                    xscale     => 1,
                    yscale     => 1
                );
            }
        }
    }

    return 1;
}

#**********************************************
#名字		:addLaser
#功能		:添加镭射
#参数		:无
#返回值		:1
#使用例子	:$self->addLaser();
#**********************************************
sub addLaser {
    my $self = shift;

    #如果没有镭射孔，则返回
    if (    $#{ $self->{laser}{drillTop} } < 0
        and $#{ $self->{laser}{drillBottom} } < 0 )
    {
        return 0;
    }

    #计算镭射数据
    $self->CountLaser();

    #镭射孔避铜(内层或次外层)
##	if ($self->{layerType} eq 'second'
##			or $self->{layerType} eq 'inner'){
##		foreach my $i (0..$#{$self->{laser}{biTong}{xs}}) {
##			$self->COM('add_line',
##				attributes    => 'no',
##				xs            => $self->{laser}{biTong}{xs}[$i],
##				ys            => $self->{laser}{biTong}{ys}[$i],
##				xe            => $self->{laser}{biTong}{xe}[$i],
##				ye            => $self->{laser}{biTong}{ye}[$i],
##				symbol        => 's6000',
##				polarity      => 'negative',
##				bus_num_lines => 0,
##				bus_dist_by   => 'pitch',
##				bus_distance  => 0,
##				bus_reference => 'left');
##		}
##	}

    #假hdi没有内层，多加靶标
    if (    $self->{coreNum} == 0
        and $self->{hdi}{jia} eq 'yes'
        and $self->{ $self->{Layer} }{yaheN} == 1
        and $self->{layerType} ne 'laser' )
    {
        foreach my $i ( 0 .. $#{ $self->{laser}{duiWei}{x} } ) {
            my $y;
            if ( $self->{Layer} =~ /t/ ) {
                if ( $i == 0 or $i == 3 ) {
                    $y = $self->{laser}{duiWei}{y}[$i] + $self->{laser}{hight};
                }
                else {
                    $y = $self->{laser}{duiWei}{y}[$i] - $self->{laser}{hight};
                }
            }
            else {
                if ( $i == 0 or $i == 3 ) {
                    $y = $self->{laser}{duiWei}{y}[$i] - $self->{laser}{hight};
                }
                else {
                    $y = $self->{laser}{duiWei}{y}[$i] + $self->{laser}{hight};
                }
            }
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{laser}{duiWei}{x}[$i],
                y          => $y,
                symbol     => 'h-laser-babiao1',
                polarity   => 'positive',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    #添加镭射靶标(内层(假hdi)或次外层)
    if (   $self->{layerType} eq 'inner' and $self->{hdi}{jia} eq 'yes'
        or $self->{layerType} eq 'second' )
    {
        foreach my $i ( 0 .. $#{ $self->{laser}{baBiao}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{laser}{baBiao}{x}[$i],
                y          => $self->{laser}{baBiao}{y}[$i],
                symbol     => $self->{laser}{baBiao}{symbol},
                polarity   => 'positive',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    #添加靶点(次外层或外层添加)
    if (   $self->{layerType} eq 'second'
        or $self->{layerType} eq 'outer' )
    {
        if (   $self->{ $self->{Layer} }{yaheN} != 1
            or $self->{hdi}{jia} eq 'yes' )
        {
            foreach my $i ( 0 .. $#{ $self->{laser}{duiWei}{x} } ) {
                $self->COM(
                    'add_pad',
                    attributes => 'no',
                    x          => $self->{laser}{duiWei}{x}[$i],
                    y          => $self->{laser}{duiWei}{y}[$i],
                    symbol     => 'h-laser-duiwei',
                    polarity   => 'positive',
                    angle      => 0,
                    mirror     => 'no',
                    nx         => 1,
                    ny         => 1,
                    dx         => 0,
                    dy         => 0,
                    xscale     => 1,
                    yscale     => 1
                );
            }
        }
    }

    if ( $self->{layerType} eq 'laser' ) {

        #第一次压合不添加靶点，如果是假hdi，则添加
        foreach my $i ( 0 .. $#{ $self->{laser}{duiWei}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{laser}{duiWei}{x}[$i],
                y          => $self->{laser}{duiWei}{y}[$i],
                symbol     => "r500",
                polarity   => 'positive',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    return 1;
}

#**********************************************
#名字		:addLaserBY
#功能		:添加镭射备用靶
#参数		:无
#返回值		:1
#使用例子	:$self->addLaserBY();
#**********************************************
sub addLaserBY {
    my $self = shift;

    #如果没有镭射孔，则返回
    if (    $#{ $self->{laser}{drillTop} } < 0
        and $#{ $self->{laser}{drillBottom} } < 0 )
    {
        return 0;
    }

    #计算镭射备用靶数据
    $self->CountLaserBY();

##	#镭射孔避铜(内层或次外层)
##	if ($self->{layerType} eq 'second'
##			or $self->{layerType} eq 'inner'){
##		foreach my $i (0..$#{$self->{laserBY}{biTong}{xs}}) {
##			$self->COM('add_line',
##				attributes    => 'no',
##				xs            => $self->{laserBY}{biTong}{xs}[$i],
##				ys            => $self->{laserBY}{biTong}{ys}[$i],
##				xe            => $self->{laserBY}{biTong}{xe}[$i],
##				ye            => $self->{laserBY}{biTong}{ye}[$i],
##				symbol        => 's6000',
##				polarity      => 'negative',
##				bus_num_lines => 0,
##				bus_dist_by   => 'pitch',
##				bus_distance  => 0,
##				bus_reference => 'left');
##		}
##	}

    #假hdi没有内层，多加靶标
    if (    $self->{coreNum} == 0
        and $self->{hdi}{jia} eq 'yes'
        and $self->{ $self->{Layer} }{yaheN} == 1
        and $self->{layerType} ne 'laser' )
    {
        foreach my $i ( 0 .. $#{ $self->{laserBY}{duiWei}{x} } ) {
            my $x;
            if ( $self->{Layer} =~ /t/ ) {
                $x = $self->{laserBY}{duiWei}{x}[$i] + $self->{laser}{hight};
            }
            else {
                $x = $self->{laserBY}{duiWei}{x}[$i] - $self->{laser}{hight};
            }
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $x,
                y          => $self->{laserBY}{duiWei}{y}[$i],
                symbol     => 'h-laser-babiao1-by',
                polarity   => 'positive',
                angle      => $self->{laserBY}{angle}[$i],
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    #添加镭射靶标(内层(假hdi)或次外层)
    if (   $self->{layerType} eq 'inner' and $self->{hdi}{jia} eq 'yes'
        or $self->{layerType} eq 'second' )
    {
        foreach my $i ( 0 .. $#{ $self->{laserBY}{baBiao}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{laserBY}{baBiao}{x}[$i],
                y          => $self->{laserBY}{baBiao}{y}[$i],
                symbol     => $self->{laserBY}{baBiao}{symbol},
                polarity   => 'positive',
                angle      => $self->{laserBY}{angle}[$i],
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    #添加靶点(次外层或外层添加)
    if (   $self->{layerType} eq 'second'
        or $self->{layerType} eq 'outer' )
    {
        #第一次压合不添加靶点，如果是假hdi，则添加
        if (   $self->{ $self->{Layer} }{yaheN} != 1
            or $self->{hdi}{jia} eq 'yes' )
        {
            foreach my $i ( 0 .. $#{ $self->{laserBY}{duiWei}{x} } ) {
                $self->COM(
                    'add_pad',
                    attributes => 'no',
                    x          => $self->{laserBY}{duiWei}{x}[$i],
                    y          => $self->{laserBY}{duiWei}{y}[$i],
                    symbol     => 'h-laser-duiwei',
                    polarity   => 'positive',
                    angle      => 0,
                    mirror     => 'no',
                    nx         => 1,
                    ny         => 1,
                    dx         => 0,
                    dy         => 0,
                    xscale     => 1,
                    yscale     => 1
                );
            }
        }
    }

    return 1;
}

#**********************************************
#名字		:addTongXinYuan
#功能		:添加同心圆
#参数		:无
#返回值		:1
#使用例子	:$self->addTongXinYuan();
#**********************************************
sub addTongXinYuan {
    my $self = shift;

    #计算同心圆数据
    $self->CountTongXinYuan();

    #添加负片
    if ( $self->{layerType} =~ /^(inner)|(second)$/ ) {
        foreach my $i ( 0 .. $#{ $self->{tongXinYuan}{firstX} } ) {

            #内层同心圆负片
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{tongXinYuan}{firstX}[$i],
                y          => $self->{tongXinYuan}{firstY}[$i],
                symbol     => "r$self->{tongXinYuan}{biTongSize}",
                polarity   => 'negative',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );

            my $x = $self->{tongXinYuan}{firstX}[$i];
            my $y = $self->{tongXinYuan}{firstY}[$i];
            if ( $self->{tongXinYuan}{fangXiang} ne 'heng' ) {
                if ( $i == 0 or $i == 3 ) {
                    $self->{tongXinYuan}{dy} = 1812;
                    $y = $self->{tongXinYuan}{firstY}[$i] +
                      ( $self->{tongXinYuan}{biTongSize} / 1000 + 1.812 ) / 2;
                }
                elsif ( $i == 1 or $i == 2 ) {
                    $self->{tongXinYuan}{dy} = -1812;
                    $y = $self->{tongXinYuan}{firstY}[$i] -
                      ( $self->{tongXinYuan}{biTongSize} / 1000 + 1.812 ) / 2;
                }
            }
            else {
                $self->{tongXinYuan}{dx} = 1812;
                $x = $self->{tongXinYuan}{firstX}[$i] +
                  ( $self->{tongXinYuan}{biTongSize} / 1000 + 1.812 ) / 2;
            }

            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $x,
                y          => $y,
                symbol     => 'r1812',
                polarity   => 'negative',
                angle      => 0,
                mirror     => 'no',
                nx         => $self->{tongXinYuan}{nx},
                ny         => $self->{tongXinYuan}{ny},
                dx         => $self->{tongXinYuan}{dx},
                dy         => $self->{tongXinYuan}{dy},
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    #添加内层或次外同心圆
    if ( $self->{layerType} =~ /^(inner)|(second)$/ ) {
        my $x = 0;
        my $y = 0;
        foreach my $i ( 0 .. $#{ $self->{tongXinYuan}{firstX} } ) {
            if ( $self->{tongXinYuan}{fangXiang} eq 'heng' ) {

                #通孔板，x坐标相同，y坐标，0和3递增，1和2递减
                $x = $self->{tongXinYuan}{firstX}[$i];
                $y = $self->{tongXinYuan}{firstY}[$i];
            }
            else {
                $x = $self->{tongXinYuan}{firstX}[$i];

                #通孔板，x坐标相同，y坐标，0和3递增，1和2递减
                if ( $i == 0 or $i == 3 ) {
                    $y = $self->{tongXinYuan}{firstY}[$i];
                }
                elsif ( $i == 1 or $i == 2 ) {
                    $y = $self->{tongXinYuan}{firstY}[$i];
                }
            }

            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $x,
                y          => $y,
                symbol     => $self->{tongXinYuan}{symbol},
                polarity   => 'positive',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    #添加压合同心圆(外层或次外层)
    if ( $self->{layerType} =~ /^(second)|(outer)/ ) {
        my $symbol;
        if ( $self->{Layer} =~ /t/ ) {
            $symbol = 'zh-12l-huan1';
            $symbol = 'donut_r1012x762';
            if ( $self->{ERP}{isOuterHT} eq "yes" ) {
                $symbol = 'donut_r1016x508';
            }

        }
        else {
            $symbol = 'donut_r1362x1112';
            if ( $self->{ERP}{isOuterHT} eq "yes" ) {
                $symbol = 'donut_r1524x1016';
            }
        }

        my $x = 0;
        my $y = 0;
        foreach my $i ( 0 .. $#{ $self->{tongXinYuan}{firstX} } ) {
            if ( $self->{tongXinYuan}{fangXiang} eq 'heng' ) {

                #通孔板，x坐标相同，y坐标，0和3递增，1和2递减
                $y = $self->{tongXinYuan}{firstY}[$i];
                if ( $self->{Layer} =~ /sec/ ) {
                    $x =
                      $self->{tongXinYuan}{firstX}[$i] +
                      ( $self->{tongXinYuan}{biTongSize} / 1000 + 1.812 ) / 2 +
                      $self->{ $self->{Layer} }{yaheN} * 1.812;
                    $y = $self->{tongXinYuan}{firstY}[$i];
                }
                else {
                    $x = $self->{tongXinYuan}{firstX}[$i] +
                      ( $self->{tongXinYuan}{biTongSize} / 1000 + 1.812 ) / 2;
                    $y = $self->{tongXinYuan}{firstY}[$i];
                }
            }
            else {
                $x = $self->{tongXinYuan}{firstX}[$i];

                #通孔板，x坐标相同，y坐标，0和3递增，1和2递减
                if ( $i == 0 or $i == 3 ) {
                    if ( $self->{Layer} =~ /sec/ ) {
                        $y =
                          $self->{tongXinYuan}{firstY}[$i] +
                          ( $self->{tongXinYuan}{biTongSize} / 1000 + 1.812 ) /
                          2 + $self->{ $self->{Layer} }{yaheN} * 1.812;
                    }
                    else {
                        $y =
                          $self->{tongXinYuan}{firstY}[$i] +
                          ( $self->{tongXinYuan}{biTongSize} / 1000 + 1.812 ) /
                          2;
                    }
                }
                elsif ( $i == 1 or $i == 2 ) {
                    if ( $self->{Layer} =~ /sec/ ) {
                        $y =
                          $self->{tongXinYuan}{firstY}[$i] -
                          ( $self->{tongXinYuan}{biTongSize} / 1000 + 1.812 ) /
                          2 - $self->{ $self->{Layer} }{yaheN} * 1.812;
                    }
                    else {
                        $y =
                          $self->{tongXinYuan}{firstY}[$i] -
                          ( $self->{tongXinYuan}{biTongSize} / 1000 + 1.812 ) /
                          2;
                    }
                }
            }

            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $x,
                y          => $y,
                symbol     => 'r1812',
                polarity   => 'negative',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );

            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $x,
                y          => $y,
                symbol     => $symbol,
                polarity   => 'positive',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    return 1;
}

#**********************************************
#名字		:addPEChongKong
#功能		:添加PE冲孔
#参数		:无
#返回值		:1
#使用例子	:$self->addPEChongKong();
#**********************************************
sub addPEChongKong {
    my $self = shift;

    #计算PE冲孔数据
    if ( $self->{coreNum} < 2 ) {
        $self->{PE}{yesNo} = 'no';
        return 0;
    }

    $self->CountPEChongKong();

    #如果留边不够，返回
    if ( $self->{PE}{yesNo} eq 'no' ) {
        return 0;
    }

    #添加PE冲孔
    foreach my $i ( 0 .. $#{ $self->{PE}{x} } ) {

        my $symbol = $self->{PE}{symbol};
        if (
            $i <= 1
            && (   $self->{PE}{symbol} eq "h-pe"
                || $self->{PE}{symbol} eq "h-pe-ht" )
          )
        {
            $symbol = $self->{PE}{smallSymbol};
        }
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{PE}{x}[$i],
            y          => $self->{PE}{y}[$i],
            symbol     => $symbol,
            polarity   => $self->{PE}{polarity},
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
        if ($self->{layerType} eq "inner")
        {
            $self->COM ("filter_reset",filter_name=>"popup");
            $self->COM ("filter_set",filter_name=>"popup",update_popup=>"no",include_syms=>"$symbol");
            $self->COM ("filter_area_strt");
            $self->COM ("filter_area_end",layer=>"",filter_name=>"popup",operation=>"select",area_type=>"none",inside_area=>"no",intersect_area=>"no");
            $self->COM ("sel_break");
            $self->COM ("filter_reset",filter_name=>"popup");
            
            $self->COM("clip_area_strt");
            $self->COM( "clip_area_xy", x => $self->{SR}{xmin}, y => $self->{SR}{ymax} );
            $self->COM( "clip_area_xy", x => $self->{SR}{xmax},  y => $self->{SR}{ymin} );
            $self->COM(
                "clip_area_end",
                layers_mode => "affected_layers",
                layer       => "",
                area        => "manual",
                area_type   => "rectangle",
                inout       => "inside",
                contour_cut => "yes",
                margin      => "0",
                feat_types  => "pad"
            );
        }
    }
    
    


    #辅助层加辅助图表
    if ( not $self->{PE_S}{have} ) {

        #产生新层
        if ( $self->LayerExists( "$self->{panelStep}", "pe" ) ) {
            $self->ClearAll();
            $self->DisplayLayer( "pe", '1' );
            $self->WorkLayer("pe");
            $self->COM('sel_delete');
        }
        else {
            $self->CreateLayer("pe");
            $self->ClearAll();
            $self->DisplayLayer( "pe", '1' );
            $self->WorkLayer("pe");
        }

        #加辅助图标
        foreach my $i ( 0 .. $#{ $self->{PE_S}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{PE_S}{x}[$i],
                y          => $self->{PE_S}{y}[$i],
                symbol     => 'h-pe-s',
                polarity   => 'positive',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
        $self->ClearAll();
        $self->DisplayLayer( "$self->{Layer}", '1' );
        $self->WorkLayer("$self->{Layer}");

        $self->{PE_S}{have} = 1;
    }

    return 1;
}

#**********************************************
#名字		:addRongHeKuai
#功能		:添加熔合块
#参数		:无
#返回值		:1
#使用例子	:$self->addRongHeKuai();
#**********************************************
sub addRongHeKuai {
    my $self = shift;

    #如果小于2张core的，返回
    if ( $self->{coreNum} < 2 ) {
        return 0;
    }

    unless ( $self->{SRToPROF}{x} < 14 and $self->{PROF}{ymax} > 431 ) {
        return 0;
    }

    #如果是喷锡板，则返回
    if ( $self->GetERPSurfaceTreatment() eq 'hasl' ) {
        return 0;
    }

    $self->CountRongHeKuai();

    #添加熔合块
    foreach my $i ( 0 .. $#{ $self->{rongHeKuai}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{rongHeKuai}{x}[$i],
            y          => $self->{rongHeKuai}{y}[$i],
            symbol     => 'h-ronghekuai',
            polarity   => 'positive',
            angle      => 0,
            mirror     => $self->{rongHeKuai}{mirror}[$i],
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}


#**********************************************
#名字		:addSanRe
#功能		:添加熔合块
#参数		:无
#返回值		:1
#使用例子	:$self->addSanRe();
#**********************************************
sub addSanRe {
    my $self = shift;


    $self->CountSanRe();

	$self->COM(
		'add_pad',
		attributes => 'no',
		x          => $self->{sanRe}{x}[0],
		y          => $self->{sanRe}{y}[0],
		symbol     => 'r2000',
		polarity   => 'positive',
		angle      => 0,
		mirror     => 'no',
		nx         => $self->{sanRe}{xNum},
		ny         => 1,
		dx         => 20000,
		dy         => 0,
		xscale     => 1,
		yscale     => 1
	);

	$self->COM(
		'add_pad',
		attributes => 'no',
		x          => $self->{sanRe}{x}[1],
		y          => $self->{sanRe}{y}[1],
		symbol     => 'r2000',
		polarity   => 'positive',
		angle      => 0,
		mirror     => 'no',
		nx         => $self->{sanRe}{xNum},
		ny         => 1,
		dx         => 20000,
		dy         => 0,
		xscale     => 1,
		yscale     => 1
	);

		$self->COM(
		'add_pad',
		attributes => 'no',
		x          => $self->{sanRe}{x}[2],
		y          => $self->{sanRe}{y}[2],
		symbol     => 'r2000',
		polarity   => 'positive',
		angle      => 0,
		mirror     => 'no',
		nx         => 1,
		ny         => $self->{sanRe}{yNum},
		dx         => 0,
		dy         => 20000,
		xscale     => 1,
		yscale     => 1
	);

		$self->COM(
		'add_pad',
		attributes => 'no',
		x          => $self->{sanRe}{x}[3],
		y          => $self->{sanRe}{y}[3],
		symbol     => 'r2000',
		polarity   => 'positive',
		angle      => 0,
		mirror     => 'no',
		nx         => 1,
		ny         => $self->{sanRe}{yNum},
		dx         => 0,
		dy         => 20000,
		xscale     => 1,
		yscale     => 1
	);


    return 1;
}


#**********************************************
#名字		:addRongHeKuaiNew
#功能		:添加熔合块
#参数		:无
#返回值		:1
#使用例子	:$self->addRongHeKuaiNew();
#**********************************************
sub addRongHeKuaiNew {
    my $self = shift;

    #	if ($self->{SRToPROF}{x} < 14 and $self->{PROF}{ymax} > 431) {
    #		return 0;
    #	}

    #如果小于2张core的，返回
    if ( $self->{coreNum} < 2 ) {
        return 0;
    }

    $self->CountRongHeKuaiNew();

    #添加熔合块
    foreach my $i ( 0 .. $#{ $self->{rongHeKuai}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{rongHeKuai}{x}[$i],
            y          => $self->{rongHeKuai}{y}[$i],
            symbol     => $self->{rongHeKuai}{symbol}[$i],
            polarity   => 'positive',
            angle      => 0,
            mirror     => $self->{rongHeKuai}{mirror}[$i],
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addRongHeKuai
#功能		:添加熔合块
#参数		:无
#返回值		:1
#使用例子	:$self->addRongHeKuai();
#**********************************************
sub addRongHeKuaiNew1 {
    my $self = shift;

    if ( $self->{SRToPROF}{x} < 14 and $self->{PROF}{ymax} > 431 ) {
        return 0;
    }

    #如果小于2张core的，返回
    if ( $self->{coreNum} < 2 ) {
        return 0;
    }

    $self->CountRongHeKuaiNew1();

    #添加熔合块
    foreach my $i ( 0 .. $#{ $self->{rongHeKuaiNew}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{rongHeKuaiNew}{x}[$i],
            y          => $self->{rongHeKuaiNew}{y}[$i],
            symbol     => 'h-ronghekuai-new',
            polarity   => 'positive',
            angle      => 0,
            mirror     => $self->{rongHeKuaiNew}{mirror}[$i],
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addYingFeiRongHeKuai
#功能		:添加熔合块
#参数		:无
#返回值		:1
#使用例子	:$self->addYingFeiRongHeKuai();
#**********************************************
sub addYingFeiRongHeKuai {
    my $self = shift;

    #如果小于2张core的，返回
    if ( $self->{coreNum} < 2 ) {
        return 0;
    }

    #如果是喷锡板，则返回
    if ( $self->GetERPSurfaceTreatment() ne 'hasl' ) {
        return 0;
    }

    if ( $self->{SRToPROF}{x} >= 14 and $self->{PROF}{ymax} > 431 ) {
        return 0;
    }

    $self->CountYingFeiRongHeKuai();

    #添加熔合块
    foreach my $i ( 0 .. $#{ $self->{yingFeiRongHeKuai}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{yingFeiRongHeKuai}{x}[$i],
            y          => $self->{yingFeiRongHeKuai}{y}[$i],
            symbol     => 'h-ronghekuai',
            polarity   => 'positive',
            angle      => 0,
            mirror     => $self->{yingFeiRongHeKuai}{mirror}[$i],
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addYingFeiRongHeKuai
#功能		:添加熔合块
#参数		:无
#返回值		:1
#使用例子	:$self->addYingFeiRongHeKuai();
#**********************************************
sub addYingFeiRongHeKuaiDrill {
    my $self = shift;

    #如果小于2张core的，返回
    if ( $self->{coreNum} < 2 ) {
        return 0;
    }

    #如果是喷锡板，则返回
    if ( $self->GetERPSurfaceTreatment() ne 'hasl' ) {
        return 0;
    }

    $self->CountYingFeiRongHeKuaiDrill();

    #添加熔合块
    foreach my $i ( 0 .. $#{ $self->{yingFeiRongHeKuaiDrill}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{yingFeiRongHeKuaiDrill}{x}[$i],
            y          => $self->{yingFeiRongHeKuaiDrill}{y}[$i],
            symbol     => 'h-yingfei-rh-drill',
            polarity   => 'positive',
            angle      => 0,
            mirror     => $self->{yingFeiRongHeKuaiDrill}{mirror}[$i],
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    #选择，打散
    #
    $self->FilterIncludeSymbol( "h-yingfei-rh-drill", '1' );

    #
    $self->FilterSelect();

    $self->COM('sel_break');

    return 1;
}

#**********************************************
#名字		:addRongHeDingWei
#功能		:添加融合定位备用靶
#参数		:无
#返回值		:1
#使用例子	:$self->addRongHeDingWei();
#**********************************************
sub addRongHeDingWeiBy {
    my $self = shift;

    #如果小于2张core的，返回
    if ( $self->{coreNum} < 2 ) {
        return 0;
    }

    #熔合块数据计算
    $self->CountRongHeDingWeiBy();

    #添加熔合定位
    foreach my $i ( 0 .. $#{ $self->{rongHeDingWeiBy}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{rongHeDingWeiBy}{x}[$i],
            y          => $self->{rongHeDingWeiBy}{y}[$i],
            symbol     => $self->{rongHeDingWeiBy}{symbol},
            polarity   => 'positive',
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addRongHeDingWei
#功能		:添加熔合块
#参数		:无
#返回值		:1
#使用例子	:$self->addRongHeDingWei();
#**********************************************
sub addRongHeDingWei {
    my $self = shift;

    #如果小于2张core的，返回
    if ( $self->{coreNum} < 2 ) {
        return 0;
    }

    #if (($self->{layerType} eq 'via' or $self->{layerType} eq 'bury')
    if (    ( $self->{layerType} eq 'bury' )
        and $#{ $self->{laser}{drillTop} } < 0
        and $#{ $self->{laser}{drillBottom} } < 0 )
    {
        return 0;
    }

    #熔合块数据计算
    $self->CountRongHeDingWei();

    #添加熔合定位
    foreach my $i ( 0 .. $#{ $self->{rongHeDingWei}{x} } ) {

        my $symbol = $self->{rongHeDingWei}{symbol};
        #if ($self->{layerType} ne 'inner')
        #{
        my $attributes = "no";
        if ($self->{layerType} eq "inner")
        {
            $self->COM ("cur_atr_reset");
            $self->COM ("cur_atr_set",attribute=>".out_scale");
            $attributes = "yes";
            if ($i >= 8)
            {
                $symbol = "h-rh-drill-by"
            }
        }
        $self->COM(
            'add_pad',
            attributes => $attributes,
            x          => $self->{rongHeDingWei}{x}[$i],
            y          => $self->{rongHeDingWei}{y}[$i],
            symbol     => $symbol,
            polarity   => 'positive',
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
        $self->COM ("cur_atr_reset");

        #}
    }
    #添加熔合定位孔r4500
    if ( $self->{layerType} eq 'via' or $self->{layerType} eq 'bury' ) {
        foreach my $i ( 0 .. $#{ $self->{rongHeDingWei}{x} } ) {

            if ( defined( $self->{skip} )
                && $self->{rongHeDingWei}{x}[$i] == $self->{skip} )
            {
                next;
            }

            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{rongHeDingWei}{x}[$i],
                y          => $self->{rongHeDingWei}{y}[$i],
                symbol     => 'r4499',
                polarity   => 'positive',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }
    
    #添加熔合定位孔r3600
    if ( $self->{layerType} eq 'via' or $self->{layerType} eq 'bury' ) {
        foreach my $i ( 0 .. $#{ $self->{rongHeDingWei}{x} } ) {

            if ( defined( $self->{skip} )
                && $self->{rongHeDingWei}{x}[$i] == $self->{skip} )
            {
                next;
            }

            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{rongHeDingWei}{x}[$i],
                y          => $self->{rongHeDingWei}{y}[$i],
                symbol     => 'r3600',
                polarity   => 'positive',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    return 1;
}


#**********************************************
#名字		:addRongHeDingWei
#功能		:添加熔合块防爆孔
#参数		:无
#返回值		:1
#使用例子	:$self->addRongHeDingWeiFangBao();
#**********************************************
sub addRongHeDingWeiFangBao {
    my $self = shift;

    #如果小于2张core的，返回
    if ( $self->{coreNum} < 2 ) {
        return 0;
    }


	@{$self->{rongHeDingWei}{angle}} = qw(90 270 0 180 0 0 180 180);


    #添加熔合定位孔r3600
    if ( $self->{layerType} eq 'via') {
        foreach my $i ( 0 .. $#{ $self->{rongHeDingWei}{x} } ) {

            if ( defined( $self->{skip} )
                && $self->{rongHeDingWei}{x}[$i] == $self->{skip} )
            {
                next;
            }

			if ($i >= 8)
			{
				#$symbol = "h-rh-drill-by"
				$self->COM("cur_atr_reset");
				return;
			}

			$self->COM("cur_atr_reset");
			$self->COM("cur_atr_set,attribute=.string,text=fb${i}");

            $self->COM(
                'add_pad',
                attributes => 'yes',
                x          => $self->{rongHeDingWei}{x}[$i],
                y          => $self->{rongHeDingWei}{y}[$i],
                symbol     => 'h-md-g-drill',
                polarity   => 'positive',
                angle      => $self->{rongHeDingWei}{angle}[$i],
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

	$self->COM("cur_atr_reset");
    return 1;
}


#**********************************************
#名字		:addRongHeDingWeiPad
#功能		:添加熔合定位pad
#参数		:无
#返回值		:1
#使用例子	:$self->addRongHeDingWeiPad();
#**********************************************
sub addRongHeDingWeiPad {
    my $self = shift;

    if (   $self->{coreNum} < 2
        or $self->{SRToPROF}{y} < 13 )
    {
        return 0;
    }

    #计算熔合定位pad
    $self->CountRongHeDingWeiPad();

    #添加熔合定位pad
    foreach my $i ( 0 .. $#{ $self->{rongHeDingWeiPad}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{rongHeDingWeiPad}{x}[$i],
            y          => $self->{rongHeDingWeiPad}{y}[$i],
            symbol     => $self->{rongHeDingWeiPad}{symbol}[$i],
            polarity   => $self->{rongHeDingWeiPad}{polarity},
            angle      => $self->{rongHeDingWeiPad}{angle}[$i],
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addRongHeDingWeiPadYingFeiDrill
#功能		:添加熔合定位pad
#参数		:无
#返回值		:1
#使用例子	:$self->addRongHeDingWeiPadYingFeiDrill();
#**********************************************
sub addRongHeDingWeiPadYingFeiDrill {
    my $self = shift;

    if (   $self->{coreNum} < 2
        or $self->{SRToPROF}{y} < 13 )
    {
        return 0;
    }

    #如果不是喷锡板，则返回
    if ( $self->GetERPSurfaceTreatment() ne 'hasl' ) {
        return 0;
    }

    #计算熔合定位pad
    $self->CountRongHeDingWeiPadYingFeiDrill();

    #添加熔合定位pad
    foreach my $i ( 0 .. $#{ $self->{rongHeDingWeiPadYingFeiDrill}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{rongHeDingWeiPadYingFeiDrill}{x}[$i],
            y          => $self->{rongHeDingWeiPadYingFeiDrill}{y}[$i],
            symbol     => 'maoding-yingfei-drill',
            polarity   => "positive",
            angle      => $self->{rongHeDingWeiPadYingFeiDrill}{angle}[$i],
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    #选择，打散
    #
    $self->FilterIncludeSymbol( "maoding-yingfei-drill", '1' );

    #
    $self->FilterSelect();

    $self->COM('sel_break');

    return 1;
}

#**********************************************
#名字		:addMaoDing
#功能		:添加铆钉孔
#参数		:无
#返回值		:1
#使用例子	:$self->addMaoDing();
#**********************************************
sub addMaoDing {
    my $self = shift;

    #如果不是两张core以上，不加铆钉孔
    if ( $self->{coreNum} < 2 ) {
        return 0;
    }

    #if (($self->{layerType} eq 'via' or $self->{layerType} eq 'bury')
    if (    ( $self->{layerType} eq 'bury' )
        and $#{ $self->{laser}{drillTop} } < 0
        and $#{ $self->{laser}{drillBottom} } < 0 )
    {
        return 0;
    }

    #计算铆钉孔坐标
    $self->CountMaoDing();

    #添加铆钉孔
    foreach my $i ( 0 .. $#{ $self->{maoDing}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{maoDing}{x}[$i],
            y          => $self->{maoDing}{y}[$i],
            symbol     => $self->{maoDing}{symbol},
            polarity   => 'positive',
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    #添加熔合定位孔r3600
    if ( $self->{layerType} eq 'via' ) {
        foreach my $i ( 0 .. $#{ $self->{maoDing}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{maoDing}{x}[$i],
                y          => $self->{maoDing}{y}[$i],
                symbol     => 'r3600',
                polarity   => 'positive',
                angle      => 0,
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    return 1;
}

#**********************************************
#名字		:addMaoDingYingFeiDrill
#功能		:添加铆钉孔
#参数		:无
#返回值		:1
#使用例子	:$self->addMaoDingYingFeiDrill();
#**********************************************
sub addMaoDingYingFeiDrill {
    my $self = shift;

    #如果不是两张core以上，不加铆钉孔
    if ( $self->{coreNum} < 2 ) {
        return 0;
    }

    #如果不是喷锡板，则返回
    if ( $self->GetERPSurfaceTreatment() ne 'hasl' ) {
        return 0;
    }

    #计算铆钉孔坐标
    $self->CountMaoDingYingFeiDrill();

    #添加铆钉孔
    foreach my $i ( 0 .. $#{ $self->{maoDingYingFeiDrill}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{maoDingYingFeiDrill}{x}[$i],
            y          => $self->{maoDingYingFeiDrill}{y}[$i],
            symbol     => 'maoding-yingfei-drill',
            polarity   => 'positive',
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    #选择，打散
    #
    $self->FilterIncludeSymbol( "maoding-yingfei-drill", '1' );

    #
    $self->FilterSelect();

    $self->COM('sel_break');

    return 1;
}


sub AddInnerErciyuan
{
    my $self = shift;
    if ($self->{signalLayer}{num} < 6)
    {
        return;
    }
    $self->CountInnerErciyuan();

    #上面
    #加背景负层
    for (my $i = 0;$i < ($self->{signalLayer}{num}-2) * 0.5 ;$i ++)
    {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{innerErciyuan}{up}{start}{x} + $i * 5.2,
            y          => $self->{innerErciyuan}{up}{start}{y},
            symbol     => "rect5500x6200",
            polarity   => 'negative',
            angle      => 0,
            mirror     => "no",
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{innerErciyuan}{up}{x},
        y          => $self->{innerErciyuan}{up}{y},
        symbol     => $self->{innerErciyuan}{symbol},
        polarity   => 'positive',
        angle      => 0,
        mirror     => "no",
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );
    #下面
    #加背景负层
    for (my $i = 0;$i < ($self->{signalLayer}{num}-2) * 0.5 ;$i ++)
    {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{innerErciyuan}{down}{start}{x} + $i * 5.2,
            y          => $self->{innerErciyuan}{down}{start}{y},
            symbol     => "rect5500x6200",
            polarity   => 'negative',
            angle      => 0,
            mirror     => "no",
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{innerErciyuan}{down}{x},
        y          => $self->{innerErciyuan}{down}{y},
        symbol     => $self->{innerErciyuan}{symbol},
        polarity   => 'positive',
        angle      => 180,
        mirror     => "no",
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );
    
    #左边
    #加背景负层
    for (my $i = 0;$i < ($self->{signalLayer}{num}-2) * 0.5 ;$i ++)
    {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{innerErciyuan}{left}{start}{x},
            y          => $self->{innerErciyuan}{left}{start}{y}  - $i * 5.2,
            symbol     => "rect6200x5500",
            polarity   => 'negative',
            angle      => 0,
            mirror     => "no",
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{innerErciyuan}{left}{x},
        y          => $self->{innerErciyuan}{left}{y},
        symbol     => $self->{innerErciyuan}{symbol},
        polarity   => 'positive',
        angle      => 270,
        mirror     => "no",
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );
    #右边
    for (my $i = 0;$i < ($self->{signalLayer}{num}-2) * 0.5 ;$i ++)
    {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{innerErciyuan}{right}{start}{x},
            y          => $self->{innerErciyuan}{right}{start}{y}  - $i * 5.2,
            symbol     => "rect6200x5500",
            polarity   => 'negative',
            angle      => 0,
            mirror     => "no",
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{innerErciyuan}{right}{x},
        y          => $self->{innerErciyuan}{right}{y},
        symbol     => $self->{innerErciyuan}{symbol},
        polarity   => 'positive',
        angle      => 90,
        mirror     => "no",
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );
    
    if ($self->{Layer} =~ /t/ && $self->{Layer} !~ /b/)
    {
        #标左边的数据
        #添加负片
        $self->COM(
            'add_line',
            attributes    => 'no',
            xs            => $self->{innerEriciyuan}{left}{text}{xs},
            ys            => $self->{innerEriciyuan}{left}{text}{ys},
            xe            => $self->{innerEriciyuan}{left}{text}{xe},
            ye            => $self->{innerEriciyuan}{left}{text}{ye},
            symbol        => 's3500',
            polarity      => 'negative',
            bus_num_lines => 0,
            bus_dist_by   => 'pitch',
            bus_distance  => 0,
            bus_reference => 'left'
        );
        $self->COM(
            'add_text',
            attributes => 'no',
            type       => 'string',
            x          => $self->{innerEriciyuan}{left}{text}{x},
            y          => $self->{innerEriciyuan}{left}{text}{y},
            text       => $self->{innerEriciyuan}{left}{text}{value},
            x_size     => 2.5,
            y_size     => 2.5,
            W_factor   => 1.15,
            polarity   => 'positive',
            angle      => 90,
            mirror     => "no",
            fontname   => 'simple',
            bar_type   => 'UPC39'
        );
        
        #标上面的数据
        #添加负片
        $self->COM(
            'add_line',
            attributes    => 'no',
            xs            => $self->{innerEriciyuan}{up}{text}{xs},
            ys            => $self->{innerEriciyuan}{up}{text}{ys},
            xe            => $self->{innerEriciyuan}{up}{text}{xe},
            ye            => $self->{innerEriciyuan}{up}{text}{ye},
            symbol        => 's3500',
            polarity      => 'negative',
            bus_num_lines => 0,
            bus_dist_by   => 'pitch',
            bus_distance  => 0,
            bus_reference => 'left'
        );
        $self->COM(
            'add_text',
            attributes => 'no',
            type       => 'string',
            x          => $self->{innerEriciyuan}{up}{text}{x},
            y          => $self->{innerEriciyuan}{up}{text}{y},
            text       => $self->{innerEriciyuan}{up}{text}{value},
            x_size     => 2.5,
            y_size     => 2.5,
            W_factor   => 1.15,
            polarity   => 'positive',
            angle      => 0,
            mirror     => "no",
            fontname   => 'simple',
            bar_type   => 'UPC39'
        );
    }

    
    
}



#**********************************************
#名字		:addJobInfo
#功能		:添加料号信息，包括料号名，时间，层别，和制作者
#参数		:无
#返回值		:1
#使用例子	:$self->addJobInfo();
#**********************************************
sub addJobInfo {
    my $self = shift;

    #计算数据
    $self->CountJobInfo();

    #添加负片
    $self->COM(
        'add_line',
        attributes    => 'no',
        xs            => $self->{jobLayerName}{biTong}{xs},
        ys            => $self->{jobLayerName}{biTong}{ys},
        xe            => $self->{jobLayerName}{biTong}{xe},
        ye            => $self->{jobLayerName}{biTong}{ye},
        symbol        => 's3000',
        polarity      => 'negative',
        bus_num_lines => 0,
        bus_dist_by   => 'pitch',
        bus_distance  => 0,
        bus_reference => 'left'
    );

    #添加料号名
    $self->COM(
        'add_text',
        attributes => 'no',
        type       => 'string',
        x          => $self->{jobLayerName}{x},
        y          => $self->{jobLayerName}{y},
        text       => "$self->{jobLayerName}{text}",
        x_size     => $self->{jobLayerName}{xSize},
        y_size     => $self->{jobLayerName}{ySize},
        W_factor   => $self->{jobLayerName}{w_factor},
        polarity   => 'positive',
        angle      => 0,
        mirror     => $self->{jobLayerName}{mirror},
        fontname   => 'simple',
        bar_type   => 'UPC39'
    );

    #制作者
    $self->COM(
        'set_attribute',
        type      => 'layer',
        job       => "$self->{Job}",
        name1     => $self->{panelStep},
        name2     => "$self->{Layer}",
        name3     => '',
        attribute => '.layer_operater',
        value     => "",
        units     => 'inch'
    );

    #审核者
    $self->COM(
        'set_attribute',
        type      => 'layer',
        job       => "$self->{Job}",
        name1     => $self->{panelStep},
        name2     => $self->{Layer},
        name3     => '',
        attribute => '.layer_check',
        value     => "",
        units     => 'inch'
    );
    #添加负片
    $self->COM(
        'add_line',
        attributes    => 'no',
        xs            => $self->{checkListSig}{biTong}{xs},
        ys            => $self->{checkListSig}{biTong}{ys},
        xe            => $self->{checkListSig}{biTong}{xe},
        ye            => $self->{checkListSig}{biTong}{ye},
        symbol        => 's2800',
        polarity      => 'negative',
        bus_num_lines => 0,
        bus_dist_by   => 'pitch',
        bus_distance  => 0,
        bus_reference => 'left'
    );
    $self->COM(
        'add_text',
        attributes => 'no',
        type       => 'string',
        x          => $self->{checkListSig}{x},
        y          => $self->{checkListSig}{y},
        text       => "$self->{checkListSig}{text}",
        x_size     => 1.5,
        y_size     => 2.5,
        W_factor   => '0.82',
        polarity   => $self->{checkListSig}{polarity},
        angle      => 0,
        mirror     => $self->{jobLayerName}{mirror},
        fontname   => 'simple',
        bar_type   => 'UPC39'
    );

    #添加层别标识
    #	if ($self->{layerType} eq 'inner'
    #			or $self->{layerType} eq 'second'
    #			or $self->{layerType} eq 'outer'){
    #		$self->COM('add_pad', attributes => 'no',
    #			x          => $self->{layerMark}{x},
    #			y          => $self->{layerMark}{y},
    #			symbol     => $self->{layerMark}{symbol},
    #			polarity   => 'positive',
    #			angle      => 0,
    #			mirror     => 'no',
    #			nx         => 1,
    #			ny         => 1,
    #			dx         => 0,
    #			dy         => 0,
    #			xscale     => 1,
    #			yscale     => 1);
    #	}

    return 1;
}

#**********************************************
#名字		:addJobInfo
#功能		:添加料号信息，包括料号名，时间，层别，和制作者
#参数		:无
#返回值		:1
#使用例子	:$self->addJobInfo();
#**********************************************
sub addFilmId {
    my $self = shift;

    #计算数据
    $self->CountFilmId();

    #添加料号名
    $self->COM(
        'add_text',
        attributes => 'no',
        type       => 'barcode',
        x          => $self->{filmId}{x},
        y          => $self->{filmId}{y},
        text       => '$$filmid',
        x_size     => 5.08,
        y_size     => 5.08,
        W_factor   => '2',
        polarity   => $self->{filmId}{polarity},
        angle      => $self->{filmId}{angle},
        mirror     => $self->{filmId}{mirror},
        fontname   => 'standard',
        bar_type   => 'UPC39',
        bar_height => '7.62'
    );

    return 1;
}

#**********************************************
#名字		:addXYScale
#功能		:添加涨缩系数
#参数		:无
#返回值		:1
#使用例子	:$self->addXYScale();
#**********************************************
sub addXYScaleOld {
    my $self = shift;

    #计算涨缩系数坐标
    $self->CountXYScale();

    #添加涨缩系数
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{xYScale}{x},
        y          => $self->{xYScale}{y},
        symbol     => 'h-xyscale',
        polarity   => 'positive',
        angle      => 90,
        mirror     => $self->{xYScale}{mirror},
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    return 1;
}

#**********************************************
#名字		:addXYScale
#功能		:添加涨缩系数
#参数		:无
#返回值		:1
#使用例子	:$self->addXYScale();
#**********************************************
sub addXYScale {
    my $self = shift;

    #计算涨缩系数坐标
    $self->CountXYScale();

    #添加涨缩系数
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{xYScale}{x},
        y          => $self->{xYScale}{y},
        symbol     => $self->{xYScale}{symbol},
        polarity   => 'positive',
        angle      => $self->{xYScale}{angle},
        mirror     => $self->{xYScale}{mirror},
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    #添加文字系数
    my $textX;
    my $textY;
    if (   $self->{layerType} eq 'second'
        or $self->{layerType} eq 'outer' )
    {
        $textX = '100.000x';
        $textY = '100.000y';
    }
    else {
        $textX = '$$filmx    $$filmy';
        $textY = '100.000    100.000';
    }

    $self->COM(
        'add_text',
        attributes => 'no',
        type       => 'string',
        x          => $self->{xYScale}{textX}{x},
        y          => $self->{xYScale}{textX}{y},
        text       => "$textX",
        x_size     => '1.143',
        y_size     => '2.54',
        W_factor   => $self->{xYScale}{w_factor},
        polarity   => 'positive',
        angle      => $self->{layerType} eq "inner" ? 0 : 90,
        mirror     => $self->{xYScale}{mirror},
        fontname   => 'simple',
        bar_type   => 'UPC39'
    );

    if (   $self->{layerType} eq 'outer'
        or $self->{layerType} eq 'second' )
    {
        $self->COM(
            'add_text',
            attributes => 'no',
            type       => 'string',
            x          => $self->{xYScale}{textY}{x},
            y          => $self->{xYScale}{textY}{y},
            text       => "$textY",
            x_size     => '1.143',
            y_size     => '2.54',
            W_factor   => $self->{xYScale}{w_factor},
            polarity   => 'positive',
            angle      => 90,
            mirror     => $self->{xYScale}{mirror},
            fontname   => 'simplex',
            bar_type   => 'UPC39'
        );
    }

    return 1;
}

#**********************************************
#名字		:addJingWEi
#功能		:添加经纬向
#参数		:无
#返回值		:1
#使用例子	:$self->addJingWEi();
#**********************************************
sub addJingWei {
    my $self = shift;

    #计算经纬向数据
    $self->CountJingWei();

    #添加经向
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{jing}{x},
        y          => $self->{jing}{y},
        symbol     => 'jing',
        polarity   => 'positive',
        angle      => $self->{jing}{angle},
        mirror     => $self->{jing}{mirror},
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    #添加纬向
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{wei}{x},
        y          => $self->{wei}{y},
        symbol     => 'wei',
        polarity   => 'positive',
        angle      => $self->{wei}{angle},
        mirror     => $self->{wei}{mirror},
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    return 1;
}

#**********************************************
#名字		:addLayerMarki
#功能		:添加层别标识
#参数		:无
#返回值		:1
#使用例子	:$self->addLayerMarki();
#**********************************************
sub addLayerMarki {
    my $self = shift;

    #计算层别标识数据
    $self->CountLayerMarki();

    #添加负片
    $self->COM(
        'add_line',
        attributes    => 'no',
        xs            => $self->{layerMarki}{biTong}{xs},
        ys            => $self->{layerMarki}{biTong}{ys},
        xe            => $self->{layerMarki}{biTong}{xe},
        ye            => $self->{layerMarki}{biTong}{ye},
        symbol        => 's5500',
        polarity      => 'negative',
        bus_num_lines => 0,
        bus_dist_by   => 'pitch',
        bus_distance  => 0,
        bus_reference => 'left'
    );

#添加层别标识
#my $layerMarkY = $self->{layerMarki}{firstY} + $self->{$self->{Layer}}{layNum} * (3.3649925);
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{layerMarki}{x},
        y          => $self->{layerMarki}{y},
        symbol     => $self->{layerMarki}{symbol},
        polarity   => 'positive',
        angle      => 0,
        mirror     => 'no',
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    return 1;
}

#**********************************************
#名字		:addFangCuoBa
#功能		:添加内层防错靶
#参数		:无
#返回值		:1
#使用例子	:$self->addFangCuoBa();
#**********************************************
sub addFangCuoBa {
    my $self = shift;

    #如果不是内层，返回
    if ( $self->{layerType} ne 'inner' or $self->{coreNum} < 2 ) {
        return 0;
    }

    #计算防错靶数据
    $self->CountFangCuoBa();

    #避铜
    $self->COM(
        'add_line',
        attributes    => 'no',
        xs            => $self->{fangCuoBa}{biTong}{xs},
        ys            => $self->{fangCuoBa}{biTong}{ys},
        xe            => $self->{fangCuoBa}{biTong}{xe},
        ye            => $self->{fangCuoBa}{biTong}{ye},
        symbol        => 's6500',
        polarity      => 'negative',
        bus_num_lines => 0,
        bus_dist_by   => 'pitch',
        bus_distance  => 0,
        bus_reference => 'left'
    );

    #	for (my $i=1 ; $i<=scalar(@{$self->{innerLayer}}); $i++){
    #		$self->DisplayLayer($self->{innerLayer}[$i-1], '1');
    #		countCoor();
    #		$self->COM('add_pad', attributes => 'no',
    #			x          => $self->{coordinate}{x},
    #			y          => $self->{coordinate}{y},
    #			symbol     => $self->{symbol},
    #			polarity   => 'negative',
    #			angle      => '0',
    #			mirror     => 'no',
    #			nx         => 1,
    #			ny         => 1,
    #			dx         => 0,
    #			dy         => 0,
    #			xscale     => 1,
    #			yscale     => 1);
    #		countCoor($i);
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{fangCuoBa}{x},
        y          => $self->{fangCuoBa}{y},
        symbol     => 'rect10000x6000',
        polarity   => 'positive',
        angle      => '0',
        mirror     => 'no',
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    #}
    return 1;
}

#**********************************************
#名字		:addTongQiePian
#功能		:添加通孔切片孔
#参数		:无
#返回值		:1
#使用例子	:$self->addTongQiePian();
#**********************************************
sub addTongQiePianRight {
    my $self = shift;

    #计算通孔切片孔
    $self->CountTongQiePianRight();

    #添加通孔切片孔
    #	$self->COM('add_pad', attributes => 'no',
    #		x          => $self->{tong}{qiePian}{x},
    #		y          => $self->{tong}{qiePian}{y},
    #		symbol     => 'h-tong-qiepian-pad',
    #		polarity   => 'positive',
    #		angle      => $self->{tong}{qiePian}{angle},
    #		mirror     => 'no',
    #		nx         => 1,
    #		ny         => 1,
    #		dx         => 0,
    #		dy         => 0,
    #		xscale     => 1,
    #		yscale     => 1);

    #如果是通孔层，加孔
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{tong}{qiePianRight}{x},
        y          => $self->{tong}{qiePianRight}{y},
        symbol     => $self->{tong}{qiePianRight}{symbol},
        polarity   => 'positive',
        angle      => $self->{tong}{qiePianRight}{angle},
        mirror     => 'no',
        nx         => $self->{tong}{qiePianRight}{nx},
        ny         => $self->{tong}{qiePianRight}{ny},
        dx         => $self->{tong}{qiePianRight}{dx},
        dy         => $self->{tong}{qiePianRight}{dy},
        xscale     => 1,
        yscale     => 1
    );

    #两个大的切片孔
    if ( $self->{layerType} eq 'via' ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{tong}{qiePianRightR1000}{x},
            y          => $self->{tong}{qiePianRightR1000}{y},
            symbol     => 'r1000',
            polarity   => 'positive',
            angle      => 0,
            mirror     => 'no',
            nx         => $self->{tong}{qiePianRightR1000}{nx},
            ny         => $self->{tong}{qiePianRightR1000}{ny},
            dx         => $self->{tong}{qiePianRightR1000}{dx},
            dy         => $self->{tong}{qiePianRightR1000}{dy},
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addTongQiePian
#功能		:添加通孔切片孔
#参数		:无
#返回值		:1
#使用例子	:$self->addTongQiePian();
#**********************************************
sub addTongQiePianTop {
    my $self = shift;

    #计算通孔切片孔
    $self->CountTongQiePianTop();

    #添加通孔切片孔
    #	$self->COM('add_pad', attributes => 'no',
    #		x          => $self->{tong}{qiePian}{x},
    #		y          => $self->{tong}{qiePian}{y},
    #		symbol     => 'h-tong-qiepian-pad',
    #		polarity   => 'positive',
    #		angle      => $self->{tong}{qiePian}{angle},
    #		mirror     => 'no',
    #		nx         => 1,
    #		ny         => 1,
    #		dx         => 0,
    #		dy         => 0,
    #		xscale     => 1,
    #		yscale     => 1);

    #如果是通孔层，加孔
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{tong}{qiePianTop}{x},
        y          => $self->{tong}{qiePianTop}{y},
        symbol     => $self->{tong}{qiePianTop}{symbol},
        polarity   => 'positive',
        angle      => $self->{tong}{qiePianTop}{angle},
        mirror     => 'no',
        nx         => $self->{tong}{qiePianTop}{nx},
        ny         => $self->{tong}{qiePianTop}{ny},
        dx         => $self->{tong}{qiePianTop}{dx},
        dy         => $self->{tong}{qiePianTop}{dy},
        xscale     => 1,
        yscale     => 1
    );

    #两个大的切片孔
    if ( $self->{layerType} eq 'via' ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{tong}{qiePianTopR1000}{x},
            y          => $self->{tong}{qiePianTopR1000}{y},
            symbol     => 'r1000',
            polarity   => 'positive',
            angle      => 0,
            mirror     => 'no',
            nx         => $self->{tong}{qiePianTopR1000}{nx},
            ny         => $self->{tong}{qiePianTopR1000}{ny},
            dx         => $self->{tong}{qiePianTopR1000}{dx},
            dy         => $self->{tong}{qiePianTopR1000}{dy},
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addBuryQiePian
#功能		:添加通孔切片孔
#参数		:无
#返回值		:1
#使用例子	:$self->addBuryQiePian();
#**********************************************
sub addBuryQiePian {
    my $self = shift;

    #如果没有埋孔层，返回
    if (   $#{ $self->{bury}{layer} } < 0
        or $self->{ $self->{Layer} }{minBury}{find} eq 'no' )
    {
        return 0;
    }

    #信号层添加symbol

    foreach my $i ( 0 .. $#{ $self->{bury}{layer} } ) {

#计算埋孔切片孔,计算放在里面，因为可能一个信号层添加多个埋孔切片孔，要进行多次计算
        $self->CountBuryQiePian();

        #添加
        #算出该埋孔层第几层到第几层
        if (   $self->{layerType} eq 'second'
            or $self->{layerType} eq 'inner' )
        {
            my $buryStart = substr( $self->{bury}{layer}[$i], 1, 1 );
            my $buryEnd = substr( $self->{bury}{layer}[$i], 2 );

            #添加埋孔切片孔
            if (    $self->{ $self->{Layer} }{layNum} >= $buryStart
                and $self->{ $self->{Layer} }{layNum} <= $buryEnd )
            {
                $self->COM(
                    'add_pad',
                    attributes => 'no',
                    x          => $self->{bury}{qiePian}{$i}{x},
                    y          => $self->{bury}{qiePian}{$i}{y},
                    symbol     => $self->{bury}{qiePian}{symbol},
                    polarity   => 'positive',
                    angle      => $self->{bury}{qiePian}{angle},
                    mirror     => 'no',
                    nx         => 1,
                    ny         => 1,
                    dx         => 0,
                    dy         => 0,
                    xscale     => 1,
                    yscale     => 1
                );
            }
        }
        elsif ( $self->{layerType} eq 'bury'
            and $self->{Layer} eq $self->{bury}{layer}[$i] )
        {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{bury}{qiePian}{$i}{x},
                y          => $self->{bury}{qiePian}{$i}{y},
                symbol     => "r$self->{cfg}{minBury}",
                polarity   => 'positive',
                angle      => 0,
                mirror     => 'no',
                nx         => $self->{bury}{qiePian}{nx},
                ny         => $self->{bury}{qiePian}{ny},
                dx         => $self->{bury}{qiePian}{dx},
                dy         => $self->{bury}{qiePian}{dy},
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    return 1;
}

#**********************************************
#名字		:addLaserQiePian
#功能		:添加镭射切片孔
#参数		:无
#返回值		:1
#使用例子	:$self->addLaserQiePian();
#**********************************************
sub addLaserQiePian {
    my $self = shift;

    #如果没有镭射层，返回
    if (    $#{ $self->{laser}{drillTop} } < 0
        and $#{ $self->{laser}{drillBottom} } < 0 )
    {
        return 0;
    }

    #计算镭射切片孔symbol
    $self->CountLaserQiePian();

    #添加镭射切片孔
    foreach my $i ( 0 .. $#{ $self->{laser}{qiePian}{x} } ) {
        if (   $self->{layerType} eq 'second'
            or $self->{layerType} eq 'outer'
            or $self->{layerType} eq 'sm' )
        {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{laser}{qiePian}{x}[$i],
                y          => $self->{laser}{qiePian}{y}[$i],
                symbol     => $self->{laser}{qiePian}{symbol},
                polarity   => 'positive',
                angle      => $self->{laser}{qiePian}{angle}[$i],
                mirror     => 'no',
                nx         => $self->{laser}{qiePian}{nx}[$i],
                ny         => $self->{laser}{qiePian}{ny}[$i],
                dx         => $self->{laser}{qiePian}{dx}[$i],
                dy         => $self->{laser}{qiePian}{dy}[$i],
                xscale     => 1,
                yscale     => 1
            );
        }

    }

    #镭射切片孔，孔层
    if ( $self->{layerType} eq 'laser' ) {
        my $characterAmount = length $self->{Layer};
        my $laserTop;
        if ( $characterAmount == 3 ) {
            $laserTop = substr( $self->{Layer}, 1, 1 );
        }
        else {
            $laserTop = substr( $self->{Layer}, 1, 2 );
        }

        my $laserTopYu = $laserTop % 2;
        if ( $laserTopYu == 0 ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{laser}{qiePian}{x}[2],
                y          => $self->{laser}{qiePian}{y}[2],
                symbol     => $self->{laser}{qiePian}{symbol},
                polarity   => 'positive',
                angle      => $self->{laser}{qiePian}{angle}[2],
                mirror     => 'no',
                nx         => $self->{laser}{qiePian}{nx}[2],
                ny         => $self->{laser}{qiePian}{ny}[2],
                dx         => $self->{laser}{qiePian}{dx}[2],
                dy         => $self->{laser}{qiePian}{dy}[2],
                xscale     => 1,
                yscale     => 1
            );

            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{laser}{qiePian}{x}[3],
                y          => $self->{laser}{qiePian}{y}[3],
                symbol     => $self->{laser}{qiePian}{symbol},
                polarity   => 'positive',
                angle      => $self->{laser}{qiePian}{angle}[3],
                mirror     => 'no',
                nx         => $self->{laser}{qiePian}{nx}[3],
                ny         => $self->{laser}{qiePian}{ny}[3],
                dx         => $self->{laser}{qiePian}{dx}[3],
                dy         => $self->{laser}{qiePian}{dy}[3],
                xscale     => 1,
                yscale     => 1
            );
        }
        else {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{laser}{qiePian}{x}[0],
                y          => $self->{laser}{qiePian}{y}[0],
                symbol     => $self->{laser}{qiePian}{symbol},
                polarity   => 'positive',
                angle      => $self->{laser}{qiePian}{angle}[0],
                mirror     => 'no',
                nx         => $self->{laser}{qiePian}{nx}[0],
                ny         => $self->{laser}{qiePian}{ny}[0],
                dx         => $self->{laser}{qiePian}{dx}[0],
                dy         => $self->{laser}{qiePian}{dy}[0],
                xscale     => 1,
                yscale     => 1
            );

            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{laser}{qiePian}{x}[1],
                y          => $self->{laser}{qiePian}{y}[1],
                symbol     => $self->{laser}{qiePian}{symbol},
                polarity   => 'positive',
                angle      => $self->{laser}{qiePian}{angle}[1],
                mirror     => 'no',
                nx         => $self->{laser}{qiePian}{nx}[1],
                ny         => $self->{laser}{qiePian}{ny}[1],
                dx         => $self->{laser}{qiePian}{dx}[1],
                dy         => $self->{laser}{qiePian}{dy}[1],
                xscale     => 1,
                yscale     => 1
            );
        }
    }
    return 1;
}

#**********************************************
#名字		:addLaserCeShi
#功能		:添加镭射测试pad
#参数		:无
#返回值		:1
#使用例子	:$self->addLaserCeShi();
#**********************************************
sub addLaserCeShi {
    my $self = shift;

    #如果没有镭射层，返回
    if (    $#{ $self->{laser}{drillTop} } < 0
        and $#{ $self->{laser}{drillBottom} } < 0 )
    {
        return 0;
    }

    #计算镭射测试坐标
    $self->CountLaserCeShi();

    #添加镭射测试
    if ( $self->{layerType} eq 'inner' ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{laser}{ceShi}{x}[0],
            y          => $self->{laser}{ceShi}{y},
            symbol     => $self->{laser}{ceShi}{symbol}[0],
            polarity   => 'positive',
            angle      => '0',
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }
    elsif ( $self->{layerType} eq 'second' ) {

        #计算锣边次数是奇数还是偶数
        my $jiOu = $self->{ $self->{Layer} }{yaheN} % 2;

        #偶数
        if ( $jiOu == 0 ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{laser}{ceShi}{x}[0],
                y          => $self->{laser}{ceShi}{y},
                symbol     => $self->{laser}{ceShi}{symbol}[0],
                polarity   => 'positive',
                angle      => '0',
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );

            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{laser}{ceShi}{x}[1],
                y          => $self->{laser}{ceShi}{y},
                symbol     => $self->{laser}{ceShi}{symbol}[1],
                polarity   => 'positive',
                angle      => '0',
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
        else {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{laser}{ceShi}{x}[0],
                y          => $self->{laser}{ceShi}{y},
                symbol     => $self->{laser}{ceShi}{symbol}[1],
                polarity   => 'positive',
                angle      => '0',
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );

            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{laser}{ceShi}{x}[1],
                y          => $self->{laser}{ceShi}{y},
                symbol     => $self->{laser}{ceShi}{symbol}[0],
                polarity   => 'positive',
                angle      => '0',
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }
    elsif ( $self->{layerType} eq 'outer' ) {
        my $jiOu = $self->{ $self->{Layer} }{yaheN} % 2;
        if ( $jiOu == 0 ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{laser}{ceShi}{x}[1],
                y          => $self->{laser}{ceShi}{y},
                symbol     => $self->{laser}{ceShi}{symbol}[1],
                polarity   => 'positive',
                angle      => '0',
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
        else {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{laser}{ceShi}{x}[0],
                y          => $self->{laser}{ceShi}{y},
                symbol     => $self->{laser}{ceShi}{symbol}[1],
                polarity   => 'positive',
                angle      => '0',
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }
    elsif ( $self->{layerType} eq 'sm' ) {
        my $jiOu = $self->{hdi}{jieShu} % 2;
        if ( $jiOu == 0 ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{laser}{ceShi}{x}[0],
                y          => $self->{laser}{ceShi}{y},
                symbol     => $self->{laser}{ceShi}{symbol}[3],
                polarity   => 'positive',
                angle      => '0',
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
        else {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{laser}{ceShi}{x}[1],
                y          => $self->{laser}{ceShi}{y},
                symbol     => $self->{laser}{ceShi}{symbol}[3],
                polarity   => 'positive',
                angle      => '0',
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }
    elsif ( $self->{layerType} eq 'laser' ) {
        my $characterAmount = length $self->{Layer};
        my $laserTop;
        if ( $characterAmount == 3 ) {
            $laserTop = substr( $self->{Layer}, 1, 1 );
        }
        else {
            $laserTop = substr( $self->{Layer}, 1, 2 );
        }
        my $jiOu       = $laserTop % 2;
        my $jiOuJieShu = $self->{hdi}{jieShu} % 2;
        if ( $jiOuJieShu == 0 ) {
            if ( $jiOu == 0 ) {
                $self->COM(
                    'add_pad',
                    attributes => 'no',
                    x          => $self->{laser}{ceShi}{x}[1],
                    y          => $self->{laser}{ceShi}{y},
                    symbol     => $self->{laser}{ceShi}{symbol}[2],
                    polarity   => 'positive',
                    angle      => '0',
                    mirror     => 'no',
                    nx         => 2,
                    ny         => 15,
                    dx         => 660.4,
                    dy         => 660.4,
                    xscale     => 1,
                    yscale     => 1
                );
            }
            else {
                $self->COM(
                    'add_pad',
                    attributes => 'no',
                    x          => $self->{laser}{ceShi}{x}[0],
                    y          => $self->{laser}{ceShi}{y},
                    symbol     => $self->{laser}{ceShi}{symbol}[2],
                    polarity   => 'positive',
                    angle      => '0',
                    mirror     => 'no',
                    nx         => 2,
                    ny         => 15,
                    dx         => 660.4,
                    dy         => 660.4,
                    xscale     => 1,
                    yscale     => 1
                );
            }
        }
        else {
            if ( $jiOu == 0 ) {
                $self->COM(
                    'add_pad',
                    attributes => 'no',
                    x          => $self->{laser}{ceShi}{x}[0],
                    y          => $self->{laser}{ceShi}{y},
                    symbol     => $self->{laser}{ceShi}{symbol}[2],
                    polarity   => 'positive',
                    angle      => '0',
                    mirror     => 'no',
                    nx         => 2,
                    ny         => 15,
                    dx         => 660.4,
                    dy         => 660.4,
                    xscale     => 1,
                    yscale     => 1
                );
            }
            else {
                $self->COM(
                    'add_pad',
                    attributes => 'no',
                    x          => $self->{laser}{ceShi}{x}[1],
                    y          => $self->{laser}{ceShi}{y},
                    symbol     => $self->{laser}{ceShi}{symbol}[2],
                    polarity   => 'positive',
                    angle      => '0',
                    mirror     => 'no',
                    nx         => 2,
                    ny         => 15,
                    dx         => 660.4,
                    dy         => 660.4,
                    xscale     => 1,
                    yscale     => 1
                );
            }

        }

    }

    return 1;
}

#**********************************************
#名字		:addFangHanCCD
#功能		:添加防焊ccd
#参数		:无
#返回值		:1
#使用例子	:$self->addFangHanCCD();
#**********************************************
sub addFangHanCCD {
    my $self = shift;

    #计算防焊ccd数据
    $self->CountFangHanCCD();

    #添加防焊ccd
    foreach my $i ( 0 .. $#{ $self->{fangHanCCD}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{fangHanCCD}{x}[$i],
            y          => $self->{fangHanCCD}{y}[$i],
            symbol     => $self->{fangHanCCD}{symbol},
            polarity   => 'positive',
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addCustomerCode
#功能		:添加客户代码
#参数		:无
#返回值		:1
#使用例子	:$self->addCustomerCode();
#**********************************************
sub addCustomerCode {
    my $self = shift;

    #计算客户代码数据
    $self->CountCustomerCode();

    #添加客户代码
    $self->COM(
        'add_text',
        attributes => 'no',
        type       => 'string',
        x          => $self->{customerCode}{x},
        y          => $self->{customerCode}{y},
        text       => "$self->{cfg}{customerCode}{num}",
        x_size     => '2.54',
        y_size     => '2.54',
        W_factor   => '0.985',
        polarity   => 'positive',
        angle      => 270,
        mirror     => 'no',
        fontname   => 'simple',
        bar_type   => 'UPC39'
    );

    return 1;
}

#**********************************************
#名字		:addFangHanCCDBY
#功能		:添加备用防焊ccd
#参数		:无
#返回值		:1
#使用例子	:$self->addFangHanCCDBY();
#**********************************************
sub addFangHanCCDBY {
    my $self = shift;

    #计算防焊ccd数据
    $self->CountFangHanCCDBY();

    #添加防焊ccd
    foreach my $i ( 0 .. $#{ $self->{fangHanCCDBY}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{fangHanCCDBY}{x}[$i],
            y          => $self->{fangHanCCDBY}{y}[$i],
            symbol     => $self->{fangHanCCDBY}{symbol},
            polarity   => 'positive',
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addBigSurface
#功能		:次外层添加大铜块
#参数		:无
#返回值		:1
#使用例子	:$self->addBigSurface();
#**********************************************
sub addBigSurface {
    my $self = shift;

    if ( $self->{fillCuMode} ne 'zuLiuTiao' ) {
        return 0;
    }

    #计算次外层大铜块数据
    $self->CountBigSurface();

    #设置参数
    $self->COM(
        'fill_params',
        type           => 'solid',
        origin_type    => 'datum',
        solid_type     => 'surface',
        std_type       => 'line',
        min_brush      => 4,
        use_arcs       => 'yes',
        symbol         => 's39.37',
        dx             => '0.0590551',
        dy             => '0.0590551',
        std_angle      => 45,
        std_line_width => 10,
        std_step_dist  => 50,
        std_indent     => 'odd',
        break_partial  => 'yes',
        cut_prims      => 'no',
        outline_draw   => 'no',
        outline_width  => 0,
        outline_invert => 'no'
    );

    if (    $self->{layerType} eq 'second'
        and $self->{Layer} =~ /t/ )
    {
        foreach my $i ( 0 .. $#{ $self->{bigSurface}{xStart} } ) {
            $self->COM(
                'add_surf_poly_strt',
                x => $self->{bigSurface}{xStart}[$i],
                y => $self->{bigSurface}{yStart}[$i]
            );
            $self->COM(
                'add_surf_poly_seg',
                x => $self->{bigSurface}{xStart}[$i],
                y => $self->{bigSurface}{yEnd}[$i]
            );
            $self->COM(
                'add_surf_poly_seg',
                x => $self->{bigSurface}{xEnd}[$i],
                y => $self->{bigSurface}{yEnd}[$i]
            );
            $self->COM(
                'add_surf_poly_seg',
                x => $self->{bigSurface}{xEnd}[$i],
                y => $self->{bigSurface}{yStart}[$i]
            );
            $self->COM(
                'add_surf_poly_seg',
                x => $self->{bigSurface}{xStart}[$i],
                y => $self->{bigSurface}{yStart}[$i]
            );
            $self->COM('add_surf_poly_end');
            $self->COM(
                'add_surf_end',
                attributes => 'no',
                polarity   => 'positive'
            );
        }
    }

    return 1;
}

#**********************************************
#名字		:addHWSymbol
#功能		:添加华为symbol
#参数		:无
#返回值		:1
#使用例子	:$self->addHWSymbol();
#**********************************************
sub addHWSymbol {
    my $self = shift;

    if (    $self->{cfg}{customerCode}{num} ne '6169'
        and $self->{cfg}{customerCode}{num} ne '6005'
        and $self->{cfg}{customerCode}{num} ne '6004' )
    {
        return 0;
    }

    #计算添加华为symbol数据
    $self->CountHWSymbol();

    #添加华为symbol
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{huaWei}{x},
        y          => $self->{huaWei}{y},
        symbol     => $self->{huaWei}{symbol},
        polarity   => 'positive',
        angle      => 0,
        mirror     => $self->{huaWei}{mirror},
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    return 1;
}

#**********************************************
#名字		:addOutMark
#功能		:添加out-mark symbol
#参数		:无
#返回值		:1
#使用例子	:$self->addOutMark();
#**********************************************
sub addOutMark {
    my $self = shift;

    #计算out-mark symbol数据
    $self->CountOutMark();

    #添加out-mark symbol
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{outMark}{x},
        y          => $self->{outMark}{y},
        symbol     => 'out-mark',
        polarity   => 'positive',
        angle      => 0,
        mirror     => $self->{outMark}{mirror},
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    return 1;
}

#**********************************************
#名字		:add3Rect
#功能		:添加三个矩形pad
#参数		:无
#返回值		:1
#使用例子	:$self->add3Rect();
#**********************************************
sub add3Rect {
    my $self = shift;

    #计算数据
    $self->Count3Rect();

    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{rect3}{x},
        y          => $self->{rect3}{y},
        symbol     => 'rect10000x5000',
        polarity   => 'positive',
        angle      => 0,
        mirror     => 'no',
        nx         => 3,
        ny         => 1,
        dx         => 15000,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    return 1;
}

#**********************************************
#名字		:addJsSymbol
#功能		:添加Js symbol
#参数		:无
#返回值		:1
#使用例子	:$self->addJsSymbol();
#**********************************************
sub addJsSymbol {
    my $self = shift;

    #如果样品不是内层，则返回
    #	if ($self->{hdi}{jobType} eq 't'
    #			and $self->{Layer} !~ /in/){
    #		return 0;
    #	}

    #计算js symbol数据
    $self->CountJsSymbol();

    #添加js symbol
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{jsSymbol}{x},
        y          => $self->{jsSymbol}{y},
        symbol     => 'zh-js',
        polarity   => 'positive',
        angle      => 0,
        mirror     => 'no',
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    return 1;
}

#**********************************************
#名字		:addFdjt
#功能		:添加防呆箭头
#参数		:无
#返回值		:1
#使用例子	:$self->addFdjt();
#**********************************************
sub addFdjt {
    my $self = shift;

    #如果样品不是内层，则返回
    #	if ($self->{hdi}{jobType} eq 't'
    #			and $self->{Layer} !~ /in/){
    #		return 0;
    #	}

    #计算js symbol数据
    $self->CountFdjtSymbol();

    #添加js symbol
    foreach my $i ( 0 .. $#{ $self->{fdjt}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{fdjt}{x}[$i],
            y          => $self->{fdjt}{y}[$i],
            symbol     => 'zh-fdjt',
            polarity   => 'positive',
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addBaKongJianTou
#功能		:添加靶孔箭头
#参数		:无
#返回值		:1
#使用例子	:$self->addBaKongJianTou();
#**********************************************
sub addBaKongJianTou {
    my $self = shift;

    if (    $self->{hdi}{jieShu} != 0
        and $self->{coreNum} < 2 )
    {
        return 0;
    }

    $self->CountBaKongJianTou();

    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{baKongJianTou}{x},
        y          => $self->{baKongJianTou}{y},
        symbol     => 'bk-hjt',
        polarity   => 'positive',
        angle      => 0,
        mirror     => 'no',
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    return 1;
}

#**********************************************
#名字		:addAuthSymbol
#功能		:添加Auth symbol
#参数		:无
#返回值		:1
#使用例子	:$self->addAuthSymbol();
#**********************************************
sub addAuthSymbol {
    my $self = shift;

    #计算Auth symbol数据
    $self->CountAuthSymbol();

    #添加Auth pad symbol
    foreach my $i ( 0 .. $#{ $self->{authPad}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{authPad}{x}[$i],
            y          => $self->{authPad}{y}[$i],
            symbol     => $self->{authPad}{symbol},
            polarity   => 'positive',
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    #添加auth text symbol
    if ( $self->{layerType} eq 'outer' ) {
        foreach my $i ( 0 .. $#{ $self->{authPad}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{authText}{x}[$i],
                y          => $self->{authText}{y}[$i],
                symbol     => 'hc-authtext',
                polarity   => 'positive',
                angle      => $self->{authText}{angle}[$i],
                mirror     => $self->{authText}{mirror},
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    return 1;
}

#**********************************************
#名字		:addBuryPianKongDuiWei
#功能		:添加埋孔偏孔对位孔
#参数		:无
#返回值		:1
#使用例子	:$self->addBuryPianKongDuiWei();
#**********************************************
sub addBuryPianKongDuiWei {
    my $self = shift;

    $self->CountBuryPianKongDuiWei();

    #计算偏孔对位孔
    if (   $#{ $self->{bury}{layer} } < 0
        or $self->{ $self->{Layer} }{minBury}{find} eq 'no' )
    {
        return 0;
    }

    #添加
    foreach my $i ( 0 .. $#{ $self->{pianKong}{bury}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{pianKong}{bury}{x}[$i],
            y          => $self->{pianKong}{bury}{y}[$i],
            symbol     => $self->{pianKong}{bury}{symbol},
            polarity   => 'positive',
            angle      => '0',
            mirror     => 'no',
            nx         => 1,
            ny         => 4,
            dx         => 0,
            dy         => $self->{pianKong}{bury}{dy}[$i],
            xscale     => 1,
            yscale     => 1
        );
    }

    if (   $self->{layerType} eq 'second'
        or $self->{layerType} eq 'inner' )
    {
        foreach my $i ( 0 .. $#{ $self->{pianKong}{bury}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{pianKong}{bury}{x}[$i],
                y          => $self->{pianKong}{bury}{y}[$i],
                symbol     => 'r754',
                polarity   => 'negative',
                angle      => '0',
                mirror     => 'no',
                nx         => 1,
                ny         => 4,
                dx         => 0,
                dy         => $self->{pianKong}{bury}{dy}[$i],
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    return 1;
}

#**********************************************
#名字		:addTongPianKongDuiWei1
#功能		:添加通孔偏孔对位第一组
#参数		:无
#返回值		:1
#使用例子	:$self->addTongPianKongDuiWei1();
#**********************************************
sub addTongPianKongDuiWei1 {
    my $self = shift;

    #如果没有镭射层，返回
    if (    $#{ $self->{laser}{drillTop} } < 0
        and $#{ $self->{laser}{drillBottom} } < 0 )
    {
        return 0;
    }

    #计算通孔偏孔对位第一组
    $self->CountTongPianKongDuiWei1();

    #添加通孔偏孔对位第一组
    if (   $self->{layerType} eq 'outer'
        or $self->{layerType} eq 'second'
        or $self->{layerType} eq 'inner'
        or $self->{layerType} eq 'via' )
    {
        foreach my $i ( 0 .. $#{ $self->{pianKong}{tong1}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{pianKong}{tong1}{x}[$i],
                y          => $self->{pianKong}{tong1}{y}[$i],
                symbol     => $self->{pianKong}{tong1}{symbol},
                polarity   => 'positive',
                angle      => '0',
                mirror     => 'no',
                nx         => 3,
                ny         => 1,
                dx         => $self->{pianKong}{tong1}{dx}[$i],
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    if (   $self->{layerType} eq 'outer'
        or $self->{layerType} eq 'second'
        or $self->{layerType} eq 'inner' )
    {
        foreach my $i ( 0 .. $#{ $self->{pianKong}{tong1}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{pianKong}{tong1}{x}[$i],
                y          => $self->{pianKong}{tong1}{y}[$i],
                symbol     => 'r804.8',
                polarity   => 'negative',
                angle      => '0',
                mirror     => 'no',
                nx         => 3,
                ny         => 1,
                dx         => $self->{pianKong}{tong1}{dx}[$i],
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    return 1;
}

#**********************************************
#名字		:addTongPianKongDuiWei2
#功能		:添加通孔偏孔对位第一组
#参数		:无
#返回值		:1
#使用例子	:$self->addTongPianKongDuiWei2();
#**********************************************
sub addTongPianKongDuiWei2 {
    my $self = shift;

    #如果时hdi板，返回
    #如果没有镭射层，返回
    if (    $#{ $self->{laser}{drillTop} } < 0
        and $#{ $self->{laser}{drillBottom} } < 0 )
    {
        return 0;
    }

    #计算通孔偏孔对位第一组
    $self->CountTongPianKongDuiWei2();

    #避铜
    if (   $self->{layerType} eq 'outer'
        or $self->{layerType} eq 'second'
        or $self->{layerType} eq 'inner' )
    {
        foreach my $i ( 0 .. $#{ $self->{pianKong}{tong2}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{pianKong}{tong2}{x}[$i],
                y          => $self->{pianKong}{tong2}{y}[$i],
                symbol     => 's1270',
                polarity   => 'negative',
                angle      => '0',
                mirror     => 'no',
                nx         => 1,
                ny         => 3,
                dx         => 0,
                dy         => $self->{pianKong}{tong2}{dy}[$i],
                xscale     => 1,
                yscale     => 1
            );

            #镭射孔避铜
            my $x = $self->{pianKong}{tong2}{x}[$i];
            my $y;
            if ( $i == 1 or $i == 2 ) {
                $y = $self->{pianKong}{tong2}{y}[$i] + 3.175;
            }
            else {
                $y = $self->{pianKong}{tong2}{y}[$i] + 0.635;
            }

            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $x,
                y          => $y,
                symbol     => 's1270',
                polarity   => 'negative',
                angle      => '0',
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );

        }
    }

    #添加通孔偏孔对位第一组
    if (   $self->{layerType} eq 'outer'
        or $self->{layerType} eq 'second'
        or $self->{layerType} eq 'inner'
        or $self->{layerType} eq 'via' )
    {
        foreach my $i ( 0 .. $#{ $self->{pianKong}{tong2}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{pianKong}{tong2}{x}[$i],
                y          => $self->{pianKong}{tong2}{y}[$i],
                symbol     => $self->{pianKong}{tong2}{symbol},
                polarity   => 'positive',
                angle      => '0',
                mirror     => 'no',
                nx         => 1,
                ny         => 3,
                dx         => 0,
                dy         => $self->{pianKong}{tong2}{dy}[$i],
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    return 1;
}

#**********************************************
#名字		:addLayerDuiWei
#功能		:删除用过的垃圾层
#参数		:无
#返回值		:1
#使用例子	:$self->addLayerDuiWei();
#**********************************************
sub DeleteTmpLayers {
    my $self = shift;
    $self->VOF();
    $self->DeleteLayer("___tmp___i");
    $self->DeleteLayer("___tmp___t");
    $self->DeleteLayer("___tmp___b");
    $self->DeleteLayer("___tmp___s");
    $self->DeleteLayer("___tmp___d");
    $self->VON();
}

sub AddTwoPinTongXinYuan
{
	my $self = shift;
	
	if ($self->{signalLayer}{num} != 4)
	{
		return;
	}
	
	$self->CountTwoPinTongXinYuan();
	
	#左上
	if ($self->{layerType} eq "inner")
	{
		$self->COM('add_pad', attributes => 'no',
				x          => $self->{SR}{xmin} - 7,
				y          => $self->{SR}{ymax} + 7,
				symbol     => $self->{twoPinTongXinYuan}{backSymbol},
				polarity   => 'negative',
				angle      => '0',
				mirror     => 'no',
				nx         => 1,
				ny         => 1,
				dx         => 0,
				dy         => 0,
				xscale     => 1,
				yscale     => 1);	
	}
	$self->COM('add_pad', attributes => 'no',
			x          => $self->{SR}{xmin} - 7,
			y          => $self->{SR}{ymax} + 7,
			symbol     => $self->{twoPinTongXinYuan}{symbol},
			polarity   => 'positive',
			angle      => '0',
			mirror     => 'no',
			nx         => 1,
			ny         => 1,
			dx         => 0,
			dy         => 0,
			xscale     => 1,
			yscale     => 1);
	
	#右上
	if ($self->{layerType} eq "inner")
	{
		$self->COM('add_pad', attributes => 'no',
				x          => $self->{SR}{xmax} + 7,
				y          => $self->{SR}{ymax} + 7,
				symbol     => $self->{twoPinTongXinYuan}{backSymbol},
				polarity   => 'negative',
				angle      => '0',
				mirror     => 'no',
				nx         => 1,
				ny         => 1,
				dx         => 0,
				dy         => 0,
				xscale     => 1,
				yscale     => 1);	
	}
	$self->COM('add_pad', attributes => 'no',
			x          => $self->{SR}{xmax} + 7,
			y          => $self->{SR}{ymax} + 7,
			symbol     => $self->{twoPinTongXinYuan}{symbol},
			polarity   => 'positive',
			angle      => '0',
			mirror     => 'no',
			nx         => 1,
			ny         => 1,
			dx         => 0,
			dy         => 0,
			xscale     => 1,
			yscale     => 1);
	
	#右下
	if ($self->{layerType} eq "inner")
	{
		$self->COM('add_pad', attributes => 'no',
				x          => $self->{SR}{xmax} + 7,
				y          => $self->{SR}{ymin} - 7,
				symbol     => $self->{twoPinTongXinYuan}{backSymbol},
				polarity   => 'negative',
				angle      => '0',
				mirror     => 'no',
				nx         => 1,
				ny         => 1,
				dx         => 0,
				dy         => 0,
				xscale     => 1,
				yscale     => 1);
	}
	$self->COM('add_pad', attributes => 'no',
			x          => $self->{SR}{xmax} + 7,
			y          => $self->{SR}{ymin} - 7,
			symbol     => $self->{twoPinTongXinYuan}{symbol},
			polarity   => 'positive',
			angle      => '0',
			mirror     => 'no',
			nx         => 1,
			ny         => 1,
			dx         => 0,
			dy         => 0,
			xscale     => 1,
			yscale     => 1);
	
	#左下
	if ($self->{layerType} eq "inner")
	{
		$self->COM('add_pad', attributes => 'no',
				x          => $self->{SR}{xmin} - 7,
				y          => $self->{SR}{ymin} - 7,
				symbol     => $self->{twoPinTongXinYuan}{backSymbol},
				polarity   => 'negative',
				angle      => '0',
				mirror     => 'no',
				nx         => 1,
				ny         => 1,
				dx         => 0,
				dy         => 0,
				xscale     => 1,
				yscale     => 1);
	}
	$self->COM('add_pad', attributes => 'no',
			x          => $self->{SR}{xmin} - 7,
			y          => $self->{SR}{ymin} - 7,
			symbol     => $self->{twoPinTongXinYuan}{symbol},
			polarity   => 'positive',
			angle      => '0',
			mirror     => 'no',
			nx         => 1,
			ny         => 1,
			dx         => 0,
			dy         => 0,
			xscale     => 1,
			yscale     => 1);
}

sub AddNewTongXinYuan {
    my $self = shift;

    if ( $self->{signalLayer}{num} < 4 ) {
        return;
    }
    #$self->GetInnerCopperThick();
    $self->CountNewTongXinYuan();
    $self->COM ("cur_atr_reset");
    $self->COM ("cur_atr_set",attribute=>".out_scale");

    #左上
    if ( $self->{layerType} eq "inner" ) {
        $self->COM(
            'add_pad',
            attributes => 'yes',
            x          => $self->{SR}{xmin} + 16.5,
            y          => $self->{SR}{ymax} + 5,
            symbol     => $self->{newTongXinYuan}{backSymbol},
            polarity   => 'negative',
            angle      => '0',
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
        $self->COM(
            'add_pad',
            attributes => 'yes',
            x          => $self->{SR}{xmin} + 16.5,
            y          => $self->{SR}{ymax} + 5 + 4.3,
            symbol     => "1bi1",
            polarity   => 'positive',
            angle      => '0',
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
        
    }
    $self->COM(
        'add_pad',
        attributes => 'yes',
        x          => $self->{SR}{xmin} + 16.5,
        y          => $self->{SR}{ymax} + 5,
        symbol     => $self->{newTongXinYuan}{symbol},
        polarity   => 'positive',
        angle      => '0',
        mirror     => 'no',
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    #右上
    if ( $self->{layerType} eq "inner" ) {
        $self->COM(
            'add_pad',
            attributes => 'yes',
            x          => $self->{SR}{xmax} - 16.5,
            y          => $self->{SR}{ymax} + 5,
            symbol     => $self->{newTongXinYuan}{backSymbol},
            polarity   => 'negative',
            angle      => '0',
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
        $self->COM(
            'add_pad',
            attributes => 'yes',
            x          => $self->{SR}{xmax} - 16.5,
            y          => $self->{SR}{ymax} + 5 + 4.3,
            symbol     => "1bi1",
            polarity   => 'positive',
            angle      => '0',
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }
    $self->COM(
        'add_pad',
        attributes => 'yes',
        x          => $self->{SR}{xmax} - 16.5,
        y          => $self->{SR}{ymax} + 5,
        symbol     => $self->{newTongXinYuan}{symbol},
        polarity   => 'positive',
        angle      => '0',
        mirror     => 'no',
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    #右下
    if ( $self->{layerType} eq "inner" ) {
        $self->COM(
            'add_pad',
            attributes => 'yes',
            x          => $self->{SR}{xmax} - 16.5,
            y          => $self->{SR}{ymin} - 5,
            symbol     => $self->{newTongXinYuan}{backSymbol},
            polarity   => 'negative',
            angle      => '0',
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
        $self->COM(
            'add_pad',
            attributes => 'yes',
            x          => $self->{SR}{xmax} - 16.5,
            y          => $self->{SR}{ymin} - 5 - 4.3,
            symbol     => "1bi1",
            polarity   => 'positive',
            angle      => '0',
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }
    $self->COM(
        'add_pad',
        attributes => 'yes',
        x          => $self->{SR}{xmax} - 16.5,
        y          => $self->{SR}{ymin} - 5,
        symbol     => $self->{newTongXinYuan}{symbol},
        polarity   => 'positive',
        angle      => '0',
        mirror     => 'no',
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    #左下
    if ( $self->{layerType} eq "inner" ) {
        $self->COM(
            'add_pad',
            attributes => 'yes',
            x          => $self->{SR}{xmin} + 16.5,
            y          => $self->{SR}{ymin} - 5,
            symbol     => $self->{newTongXinYuan}{backSymbol},
            polarity   => 'negative',
            angle      => '0',
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
        $self->COM(
            'add_pad',
            attributes => 'yes',
            x          => $self->{SR}{xmin} + 16.5,
            y          => $self->{SR}{ymin} - 5 - 4.3,
            symbol     => "1bi1",
            polarity   => 'positive',
            angle      => '0',
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }
    $self->COM(
        'add_pad',
        attributes => 'yes',
        x          => $self->{SR}{xmin} + 16.5,
        y          => $self->{SR}{ymin} - 5,
        symbol     => $self->{newTongXinYuan}{symbol},
        polarity   => 'positive',
        angle      => '0',
        mirror     => 'no',
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );
    
    $self->COM ("cur_atr_reset");
}

#**********************************************
#名字		:addLayerDuiWei
#功能		:添加层间对位
#参数		:无
#返回值		:1
#使用例子	:$self->addLayerDuiWei();
#**********************************************
sub addLayerDuiWeiPre {
    my $self = shift;

    if (   $self->{hdi}{jieShu} > 0
        or $self->{hdi}{jia} eq 'yes'
        or $self->{coreNum} < 2 )
    {
        return 0;
    }

    #计算对位

    $self->VOF();
    $self->DeleteLayer("___tmp___i");
    $self->DeleteLayer("___tmp___t");
    $self->DeleteLayer("___tmp___b");
    $self->DeleteLayer("___tmp___s");
    $self->DeleteLayer("___tmp___d");
    $self->CreateLayer( "___tmp___i", "misc", "signal", "" );
    $self->CreateLayer( "___tmp___t", "misc", "signal", "" );
    $self->CreateLayer( "___tmp___b", "misc", "signal", "" );
    $self->CreateLayer( "___tmp___s", "misc", "signal", "" );
    $self->CreateLayer( "___tmp___d", "misc", "signal", "" );
    $self->VON();
    $self->CountCCD();
    $self->CountDaba();

    #内层
    my @layers = qw(___tmp___i ___tmp___t ___tmp___b ___tmp___s ___tmp___d);
    foreach my $layer (@layers) {
        $self->ClearAll();
        $self->AffectedLayer($layer);
        $self->CountLayerDuiWeiPre($layer);
        foreach my $i ( 0 .. $#{ $self->{layer}{duiWei}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => "$self->{layer}{duiWei}{x}[$i]",
                y          => "$self->{layer}{duiWei}{y}[$i]",
                symbol     => $self->{layer}{duiwei}{symbol},
                polarity   => "positive",
                angle      => $self->{layer}{duiWei}{angle}[$i],
                mirror     => "no",
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
            $self->COM("sel_break_level,attr_mode=retain");
        }
        #内层
        if ( $layer eq "___tmp___i" ) {
            $self->COM( "filter_reset", filter_name => "popup" );
            $self->COM(
                "filter_set",
                filter_name  => "popup",
                update_popup => "no",
                feat_types   => "pad"
            );
            $self->COM(
                "filter_set",
                filter_name  => "popup",
                update_popup => "no",
                polarity     => "negative"
            );
            $self->COM("filter_area_strt");
            $self->COM(
                "filter_area_end",
                layer          => "",
                filter_name    => "popup",
                operation      => "select",
                area_type      => "none",
                inside_area    => "no",
                intersect_area => "no"
            );
            $self->COM( "filter_reset", filter_name => "popup" );
            if ( $self->GetSelectNumber() > 0 ) {
                $self->COM(
                    "sel_resize",
                    size       => $self->{layer}{duiwei}{drlSize},
                    corner_ctl => "no"
                );
            }
        }
        elsif ($layer eq "___tmp___t"
            || $layer eq "___tmp___b"
            || $layer eq "___tmp___s" )
        {
            $self->COM( "filter_reset", filter_name => "popup" );
            $self->COM(
                "filter_set",
                filter_name  => "popup",
                update_popup => "no",
                feat_types   => "pad"
            );
            $self->COM("filter_area_strt");
            $self->COM(
                "filter_area_end",
                layer          => "",
                filter_name    => "popup",
                operation      => "select",
                area_type      => "none",
                inside_area    => "no",
                intersect_area => "no"
            );
            $self->COM( "filter_reset", filter_name => "popup" );
            if ( $self->GetSelectNumber() > 0 ) {
                $self->COM(
                    "sel_resize",
                    size       => $self->{layer}{duiwei}{drlSize},
                    corner_ctl => "no"
                );
            }
        }
        elsif ( $layer eq "___tmp___d" ) {
            $self->COM(
                "sel_change_sym",
                symbol      => "r" . $self->{layer}{duiwei}{drlSize},
                reset_angle => "no"
            );
        }
    }
    $self->ClearAll();
    return 1;
}

#**********************************************
#名字		:addLayerDuiWei
#功能		:添加层间对位
#参数		:无
#返回值		:1
#使用例子	:$self->addLayerDuiWei();
#**********************************************
sub addLayerDuiWei {
    my $self = shift;

    if (   $self->{hdi}{jieShu} > 0
        or $self->{hdi}{jia} eq 'yes'
        or $self->{coreNum} < 2 )
    {
        return 0;
    }

    #计算对位
    $self->CountLayerDuiWei();
    $self->ClearAll();
    $self->COM(
        "display_layer",
        name    => $self->{layer}{duiWei}{workLayer},
        display => "yes",
        number  => 1
    );
    $self->COM( "work_layer", name => $self->{layer}{duiWei}{workLayer} );
    $self->COM(
        "sel_copy_other",
        dest         => "layer_name",
        target_layer => "$self->{Layer}",
        invert       => "no",
        dx           => "0",
        dy           => "0",
        size         => "0",
        x_anchor     => "0",
        y_anchor     => "0",
        rotation     => "0",
        mirror       => "none"
    );
    $self->COM(
        "display_layer",
        name    => $self->{layer}{duiWei}{workLayer},
        display => "no",
        number  => 1
    );
    $self->ClearAll();
    $self->AffectedLayer( $self->{Layer} );

    #添加层别对位
    if ( $self->{layerType} eq 'inner' ) {
        foreach my $i ( 0 .. $#{ $self->{layer}{duiWei}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => "$self->{layer}{duiWei}{firstX}[$i]",
                y          => "$self->{layer}{duiWei}{firstY}[$i]",
                symbol => "r" . ( $self->{layer}{duiwei}{drlSize} + 100 + 600 ),
                polarity => "$self->{layer}{duiWei}{polarity}",
                angle    => 0,
                mirror   => 'no',
                nx       => 1,
                ny       => 1,
                dx       => 0,
                dy       => 0,
                xscale   => 1,
                yscale   => 1
            );
        }
    }
    return 1;
}

#**********************************************
#名字		:addXiaoYe
#功能		:添加小野十字架
#参数		:无
#返回值		:1
#使用例子	:$self->addXiaoYe();
#**********************************************
sub addXiaoYe {
    my $self = shift;

    #不是量产，不用添加
    if ( $self->{hdi}{jobType} eq 't' ) {

        #return 0;
    }

    #计算小野十字架数据
    $self->CountXiaoYe();

    #添加小野十字架
    foreach my $i ( 0 .. $#{ $self->{xiaoYe}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => "$self->{xiaoYe}{x}[$i]",
            y          => "$self->{xiaoYe}{y}[$i]",
            symbol     => 'zh-lgp',
            polarity   => "$self->{xiaoYe}{polarity}",
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:fillZhengPianCu
#功能		:铺正片流程铜
#参数		:无
#返回值		:1
#使用例子	:$self->fillZhengPianCu();
#**********************************************
sub fillZhengPianCu {
    my $self = shift;

    if ( $self->{cfg}{hdi}{zhengFuPian} ne '正片' ) {
        return 0;
    }

    my $step_margin_x   = '-0.508';
    my $step_margin_y   = '-0.508';
    my $step_max_dist_x = $self->{liuBian}{xmin} + 10;
    my $step_max_dist_y = $self->{liuBian}{ymin} + 10;
    my $sr_margin_x     = '2.4993';
    my $sr_margin_y     = '2.4993';
    my $sr_max_dist_x   = '0';
    my $sr_max_dist_y   = '0';

    $self->COM(
"fill_params,type=solid,origin_type=datum,solid_type=surface,std_type=line,min_brush=101.6,use_arcs=yes,symbol=s1000,dx=1.5,dy=1.5,std_angle=45,std_line_width=254,std_step_dist=1270,std_indent=odd,break_partial=yes,cut_prims=no,outline_draw=no,outline_width=0,outline_invert=no"
    );
    $self->COM(
"sr_fill,polarity=positive,step_margin_x=$step_margin_x,step_margin_y=$step_margin_y,step_max_dist_x=$step_max_dist_x,step_max_dist_y=$step_max_dist_y,sr_margin_x=$sr_margin_x,sr_margin_y=$sr_margin_y,sr_max_dist_x=$sr_max_dist_x,sr_max_dist_y=$sr_max_dist_y,nest_sr=no,consider_feat=no,consider_drill=no,consider_rout=no,dest=affected_layers,attributes=no"
    );

    #添加dummy pads
    $step_margin_x   = $self->{liuBian}{xmin} + 10;
    $step_margin_y   = $self->{liuBian}{ymin} + 10;
    $step_max_dist_x = 1000;
    $step_max_dist_y = 1000;
    $sr_margin_x     = 2;
    $sr_margin_y     = 2;
    $sr_max_dist_x   = 10;
    $sr_max_dist_y   = 10;

    $self->COM(
"fill_params,type=pattern,origin_type=datum,solid_type=surface,std_type=line,min_brush=101.6,use_arcs=yes,symbol=s1000,dx=1.5,dy=1.5,std_angle=45,std_line_width=254,std_step_dist=1270,std_indent=odd,break_partial=yes,cut_prims=no,outline_draw=no,outline_width=0,outline_invert=no"
    );
    $self->COM(
"sr_fill,polarity=positive,step_margin_x=$step_margin_x,step_margin_y=$step_margin_y,step_max_dist_x=$step_max_dist_x,step_max_dist_y=$step_max_dist_y,sr_margin_x=$sr_margin_x,sr_margin_y=$sr_margin_y,sr_max_dist_x=$sr_max_dist_x,sr_max_dist_y=$sr_max_dist_y,nest_sr=no,consider_feat=no,consider_drill=no,consider_rout=no,dest=affected_layers,attributes=no"
    );

    return 1;
}

#**********************************************
#名字		:addLaserPianKongDuiWei
#功能		:添加通孔偏孔对位第一组
#参数		:无
#返回值		:1
#使用例子	:$self->addLaserPianKongDuiWei();
#**********************************************
sub addLaserPianKongDuiWei {
    my $self = shift;

    #如果没有镭射层，返回
    if (    $#{ $self->{laser}{drillTop} } < 0
        and $#{ $self->{laser}{drillBottom} } < 0 )
    {
        return 0;
    }

    #计算通孔偏孔对位第一组
    $self->CountLaserDuiWei();

    #添加通孔偏孔对位第一组
    foreach my $i ( 0 .. $#{ $self->{pianKong}{laser}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{pianKong}{laser}{x}[$i],
            y          => $self->{pianKong}{laser}{y}[$i],
            symbol     => $self->{pianKong}{laser}{symbol},
            polarity   => 'positive',
            angle      => '0',
            mirror     => 'no',
            nx         => 1,
            ny         => 3,
            dx         => 0,
            dy         => $self->{pianKong}{laser}{dy}[$i],
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addSuanJian
#功能		:添加酸碱symbol
#参数		:无
#返回值		:1
#使用例子	:$self->addSuanJian();
#**********************************************
sub addSuanJian {
    my $self = shift;

    #计算酸碱symbol
    $self->CountSuanJian();

    #添加酸碱symbol
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{suanJian}{x},
        y          => $self->{suanJian}{y},
        symbol     => $self->{suanJian}{symbol},
        polarity   => $self->{suanJian}{poloarity},
        angle      => '0',
        mirror     => $self->{suanJian}{mirror},
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    return 1;
}

#**********************************************
#名字		:addCuArea
#功能		:添加铜面积
#参数		:无
#返回值		:1
#使用例子	:$self->addCuArea();
#**********************************************
sub addCuArea {
    my $self = shift;

    if ( $self->{cfg}{hdi}{zhengFuPian} ne '正片' ) {
        return 0;
    }

    #计算
    $self->CountCuArea();

    #添加
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => "$self->{cuArea}{x}",
        y          => "$self->{cuArea}{y}",
        symbol     => 'ia_cu',
        polarity   => 'positive',
        angle      => 0,
        mirror     => $self->{cuArea}{mirror},
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    return 1;
}

#**********************************************
#名字		:addZhengPianNum
#功能		:添加正片序号
#参数		:无
#返回值		:1
#使用例子	:$self->addZhengPianNum();
#**********************************************
sub addZhengPianNum {
    my $self = shift;

    if ( $self->{cfg}{hdi}{zhengFuPian} ne '正片' ) {
        return 0;
    }

    #计算正片序号数据
    $self->CountZhengPianNum();

    #添加数字
    $self->COM(
        'add_text',
        attributes => 'no',
        type       => 'string',
        x          => "$self->{zhengPianNum}{x}",
        y          => "$self->{zhengPianNum}{y}",
        text       => "A B 1 2 3 4 5 6 7 8 9 10 11 12",
        x_size     => '1.524',
        y_size     => '2.54',
        w_factor   => 1,
        polarity   => 'negative',
        angle      => 270,
        mirror     => $self->{zhengPianNum}{mirror},
        fontname   => 'standard',
        ver        => 0
    );

    return 1;
}

#**********************************************
#名字		:addFilmTime
#功能		:添加菲林时间
#参数		:无
#返回值		:1
#使用例子	:$self->addFilmTime();
#**********************************************
sub addFilmTime {
    my $self = shift;

    #计算菲林时间数据
    $self->CountFilmTime();

    #添加菲林时间
    foreach my $i ( 0 .. $#{ $self->{filmTime}{text} } ) {
        my $y = $self->{filmTime}{y} + $i * 25;
        if ( $i == 0 ) {
            $self->COM(
                'add_text',
                attributes => 'no',

                x        => "$self->{filmTime}{x}",
                y        => "$y",
                text     => "$self->{filmTime}{text}[$i]",
                x_size   => '2.54',
                y_size   => '2.54',
                w_factor => 1.25,
                polarity => 'positive',
                angle    => 270,
                mirror   => $self->{filmTime}{mirror},
                fontname => 'standard',
                ver      => 0
            );
        }
        else {

            $self->COM(
                'add_text',
                attributes => 'no',
                type       => 'orb_plot_stamp_str',
                x          => "$self->{filmTime}{x}",
                y          => "$y",
                text       => "$self->{filmTime}{text}[$i]",
                x_size     => '2.54',
                y_size     => '2.54',
                w_factor   => 1.25,
                polarity   => 'positive',
                angle      => 270,
                mirror     => $self->{filmTime}{mirror},
                fontname   => 'standard',
                ver        => 0
            );
        }
    }

    return 1;
}

#**********************************************
#名字		:addyyddwwSymbol
#功能		:添加yyddwwSymbol
#参数		:无
#返回值		:1
#使用例子	:$self->addyyddwwSymbol();
#**********************************************
sub addyymmddSymbol {
    my $self = shift;

    #通孔板添加
    if ( $self->{hdi}{jieShu} > 0 ) {
        return 0;
    }

    #计算数据
    $self->CountyymmddSymbol();

    #添加
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{yymmdd}{x},
        y          => $self->{yymmdd}{y},
        symbol     => 'yymmdd',
        polarity   => 'negative',
        angle      => '270',
        mirror     => 'no',
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    return 1;
}

#**********************************************
#名字		:addJiaoKong
#功能		:添加角孔
#参数		:无
#返回值		:1
#使用例子	:$self->addJiaoKong();
#**********************************************
sub addJiaoKong {
    my $self = shift;

    #hdi板不加
    if (   $self->{hdi}{jieShu} > 0
        or $self->{hdi}{jia} eq 'yes' )
    {
        return 0;
    }

    #计算角孔数据
    $self->CountJiaoKong();

    #添加
    foreach my $i ( 0 .. $#{ $self->{jiaoKong}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{jiaoKong}{x}[$i],
            y          => $self->{jiaoKong}{y}[$i],
            symbol     => 'r1000',
            polarity   => 'positive',
            angle      => '0',
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addMangKongDuiWei
#功能		:添加盲孔对位
#参数		:无
#返回值		:1
#使用例子	:$self->addMangKongDuiWei();
#**********************************************
sub addMangKongDuiWei {
    my $self = shift;

    if (   $self->{cfg}{mangKongDuiWei} ne '添加'
        or $self->{hdi}{jieShu} == 0 )
    {
        return 0;
    }

    #计算
    $self->CountMangKongDuiWei();

    #添加负片
    if (   $self->{layerType} eq 'outer'
        or $self->{layerType} eq 'second' )
    {
        foreach my $i ( 0 .. $#{ $self->{mangKongDuiWei}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{mangKongDuiWei}{x}[$i],
                y          => $self->{mangKongDuiWei}{y}[$i],
                symbol     => $self->{mangKongDuiWei}{symbol},
                polarity   => 'positive',
                angle      => '0',
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    #添加
    if ( $self->{layerType} eq 'laser' ) {
        foreach my $i ( 0 .. $#{ $self->{mangKongDuiWei}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{mangKongDuiWei}{x}[$i],
                y          => $self->{mangKongDuiWei}{y}[$i],
                symbol     => $self->{mangKongDuiWei}{symbol},
                polarity   => 'positive',
                angle      => '0',
                mirror     => 'no',
                nx         => 6,
                ny         => 6,
                dx         => 508,
                dy         => 508,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    return 1;
}

#**********************************************
#名字		:addLuoBanDingWei
#功能		:添加锣板定位孔
#参数		:无
#返回值		:1
#使用例子	:$self->addLuoBanDingWei();
#**********************************************
sub addLuoBanDingWei {
    my $self = shift;

    if (    $self->{layerType} eq 'outer'
        and $self->{cfg}{hdi}{zhengFuPian} ne '正片' )
    {
        return 0;
    }

    #计算锣板定位孔数据
    $self->CountLuoBanDingWei();

    foreach my $i ( 0 .. $#{ $self->{luoBanDingWei}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{luoBanDingWei}{x}[$i],
            y          => $self->{luoBanDingWei}{y}[$i],
            symbol     => $self->{luoBanDingWei}{symbol},
            polarity   => $self->{luoBanDingWei}{polarity},
            angle      => '0',
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addFangHanBanZiDong
#功能		:添加防焊半自动定位孔
#参数		:无
#返回值		:1
#使用例子	:$self->addFangHanBanZiDong();
#**********************************************
sub addFangHanBanZiDong {
    my $self = shift;

    #计算防焊半自动定位孔数据
    $self->CountFangHanBanZiDong();

    #添加
    foreach my $i ( 0 .. $#{ $self->{fangHanBanZiDong}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{fangHanBanZiDong}{x}[$i],
            y          => $self->{fangHanBanZiDong}{y}[$i],
            symbol     => $self->{fangHanBanZiDong}{symbol},
            polarity   => 'positive',
            angle      => '0',
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addFangHanBanZiDongNew
#功能		:添加防焊半自动定位孔
#参数		:无
#返回值		:1
#使用例子	:$self->addFangHanBanZiDongNew();
#**********************************************
sub addFangHanBanZiDongNew {
    my $self = shift;

    if ( $self->{hdiType} ne 'muti' ) {
        return 0;
    }

    #计算防焊半自动定位孔数据
    $self->CountFangHanBanZiDongNew();

    #添加
    foreach my $i ( 0 .. $#{ $self->{fangHanBanZiDongNew}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{fangHanBanZiDongNew}{x}[$i],
            y          => $self->{fangHanBanZiDongNew}{y}[$i],
            symbol     => $self->{fangHanBanZiDongNew}{symbol},
            polarity   => 'positive',
            angle      => '0',
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addPenQiGuaKong
#功能		:添加喷漆挂孔
#参数		:无
#返回值		:1
#使用例子	:$self->addPenQiGuaKong();
#**********************************************
sub addPenQiGuaKong {
    my $self = shift;

    #计算喷漆挂空位置
    $self->CountPenQiGuaKong();

    #	#添加
    #	if ($self->{layerType} eq 'outer'){
    #		foreach my $i (0..$#{$self->{penQieGuaKong}{x}}) {
    #			$self->COM('add_pad', attributes => 'no',
    #					x          => $self->{penQieGuaKong}{x}[$i],
    #					y          => $self->{penQieGuaKong}{y}[$i],
    #					symbol     => 's5000',
    #					polarity   => 'negative',
    #					angle      => '0',
    #					mirror     => 'no',
    #					nx         => 1,
    #					ny         => 1,
    #					dx         => 0,
    #					dy         => 0,
    #					xscale     => 1,
    #					yscale     => 1);
    #		}
    #	}

    #添加
    foreach my $i ( 0 .. $#{ $self->{penQieGuaKong}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{penQieGuaKong}{x}[$i],
            y          => $self->{penQieGuaKong}{y}[$i],
            symbol     => $self->{penQieGuaKong}{symbol},
            polarity   => 'positive',
            angle      => '0',
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addWenZiPenMo
#功能		:添加文字喷墨孔
#参数		:无
#返回值		:1
#使用例子	:$self->addWenZiPenMo();
#**********************************************
sub addWenZiPenMo {
    my $self = shift;

    #计算文字喷墨孔
    $self->CountWenZiPenMo();

    #添加避铜
    if ( $self->{layerType} eq 'outer' ) {
        foreach my $i ( 0 .. $#{ $self->{wenZiPenMo}{x} } ) {
            $self->COM(
                'add_pad',
                attributes => 'no',
                x          => $self->{wenZiPenMo}{x}[$i],
                y          => $self->{wenZiPenMo}{y}[$i],
                symbol     => 's5000',
                polarity   => 'negative',
                angle      => '0',
                mirror     => 'no',
                nx         => 1,
                ny         => 1,
                dx         => 0,
                dy         => 0,
                xscale     => 1,
                yscale     => 1
            );
        }
    }

    if ( $self->{layerType} eq 'outer' ) {
        return 0;
    }

    #添加文字喷墨
    foreach my $i ( 0 .. $#{ $self->{wenZiPenMo}{x} } ) {
        if (    $self->{hdi}{yesNo} eq 'no'
            and $self->{layerType} eq 'ss' )
        {
            if ( $i == 0 or $i == 2 ) {
                $self->{wenZiPenMo}{symbol} = 'donut_r3504.79x3201';
            }
            else {
                $self->{wenZiPenMo}{symbol} = 'donut_r3504.79x3200';
            }
        }
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{wenZiPenMo}{x}[$i],
            y          => $self->{wenZiPenMo}{y}[$i],
            symbol     => $self->{wenZiPenMo}{symbol},
            polarity   => 'positive',
            angle      => '0',
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addBaoGuangCiShu
#功能		:添加曝光次数
#参数		:无
#返回值		:1
#使用例子	:$self->addBaoGuangCiShu();
#**********************************************
sub addBaoGuangCiShu {
    my $self = shift;

    #计算曝光次数
    $self->CountBaoGuangCiShu();

    #添加
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{baoGuangCiShu}{x},
        y          => $self->{baoGuangCiShu}{y},
        symbol     => 'flbg-dg',
        polarity   => $self->{baoGuangCiShu}{polarity},
        angle      => '0',
        mirror     => $self->{baoGuangCiShu}{mirror},
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    return 1;
}

#**********************************************
#名字		:addSilkNum
#功能		:添加文字数值
#参数		:无
#返回值		:1
#使用例子	:$self->addSilkNum();
#**********************************************
sub addSilkNum {
    my $self = shift;

    #计算数据
    $self->CountSilkNum();

    #添加
    #添加数字
    $self->COM(
        'add_text',
        attributes => 'no',
        type       => 'string',
        x          => "$self->{silkNum}{x}",
        y          => "$self->{silkNum}{y}",
        text       => "A B 1 2 3 4 5 6 7 8 9 10 11 12",
        x_size     => '2.54',
        y_size     => '2.54',
        w_factor   => 0.84,
        polarity   => 'positive',
        angle      => 270,
        mirror     => $self->{silkNum}{mirror},
        fontname   => 'standard',
        ver        => 0
    );

    return 1;
}

#**********************************************
#名字		:addWeek
#功能		:添加周期
#参数		:无
#返回值		:1
#使用例子	:$self->addWeek();
#**********************************************
sub addWeek {
    my $self = shift;

    #计算周期数据
    $self->CountWeek();

    if (
        $self->{Layer} ne $self->{cfg}{week}{layer}
        or (    $self->{cfg}{week}{mode} ne 'WWYY'
            and $self->{cfg}{week}{mode} ne 'YYWW' )
      )
    {
        return 0;
    }

    #添加
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{week}{x},
        y          => $self->{week}{y},
        symbol     => $self->{week}{symbol},
        polarity   => $self->{week}{polarity},
        angle      => '0',
        mirror     => $self->{week}{mirror},
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    return 1;
}

#**********************************************
#名字		:addDateCode
#功能		:添加文字datecode  symbol
#参数		:无
#返回值		:1
#使用例子	:$self->addDateCode();
#**********************************************
sub addDateCodeSymbol {
    my $self = shift;

    #计算symbol坐标
    $self->CountDateCodeSymbol();

    #添加
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{dateCode}{x},
        y          => $self->{dateCode}{y},
        symbol     => 'datecode',
        polarity   => 'positive',
        angle      => '90',
        mirror     => $self->{dateCode}{mirror},
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    return 1;
}

#**********************************************
#名字		:addSilkCSText
#功能		:添加文字
#参数		:无
#返回值		:1
#使用例子	:$self->addSilkCSText();
#**********************************************
sub addSilkCSText {
    my $self = shift;
    if ( $self->{Layer} =~ /cop[tb]/ ) {
        return;
    }

    #计算symbol坐标
    $self->CountCSText();

    #添加
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{CSText}{x},
        y          => $self->{CSText}{y},
        symbol     => $self->{CSText}{symbol},
        polarity   => 'positive',
        angle      => '180',
        mirror     => 'no',
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    return 1;
}

#**********************************************
#名字		:addPanelInSymbol
#功能		:添加panelIn顶层symbol
#参数		:无
#返回值		:1
#使用例子	:$self->addPanelInSymbol();
#**********************************************
sub addPanelInSymbol {
    my $self = shift;

    $self->CountPanelInSymbol();
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{panelIn}{symbolX},
        y          => $self->{panelIn}{symbolY},
        symbol     => $self->{panelIn}{symbol},
        polarity   => 'positive',
        angle      => '0',
        mirror     => 'no',
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    return 1;
}

#**********************************************
#名字		:addLoubLine
#功能		:添加锣边线
#参数		:无
#返回值		:1
#使用例子	:$self->addLoubLine();
#**********************************************
sub addLoubLine {
    my $self = shift;

    #添加
    $self->COM('add_polyline_strt');
    $self->COM(
        'add_polyline_xy',
        x => $self->{liuBian}{xmin},
        y => $self->{liuBian}{ymin}
    );
    $self->COM(
        'add_polyline_xy',
        x => $self->{liuBian}{xmin},
        y => "$self->{liuBian}{ymax}"
    );
    $self->COM(
        'add_polyline_xy',
        x => $self->{liuBian}{xmax},
        y => $self->{liuBian}{ymax}
    );
    $self->COM(
        'add_polyline_xy',
        x => $self->{liuBian}{xmax},
        y => $self->{liuBian}{ymin}
    );
    $self->COM(
        'add_polyline_xy',
        x => $self->{liuBian}{xmin},
        y => $self->{liuBian}{ymin}
    );
    $self->COM(
        'add_polyline_end',
        attributes    => 'no',
        symbol        => 'r254',
        polarity      => 'positive',
        bus_num_lines => 1,
        bus_dist_by   => 'pitch',
        bus_distance  => 0,
        bus_reference => 'right'
    );

    $self->AreaSelect(
        $self->{liuBian}{xmin} + 4,
        $self->{liuBian}{ymin} + 4,
        $self->{liuBian}{xmin} - 4,
        $self->{liuBian}{ymin} - 4,
        'yes'
    );
    if ( $self->GetSelectNumber() > 0 ) {
        $self->COM(
"sel_intersect_best,function=find_connect,mode=round,radius=8000,length_x=0,length_y=0,type_x=length,type_y=length,show_all=no,keep_remainder1=no,keep_remainder2=no,ang_x=0,ang_y=0"
        );
    }

    $self->AreaSelect(
        $self->{liuBian}{xmin} + 4,
        $self->{liuBian}{ymax} + 4,
        $self->{liuBian}{xmin} - 4,
        $self->{liuBian}{ymax} - 4,
        'yes'
    );
    if ( $self->GetSelectNumber() > 0 ) {
        $self->COM(
"sel_intersect_best,function=find_connect,mode=round,radius=8000,length_x=0,length_y=0,type_x=length,type_y=length,show_all=no,keep_remainder1=no,keep_remainder2=no,ang_x=0,ang_y=0"
        );
    }

    $self->AreaSelect(
        $self->{liuBian}{xmax} + 4,
        $self->{liuBian}{ymax} + 4,
        $self->{liuBian}{xmax} - 4,
        $self->{liuBian}{ymax} - 4,
        'yes'
    );
    if ( $self->GetSelectNumber() > 0 ) {
        $self->COM(
"sel_intersect_best,function=find_connect,mode=round,radius=8000,length_x=0,length_y=0,type_x=length,type_y=length,show_all=no,keep_remainder1=no,keep_remainder2=no,ang_x=0,ang_y=0"
        );
    }
    $self->AreaSelect(
        $self->{liuBian}{xmax} + 4,
        $self->{liuBian}{ymin} + 4,
        $self->{liuBian}{xmax} - 4,
        $self->{liuBian}{ymin} - 4,
        'yes'
    );
    if ( $self->GetSelectNumber() > 0 ) {
        $self->COM(
"sel_intersect_best,function=find_connect,mode=round,radius=8000,length_x=0,length_y=0,type_x=length,type_y=length,show_all=no,keep_remainder1=no,keep_remainder2=no,ang_x=0,ang_y=0"
        );
    }
    return 1;
}

#**********************************************
#名字		:addPanelCbSymbol
#功能		:添加panelCb顶层symbol
#参数		:无
#返回值		:1
#使用例子	:$self->addPanelCbSymbol();
#**********************************************
sub addPanelCbSymbol {
    my $self = shift;

    $self->CountPanelCbSymbol();
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{panelCb}{symbolX},
        y          => $self->{panelCb}{symbolY},
        symbol     => $self->{panelCb}{symbol},
        polarity   => 'positive',
        angle      => '0',
        mirror     => 'no',
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    return 1;
}

#**********************************************
#名字		:addPanelInText
#功能		:添加panelIn 文字
#参数		:无
#返回值		:1
#使用例子	:$self->addPanelInText();
#**********************************************
sub addPanelInText {
    my $self = shift;

    #计算panel-in文字数据
    $self->CountPanelInText();
    my $jobText = uc( $self->{Job} );

    #添加
    $self->COM(
        'add_text',
        attributes => 'no',
        type       => 'string',
        x          => "$self->{panelIn}{textX}",
        y          => "$self->{panelIn}{textY}",
        text       => "$jobText",
        x_size     => '10.16',
        y_size     => '10.16',
        w_factor   => 5,
        polarity   => 'positive',
        angle      => 270,
        mirror     => $self->{panelIn}{mirror},
        fontname   => 'simple',
        ver        => 0
    );

    return 1;
}

#**********************************************
#名字		:addPanelBhText
#功能		:添加panelBh 文字
#参数		:无
#返回值		:1
#使用例子	:$self->addPanelBhText();
#**********************************************
sub addPanelBhText {
    my $self = shift;

    #计算panel-in文字数据
    $self->CountPanelBhText();
    my $jobText = uc( $self->{Job} );

    #添加
    $self->COM(
        'add_text',
        attributes => 'no',
        type       => 'string',
        x          => "$self->{panelBh}{textX}",
        y          => "$self->{panelBh}{textY}",
        text       => "$jobText",
        x_size     => '10.16',
        y_size     => '10.16',
        w_factor   => 5,
        polarity   => 'positive',
        angle      => 270,
        mirror     => $self->{panelBh}{mirror},
        fontname   => 'simple',
        ver        => 0
    );

    return 1;
}

#**********************************************
#名字		:addPanelOutOldShiZiJia
#功能		:添加panel-out 十字架
#参数		:无
#返回值		:1
#使用例子	:$self->addPanelOutOldShiZiJia();
#**********************************************
sub addPanelOutOldShiZiJia {
    my $self = shift;

    if ( $self->{hdi}{jobType} ne "b" ) {

        #return 0;
    }

    #计算symbol
    $self->CountPanelOutOldShiZiJia();

    #添加
    foreach my $i ( 0 .. $#{ $self->{panelOutOldShiZiJia}{symbol} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{panelOutOldShiZiJia}{x},
            y          => $self->{panelOutOldShiZiJia}{y},
            symbol     => $self->{panelOutOldShiZiJia}{symbol}[$i],
            polarity   => 'positive',
            angle      => '0',
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addPanelOutOldLine
#功能		:添加防焊全自动
#参数		:无
#返回值		:1
#使用例子	:$self->addPanelOutOldLine();
#**********************************************
sub addPanelOutOldLine {
    my $self = shift;

    #计算symbol
    $self->CountPanelOutOldLine();

    #添加
    $self->COM('add_polyline_strt');
    $self->COM(
        'add_polyline_xy',
        x => $self->{panelOutOldLine}{x}[0],
        y => $self->{panelOutOldLine}{y}[0]
    );
    $self->COM(
        'add_polyline_xy',
        x => $self->{panelOutOldLine}{x}[1],
        y => "$self->{panelOutOldLine}{y}[0]"
    );
    $self->COM(
        'add_polyline_xy',
        x => $self->{panelOutOldLine}{x}[1],
        y => $self->{panelOutOldLine}{y}[1]
    );
    $self->COM(
        'add_polyline_xy',
        x => $self->{panelOutOldLine}{x}[0],
        y => $self->{panelOutOldLine}{y}[1]
    );
    $self->COM(
        'add_polyline_xy',
        x => $self->{panelOutOldLine}{x}[0],
        y => $self->{panelOutOldLine}{y}[0]
    );
    $self->COM(
        'add_polyline_end',
        attributes    => 'no',
        symbol        => 'r254',
        polarity      => 'positive',
        bus_num_lines => 1,
        bus_dist_by   => 'pitch',
        bus_distance  => 0,
        bus_reference => 'right'
    );

    return 1;
}

#**********************************************
#名字		:addBzdSymbol
#功能		:添加防焊半自动symbol
#参数		:无
#返回值		:1
#使用例子	:$self->addBzdSymbol();
#**********************************************
sub addBzdSymbol {
    my $self = shift;

    $self->CountBzdSymbol();

    #添加
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{bzd}{x},
        y          => $self->{bzd}{y},
        symbol     => 'bzd',
        polarity   => 'positive',
        angle      => '90',
        mirror     => 'no',
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    return 1;
}

#**********************************************
#名字		:addCCDGaiYou
#功能		:添加ccd盖油
#参数		:无
#返回值		:1
#使用例子	:$self->addCCDGaiYou();
#**********************************************
sub addDabaGaiYou {
    my $self = shift;

    if ( $self->{Layer} eq 'gto' ) {
        $self->{addDabaGaiYou}{gto} = 'yes';
    }
    elsif ( $self->{Layer} eq 'gbo' ) {
        $self->{addDabaGaiYou}{gbo} = 'yes';
    }

    if (    $self->{Layer} eq 'copt'
        and $self->{addDabaGaiYou}{gto} eq 'yes' )
    {
        return 0;
    }
    elsif ( $self->{Layer} eq 'copb'
        and $self->{addDabaGaiYou}{gbo} eq 'yes' )
    {
        return 0;
    }

    foreach my $i ( 0 .. $#{ $self->{ccd}{duiWei}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{ccd}{duiWei}{x}[$i],
            y          => $self->{ccd}{duiWei}{y}[$i],
            symbol     => "h-chongkong-duiwei",
            polarity   => 'positive',
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );

        #添加负片
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{ccd}{duiWei}{x}[$i],
            y          => $self->{ccd}{duiWei}{y}[$i],
            symbol     => "r3200",
            polarity   => 'negative',
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    foreach my $i ( 0 .. $#{ $self->{ccdBY}{duiWei}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{ccdBY}{duiWei}{x}[$i],
            y          => $self->{ccdBY}{duiWei}{y}[$i],
            symbol     => "h-chongkong-duiwei",
            polarity   => 'positive',
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );

        #添加负片
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{ccdBY}{duiWei}{x}[$i],
            y          => $self->{ccdBY}{duiWei}{y}[$i],
            symbol     => "r3200",
            polarity   => 'negative',
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    if ( $self->{signalLayer}{num} == 2 ) {
        return 0;
    }

    foreach my $i ( 0 .. $#{ $self->{daba}{duiWei}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{daba}{duiWei}{x}[$i],
            y          => $self->{daba}{duiWei}{y}[$i],
            symbol     => "h-chongkong-duiwei",
            polarity   => 'positive',
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );

        #添加负片
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{daba}{duiWei}{x}[$i],
            y          => $self->{daba}{duiWei}{y}[$i],
            symbol     => "r3200",
            polarity   => 'negative',
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    foreach my $i ( 0 .. $#{ $self->{dabaBY}{duiWei}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{dabaBY}{duiWei}{x}[$i],
            y          => $self->{dabaBY}{duiWei}{y}[$i],
            symbol     => "h-chongkong-duiwei",
            polarity   => 'positive',
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );

        #添加负片
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{dabaBY}{duiWei}{x}[$i],
            y          => $self->{dabaBY}{duiWei}{y}[$i],
            symbol     => "r3200",
            polarity   => 'negative',
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addPanelOutNewShiZiJia
#功能		:添加panel-out 十字架
#参数		:无
#返回值		:1
#使用例子	:$self->addPanelOutNewShiZiJia();
#**********************************************
sub addPanelOutNewShiZiJia {
    my $self = shift;

    if ( $self->{hdi}{jobType} ne "b" ) {

        #return 0;
    }

    #计算symbol
    $self->CountPanelOutNewShiZiJia();

    #添加
    foreach my $i ( 0 .. $#{ $self->{panelOutNewShiZiJia}{symbol} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{panelOutNewShiZiJia}{x},
            y          => $self->{panelOutNewShiZiJia}{y},
            symbol     => $self->{panelOutNewShiZiJia}{symbol}[$i],
            polarity   => 'positive',
            angle      => '0',
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:addPanelOutNewLine
#功能		:添加防焊全自动
#参数		:无
#返回值		:1
#使用例子	:$self->addPanelOutNewLine();
#**********************************************
sub addPanelOutNewLine {
    my $self = shift;

    #计算symbol
    $self->CountPanelOutNewLine();

    #添加
    $self->COM('add_polyline_strt');
    $self->COM(
        'add_polyline_xy',
        x => $self->{panelOutNewLine}{x}[0],
        y => $self->{panelOutNewLine}{y}[0]
    );
    $self->COM(
        'add_polyline_xy',
        x => $self->{panelOutNewLine}{x}[1],
        y => "$self->{panelOutNewLine}{y}[0]"
    );
    $self->COM(
        'add_polyline_xy',
        x => $self->{panelOutNewLine}{x}[1],
        y => $self->{panelOutNewLine}{y}[1]
    );
    $self->COM(
        'add_polyline_xy',
        x => $self->{panelOutNewLine}{x}[0],
        y => $self->{panelOutNewLine}{y}[1]
    );
    $self->COM(
        'add_polyline_xy',
        x => $self->{panelOutNewLine}{x}[0],
        y => $self->{panelOutNewLine}{y}[0]
    );
    $self->COM(
        'add_polyline_end',
        attributes    => 'no',
        symbol        => 'r254',
        polarity      => 'positive',
        bus_num_lines => 1,
        bus_dist_by   => 'pitch',
        bus_distance  => 0,
        bus_reference => 'right'
    );

    return 1;
}

#**********************************************
#名字		:addPanelOutSdLine
#功能		:添加防焊全自动
#参数		:无
#返回值		:1
#使用例子	:$self->addPanelOutSdLine();
#**********************************************
sub addPanelOutSdLine {
    my $self = shift;

    #计算symbol
    $self->CountPanelOutSdLine();

    #添加
    $self->COM('add_polyline_strt');
    $self->COM(
        'add_polyline_xy',
        x => $self->{panelOutSdLine}{x}[0],
        y => $self->{panelOutSdLine}{y}[0]
    );
    $self->COM(
        'add_polyline_xy',
        x => $self->{panelOutSdLine}{x}[1],
        y => "$self->{panelOutSdLine}{y}[0]"
    );
    $self->COM(
        'add_polyline_xy',
        x => $self->{panelOutSdLine}{x}[1],
        y => $self->{panelOutSdLine}{y}[1]
    );
    $self->COM(
        'add_polyline_xy',
        x => $self->{panelOutSdLine}{x}[0],
        y => $self->{panelOutSdLine}{y}[1]
    );
    $self->COM(
        'add_polyline_xy',
        x => $self->{panelOutSdLine}{x}[0],
        y => $self->{panelOutSdLine}{y}[0]
    );
    $self->COM(
        'add_polyline_end',
        attributes    => 'no',
        symbol        => 'r254',
        polarity      => 'positive',
        bus_num_lines => 1,
        bus_dist_by   => 'pitch',
        bus_distance  => 0,
        bus_reference => 'right'
    );

    return 1;
}

#**********************************************
#名字		:addPanelBhSymbol
#功能		:添加panelBh顶层symbol
#参数		:无
#返回值		:1
#使用例子	:$self->addPanelBhSymbol();
#**********************************************
sub addPanelBhSymbol {
    my $self = shift;

    $self->CountPanelBhSymbol();
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{panelBh}{symbolX},
        y          => $self->{panelBh}{symbolY},
        symbol     => $self->{panelBh}{symbol},
        polarity   => 'positive',
        angle      => '0',
        mirror     => 'no',
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    return 1;
}

#**********************************************
#名字		:addPanelBhRetc
#功能		:添加巴赫矩形
#参数		:无
#返回值		:1
#使用例子	:$self->addPanelBhRetc();
#**********************************************
sub addPanelBhRect {
    my $self = shift;

    #计算
    $self->CountPanelBhRect();

    #添加
    foreach my $i ( 0 .. $#{ $self->{panelBh}{rect}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{panelBh}{rect}{x}[$i],
            y          => $self->{panelBh}{rect}{y}[$i],
            symbol     => $self->{panelBh}{rect}{symbol}[$i],
            polarity   => 'positive',
            angle      => '0',
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    return 1;
}

#**********************************************
#名字		:CreatePanelInPro
#功能		:挂载panel-in
#参数		:无
#返回值		:1
#使用例子	:$self->CreatePanelInProf();
#**********************************************
sub CreatePanelInProf {
    my $self = shift;

   #如果存在panel-in，打开，删除里面的,否则，产生，生成prof
    if ( $self->StepExists( $self->{panelInStep} ) ) {
        $self->OpenStep( $self->{panelInStep} );

        #清空所有
        $self->COM(
            'affected_layer',
            mode     => 'board',
            affected => 'yes'
        );
        $self->COM('sel_clear_feat');

        $self->COM('sel_delete');
        $self->SetUnits('mm');
    }
    else {
        $self->CreateStep("$self->{panelInStep}");
        $self->OpenStep( $self->{panelInStep} );

        #产生一个profile
        $self->COM(
            "profile_rect",
            x1 => 0,
            y1 => 0,
            x2 => 23,
            y2 => 26
        );

        $self->SetUnits('mm');
        $self->COM(
            "sr_tab_add",
            line => 1,
            step => $self->{panelStep},
            x    => 0,
            y    => 0,
            nx   => 1,
            ny   => 1
        );

        my $changX = ( 23 * 25.4 - $self->{PROF}{xmax} ) / 2;
        $self->COM(
            'sr_tab_change',
            line => 1,
            step => $self->{panelStep},
            x    => $changX,
            y    => 20.32,
            nx   => 1,
            ny   => 1
        );

        $self->COM('zoom_home');
    }

    return 1;
}

#**********************************************
#名字		:addPanelCbText
#功能		:添加panelCb 文字
#参数		:无
#返回值		:1
#使用例子	:$self->addPanelCbText();
#**********************************************
sub addPanelCbText {
    my $self = shift;

    #计算panel-in文字数据
    $self->CountPanelCbText();
    my $jobText = uc( $self->{Job} );

    #添加
    $self->COM(
        'add_text',
        attributes => 'no',
        type       => 'string',
        x          => "$self->{panelCb}{textX}",
        y          => "$self->{panelCb}{textY}",
        text       => "$jobText",
        x_size     => '10.16',
        y_size     => '10.16',
        w_factor   => 5,
        polarity   => 'positive',
        angle      => 270,
        mirror     => $self->{panelCb}{mirror},
        fontname   => 'simple',
        ver        => 0
    );

    return 1;
}

#**********************************************
#名字		:CreatePanelOutOldPro
#功能		:挂载panel-in
#参数		:无
#返回值		:1
#使用例子	:$self->CreatePanelOutOldProf();
#**********************************************
sub CreatePanelOutOldProf {
    my $self = shift;

   #如果存在panel-in，打开，删除里面的,否则，产生，生成prof
   #如果存在panel-in，打开，删除里面的,否则，产生，生成prof
    if ( $self->StepExists( $self->{panelOutOldStep} ) ) {
        $self->OpenStep( $self->{panelOutOldStep} );

        #清空所有
        $self->COM(
            'affected_layer',
            mode     => 'board',
            affected => 'yes'
        );
        $self->COM('sel_clear_feat');

        $self->COM('sel_delete');
        $self->ClearAll();
        $self->SetUnits('mm');
    }
    else {
        $self->CreateStep("$self->{panelOutOldStep}");
        $self->OpenStep( $self->{panelOutOldStep} );
        $self->SetUnits('mm');
        my $width     = 21.8 * 25.4;
        my $selfeight = 25.8 * 25.4;

        #产生一个profile
        $self->COM(
            'sr_auto',
            step           => 'panel',
            num_mode       => 'single',
            xmin           => 0,
            ymin           => 0,
            width          => $width,
            height         => $selfeight,
            panel_margin   => 0,
            step_margin    => 0,
            gold_plate     => 'no',
            orientation    => 'any',
            evaluate       => 'no',
            active_margins => 'yes',
            top_active     => 0,
            bottom_active  => 0,
            left_active    => 0,
            right_active   => 0,
            step_xy_margin => 'no',
            step_margin_x  => 0,
            step_margin_y  => 0
        );
        $self->COM(
            'set_attribute',
            type      => 'step',
            job       => $self->{Job},
            name1     => "$self->{panelOutOldStep}",
            name2     => '',
            name3     => '',
            attribute => '.pnl_class',
            value     => '',
            units     => 'inch'
        );
        $self->COM(
            'set_attribute',
            type      => 'step',
            job       => $self->{Job},
            name1     => $self->{panelOutOldStep},
            name2     => '',
            name3     => '',
            attribute => '.pnl_pcb',
            value     => $self->{panelStep},
            units     => 'inch'
        );
    }

    return 1;
}

#**********************************************
#名字		:CreatePanelOutNewPro
#功能		:挂载panel-in
#参数		:无
#返回值		:1
#使用例子	:$self->CreatePanelOutNewProf();
#**********************************************
sub CreatePanelOutNewProf {
    my $self = shift;

   #如果存在panel-in，打开，删除里面的,否则，产生，生成prof
   #如果存在panel-in，打开，删除里面的,否则，产生，生成prof
    if ( $self->StepExists( $self->{panelOutNewStep} ) ) {
        $self->OpenStep( $self->{panelOutNewStep} );

        #清空所有
        $self->COM(
            'affected_layer',
            mode     => 'board',
            affected => 'yes'
        );
        $self->COM('sel_clear_feat');

        $self->COM('sel_delete');
        $self->ClearAll();
        $self->SetUnits('mm');
    }
    else {
        $self->CreateStep("$self->{panelOutNewStep}");
        $self->OpenStep( $self->{panelOutNewStep} );
        $self->SetUnits('mm');
        my $width     = 23.8 * 25.4;
        my $selfeight = 27.8 * 25.4;

        #产生一个profile
        $self->COM(
            'sr_auto',
            step           => 'panel',
            num_mode       => 'single',
            xmin           => 0,
            ymin           => 0,
            width          => $width,
            height         => $selfeight,
            panel_margin   => 0,
            step_margin    => 0,
            gold_plate     => 'no',
            orientation    => 'any',
            evaluate       => 'no',
            active_margins => 'yes',
            top_active     => 0,
            bottom_active  => 0,
            left_active    => 0,
            right_active   => 0,
            step_xy_margin => 'no',
            step_margin_x  => 0,
            step_margin_y  => 0
        );
        $self->COM(
            'set_attribute',
            type      => 'step',
            job       => $self->{Job},
            name1     => "$self->{panelOutNewStep}",
            name2     => '',
            name3     => '',
            attribute => '.pnl_class',
            value     => '',
            units     => 'inch'
        );
        $self->COM(
            'set_attribute',
            type      => 'step',
            job       => $self->{Job},
            name1     => $self->{panelOutNewStep},
            name2     => '',
            name3     => '',
            attribute => '.pnl_pcb',
            value     => $self->{panelStep},
            units     => 'inch'
        );
    }

    return 1;
}

#**********************************************
#名字		:CreatePanelOutSdProf
#功能		:挂载panel-in
#参数		:无
#返回值		:1
#使用例子	:$self->CreatePanelOutSdProf();
#**********************************************
sub CreatePanelOutSdProf {
    my $self = shift;

#如果存在panel-out-sd，打开，删除里面的,否则，产生，生成prof
    if ( $self->StepExists( $self->{panelOutSdStep} ) ) {
        $self->OpenStep( $self->{panelOutSdStep} );

        #清空所有
        $self->COM(
            'affected_layer',
            mode     => 'board',
            affected => 'yes'
        );
        $self->COM('sel_clear_feat');

        $self->COM('sel_delete');
        $self->SetUnits('mm');
    }
    else {
        $self->CreateStep("$self->{panelOutSdStep}");
        $self->OpenStep( $self->{panelOutSdStep} );

        #产生一个profile
        $self->COM(
            "profile_rect",
            x1 => 0,
            y1 => 0,
            x2 => 23.8,
            y2 => 27.8
        );

        $self->SetUnits('mm');
        $self->COM(
            "sr_tab_add",
            line => 1,
            step => $self->{panelStep},
            x    => 0,
            y    => 0,
            nx   => 1,
            ny   => 1
        );

        #孔到profile距离32.4
        my $changX = 32.4 - $self->{fangHanBanZiDong}{x}[0];
        $self->COM(
            'sr_tab_change',
            line => 1,
            step => $self->{panelStep},
            x    => $changX,
            y    => 42.81,
            nx   => 1,
            ny   => 1
        );

        $self->COM('zoom_home');
    }

    return 1;
}

#**********************************************
#名字		:CreatePanelCbProf
#功能		:建立值圣川宝prof
#参数		:无
#返回值		:1
#使用例子	:$self->CreatePanelCbProf();
#**********************************************
sub CreatePanelCbProf {
    my $self = shift;

   #如果存在panel-in，打开，删除里面的,否则，产生，生成prof
   #如果存在panel-in，打开，删除里面的,否则，产生，生成prof
    if ( $self->StepExists( $self->{panelCbStep} ) ) {
        $self->OpenStep( $self->{panelCbStep} );

        #清空所有
        $self->COM(
            'affected_layer',
            mode     => 'board',
            affected => 'yes'
        );
        $self->COM('sel_clear_feat');

        $self->COM('sel_delete');
        $self->ClearAll();
        $self->SetUnits('mm');
    }
    else {
        $self->CreateStep("$self->{panelCbStep}");
        $self->OpenStep( $self->{panelCbStep} );
        $self->SetUnits('mm');
        my $width     = 604.52;
        my $selfeight = 706.12;

        #产生一个profile
        $self->COM(
            'sr_auto',
            step           => 'panel',
            num_mode       => 'single',
            xmin           => 0,
            ymin           => 0,
            width          => $width,
            height         => $selfeight,
            panel_margin   => 0,
            step_margin    => 0,
            gold_plate     => 'no',
            orientation    => 'any',
            evaluate       => 'no',
            active_margins => 'yes',
            top_active     => 0,
            bottom_active  => 0,
            left_active    => 0,
            right_active   => 0,
            step_xy_margin => 'no',
            step_margin_x  => 0,
            step_margin_y  => 0
        );

        $self->COM(
            'set_attribute',
            type      => 'step',
            job       => $self->{Job},
            name1     => "$self->{panelCbStep}",
            name2     => '',
            name3     => '',
            attribute => '.pnl_class',
            value     => '',
            units     => 'inch'
        );
        $self->COM(
            'set_attribute',
            type      => 'step',
            job       => $self->{Job},
            name1     => $self->{panelCbStep},
            name2     => '',
            name3     => '',
            attribute => '.pnl_pcb',
            value     => $self->{panelStep},
            units     => 'inch'
        );
    }

    $self->COM(
        'sredit_pack_steps',
        mode        => 'left',
        hgap        => 5.08,
        vgap        => 5.08,
        pos         => 25,
        pos2        => 0,
        overlap_tol => 0.0000375
    );

    return 1;
}

#**********************************************
#名字		:CreatePanelBhProf
#功能		:建立值圣川宝prof
#参数		:无
#返回值		:1
#使用例子	:$self->CreatePanelBhProf();
#**********************************************
sub CreatePanelBhProf {
    my $self = shift;

   #如果存在panel-in，打开，删除里面的,否则，产生，生成prof
   #如果存在panel-in，打开，删除里面的,否则，产生，生成prof
    if ( $self->StepExists( $self->{panelBhStep} ) ) {
        $self->OpenStep( $self->{panelBhStep} );

        #清空所有
        $self->COM(
            'affected_layer',
            mode     => 'board',
            affected => 'yes'
        );
        $self->COM('sel_clear_feat');

        $self->COM('sel_delete');
        $self->ClearAll();
        $self->SetUnits('mm');
    }
    else {
        $self->CreateStep("$self->{panelBhStep}");
        $self->OpenStep( $self->{panelBhStep} );
        $self->SetUnits('mm');
        my $width     = 604.52;
        my $selfeight = 706.12;

        #产生一个profile
        $self->COM(
            'sr_auto',
            step           => 'panel',
            num_mode       => 'single',
            xmin           => 0,
            ymin           => 0,
            width          => $width,
            height         => $selfeight,
            panel_margin   => 0,
            step_margin    => 0,
            gold_plate     => 'no',
            orientation    => 'any',
            evaluate       => 'no',
            active_margins => 'yes',
            top_active     => 0,
            bottom_active  => 0,
            left_active    => 0,
            right_active   => 0,
            step_xy_margin => 'no',
            step_margin_x  => 0,
            step_margin_y  => 0
        );
        $self->COM(
            'set_attribute',
            type      => 'step',
            job       => $self->{Job},
            name1     => "$self->{panelBhStep}",
            name2     => '',
            name3     => '',
            attribute => '.pnl_class',
            value     => '',
            units     => 'inch'
        );
        $self->COM(
            'set_attribute',
            type      => 'step',
            job       => $self->{Job},
            name1     => $self->{panelBhStep},
            name2     => '',
            name3     => '',
            attribute => '.pnl_pcb',
            value     => $self->{panelStep},
            units     => 'inch'
        );
    }

    return 1;
}

#**********************************************
#名字		:AddInnerSymbol
#功能		:为内层添加symbol
#参数		:无
#返回值		:1
#使用例子	:$self->AddInnerSymbol();
#**********************************************
sub AddInnerSymbol {
    my $self = shift;
    $self->addBoardLine();
    $self->addLiuJiao();
    $self->addScreenHole();
    $self->addyymmddSymbol();
    $self->addErCiYuan();
    $self->addHuaWeiLayerDuiwei();
    $self->addLayerMarki();
    $self->addJobInfo();
    $self->addDaba();
    $self->addCCD();
    $self->addLaserBiaoJi();
    $self->addLaserBYBiaoJi();
    $self->addLaser();
    $self->addCCDBY();
    $self->addTongXinYuan();
    $self->addDabaBY();
    $self->addBaKongJianTou;
    $self->addLaserBY();
    $self->addPEChongKong();
    $self->addRongHeKuaiNew();

    #$self->addMaoDing();
    #$self->addRongHeKuai();
    #$self->addYingFeiRongHeKuai();
    $self->addRongHeDingWeiPad();
    $self->addRongHeDingWei();
    $self->addFilmId();
    #$self->addRongHeDingWeiBy();
    $self->addJingWei();
    $self->addXYScale();
    $self->addFangCuoBa();
    $self->addTongQiePianTop();
    $self->addTongQiePianRight();
    $self->addBuryQiePian();
    $self->addLaserCeShi();
    $self->addHWSymbol();
    $self->addTongPianKongDuiWei1();
    $self->addBuryPianKongDuiWei();
    $self->addTongPianKongDuiWei2();
    $self->addLaserPianKongDuiWei();
    $self->addJsSymbol();
    $self->AddInnerErciyuan();
    #$self->addFdjt();
    $self->addFilmTime();
    $self->addBaoGuangCiShu();
    $self->addLayerDuiWei();
    $self->AddNewTongXinYuan();
    $self->AddTwoPinTongXinYuan();
    #$self->AddSpaceAndCopperThick();

    return 1;
}

#**********************************************
#名字		:AddSecondSymbol
#功能		:添加次外层symbol
#参数		:无
#返回值		:1
#使用例子	:$self->AddSecondSymbol();
#**********************************************
sub AddSecondSymbol {
    my $self = shift;

    $self->addBoardLine();
    $self->addLiuJiao();
    $self->addScreenHole();
    $self->addOutMark();
    $self->addErCiYuan();
    $self->addHuaWeiLayerDuiwei();
    $self->addBigSurface();
    $self->addLayerMarki();
    $self->addDaba();
    $self->addCCD();
    $self->addLaserBiaoJi();
    $self->addLaserBYBiaoJi();
    $self->addLaser();
    $self->addCCDBY();
    $self->addTongXinYuan();
    $self->addDabaBY();
    $self->addLaserBY();
    $self->addBaKongJianTou;
    $self->addJobInfo();
    $self->addFilmId();
    $self->addJingWei();
    $self->addXYScale();
    $self->addTongQiePianTop();
    $self->addTongQiePianRight();
    $self->addBuryQiePian();
    $self->addLaserQiePian();
    $self->addLaserCeShi();
    $self->addHWSymbol();
    $self->addTongPianKongDuiWei1();
    $self->addMangKongDuiWei;
    $self->addBuryPianKongDuiWei();
    $self->addTongPianKongDuiWei2();
    $self->addLaserPianKongDuiWei();
    $self->addJsSymbol();

    #$self->addFdjt();
    $self->addXiaoYe();
    $self->addFilmTime();
    $self->addBaoGuangCiShu();

    return 1;
}

#**********************************************
#名字		:AddOuterSymbol
#功能		:添加外层symbol
#参数		:无
#返回值		:1
#使用例子	:$self->AddOuterSymbol();
#**********************************************
sub AddOuterSymbol {
    my $self = shift;

    $self->fillZhengPianCu();
    $self->addBoardLine();
    $self->addScreenHole();
    $self->addyymmddSymbol();
    $self->addOutMark();
    $self->addErCiYuan();
    $self->addHuaWeiLayerDuiwei();
    #$self->add3Rect();
    $self->addLayerMarki();
    $self->addDaba();    #多层板物件
    $self->addCCD();
    $self->addLaser();
    $self->addCCDBY();
    $self->addTongXinYuan();
    $self->addDabaBY();
    $self->addLaserBY();
    $self->addJobInfo();
    $self->addFilmId();
    $self->addJingWei();
    $self->addXYScale();
    $self->addTongQiePianTop();
    $self->addTongQiePianRight();
    $self->addBuryQiePian();
    $self->addLaserQiePian();
    $self->addLaserCeShi();
    $self->addFangHanCCD();
    $self->addFangHanCCDBY();
    $self->addMangKongDuiWei;
    $self->addCustomerCode();
    $self->addHWSymbol();
    $self->addAuthSymbol();
    $self->addTongPianKongDuiWei1();
    $self->addTongPianKongDuiWei2();
    $self->addLaserPianKongDuiWei();
    $self->addSuanJian();
    $self->addCuArea();
    $self->addJsSymbol();

    #$self->addFdjt();
    $self->addLayerDuiWei();
    $self->addXiaoYe();
    $self->addZhengPianNum();
    $self->addFilmTime();
    #$self->addPenQiGuaKong();
    $self->addWenZiPenMo();
    $self->addBaoGuangCiShu();
    $self->addWeek();
    $self->addLuoBanDingWei();
    $self->addRongHeDingWei();
    $self->addFilmSizeTestPad()
      ;    #新增 长尺寸菲林尺寸测试pad。wxl 2017.02.16

    return 1;
}

#**********************************************
#名字		:AddSolderMaskSymbol
#功能		:添加防焊symbol
#参数		:无
#返回值		:1
#使用例子	:$self->AddSolderMaskSymbol();
#**********************************************
sub AddSolderMaskSymbol {
    my $self = shift;
    $self->AddTmpOpen();    #添加tmp层窗口的开窗 WXL 20170317
    $self->addBoardLine();
    $self->addScreenHole();
    $self->addErCiYuan();
    $self->addHuaWeiLayerDuiwei();
    $self->addCCDDrill();
    $self->addWenZiPenMo();
    $self->addLuoBanDingWei();
    $self->addyymmddSymbol();

    #$self->addFangHanBanZiDong();
    #$self->addFangHanBanZiDongNew();
    $self->addJobInfo();
    $self->addFilmId();

    #$self->addJingWei();
    $self->addXYScale();
    $self->addTongQiePianTop();
    $self->addTongQiePianRight();
    $self->addLaserQiePian();
    $self->addLaserCeShi();
    $self->addFangHanCCD();
    $self->addFangHanCCDBY();
    $self->addHWSymbol();
    $self->addAuthSymbol();
    $self->addJsSymbol();

    #$self->addFdjt();
    #$self->addXiaoYe();
    $self->addFilmTime();
    $self->addBaoGuangCiShu();
    $self->addWeek();
    $self->addLayerDuiWei();
    $self->addFilmSizeTestOpen()
      ;    #新增 长尺寸菲林尺寸测试pad开窗。wxl 2017.02.17
    return 1;
}

#**********************************************
#名字		:AddSilkScreenSymbol
#功能		:添加文字
#参数		:无
#返回值		:1
#使用例子	:$self->AddSilkScreenSymbol();
#**********************************************
sub AddSilkScreenSymbol {
    my $self = shift;

    $self->addSilkBoardLine();
    $self->addScreenHole();
    $self->addWenZiPenMo();
    $self->addJobInfo();

    #$self->addFilmId();
    $self->addHWSymbol();

    #$self->addXYScale();
    $self->addWeek();
    $self->addDateCodeSymbol();
    $self->addSilkNum();
    $self->addSilkCSText();

    #$self->addDabaGaiYou();
    #$self->addOutMark();
    $self->addJingWei();

    return 1;
}

#**********************************************
#名字		:AddSolderPaste
#功能		:添加选化
#参数		:无
#返回值		:1
#使用例子	:$self->AddSolderPaste();
#**********************************************
sub AddSolderPaste {
    my $self = shift;

    $self->addBoardLine();
    $self->addScreenHole();
    $self->addWenZiPenMo();
    $self->addJobInfo();

    #$self->addFilmId();
    $self->addHWSymbol();
    $self->addXYScale();
    $self->addWeek();
    $self->addSilkNum();

    #$self->addDabaGaiYou();
    #$self->addOutMark();
    $self->addJingWei();
    $self->addSilkCSText();

    #普通网SR边界外3mm
    $self->addDotCopper();

    return 1;
}

#**********************************************
#名字		:addDotCopper
#功能		:挡点菲林铺铜
#参数		:无
#返回值		:1
#使用例子	:$self->addDotCopper();
#**********************************************
sub addDotCopper {
    my $self = shift;
    if ( $self->{Layer} !~ /dot/ ) {
        return;
    }
    $self->COM(
        "fill_params",
        type           => "solid",
        origin_type    => "datum",
        solid_type     => "surface",
        std_type       => "line",
        min_brush      => "25.4",
        use_arcs       => "yes",
        symbol         => "s1000",
        dx             => "1.5",
        dy             => "1.5",
        x_off          => "0",
        y_off          => "0",
        std_angle      => "45",
        std_line_width => "254",
        std_step_dist  => "1270",
        std_indent     => "odd",
        break_partial  => "yes",
        cut_prims      => "no",
        outline_draw   => "no",
        outline_width  => "0",
        outline_invert => "no"
    );
    $self->COM(
        "sr_fill",
        polarity        => "positive",
        step_margin_x   => "0",
        step_margin_y   => "0",
        step_max_dist_x => "1000",
        step_max_dist_y => "1000",
        sr_margin_x     => "0",
        sr_margin_y     => "0",
        sr_max_dist_x   => "3",
        sr_max_dist_y   => "3",
        nest_sr         => "no",
        consider_feat   => "yes",
        feat_margin     => "1",
        consider_drill  => "no",
        consider_rout   => "no",
        dest            => "affected_layers",
        attributes      => "no"
    );
}

#**********************************************
#名字		:addBurySymbol
#功能		:添加埋孔symbol
#参数		:无
#返回值		:1
#使用例子	:$self->addBurySymbol();
#**********************************************
sub AddBurySymbol {
    my $self = shift;

    $self->addScreenHole();
    $self->addCCDDrill();
    $self->addRongHeDingWei();
    $self->addBuryQiePian();
    $self->addBuryPianKongDuiWei();

    return 1;
}

#**********************************************
#名字		:AddLaserSymbol
#功能		:添加镭射
#参数		:无
#返回值		:1
#使用例子	:$self->AddLaserSymbol();
#**********************************************
sub AddLaserSymbol {
    my $self = shift;

    $self->addLaserQiePian();
    $self->addLaserPianKongDuiWei();
    $self->addLaserCeShi();
    $self->addLaser();
    $self->addMangKongDuiWei();

    return 1;
}

#**********************************************
#名字		:AddViaSymbol
#功能		:添加通孔symbol
#参数		:无
#返回值		:1
#使用例子	:$self->AddViaSymbol();
#**********************************************
sub AddViaSymbol {
    my $self = shift;

    $self->addScreenHole();
    $self->addJiaoKong();
    $self->addTongQiePianRight();
    $self->addTongQiePianTop();
    $self->addLuoBanDingWei();
    $self->addCCDDrill();
    $self->addHuaWeiLayerDuiwei();
    #$self->addFangHanBanZiDong();
    #$self->addFangHanBanZiDongNew();
    $self->addPenQiGuaKong();

    #$self->addMaoDing();
    $self->addRongHeDingWei();
    $self->addYingFeiRongHeKuaiDrill();
    $self->addMaoDingYingFeiDrill();
    $self->addRongHeDingWeiPadYingFeiDrill();
    $self->addTongPianKongDuiWei1();
    $self->addTongPianKongDuiWei2();
    $self->addWenZiPenMo();
    $self->addLayerDuiWei();
    $self->AddTwoPinTongXinYuan();

	#无铅喷锡
	if ($self->{Job} =~ /\w{4}l/i) {
		$self->addSanRe();
	}

	#有铅喷锡
	if ($self->{Job} =~ /\w{4}p/i) {
		#融合快旁边防爆孔
		$self->addRongHeKuaiNew();
		#铆钉防爆孔
		$self->addRongHeDingWeiFangBao();
	}

    return 1;
}

#**********************************************
#名字		:AddLoubBian
#功能		:添加锣边
#参数		:无
#返回值		:1
#使用例子	:$self->AddLoubBian();
#**********************************************
sub AddLoubBian {
    my $self = shift;
    $self->addLoubLine();
    return 1;
}

#**********************************************
#名字		:AddTmpBox
#功能		:在tmp层加一个的框
#参数		:无
#返回值		:1
#使用例子	:$self->AddTmpBox();
#**********************************************
sub AddTmpBox {
    my $self = shift;

    $self->COM( "filter_reset", filter_name => "popup" );
    $self->COM(
        "filter_set",
        filter_name  => "popup",
        update_popup => "no",
        feat_types   => "line"
    );
    $self->COM(
        "filter_set",
        filter_name  => "popup",
        update_popup => "no",
        include_syms => "r254"
    );
    $self->COM("filter_area_strt");
    $self->COM(
        "filter_area_end",
        layer          => "",
        filter_name    => "popup",
        operation      => "select",
        area_type      => "none",
        inside_area    => "no",
        intersect_area => "no"
    );
    $self->COM( "filter_reset", filter_name => "popup" );
    $self->COM("get_select_count");

    if ( $self->{COMANS} > 0 ) {
        $self->COM("sel_delete");
    }

    #tmp层加一个7x50mm的框 1
    $self->COM("add_polyline_strt");
    $self->COM(
        "add_polyline_xy",
        x => $self->{liuBian}{xmin} - 2,
        y => $self->{liuBian}{ymin} + 115
    );
    $self->COM(
        "add_polyline_xy",
        x => $self->{liuBian}{xmin} - 2,
        y => $self->{liuBian}{ymin} + 115 + 80
    );
    $self->COM(
        "add_polyline_xy",
        x => $self->{SR}{xmin} - 1,
        y => $self->{liuBian}{ymin} + 115 + 80
    );
    $self->COM(
        "add_polyline_xy",
        x => $self->{SR}{xmin} - 1,
        y => $self->{liuBian}{ymin} + 115
    );
    $self->COM(
        "add_polyline_xy",
        x => $self->{liuBian}{xmin} - 2,
        y => $self->{liuBian}{ymin} + 115
    );
    $self->COM(
        "add_polyline_end",
        attributes => "no",
        symbol     => "r254",
        polarity   => "positive"
    );

    #tmp层加一个7x50mm的框 2
    $self->COM("add_polyline_strt");
    $self->COM(
        "add_polyline_xy",
        x => $self->{liuBian}{xmin} + 2,
        y => $self->{liuBian}{ymin} + 130
    );
    $self->COM(
        "add_polyline_xy",
        x => $self->{liuBian}{xmin} + 2,
        y => $self->{liuBian}{ymin} + 130 + 50
    );
    $self->COM(
        "add_polyline_xy",
        x => $self->{liuBian}{xmin} + 2 + 5,
        y => $self->{liuBian}{ymin} + 130 + 50
    );
    $self->COM(
        "add_polyline_xy",
        x => $self->{liuBian}{xmin} + 2 + 5,
        y => $self->{liuBian}{ymin} + 130
    );
    $self->COM(
        "add_polyline_xy",
        x => $self->{liuBian}{xmin} + 2,
        y => $self->{liuBian}{ymin} + 130
    );
    $self->COM(
        "add_polyline_end",
        attributes => "no",
        symbol     => "r254",
        polarity   => "positive"
    );
}

#**********************************************
#名字		:AddTmpOpen
#功能		:在防焊层加一个tmp层窗口的开窗（surface 同tmp层框的坐标）
#参数		:无
#返回值		:1
#使用例子	:$self->AddTmpOpen();
#**********************************************
sub AddTmpOpen {
    my $self = shift;

    $self->COM(
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
    $self->COM( 'add_surf_strt', surf_type => 'feature' );
    $self->COM(
        'add_surf_poly_strt',
        x => $self->{liuBian}{xmin} - 2,
        y => $self->{liuBian}{ymin} + 115
    );
    $self->COM(
        'add_surf_poly_seg',
        x => $self->{liuBian}{xmin} - 2,
        y => $self->{liuBian}{ymin} + 115 + 80
    );
    $self->COM(
        'add_surf_poly_seg',
        x => $self->{SR}{xmin} - 1,
        y => $self->{liuBian}{ymin} + 115 + 80
    );
    $self->COM(
        'add_surf_poly_seg',
        x => $self->{SR}{xmin} - 1,
        y => $self->{liuBian}{ymin} + 115
    );
    $self->COM(
        'add_surf_poly_seg',
        x => $self->{liuBian}{xmin} - 2,
        y => $self->{liuBian}{ymin} + 115
    );
    $self->COM('add_surf_poly_end');
    $self->COM( 'add_surf_end', attributes => 'no', polarity => 'positive' );
    return 1;
}

#**********************************************
#名字		:AddPanelInSymbol
#功能		:添加panel-in
#参数		:无
#返回值		:1
#使用例子	:$self->AddPanelInSymbol();
#**********************************************
sub AddPanelInSymbol {
    my $self = shift;

    #添加panel-insymbol
    $self->addPanelInSymbol();
    $self->addPanelInText();

    return 1;
}

#**********************************************
#名字		:AddPanelOutOldSymbol
#功能		:添加panelOutOld
#参数		:无
#返回值		:1
#使用例子	:$self->AddPanelOutOldSymbol();
#**********************************************
sub AddPanelOutOldSymbol {
    my $self = shift;

    $self->addPanelOutOldLine();
    $self->addPanelOutOldShiZiJia();

    return 1;
}

#**********************************************
#名字		:AddPanelOutNewSymbol
#功能		:添加panelOutNew
#参数		:无
#返回值		:1
#使用例子	:$self->AddPanelOutNewSymbol();
#**********************************************
sub AddPanelOutNewSymbol {
    my $self = shift;

    $self->addPanelOutNewLine();
    $self->addPanelOutNewShiZiJia();

    return 1;
}

#**********************************************
#名字		:AddPanelOutSdSymbol
#功能		:添加panelOutNew
#参数		:无
#返回值		:1
#使用例子	:$self->AddPanelOutSdSymbol();
#**********************************************
sub AddPanelOutSdSymbol {
    my $self = shift;

    $self->addPanelOutSdLine();
    $self->addBzdSymbol();

    return 1;
}

#**********************************************
#名字		:AddPanelCbSymbol
#功能		:添加至圣川宝symbol
#参数		:无
#返回值		:1
#使用例子	:$self->AddPanelCbSymbol();
#**********************************************
sub AddPanelCbSymbol {
    my $self = shift;

    $self->addPanelCbSymbol();
    $self->addPanelCbText();

    return 1;
}

#**********************************************
#名字		:AddPanelBhSymbol
#功能		:添加至圣川宝symbol
#参数		:无
#返回值		:1
#使用例子	:$self->AddPanelBhSymbol();
#**********************************************
sub AddPanelBhSymbol {
    my $self = shift;

    $self->addPanelBhSymbol();
    $self->addPanelBhText();
    $self->addPanelBhRect();

    return 1;
}

sub AddSpaceAndCopperThick {
    my $self = shift;

    $self->GetInnerCopperThick();
    $self->CountSpaceAndCopperThick();

    #添加 symbol
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{scSymbol}{x},
        y          => $self->{scSymbol}{y},
        symbol     => 'space_and_thick',
        polarity   => $self->{scSymbol}{polarity},
        angle      => 0,
        mirror     => $self->{scSymbol}{mirror},
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    #添加字
    $self->COM(
        "add_text",
        attributes => "no",
        type       => "string",
        x          => $self->{scSymbol}{x1},
        y          => $self->{scSymbol}{y1},
        text       => "xxx",
        x_size     => "2",
        y_size     => "2.5",
        w_factor   => "0.82020998",
        polarity   => $self->{scSymbol}{polarity},
        angle      => "0",
        mirror     => $self->{scSymbol}{mirror},
        fontname   => "simple",
        ver        => "0"
    );

    if ( defined( $self->{ $self->{Layer} }{copperThick} )
        && $self->{ $self->{Layer} }{copperThick} ne "" )
    {
        #添加字
        #		$sielf->COM(
        #			"add_text",
        #			attributes => "no",
        #			type       => "string",
        #			x          => $self->{scSymbol}{x2},
        #			y          => $self->{scSymbol}{y2},
        #			text       => $self->{$self->{Layer}}{copperThick},
        #			x_size     => "2",
        #			y_size     => "2.5",
        #			w_factor   => "0.82020998",
        #			polarity   => $self->{scSymbol}{polarity},
        #			angle      => "0",
        #			mirror     => $self->{scSymbol}{mirror},
        #			fontname   => "simple",
        #			ver        => "0"
        #		);
        $self->COM(
            "add_text",
            attributes => "no",
            type       => "string",
            x          => $self->{scSymbol}{x2},
            y          => $self->{scSymbol}{y2},
            text       => "xxx",
            x_size     => "2",
            y_size     => "2.5",
            w_factor   => "0.82020998",
            polarity   => $self->{scSymbol}{polarity},
            angle      => "0",
            mirror     => $self->{scSymbol}{mirror},
            fontname   => "simple",
            ver        => "0"
        );
    }
}

sub GetInnerCopperThick {
    my $self = shift;
    my $list = $self->GetAllCoreCopperThick( $self->{Job} );
    if ($list) {
        foreach my $line ( @{$list} ) {
            my $core   = $line->[0];
            my @copper = split(/\//,$line->[1]);

            if ( $self->{signalLayer}{num} == 4
                && lc($core) eq lc( $self->{Job} ) )
            {
                $core = $core . ".IN23";
            }
            my @tmp = split( /\./, $core, 2 );
            my $temp = $tmp[1];
            $temp =~ s/\D//g;
            $temp = $temp * 1;
            my $number1 = "0";
            my $number2 = "0";
            if ( length($temp) <= 3 ) {
                $number1 = substr( $temp, 0, 1 );
                $number2 = substr( $temp, 1 );
            }
            else {
                $number1 = substr( $temp, 0, 2 );
                $number2 = substr( $temp, 2 );
            }

            foreach my $layer ( @{ $self->{inner}{layer} } ) {
                my $tmp1 = $layer;
                $tmp1 =~ s/\D//g;
                if ( $tmp1 eq $number1 ) {
                    $self->{$layer}{copperThick} = $copper[0];
                }
                elsif ($tmp1 eq $number2)
                {
                    $self->{$layer}{copperThick} = $copper[1];
                }
            }
        }
    }
}

#**********************************************
#名字		:addFilmSizeTestPad
#功能		:单双面板，Y方向尺寸大于622.5mm的，新增加一类菲林尺寸测试。
#在Y方向增加6个symbol用于测试长菲林尺寸，原有的二次元symbol因为菲林Y方向太长，二次元无法测试。
#2017.02.16
#参数		:无
#返回值		:1
#使用例子	:$self->addFilmSizeTestPad();
#**********************************************
sub addFilmSizeTestPad {
    my $self = shift;

    #条件
    if ( $self->{signalLayer}{num} > 2 or $self->{PROF}{ymax} <= 622.5 ) {
        return 1;
    }

    #计算数据
    $self->CountFilmSizeTestPad();

    #添加 symbol
    foreach my $i ( 0 .. $#{ $self->{FilmSizeTestPad}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{FilmSizeTestPad}{x}[$i],
            y          => $self->{FilmSizeTestPad}{y}[$i],
            symbol     => $self->{FilmSizeTestPad}{symbol},
            polarity   => 'positive',
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }

    #添加文字 1 2 3
    foreach my $i ( 0 .. $#{ $self->{FilmSizeText}{x} } ) {
        my $num = $i + 1;
        if ( $num <= 3 ) {
            $self->{FilmSizeText}{symbol} = $num;
        }
        else {
            $self->{FilmSizeText}{symbol} = $num - 3;
        }
        $self->COM(
            "add_text",
            attributes => "no",
            type       => "string",
            x          => $self->{FilmSizeText}{x}[$i],
            y          => $self->{FilmSizeText}{y}[$i],
            text       => $self->{FilmSizeText}{symbol},
            x_size     => "1.0",
            y_size     => "1.0",
            w_factor   => "0.6",
            polarity   => 'positive',
            angle      => "0",
            mirror     => 'no',
            fontname   => "standard",
            ver        => "0"
        );
    }

    #添加尺寸文字衬底
    $self->COM(
        'add_pad',
        attributes => 'no',
        x          => $self->{FilmSizeCD}{x},
        y          => $self->{FilmSizeCD}{y},
        symbol     => 'rect40000x3000',
        polarity   => 'negative',
        angle      => 0,
        mirror     => 'no',
        nx         => 1,
        ny         => 1,
        dx         => 0,
        dy         => 0,
        xscale     => 1,
        yscale     => 1
    );

    #添加尺寸内容
    $self->COM(
        "add_text",
        attributes => "no",
        type       => "string",
        x          => $self->{FilmSizeCD}{textx},
        y          => $self->{FilmSizeCD}{texty},
        text       => $self->{FilmSizeCD}{text},
        x_size     => "1.0",
        y_size     => "1.0",
        w_factor   => "0.6",
        polarity   => 'positive',
        angle      => "0",
        mirror     => 'no',
        fontname   => "standard",
        ver        => "0"
    );

}

#**********************************************
#名字		:addFilmSizeTestOpen
#功能		:单双面板，Y方向尺寸大于622.5mm的，新增加一类菲林尺寸测试。
#在Y方向增加6个symbol用于测试长菲林尺寸，原有的二次元symbol因为菲林Y方向太长，二次元无法测试。
#2017.02.16
#参数		:无
#返回值		:1
#使用例子	:$self->addFilmSizeTestOpen();
#**********************************************
sub addFilmSizeTestOpen {
    my $self = shift;

    #条件
    if ( $self->{signalLayer}{num} > 2 or $self->{PROF}{ymax} <= 622.5 ) {
        return 1;
    }

    #计算数据
    $self->CountFilmSizeTestPad();

    #添加 symbol
    foreach my $i ( 0 .. $#{ $self->{FilmSizeTestPad}{x} } ) {
        $self->COM(
            'add_pad',
            attributes => 'no',
            x          => $self->{FilmSizeTestPad}{x}[$i],
            y          => $self->{FilmSizeTestPad}{y}[$i],
            symbol     => 's4000',
            polarity   => 'positive',
            angle      => 0,
            mirror     => 'no',
            nx         => 1,
            ny         => 1,
            dx         => 0,
            dy         => 0,
            xscale     => 1,
            yscale     => 1
        );
    }
}
1;
__END__
