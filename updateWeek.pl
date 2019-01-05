#!/usr/bin/perl
#源码名称: outPutFilm
#功能描述: 自动输出菲林
#开发单位: 集团工程系统开发部

#导入模块
use strict;
use warnings;
use lib qw(/gen_db/odb2/.hc/lib);
use HC_NG;
use Data::Dumper;
use utf8;

#设置程式名称
my $appName = 'updateWeek';

#设置版本号
my $version = '1.0';

#初始化模块
my $h = HC_NG->new();

$h->readJoblistFile();
my $dbs = $h->readDblistFile();

my $data = $h->GetFilmWaitCheck();

unless ($data) {
	exit;
}

foreach my $row (@$data) {
		push @{$h->{jobName}} , Encode::decode_utf8($row->[0]{jobName_});
		push @{$h->{scaleX}} , Encode::decode_utf8($row->[0]{ScaleX_});
		push @{$h->{scaleY}} , Encode::decode_utf8($row->[0]{ScaleY_});
		push @{$h->{scaleXOrig}} , Encode::decode_utf8($row->[0]{FinishX_});
		push @{$h->{scaleYOrig}} , Encode::decode_utf8($row->[0]{FinishY_});
		push @{$h->{mirror}} , Encode::decode_utf8($row->[0]{Mir_});
		push @{$h->{Layer}} , Encode::decode_utf8($row->[0]{FilmLayer_});
		push @{$h->{machine}} , Encode::decode_utf8($row->[0]{Machine_});
		push @{$h->{Guid_}} , Encode::decode_utf8($row->[0]{TiaoMa_});
		push @{$h->{filmtype}} , Encode::decode_utf8($row->[0]{FilmType_});
		push @{$h->{tieMoX}}, Encode::decode_utf8($row->[0]{TieMoX_});
		push @{$h->{tieMoY}}, Encode::decode_utf8($row->[0]{TieMoY_});
		push @{$h->{filmMachine}} , Encode::decode_utf8($row->[0]{FilmMachine_});
		push @{$h->{polarity}}, Encode::decode_utf8($row->[0]{Polarity_});
		push @{$h->{size}}, Encode::decode_utf8($row->[0]{Size_});
		push @{$h->{applyWeek}}, Encode::decode_utf8($row->[0]{ApplyWeek});
		push @{$h->{Group}}, Encode::decode_utf8($row->[0]{group_});
		push @{$h->{GuidWeek_}} , Encode::decode_utf8($row->[0]{Guid_});
}

updateWeek();
updateChecker();

#**********************************************
#名字		:outputFilm
#功能		:输出菲林
#参数		:无
#返回值		:1
#使用例子	:$h->outputFilm();
#**********************************************
sub updateWeek {
	#获取当前料号需要绘片的所有层别
	my @lay = @{$h->{Layer}};
	
	my $do_lay = 0;

	while ($do_lay <= $#lay) {
		
		if ($lay[$do_lay] =~ /in.*/) {
			$do_lay++;
			next;
		}
		my $jobName  =  ${$h->{jobName}}[$do_lay];
		$h->{week4Apply}  =  ${$h->{applyWeek}}[$do_lay];
		$h->{weekGuid}  =  ${$h->{GuidWeek_}}[$do_lay];
		$h->{weekGroup}  =  ${$h->{Group}}[$do_lay];

		#如果当前层有周期。则把当前

		$h->{Job} = lc($jobName);
		my $jobTest = $h->{Job};
		$jobTest =~ s/(\D{3}\d\D\d{7}\D\d).*/$1/;
		$jobTest =~ s/(\D{2,3}\d{5,6}\D\d).*/$1/;
		$h->{weekSide} = undef;
		$h->{weekMode} = undef;
		$h->{weekLayer} = undef;

	   	$h->{weekMode4Job} = undef;
		$h->{week4Job} = undef;
		$h->GetErpWeekModeAndSide($jobTest);
		$h->{weekStatus} = 'ok';
		$h->{week}{value}{$lay[$do_lay]} =  "";
		#同组如果有NG了，就不再更新了，防止同一组有些ok，有些不ok。菲林房乱
		if (grep /^$h->{weekGroup}$/, @{$h->{weekNgGroup}}) {
			$do_lay ++;
			next;
		}

		if ($h->{weekMode} ne '') {
			if(
				($h->{weekLayer} eq "ss" and 
					(
						(($h->{weekSide} eq "top" or $h->{weekSide} eq "both") and $lay[$do_lay] eq "gto") or (($h->{weekSide} eq "bot" or $h->{weekSide} eq "both") and $lay[$do_lay] eq "gbo")
					)
				)
					or 
				($h->{weekLayer} eq 'sm' and 
					(
						(($h->{weekSide} eq "top" or $h->{weekSide} eq "both") and $lay[$do_lay] eq "gts") or (($h->{weekSide} eq "bot" or $h->{weekSide} eq "both") and $lay[$do_lay] eq "gbs")
					)
				)
					or
				($h->{weekLayer} eq 'outer' and 
					(
						(($h->{weekSide} eq "top" or $h->{weekSide} eq "both") and $lay[$do_lay] eq "gtl") or (($h->{weekSide} eq "bot" or $h->{weekSide} eq "both") and $lay[$do_lay] eq "gbl")
					)
				)
			) {
				#获取料号里面的周期和check status
				getJobWeekAndWeekMode();

				$h->{weekMode} = uc ($h->{weekMode});
				$h->{weekMode4Job} = uc ($h->{weekMode4Job});

				$h->{weekOk4Job} = $h->{week4Job};
				if ($h->{weekMode} eq 'WWYY') {
					$h->{week4Job} = substr ($h->{week4Job}, 0, 2);
				} else {
					$h->{week4Job} = substr ($h->{week4Job}, 2, 2);
				}


				if ($h->{weekMode} ne $h->{weekMode4Job} or $h->{week4Job} ne $h->{week4Apply}) {
					$h->{weekStatus} = "ng";
					push @{$h->{weekNgGroup}}, $h->{weekGroup};
				}

				#更新ERP周期格式，料号周期格式，料号周期，料号签名， 如果周期料号和erp对不上，同一组的设置为状态NG
				#$h->UpdateFilmStatus();
				$h->UpdateWeekStatus();
			}

		}


		$do_lay++;
	}

	return 1;
}


