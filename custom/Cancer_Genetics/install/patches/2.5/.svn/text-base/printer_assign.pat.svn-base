<DATA>
#INSERT INTO Printer (Printer_Name,Printer_DPI,Printer_Type) VALUES (z4m-5,300,LARGE_LABEL_PRINTER),(z4m-6,300,2D_BARCODE_PRINTER),(z105sl-6,300,SMALL_LABEL_PRINTER),(

UPDATE Printer SET Printer_Name='z4m-5' WHERE Printer_Name = 'default_large_label_printer';
UPDATE Printer SET Printer_Name='z4m-6' WHERE Printer_Name = 'default_2d_barcode_printer';
UPDATE Printer SET Printer_Name='z105sl-6' WHERE Printer_Name = 'default_small_label_printer';
UPDATE Printer SET Printer_Name='orbita' WHERE Printer_Name = 'default_chemistry_printer';
UPDATE Printer SET Printer_Name='polyhymnia' WHERE Printer_Name = 'default_laser_printer';

UPDATE Printer SET Printer_Address=Printer_Name;
UPDATE Printer SET Printer_Output='ZPL' where Printer_Name IN ('z4m-5','z4m-6','z105sl-6');

 

</DATA>
