#!/usr/local/bin/perl
###################################################################################################################################
# check_trackign.pl 
#
###################################################################################################################################

##############################
# standard_modules_ref       #
##############################
use strict;
use lib "/opt/alDente/versions/beta/lib/perl/";
use CGI qw(:standard);
use Getopt::Std;
use Data::Dumper;
use alDente::Cron;

##############################
# custom_modules_ref         #
##############################
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::DB_Object;
  
use SDB::Session;
use RGTools::RGIO;
use RGTools::Conversion;
use alDente::Container;
##############################
# global_vars                #
##############################
use vars qw($user_id $user);
use vars qw(%Settings $Connection $AUTOLOAD );
our ($opt_d,$opt_s,$opt_u,$opt_p,$opt_l,$opt_q,$opt_h,$opt_e);
getopts('d:s:u:p:l:q:h:e');
my $dbase;
my $host;
my $user;
my $pass;
my $lib;
my $prot;
my $exec;
my $header_info;
my $background_info;
my $creation_time_limit = 60;;

my $cronjob = 'check_tracking';
my $email_recipient = 'aldente';
my %Crons;
my $check_name = "protocol_tracking_check";
$Crons{$check_name}{file} = $cronjob;
$Crons{$check_name}{monitor} = '';
$Crons{$check_name}{notify} = $email_recipient;

if ($opt_d) {$dbase = $opt_d}     # database name
if ($opt_h) {$host	= $opt_h} # database	host 
if ($opt_u) {$user 	= $opt_u} # user for database login
if ($opt_p) {$pass 	= $opt_p} # password for database login
if ($opt_l) {$lib 	= $opt_l} # library to fix
if ($opt_q) {$prot	= $opt_q} # protocol to fix
if ($opt_e) {$exec  = 1		} else { $exec = 0 }		#execute the fix

#########################
my $dbc;

if ($opt_d && $opt_u && $opt_p) { 
	$header_info .= "############################################\n"; 
	$header_info .= "DATABASE: \t$host:$dbase \nUSERNAME: \t$user \nPASSWORD: \t$pass";
	if ($lib){
		$header_info .= "\nLIBRARY: \t$lib";
	} else {
		$header_info .= "\nLIBRARY: \tall";
	}
	if ($prot){
		$header_info .= "\nPROTOCOL: \t$prot\n";
	} else {
		$header_info .= "\nPROTOCOL: \tall\n";
	}
	$header_info .= "############################################\n"; 

	$dbc = SDB::DBIO->new(-user=>$user,-password=>$pass,-host=>$host,-dbase=>$dbase);
} else {
	$dbc = SDB::DBIO->new(-user=>'viewer',-password=>'viewer',-host=>'lims02',-dbase=>'seqtest');
}
$dbc->connect();
my @protocols;

if ($prot eq 'all'){
	@protocols = &Table_find($dbc,'Lab_Protocol','Lab_Protocol_ID',"WHERE Lab_Protocol_Status='Active'",'Distinct');
}
elsif ($prot){
	$protocols[0] = $prot;
}
else {
    Message("Please choose protocol to run this on or choose all (eg -p 75 or -p all)");
}

$Crons{$check_name}{tested} = scalar(@protocols);