sub updateChecker {
	#获取当前料号需要绘片的所有层别
	my @lay = @{$h->{Layer}};
	
	my $do_lay = 0;

	while ($do_lay <= $#lay) {
		my $jobName  =  ${$h->{jobName}}[$do_lay];
		$h->{checkGuid}  =  ${$h->{GuidWeek_}}[$do_lay];
		$h->{checkGroup}  =  ${$h->{Group}}[$do_lay];

		#如果当前层有周期。则把当前

		$h->{Job} = lc($jobName);
		my $jobTest = $h->{Job};
		$jobTest =~ s/(\D{3}\d\D\d{7}\D\d).*/$1/;
		$jobTest =~ s/(\D{2,3}\d{5,6}\D\d).*/$1/;

		#获取签名
		#同组如果有ng，则不用再找。
		if (grep /^$h->{checkGroup}$/, @{$h->{checkStatusNg}}) {
			$do_lay ++;
			next;
		}

		#更新状态为ok
		getLayerCheck($lay[$do_lay]);

		if ( $h->{checkStatus} eq 'ng') {
			push @{$h->{checkStatusNg}}, $h->{checkGroup}; 
		}


		$h->UpdateCheckStatus();


		$do_lay++;
	}

}

sub getLayerCheck {
	my $layer = shift;

	my $path = $h->{Job} eq 'genesislib' ? $dbs->{$h->{JobList}{$h->{Job}}} . '/lib/' : $dbs->{$h->{JobList}{$h->{Job}}} . '/jobs/' . $h->{Job};
	my $attrPath = $path."/steps/panel/layers/$layer/attrlist";

	my @file = $h->ReadFile("$attrPath","no");
	#open FILE,"<",$matrixPath or die "can't open $matrixPath $!\n";
	my $i = 0;
	my $checkStatus;
	while ($#file > 0) {
		my $line = shift (@file);
		next if $line =~ /^$/;
		next if $line =~ /^\s*\#/;
		if  ($line =~ /^\.layer_check\s+\=/) {
			$checkStatus = lc((split(/\=/,$line))[1]);
			last;
		}
	}

	$h->{checkStatus} = 'ng';
	if ($checkStatus =~ /check/i) {
		$h->{checkStatus} = "ok";
	}
}

sub getJobWeekAndWeekMode {
	my $path = $h->{Job} eq 'genesislib' ? $dbs->{$h->{JobList}{$h->{Job}}} . '/lib/' : $dbs->{$h->{JobList}{$h->{Job}}} . '/jobs/' . $h->{Job};

	my $attrPath = $path."/misc/attrlist";
	my @file = $h->ReadFile("$attrPath","no");

	while ($#file >= 0) {
		my $line = shift (@file);
		next if $line =~ /^$/;
		next if $line =~ /^\s*\#/;
		chomp $line;
		if  ($line =~ /^week\s+\=/) {
			$h->{week4Job} = lc((split(/\=/,$line))[1]);
			$h->{week4Job} =~ s/\s//g;
		}

		if  ($line =~ /^mdate_code_wzdg\s+\=/) {
			$h->{weekMode4Job} = lc((split(/\=/,$line))[1]);
			$h->{weekMode4Job} =~ s/\s//g;
		}

	}

	return 1;
}


#**********************************************
#名字		:ChangeCodeText
#功能		:格式化写日志
#参数1      :为日志文件路径
#参数2      :为引用数组，每个引用有两个键值对，count代表宽度,value为值，最多26个值
#返回值		:1
#使用例子	:$h->ChangeCodeText();
#**********************************************

sub WriteLog {
 
}

__END__




