###################################################################################################################################
# LampLite::DB_Access_Views.pm
#
# Interface generating methods for the Session MVC  (associated with Session.pm, Session_App.pm)
#
###################################################################################################################################
package LampLite::DB_Access_Views;

use base LampLite::Views;

use strict;

## Standard modules ##

use Time::localtime;

## Local modules ##

## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use RGTools::HTML_Table;

use LampLite::CGI;
use LampLite::Form;
use LampLite::HTML;

use LampLite::Form;

my $q = new LampLite::CGI;
my $BS = new Bootstrap();

#########################
sub display_DB_Access {
#########################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'access_user,dbase');
    my $access_title = $args{-access_title};
    my $access_user     = $args{-access_user};
    
    my $dbase = $args{-dbase};
    my $scope = $args{-scope} || 'Production';  ## Production or nonProduction 
    
    my $debug = $args{-debug};
    
    my $dbc  = $self->dbc();
    
    my $overview = section_heading( "Manage Database Access");
    
    $overview .=  $self->adjust_Access(-scope=>$scope) . '<HR>';
    
    if ($access_user) {
        $access_title ||= $dbc->get_db_value(-sql=>"Select DB_Access_Title FROM DB_Login, DB_Access where DB_User = '$access_user' and FK${scope}_DB_Access__ID=DB_Access_ID");
    }
    
    my @fields = ("'Edit' as Edit", 'DB_Access_Title', "Group_Concat(DISTINCT DB_User) as Users", 'Select_priv as S', 'Insert_priv as I', 'Update_priv as U', 'Delete_priv as D');
    my (@include_fields, @exclude_fields);
    
     my $left_joins;
     foreach my $priv ('Select', 'Insert', 'Update', 'Delete') {
         $left_joins .= " LEFT JOIN Access_Inclusion AS Include_$priv ON Include_$priv.FK_DB_Access__ID=DB_Access_ID AND Include_$priv.Privilege = '$priv'";
         $left_joins .= " LEFT JOIN Access_Exclusion as Exclude_$priv ON Exclude_$priv.FK_DB_Access__ID=DB_Access_ID AND Exclude_$priv.Privilege = '$priv'";
         $left_joins .= " LEFT JOIN DBTable as iT_$priv ON iT_$priv.DBTable_ID=Include_$priv.FK_DBTable__ID AND Include_$priv.FK_DBField__ID IS NULL";
         $left_joins .= " LEFT JOIN DBField as iC_$priv ON iC_$priv.DBField_ID=Include_$priv.FK_DBField__ID";
         $left_joins .= " LEFT JOIN DBTable as xT_$priv ON xT_$priv.DBTable_ID=Exclude_$priv.FK_DBTable__ID AND Exclude_$priv.FK_DBField__ID IS NULL";
         $left_joins .= " LEFT JOIN DBField as xC_$priv ON xC_$priv.DBField_ID=Exclude_$priv.FK_DBField__ID";

         push @include_fields, "Group_Concat(Distinct iT_$priv.DBTable_Name) AS iT_$priv";
         push @exclude_fields, "Group_Concat(Distinct xT_$priv.DBTable_Name) AS xT_$priv";
         push @include_fields, "Group_Concat(Distinct Concat(iC_$priv.Field_Table, '.', iC_$priv.Field_Name)) AS iC_$priv";
         push @exclude_fields, "Group_Concat(Distinct Concat(xC_$priv.Field_Table, '.', xC_$priv.Field_Name)) AS xC_$priv";
     }
     
     my $condition = "WHERE FK${scope}_DB_Access__ID=DB_Access_ID";
     if ($access_title) { $condition .= " AND DB_Access_Title = '$access_title'" }

     my $link = "&cgi_app=LampLite::DB_Access_App&rm=Show Access&access_title=<DB_Access_Title>";
     my $edit_link = "&cgi_app=LampLite::DB_Access_App&rm=Edit Access&access_title=<DB_Access_Title>&Scope=$scope";
#     if ($user) { $link = "&cgi_app=Site_Admin::Department_App&rm=Edit Access&DB_User=<DB_User>"}

     $overview .= $dbc->Table_retrieve_display(
         "(DB_Access, DB_Login) LEFT JOIN Grp ON Grp.FK_DB_Login__ID=DB_Login_ID $left_joins", 
         [@fields, @include_fields, @exclude_fields],
         $condition,
         -group=>'DB_Access_ID',
         -order=>'DB_Access_ID,Grp_Name',
         -highlight_cell => { 'N' => 'lightredbw', 'Y' => 'lightgreenbw', 'I' => 'lightorangebw', 'X' => 'lightbluebw'},
         -toggle_on_column => 'DB_Access_Title',
         -link_parameters => {"Edit" => $edit_link, 'DB_Access_Title' => $link },
         -debug=>$debug,
         -return_html=>1,
         -no_footer => 1,
         -list_in_folders=>['Users'],
         -title=>"$scope Access Permission",
         -sub_titles=>{ 
             '1' => {'title' => 'Scope', 'colspan' => 7, 'colour' => 'mediumbluebw'}, 
             '2' => {'title' => 'Include', 'colspan' => 8, 'colour' => 'mediumgreenbw'}, 
             '3' => {'title' => 'Exclude', 'colspan' => 8, 'colour' => 'mediumredbw'}, 
             },
         -debug=>$debug
     );
     

     $overview .= "<HR>" . $self->display_mysql_Access(-access_title=>$access_title, -dbase=>$dbase, -scope=>$scope);
     
     return $overview;
}