foreach my $protocol (@protocols){

	my $ps = " AND Plate_Status = 'Active' ";
	my $L_condition = "AND FK_Library__Name = '$lib' " if $lib;
	my $L_order= "FK_Library__Name," if $prot;
	my $P_condition = "AND FK_Lab_Protocol__ID = $protocol " if $prot;
	my $P_order= "FK_Lab_Protocol__ID," if $lib;

	my %info = &Table_retrieve($dbc,'Plate_Prep,Prep,Plate',['FK_Prep__ID','Plate_Prep_ID','Prep_DateTime','Prep_Name','FK_Lab_Protocol__ID','FK_Library__Name','FK_Plate__ID','FK_Plate_Set__Number'],
		"where FK_Plate__ID=Plate_ID AND FK_Prep__ID=Prep_ID $ps $L_condition $P_condition Order by $L_order $P_order FK_Plate_Set__Number,Plate_ID,Prep_DateTime,Plate_Prep_ID");

	if (exists $info{Plate_Prep_ID}[0]){
		my @prep_id = @{$info{Plate_Prep_ID}};
		my @date = @{$info{Prep_DateTime}};
		my @name = @{$info{Prep_Name}};
		my @plate_id = @{$info{FK_Plate__ID}};
		my @fkprep_id = @{$info{FK_Prep__ID}};
		my @plateset_id= @{$info{FK_Plate_Set__Number}};
		my @protocol = @{$info{FK_Lab_Protocol__ID}};
		my @library	= @{$info{FK_Library__Name}};

		my $old_plate_id    = 0;
		my $old_plateset_id = 0;
		my $new_plate_id    = 0;
		my %block;
		my @plateprep;
		my @blockDate;
		my @blockName;
		my @blockPlate;
		my @blockPlateSet;
		my @blockProtocol;
		my $commentList; 
		my $newplateset_id; 
		my $prePrintFormat; 
		my $prePrintTime; 
		my $prePrintPlate; 
		my $blockSwitch;
		my $headerSwitch;
		my $fix;
		my $error = '';


### iterate through all of the prep steps
		for (my $i=0; $i<scalar(@prep_id); $i++){

			if ($name[$i] =~/^(Pre-Print) (.+)/i) {
				$prePrintFormat	= $2;
				$prePrintTime 	= @date[$i];
				$prePrintPlate	= @plate_id[$i]; 
			}
			## extract protocol steps applied to each plate to display the problem area to the user
			if (_check_if_new_plate($name[$i])) {
				%block = &Table_retrieve($dbc,'Plate_Prep,Prep,Plate',['Plate_Prep_ID','Prep_DateTime','Prep_Name','FK_Plate__ID','FK_Plate_Set__Number','FK_Lab_Protocol__ID'],"where FK_Plate__ID=Plate_ID AND FK_Prep__ID=Prep_ID $ps AND FK_Library__Name='$library[$i]' AND FK_Lab_Protocol__ID=$protocol[$i] AND FK_Plate__ID = $plate_id[$i] ORDER BY FK_Plate_Set__Number,Prep_DateTime,Plate_Prep_ID");
			
				@plateprep = @{$block{Plate_Prep_ID}};
				@blockDate = @{$block{Prep_DateTime}};
				@blockName = @{$block{Prep_Name}};
				@blockPlate= @{$block{FK_Plate__ID}};
				@blockPlateSet = @{$block{FK_Plate_Set__Number}};
				@blockProtocol= @{$block{FK_Lab_Protocol__ID}};
				$blockSwitch = 0;
				
			}

			## find steps that are Transfers or Aliquots 
			my $step_info = _check_if_new_plate($name[$i]);
			if ($step_info) {
				$background_info = '';
				my $plate_format = $step_info->{new_format};
				$fix = 0;
				$old_plateset_id = $plateset_id[$i+1];
				$old_plate_id = $plate_id[$i];

				## check if the next step is also a Transfer or an Aliquot
				if (_check_if_new_plate($name[$i+1]) && $plate_id[$i] == $plate_id[$i+1]){
					$background_info .= "\n===============================================================================================================================\n";
					## diplay the problematic protocol steps to the user
					if(exists $block{Prep_DateTime}[0]){	
						if ($lib && $prot){
						}elsif ($lib){
							$background_info .= "PROTOCOL# $protocol[$i]\n";
						}elsif($prot ne 'all'){
							$background_info .= "LIBRARY NAME: $library[$i]\n";
						}else{
							$background_info .= "LIBRARY NAME: $library[$i]\n";
							$background_info .= "PROTOCOL# $protocol[$i]\n";
						}

						for (my $k=0; $k<scalar(@blockDate); $k++){
							$background_info .= "Plate_Prep_ID ($plateprep[$k]) $blockDate[$k] \t--> $blockPlateSet[$k] \t--> $blockPlate[$k] \t--> $blockName[$k]\n";
						}
					}
					$background_info .= "\nStep \'$name[$i]\' was performed but Plate_ID($plate_id[$i]) was not changed (Using first occurence fix the problem)\n";
					$error = "\nStep \'$name[$i]\' was performed but Plate_ID($plate_id[$i]) was not changed (Using first occurence fix the problem)\n";
					$fix = 'set';
				} elsif ($name[$i+1] =~/^(Completed Protocol)/i && $plate_id[$i] == $plate_id[$i+1]){
				} elsif (!_check_if_new_plate($name[$i+1]) && !_check_if_new_plate($name[$i-1]) && $plate_id[$i] == $plate_id[$i+1] && $plateset_id[$i] == $plateset_id[$i+1]){
					$background_info .= "\n===============================================================================================================================\n";
					## diplay the problematic protocol steps to the user
					if(exists $block{Prep_DateTime}[0]){	
						if ($lib && $prot){
						}elsif ($lib){
							$background_info .= "PROTOCOL# $protocol[$i]\n";
						}elsif($prot ne 'all'){
							$background_info .= "LIBRARY NAME: $library[$i]\n";
						}else{
							$background_info .= "LIBRARY NAME: $library[$i]\n";
							$background_info .= "PROTOCOL# $protocol[$i]\n";
						}

						for (my $k=0; $k<scalar(@blockDate); $k++){
							$background_info .= "Plate_Prep_ID ($plateprep[$k]) $blockDate[$k] \t--> $blockPlateSet[$k] \t--> $blockPlate[$k] \t--> $blockName[$k]\n";
						}
					}
					$background_info .= "\nStep \'$name[$i]\' was performed but Plate_ID($plate_id[$i]) not changed\n";
					$error = "\nStep \'$name[$i]\' was performed but Plate_ID($plate_id[$i]) not changed\n";
					$fix = 'set';
				} elsif (!_check_if_new_plate($name[$i+1]) && _check_if_new_plate($name[$i-1]) && $plate_id[$i] != $plate_id[$i-1]){
					if ($plate_id[$i] == $plate_id[$i+1]){
						$background_info .= "\n===============================================================================================================================\n";
						## diplay the problematic protocol steps to the user
						if(exists $block{Prep_DateTime}[0]){	
							if ($lib && $prot){
							}elsif ($lib){
								$background_info .= "PROTOCOL# $protocol[$i]\n";
							}elsif($prot ne 'all'){
								$background_info .= "LIBRARY NAME: $library[$i]\n";
							}else{
								$background_info .= "LIBRARY NAME: $library[$i]\n";
								$background_info .= "PROTOCOL# $protocol[$i]\n";
							}

							for (my $k=0; $k<scalar(@blockDate); $k++){
								$background_info .= "Plate_Prep_ID ($plateprep[$k]) $blockDate[$k] \t--> $blockPlateSet[$k] \t--> $blockPlate[$k] \t--> $blockName[$k]\n";
							}
						}
						$background_info .= "\nStep \'$name[$i]\' was performed but Plate_ID($plate_id[$i]) not changed\n";
						$error = "\nStep \'$name[$i]\' was performed but Plate_ID($plate_id[$i]) not changed\n";
						$fix = 'set';
					}
				}else {
					next;
					#print  "PREV NAME: $name[$i-1] 	\tPREP: $prep_id[$i-1]\n";
					#print  "CURR NAME: $name[$i]	\tPREP: $prep_id[$i]\n";
					#print  "NEXT NAME: $name[$i+1]	\tPREP: $prep_id[$i+1]\n";
				}
				
				## figure out the exact time of the Transfer/Aliquot step
				my $datetime = $date[$i];
				my $prePrintFormat_id;
				my %details;
				
				if($prePrintFormat){
					$prePrintFormat_id = &get_FK_ID($dbc,'FK_Plate_Format__ID',$prePrintFormat);
				}
				my $F_cond;
				my $format_id = &get_FK_ID($dbc,'FK_Plate_Format__ID',$plate_format);

				if ($prePrintFormat_id && $format_id){
					$F_cond = " AND FK_Plate_Format__ID=$prePrintFormat_id ";
				}elsif ($format_id){
					$F_cond = " AND FK_Plate_Format__ID=$format_id ";
				}

				## find any Plates that have the plate Transferred/Aliquoted from as their parent plate and same plate format
				if($prePrintPlate == $plate_id[$i] && $prePrintFormat_id == $format_id && $fix eq 'set'){
					%details = &Table_retrieve($dbc,'Plate',['Plate_Created','TIME_TO_SEC(Plate_Created)-TIME_TO_SEC("'.$prePrintTime.'") as timeDiff','Plate_ID'],
						"WHERE FKParent_Plate__ID = $plate_id[$i] $F_cond");
				}elsif ($fix eq 'set'){
					%details = &Table_retrieve($dbc,'Plate',['Plate_Created','TIME_TO_SEC(Plate_Created)-TIME_TO_SEC("'.$datetime.'") as timeDiff','Plate_ID'],
						"WHERE FKParent_Plate__ID = $plate_id[$i] $F_cond");
				}
				
				## proceed if any plates were found
				if(exists $details{Plate_ID}[0] && $fix eq 'set'){	

					my @diff= @{$details{timeDiff}};
					my @created = @{$details{Plate_Created}};
					my @plt = @{$details{Plate_ID}};
				
					## for each of the plates found above
					for (my $j=0; $j<scalar(@plt); $j++){
						my $ind = $j + 1;

						my $timeDiff = $diff[$j];
						## if the plate was created within 5 seconds of the Transfer/Aliquot print out its details
						if ($timeDiff>= 0 && $timeDiff< $creation_time_limit){
							$background_info .= "\n$ind \'$name[$i]\' applied to plate $plate_id[$i] on $date[$i]  PLATE SET:$plateset_id[$i]\n";
							$background_info .= "   ========> created plate $plt[$j] on $created[$j]  ($timeDiff second difference)\n";
						}

						## take the id of the first daughter plate as the new plate_id
						if ($fix eq 'set' && ($timeDiff>= 0 && $timeDiff< $creation_time_limit) ){
							$new_plate_id = $plt[$j];
							$fix = 'replace';

						}		
					}	
				} else {
					my @extracted_plateID = @{_check_if_extraction($plate_id[$i])};
					
					if ($extracted_plateID[0]){
						foreach my $extracted_plate (@extracted_plateID){
							if($prePrintPlate == $extracted_plate && $fix eq 'set'){
								%details = &Table_retrieve($dbc,'Plate,Sample_Type',['Plate_Created','Sample_Type','TIME_TO_SEC(Plate_Created)-TIME_TO_SEC("'.$prePrintTime.'") as timeDiff','Plate_ID'], "WHERE FK_Sample_Type__ID = Sample_Type_ID AND Plate_ID = $extracted_plate $F_cond");
							}elsif ($fix eq 'set'){
								%details = &Table_retrieve($dbc,'Plate,Sample_Type',['Plate_Created','Sample_Type','TIME_TO_SEC(Plate_Created)-TIME_TO_SEC("'.$datetime.'") as timeDiff','Plate_ID'], "WHERE FK_Sample_Type__ID = Sample_Type_ID AND Plate_ID = $extracted_plate $F_cond");
							}	
							my ($plate_content) = &Table_find($dbc,'Plate,Sample_Type','Sample_Type',"WHERE FK_Sample_Type__ID = Sample_Type_ID AND Plate_ID= $plate_id[$i]");	
							
							if(exists $details{Plate_ID}[0] && $fix eq 'set'){	
								my @diff	= @{$details{timeDiff}};
								my @created = @{$details{Plate_Created}};
								my @content = @{$details{Sample_Type}};
								my @plt 	= @{$details{Plate_ID}};
							
								## for each of the plates found above
								for (my $j=0; $j<scalar(@plt); $j++){
									my $ind = $j + 1;

									my $timeDiff = $diff[$j];
									## if the plate was created within 60 seconds of the Transfer/Aliquot print out its details
									if ($timeDiff>= 0 && $timeDiff< $creation_time_limit){
										$background_info .= "\n$ind \'$name[$i]\' applied to plate $plate_id[$i] on $date[$i]  PLATE SET:$plateset_id[$i]\n";
										$background_info .= "==>EXTRACTION ($plate_content --> $content[$j]):  created plate $plt[$j] on $created[$j]  ($timeDiff second difference)\n";
									} else {
										$background_info .= "\n$ind \'$name[$i]\' applied to plate $plate_id[$i] on $date[$i]  PLATE SET:$plateset_id[$i]\n";
										$background_info .= "==>EXTRACTION ($plate_content --> $content[$j]):  created plate $plt[$j] on $created[$j]  ($timeDiff second difference)\n";
									}
									
									## take the id of the first daughter plate as the new plate_id
									if ($fix eq 'set' && ($timeDiff>= 0 && $timeDiff < $creation_time_limit)){
										$new_plate_id = $plt[$j];
										$fix = 'replace';
										last;
									}		
								}
							 
							} else {
								print "No Child or Extraction plate found for Plate $plate_id[$i]\n";
								push (@{%Crons->{$check_name}{details}},"No Child or Extraction plate found for Plate $plate_id[$i]");
							}
						}
					}
				}
			} else{
				#print "PlateID= $plate_id[$i]  == $old_plate_id  --> FIX $fix\n";
				if($plate_id[$i] == $old_plate_id && $fix eq 'replace') {
					## get the Plate_Set_ID of the plate found above
					my @set_id = &Table_find($dbc,'Plate_Set','DISTINCT(Plate_Set_Number)',"WHERE FK_Plate__ID=$new_plate_id AND Plate_Set_Number > $plateset_id[$i]");	
					if(scalar(@set_id) == 1){
						$newplateset_id = $set_id[0];
					}else{
						$newplateset_id = $old_plateset_id;
					}
					if (!$headerSwitch){
						$header_info = '';
						$headerSwitch = 1;
					}
					if (!$blockSwitch){
						print "\n $background_info";
						push (@{%Crons->{$check_name}{details}},$background_info);
						push (@{%Crons->{$check_name}{errors}},$error);
						$blockSwitch = 1;
						
					}
					print "\n*** Replacing the FK_Plate__ID for Plate_Prep_ID=$prep_id[$i] step \'$name[$i]\' ($plate_id[$i] --> $new_plate_id)\n"; 	
					push (@{%Crons->{$check_name}{details}},"*** Replacing the FK_Plate__ID for Plate_Prep_ID=$prep_id[$i] step \'$name[$i]\' ($plate_id[$i] --> $new_plate_id)");
					push (@{%Crons->{$check_name}{messages}},"*** Replacing the FK_Plate__ID for Plate_Prep_ID=$prep_id[$i] step \'$name[$i]\' ($plate_id[$i] --> $new_plate_id)");
					print "\n*** Replacing the FK_Plate_Set__Number for Plate_Prep_ID=$prep_id[$i] step \'$name[$i]\' ($plateset_id[$i] --> $newplateset_id)\n"; 	
					push (@{%Crons->{$check_name}{details}},"*** Replacing the FK_Plate_Set__Number for Plate_Prep_ID=$prep_id[$i] step \'$name[$i]\' ($plateset_id[$i] --> $newplateset_id)");
					push (@{%Crons->{$check_name}{messages}},"*** Replacing the FK_Plate_Set__Number for Plate_Prep_ID=$prep_id[$i] step \'$name[$i]\' ($plateset_id[$i] --> $newplateset_id)");

					if ($exec){
						my $update = &Table_update_array($dbc,'Plate_Prep',['FK_Plate__ID','FK_Plate_Set__Number'],[$new_plate_id,$newplateset_id],"where Plate_Prep_ID= $prep_id[$i]");
						if ($update){
							if (!$commentList){
								$commentList = $fkprep_id[$i];
							} else {
								$commentList = $commentList.",$fkprep_id[$i]";
							}
						}
					}
				} else { $background_info = '';}  ## clear background info for next plate .. ##
			}

		}

		if ($commentList){
			my $comment = &Table_update_array($dbc,'Prep',['Prep_Comments'],
						["CASE WHEN Length(Prep_Comments) > 0 THEN concat(Prep_Comments,'; fixed aliquot/transfer tracking') ELSE 'Fixed aliquot/transfer tracking' END"],
						"WHERE Prep_ID in ($commentList)");
			if ($comment){
				print "Comment added to Prep_IDs -->  $commentList\n";
				push (@{%Crons->{$check_name}{details}},"Comment added to Prep_IDs -->  $commentList");
				push (@{%Crons->{$check_name}{messages}},"Comment added to Prep_IDs -->  $commentList");
			}
		}

	} else {
		exit 0;
	}
_submit_results();
}
##############################
# Notify the problems to admin
##############################
sub _submit_results{
	my $ok;
#	$ok = &alDente::Cron::parse_job_results(-job_results=>\%Crons);
	print Dumper \%Crons;
	exit;
	#return $ok;
}

