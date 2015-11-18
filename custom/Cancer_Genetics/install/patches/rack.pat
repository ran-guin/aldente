## Change the following lines of code:

File: lib/perl/alDente/Rack.pm

Line: ~300
From:  $label_field = " Label:".textfield(-name=>'Rack_Prefix',-size=>10,-default=>'') unless $type eq 'Box';
To: $label_field = " Label:".popup_menu(-name=>'Rack_Prefix',-values=>\@append_values,-default=>'') unless ($type eq 'Box');