#####################
sub adjust_Access {
#####################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'access_user,dbase');
    my $scope = $args{-scope};
    
    my $dbc = $self->dbc();
    
    my $form = new LampLite::Form(-dbc=>$dbc);
    
    my ($prompt, $field) = $form->View->prompt(-field=>'FK_DBTable__ID');
    
    $form->append( $field, $q->submit(-name=>'rm', -value=>'Set Table Access', -class=>'Std', -force=>1) . ' ' . $q->radio_group(-name=>'Scope', -values=>['Production', 'nonProduction']) );
    
    my $hidden =  $q->hidden(-name=>'cgi_app', -value=>'LampLite::DB_Access_App', -force=>1)
        . $q->hidden(-name=>'Scope', -value=>$scope, -force=>1);
        
    my $page = $form->generate(-wrap=>1, -include=>$hidden);

    return $page;
}


#########################
sub display_mysql_Access {
#########################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'access_user,dbase');

    my $dbc  = $self->dbc();
    my $access_title = $args{-access_title};
    my $access_user  = $args{-access_user};
    my $dbase = $args{-dbase} || $dbc->config('dbase');
    my $scope = $args{-scope};

    my $debug = $args{-debug};
    
        
    my $overview = section_heading('Access as defined by mysql');
    
    my $users = $access_user;
    if ($access_title) {
        my @db_users = $dbc->get_db_array(-sql=>"Select DB_User FROM DB_Login, DB_Access where DB_Access_Title = '$access_title' and FK${scope}_DB_Access__ID=DB_Access_ID");
        $users = join "','", @db_users; 
    }
    
    my $table = 'mysql.db';
    $table .= " LEFT JOIN mysql.tables_priv ON db.User=tables_priv.User";
    $table .= " LEFT JOIN mysql.columns_priv ON db.User=columns_priv.User AND (tables_priv.Table_name=columns_priv.Table_name)";

    my $condition = "WHERE 1";
    if ($users) { $condition .= " AND db.User IN ('$users')" }
    if ($dbase) { $condition .= " AND '$dbase' LIKE db.Db" }

    my @standard_priv = qw(Select Insert Update Delete);
    my @fields = qw(db.User db.Host db.Db);
    my $group = 'db.User, db.Host, db.Db, db.User';
    my $order = 'db.User, db.Host, db.Db';
    my ($t_plus,  $c_plus) = (1,1);
    my $toggle_column = 'User';

    my $title = "$dbase defined permissions";

    foreach my $priv (@standard_priv) { push @fields, "db.${priv}_priv" }
    if ($dbase && $access_title) {
        push @fields, ("Group_Concat(distinct tables_priv.Table_name ORDER BY tables_priv.Table_name Separator ', ') as Tables", "tables_priv.Table_priv", "tables_priv.Column_priv");
        push @fields, ("Group_Concat(distinct Concat(columns_priv.Table_name,'.',columns_priv.Column_name) ORDER BY columns_priv.Table_name, columns_priv.Column_name Separator ', ') as Columns", "columns_priv.Column_priv as Col_priv");

        $group .= ", tables_priv.Table_priv, columns_priv.Column_priv";
        $order .= ',tables_priv.Table_priv, columns_priv.Column_priv, columns_priv.Table_name, columns_priv.Column_name, tables_priv.Table_name';
        $t_plus = 3;
        $c_plus = 2;
        $toggle_column = 'Table_priv';
        $title = "'$access_title' permissions [applies to: $users]";
    }
    else {
        push @fields, "count(distinct tables_priv.Table_name) as Specified_Tables";
        push @fields, "count(distinct columns_priv.Column_name) as Specified_Columns";
    }

    my $link = "&cgi_app=LampLite::DB_Access_App&rm=Edit Access&access_user=<DB_User>";
    my $db_link = "&cgi_app=LampLite::DB_Access_App&rm=Show Access&access_user=<User>&access_dbase=<Db>";

     $overview .= $dbc->Table_retrieve_display(
         $table, 
         \@fields,
         $condition,
         -group=>$group,
         -order=>$order,
         -highlight_cell => { 'N' => 'lightredbw', 'Y' => 'lightgreenbw', 'I' => 'lightorangebw', 'X' => 'lightbluebw' },
         -toggle_on_column => $toggle_column,
         -link_parameters => {"DB_User" => $link, 'Db' => $db_link },
         -debug=>$debug,
         -return_html=>1,
         -title => $title,
         -list_in_folders=>['Tables', 'Columns'],
         -sub_titles=>{ 
             '1' => {'title' => 'Scope', 'colspan' => 3, 'colour' => 'mediumbluebw'}, 
             '2' => {'title' => 'Default Permission', 'colspan' => 4, 'colour' => 'mediumredbw'}, 
             '3' => {'title' => 'Table Permissions', 'colspan' => $t_plus, 'colour' => 'mediumgreenbw'}, 
             '4' => {'title' => 'Column Permissions', 'colspan' => $c_plus, 'colour' => 'mediumyellowbw'},
            },
            -no_footer => 1,
     );
     
     return $overview;
}