########################
#
# Check if this step is a transfer step. (Aliquot, Transfer, Pool, or Split..)
#  If it is, perform the appropriate transfer and generate the new plate ids.
#
#  required:  step name (eg. 'Transfer to 96-well Beckman')
#             current_plates.
#
#
####################
sub _check_if_extraction{
#####################
#
	my $plate_id = shift;  	
	my @extraction = &Table_find($dbc,'Extraction','FKTarget_Plate__ID',"WHERE FKSource_Plate__ID = $plate_id");
	if ($extraction[0]) {
		return \@extraction;
	}
	return \@extraction;
}

########################
#
# Check if this step is a transfer step. (Aliquot, Transfer, Pool, or Split..)
#  If it is, perform the appropriate transfer and generate the new plate ids.
#
#  required:  step name (eg. 'Transfer to 96-well Beckman')
#             current_plates.
#
#
####################
sub _check_if_new_plate{
#####################
#
	my $step = shift;
	my %step_info; 	
	#print $step."\n";
	if ($step=~ /^
	            (Transfer|Aliquot|Setup|Pool|Split)\s+     ## special cases
	            (\#\d+\s)?                           ## optional for multiple steps with similar name (eg Transfer #2 to ..)
	            (\w*)\s*                             ## optional new extraction type         
	            to\s+                                ## ... to .. (type)
	            (.+)                                 ## mandatory target type
	            (\(Track New Sample\))?              ## special cases for suffixes (optional)
	           $/xi) 
		{
	
		my %step_info; 	
		$step_info{'transfer_method'} 	= $1; 	
		$step_info{'instance_num'} 		= $2; 	
		$step_info{'new_sample_type'}	= $3; 	
		$step_info{'new_format'} 		= $4; 	
			
		return \%step_info;

	} else {
		return;
	}
}

#############################
sub _print_help_info {
#############################
#
#Prints the help info to the console if the -h switch is specified.
#
}
$dbc->disconnect();
exit;

############################
