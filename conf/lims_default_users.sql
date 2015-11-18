use mysql;

-- Level 3 Users
INSERT INTO `user` VALUES ('%','aldente_admin',     PASSWORD('etnedla'),    'Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','','','','', 0, 0, 0, 0,'','');
INSERT INTO `user` VALUES ('%','super_cron',        PASSWORD('repus'),      'Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','N','Y','Y','Y','Y','Y','N','Y','Y','Y','N','N','N','Y','Y','Y','N','Y','Y','','','','', 0, 0, 0, 0,'','');
INSERT INTO `user` VALUES ('%','super_api',         PASSWORD('aldente'),    'Y','Y','Y','Y','N','N','N','N','N','Y','N','N','N','N','N','N','Y','N','N','N','N','N','N','N','N','N','N','N','N','','','','', 0, 0, 0, 0,'','');
INSERT INTO `user` VALUES ('%','repl',              PASSWORD('aldente'),    'Y','Y','Y','Y','N','N','N','N','N','Y','N','N','N','N','N','N','Y','N','N','Y','Y','N','N','N','N','N','N','N','N','','','','', 0, 0, 0, 0,'','');
INSERT INTO `user` VALUES ('%','replicant',              PASSWORD('replicant'),    'Y','Y','Y','Y','N','N','N','N','N','Y','N','N','N','N','N','N','Y','N','N','Y','Y','N','N','N','N','N','N','N','N','','','','', 0, 0, 0, 0,'','');

-- Level 2 Users
INSERT INTO `user` VALUES ('%','lims_admin',        PASSWORD('aldente'),    'Y','Y','Y','Y','N','N','N','N','N','Y','N','N','N','N','N','N','Y','N','N','N','N','N','N','N','N','N','N','N','N','','','','', 0, 0, 0, 0,'','');

-- Level 1 Users
INSERT INTO `user` VALUES ('%','cron',              PASSWORD('aldente'),    'N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','','','','', 0, 0, 0, 0,'','');
INSERT INTO `user` VALUES ('%','lab_admin',         PASSWORD('aldente'),    'N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','','','','', 0, 0, 0, 0,'','');
INSERT INTO `user` VALUES ('%','labuser',           PASSWORD('manybases'),  'N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','','','','', 0, 0, 0, 0,'','');
INSERT INTO `user` VALUES ('%','collab_user',       PASSWORD('aldente'),    'N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','','','','', 0, 0, 0, 0,'','');
INSERT INTO `user` VALUES ('%','api',               PASSWORD('aldente'),    'N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','','','','', 0, 0, 0, 0,'','');
INSERT INTO `user` VALUES ('%','guest',             PASSWORD('aldente'),    'N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','','','','', 0, 0, 0, 0,'','');
INSERT INTO `user` VALUES ('%','viewer',            PASSWORD('viewer'),     'N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','','','','', 0, 0, 0, 0,'','');

INSERT INTO db VALUES ('%','%','cron','Y','Y','Y','Y','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N');
INSERT INTO db VALUES ('%','%','collab_user','Y','Y','Y','Y','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N');
INSERT INTO db VALUES ('%','%','viewer', 'Y','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N');
INSERT INTO db VALUES ('%','%','forestry_admin','Y','Y','Y','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N');
INSERT INTO db VALUES ('%','%','mapper_admin','Y','Y','Y','Y','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N');
INSERT INTO db VALUES ('%','%','mgcc_admin','Y','Y','Y','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N');
INSERT INTO db VALUES ('%','%','seqbio','Y','Y','Y','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N');
INSERT INTO db VALUES ('%','seqtest','unit_tester','Y','Y','Y','Y','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N');
INSERT INTO db VALUES ('%','seqbeta','unit_tester','Y','Y','Y','Y','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N');
INSERT INTO db VALUES ('%','%','labuser','Y','Y','Y','Y','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N');

INSERT INTO `user` VALUES ('%','viewer',            PASSWORD('viewer'),    'N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','','','','', 0, 0, 0, 0,'','');
INSERT INTO `user` VALUES ('localhost','viewer',    PASSWORD('viewer'),    'N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','','','','', 0, 0, 0, 0,'','');
INSERT INTO `user` VALUES ('%','labuser',           PASSWORD('manybases'), 'N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','','','','', 0, 0, 0, 0,'','');
INSERT INTO `user` VALUES ('localhost','labuser',   PASSWORD('manybases'), 'N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','','','','', 0, 0, 0, 0,'','');