#######################
sub edit_User_Access {
#######################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'access_user,dbase');
    
    my $access_user = $args{-access_user};
    my $access_db = $args{-access_db};
    my $access_title = $args{-access_title};
    my $dbase = $args{-dbase};
    my $scope = $args{-scope};
    my $access_host = $args{-access_host} || '%';

    my $dbc = $self->dbc();
    
    if (!$access_db) {
        $access_db = $dbc->config('PRODUCTION_DATABASE');
        if ($scope ne 'Production') {
            $access_db .= '_%';        ## apply access permissions to non-production databases ##
        }
    }

    
    my $condition = "FK${scope}_DB_Access__ID=DB_Access_ID";

    if ($access_title && !$access_user) {
        ## use first defined user as example (by definition all users under same title should have identical privileges) ## ...
        ($access_user) = $dbc->get_db_array(-sql=>"Select DB_User FROM DB_Login, DB_Access where DB_Access_Title = '$access_title' and FK${scope}_DB_Access__ID=DB_Access_ID");
        $condition .= " AND DB_Access_Title = '$access_title'";
    }
    elsif ($access_user && !$access_title) {
        ($access_title) = $dbc->get_db_array(-sql=>"Select DB_Access_Title FROM DB_Login, DB_Access where DB_User = '$access_user' and FK${scope}_DB_Access__ID=DB_Access_ID");        
        $condition .= " AND DB_User = '$access_user'";
    }
    my $Priv = $dbc->hash(-sql=>"SELECT DISTINCT Select_priv, Insert_priv, Update_priv, Delete_priv FROM DB_Access, DB_Login WHERE $condition");    

    if (!$access_user || !($scope || $access_db) ) { $dbc->error("Must specify access user ($access_user) as well as scope ($scope) or access_db ($access_db)"); return; }

    my ($Inclusions, $Exclusions);
    my ($TI, $FI, $TX, $FX);

    if ($access_user) {
        $Inclusions = $dbc->hash(-sql=>"SELECT Privilege, DBTable_Name, Field_name, FROM (DB_Access, DBTable, Access_Inclusion) LEFT JOIN DBField ON FK_DBField__ID=DBField_ID WHERE Access_Inclusion.FK_DBTable__ID = DBTable_ID AND FK_DB_Access__ID=DB_Access_ID AND DB_Access_Title='$access_title'");
        $Exclusions = $dbc->hash(-sql=>"SELECT Privilege, DBTable_Name, Field_Name FROM (DB_Access, DBTable, Access_Exclusion) LEFT JOIN DBField ON FK_DBField__ID=DBField_ID WHERE Access_Exclusion.FK_DBTable__ID = DBTable_ID AND FK_DB_Access__ID=DB_Access_ID AND DB_Access_Title='$access_title'");

        my $i=0;
        while (defined $Inclusions->{DBTable_Name}[$i]) {
            my $table = $Inclusions->{DBTable_Name}[$i];
            my $priv  = $Inclusions->{Privilege}[$i];
            my $field = $Inclusions->{Field_Name}[$i];
            $i++;

            if ($field) { push @{$FI->{$priv}}, "$table.$field" }
            elsif ($table) { push @{$TI->{$priv}}, $table }
        }

        $i = 0;
        while (defined $Exclusions->{DBTable_Name}[$i]) {
            my $table = $Exclusions->{DBTable_Name}[$i];
            my $priv  = $Exclusions->{Privilege}[$i];
            my $field = $Exclusions->{Field_Name}[$i];
            $i++;

            if ($field) { push @{$FX->{$priv}}, "$table.$field" }
            elsif ($table) { push @{$TX->{$priv}}, $table }
        }
    }
    
    my $page = section_heading("Edit Access Form");
    my $form = new LampLite::Form(-dbc=>$dbc);

    $form->append("Scope: <B>$scope</B>");
    $form->append("$access_db.DB_Access_Title: <B>$access_title</B>");
    $form->append("mysql.Db: <B>$access_db</B>");
    $form->append("mysql.User: <B>$access_user</B>");
    
    $form->append(section_heading("Inclusions") );
    foreach my $priv ('Select', 'Insert', 'Update', 'Delete') {
        my ($T, $F);
        if ($TI->{$priv}) { $T = join ',', @{$TI->{$priv}} }
        if ($FI->{$priv}) { $F = join ',', @{$FI->{$priv}} }
        
        if ($Priv->{"${priv}_priv"}[0] eq 'Y') { $form->append('', "$priv allowed for all Tables / Fields") }
        elsif ($Priv->{"${priv}_priv"}[0] eq 'N') { $form->append('', "$priv DENIED for all Tables / Fields", -class=>'mediumredbw') }
        elsif ($Priv->{"${priv}_priv"}[0] eq 'X') { $form->append('', "$priv allowed unless specifically excluded") }
        else {
            $form->append('', subsection_heading("$priv") );
            $form->append("<B>$priv</B> Table Inclusions:", $q->textfield(-name=>"Table_${priv}_Inclusions", -default=>$T, -class=>'form-control', -force=>1));
            $form->append("<B>$priv</B> Field Inclusions:", $q->textfield(-name=>"Field_${priv}_Inclusions", -default=>$F, -class=>'form-control', -force=>1));
        }
    }
    
    $form->append(section_heading("Exclusions") );
    foreach my $priv ('Select', 'Insert', 'Update', 'Delete') {
        my ($T, $F);
        if ($TX->{$priv}) { $T = join ',', @{$TX->{$priv}} }
        if ($FX->{$priv}) { $F = join ',', @{$FX->{$priv}} }

        if ($Priv->{"${priv}_priv"}[0] eq 'Y') { $form->append('', "$priv allowed for all Tables / Fields") }
        elsif ($Priv->{"${priv}_priv"}[0] eq 'N') { $form->append('', "$priv DENIED for all Tables / Fields", -class=>'mediumredbw') }
        elsif ($Priv->{"${priv}_priv"}[0] eq 'I') { $form->append('', "$priv DENIED unless specifically included") }
        else {
            $form->append('', subsection_heading("$priv") );
            $form->append("<B>$priv</B> Table Inclusions:", $q->textfield(-name=>"Table_${priv}_Inclusions", -default=>$T, -class=>'form-control', -force=>1));
            $form->append("<B>$priv</B> Field Inclusions:", $q->textfield(-name=>"Field_${priv}_Inclusions", -default=>$F, -class=>'form-control', -force=>1));
        }
    }

    $form->append('', $q->submit(-name=>'Update Access', -class=>'Action') );
    my $hidden = $q->hidden(-name=>'cgi_app', -value=>'LampLite::DB_Access_App', -force=>1) 
        . $q->hidden(-name=>'access_title', -value=>$access_title, -force=>1)
        . $q->hidden(-name=>'access_dbase', -value=>$access_db, -force=>1)
        . $q->hidden(-name=>'access_host', -value=>$access_host, -force=>1)
        . $q->hidden(-name=>'rm', -value=>'Update Access', -force=>1);

   $page .= $form->generate(-wrap=>1, -include=>$hidden);

   return $page;
}

#######################
sub edit_Table_Access {
#######################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'table');

    my $table_id = $args{-table_id};
    my $table    = $args{-table};
    my $access_db    = $args{-dbase};
    my $scope = $args{-scope};
    my $access_title    = $args{-access_title};

    my $dbc = $self->dbc();
    
    if ($table_id) { $table = $dbc->get_FK_info('FK_DBTable__ID', $table_id) }
    
    my $Model = $self->Model;
    my $privileges = $Model->parse_Access_privileges(-db_table=>$table, -scope=>$scope);

    my $Access = $Model->db_access(-scope=>$scope, -key=>'DB_Access_Title', -access_title=>$access_title) || {};
    my @access_types = keys %{$Access};
    
    my @privs = $Model->db_privileges();

    my $output_table = new HTML_Table(-title=>"$scope Privileges for '$table' Table", -border=>1);
    
    my @headers = ('Access');

    foreach my $access (@{$Access}) {
        my ($access_title) = keys %{$access};

        my @row = ($access_title);
        foreach my $priv (@privs) { 
            push @row, $access->{$access_title}{"${priv}_priv"} ;
            if ($access_title eq $access_types[0]) { push @headers, $priv }
        }
 
        my @col_specs = grep/^$table\./, keys %{$privileges->{$access_title}{column_priv}};
        
        foreach my $priv ( @privs ) {
            my $colour;
            if ($access_title eq $access_types[0]) { push @headers, "Table $priv" }
            my $default = $privileges->{$access_title}{table_priv}{$table}{$priv};
            
            my $column_specific = 0;
            foreach my $col (@col_specs) {
                ## If this column has specified privileges of this type ##
                if ($privileges->{$access_title}{column_priv}{$col}{$priv}) { $column_specific = 1 }
            }
            
            my $expand_link;
            #if ($column_specific) { 
                $expand_link = &Link_To($dbc->homelink(), 
                                ' +', 
                                "&cgi_app=LampLite::DB_Access_App&rm=Set Table Access&Scope=$scope&Table=$table&DB_Access_Title=$access_title&Access Level=Column", 
                                -tooltip=>"Manage Access for Individual Fields");
            #}
                        
            my $priv_scope = $access->{$access_title}{"${priv}_priv"};
            if ( $priv_scope =~ /I/) {
                $default ||= 'N';
                my $tip = "$priv access is generally ALLOWED,  but DENIED for those SPECIFICALLY EXCLUDED (set to 'Y' to Include $priv access this table)";
                push @row, Show_Tool_Tip( $q->radio_group(-name=>"$access_title-$priv", -values=>['Y','N'], -default=>'', -force=>1), $tip) . $expand_link;
            }
            elsif ( $priv_scope =~ /X/) {
                $default ||= 'Y';
                my $tip = "$priv access is generally ALLOWED,  but DENIED for those SPECIFICALLY EXCLUDED (set to 'N' to Exclude $priv access to table)";
                push @row, Show_Tool_Tip( $q->radio_group(-name=>"$access_title-$priv", -values=>['Y','N'], -default=>'', -force=>1), $tip) . $expand_link
            }
            else {
                my $tip;
                if ($access->{$access_title}{"${priv}_priv"} eq 'Y') {
                    $tip = "$priv access is ALLOWED for ALL tables";
                    $colour = 'white';
                }
                elsif ($access->{$access_title}{"${priv}_priv"} eq 'N') {
                    $tip = "$priv access is DENIED for ALL tables";
                    $colour = 'darkgrey';
                }
                elsif ($access->{$access_title}{"${priv}_priv"} eq 'I') {
                    $tip = "$priv access is generally DENIED, but ALLOWED for those SPECIFICALLY INCLUDED";
                }
                elsif ($access->{$access_title}{"${priv}_priv"} eq 'X') {
                    $tip = "$priv access is generally ALLOWED,  but DENIED for those SPECIFICALLY EXCLUDED";
                }
                else { $tip = qq(no tip for '$access->{$access_title}{"${priv}_priv"}') }
                
                push @row, Show_Tool_Tip( $access->{$access_title}{"${priv}_priv"}, $tip);
            }
            
            if ($column_specific) { $colour = 'mediumorangebw' }
            elsif ($default eq 'N') { $colour ||= 'lightredbw' }
            elsif ($default eq 'Y') { $colour ||= 'lightgreenbw' }
            
            if ($colour) { $output_table->Set_Cell_Class($output_table->{rows}+1, int(@row), $colour) }                
        }

        $output_table->Set_Row(\@row);
    }
    $output_table->Set_Headers(\@headers);    
    
    my $form = new LampLite::Form(-dbc=>$dbc);
    
    $form->append( $output_table->Printout(0) );
    $form->append( $q->submit(-name=>'rm', -value=>'Update Table Access', -force=>1, -class=>'Std') );
    $form->append( $q->reset(-name=>'Reset', -class=>'Std') );
    
    my $hidden = $q->hidden(-name=>'cgi_app', -value=>'LampLite::DB_Access_App', -force=>1)
        . $q->hidden(-name=>'Scope', -value=>$scope, -force=>1)
        . $q->hidden(-name=>'access_db', -value=>$access_db, -force=>1)
        . $q->hidden(-name=>'DB_Access_Title', -value=>$access_title, -force=>1)
        . $q->hidden(-name=>'DB_Table_Name', -value=>$table, -force=>1)
        . $q->hidden(-name=>'DB_Table_ID', -value=>$table_id, -force=>1)
        . $q->hidden(-name=>'form', -value=>'Table', -force=>1);
        
   
    return $form->generate(-wrap=>1, -include=>$hidden);    
}

#######################
sub edit_Column_Access {
#######################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'table');

    my $table_id = $args{-table_id};
    my $table    = $args{-table};
    my $scope = $args{-scope};
    my $access_title    = $args{-access_title};
    my $access_db    = $args{-dbase};

    my $dbc = $self->dbc();
    
    if ($table_id) { $table = $dbc->get_FK_info('FK_DBTable__ID', $table_id) }
    
    my $Model = $self->Model;
    my $privileges = $Model->parse_Access_privileges(-db_table=>$table, -scope=>$scope, -access_title=>$access_title);

    my $Access = $Model->db_access(-scope=>$scope, -key=>'DB_Access_Title', -access_title=>$access_title) || {};
    my @access_types = keys %{$Access};
    
    my @privs = $Model->db_privileges();

    my $output_table = new HTML_Table(-title=>"'$access_title' Column Privileges for $table Table", -border=>1);
    
    my @headers = ('Access');
    
    my @fields = $dbc->get_fields($table);
    
    foreach my $access (@$Access) {
    foreach my $field (@fields) {
        if ($field =~ /(\w+)\.(\w+)/) { $field = $2 }
         
        my @row = ($field);
        foreach my $priv (@privs) { 
            push @row, $access->{$access_title}{"${priv}_priv"};
            if ($field eq $fields[0]) { push @headers, $priv }
        }
 
        my @col_specs = grep/^$table\./, keys %{$privileges->{$access_title}{column_priv}};
        
        foreach my $priv ( @privs ) {
            my $colour;
            if ($access_title eq $access_types[0]) { push @headers, "Table $priv" }
            my $default = $privileges->{$access_title}{column_priv}{"$table.$field"}{$priv};

            my $priv_scope = $access->{$access_title}{"${priv}_priv"};
                        
            if ( $priv_scope =~ /I/) {
                $default ||= 'N'; 
                my $tip = "$priv access is generally DENIED, but ALLOWED for those SPECIFICALLY INCLUDED (set to 'Y' to Include $priv access this table)";
                push @row, Show_Tool_Tip( $q->radio_group(-name=>"$access_title-$priv-$field", -values=>['Y','N'], -default=>'', -force=>1), $tip);
            }
            elsif ( $priv_scope =~ /X/) {
                $default ||= 'Y';
                my $tip = "$priv access is generally ALLOWED,  but DENIED for those SPECIFICALLY EXCLUDED (set to 'N' to Exclude $priv access to table)";
                push @row, Show_Tool_Tip( $q->radio_group(-name=>"$access_title-$priv-$field", -values=>['Y','N'], -default=>'', -force=>1), $tip);
            }
            else {
                my $tip = qq(no tip for '$priv_scope');
                if ($priv_scope eq 'Y') {
                     $tip = "$priv access is ALLOWED for ALL tables/fields";
                 }
                 elsif ($priv_scope eq 'N') {
                     $tip = "$priv access is DENIED for ALL tables/fields";
                 }
                 elsif ($priv_scope eq 'I') {
                     $tip = "$priv access is generally DENIED, but ALLOWED for those SPECIFICALLY INCLUDED";
                 }
                 elsif ($priv_scope eq 'X') {
                     $tip = "$priv access is generally ALLOWED,  but DENIED for those SPECIFICALLY EXCLUDED";
                 }
                 push @row, Show_Tool_Tip( $priv_scope, $tip);
                
                if ($priv_scope eq 'Y') { $colour = 'mediumgreenbw'}
                elsif ($priv_scope eq 'N') { $colour = 'mediumredbw' }
            }
            
            if ($default eq 'N') { $colour = 'lightredbw' }
            elsif ($default eq 'Y') { $colour = 'lightgreenbw' }
          
            
            if ($colour) { $output_table->Set_Cell_Class($output_table->{rows}+1, int(@row), $colour) }                
        }

        $output_table->Set_Row(\@row);
    }
    }
    $output_table->Set_Headers(\@headers); 
       
    my $form = new LampLite::Form(-dbc=>$dbc);
    
    $form->append( $output_table->Printout(0) );
    $form->append( $q->submit(-name=>'rm', -value=>'Update Column Access', -force=>1, -class=>'Std') );
    $form->append( $q->reset(-name=>'Reset', -class=>'Std') );
    
    my $hidden = $q->hidden(-name=>'cgi_app', -value=>'LampLite::DB_Access_App', -force=>1)
            . $q->hidden(-name=>'Scope', -value=>$scope, -force=>1)
            . $q->hidden(-name=>'access_db', -value=>$access_db, -force=>1)
            . $q->hidden(-name=>'DB_Access_Title', -value=>$access_title, -force=>1)
            . $q->hidden(-name=>'DB_Table_Name', -value=>$table, -force=>1)
            . $q->hidden(-name=>'DB_Table_ID', -value=>$table_id, -force=>1);
    
    return $form->generate(-wrap=>1, -include=>$hidden);
      
}

return 1;