local init = {
    table = 'xt_printers',
    query = [[
        CREATE TABLE IF NOT EXISTS `xt_printers` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `model` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
            `coords` LONGTEXT NOT NULL DEFAULT json_object() COLLATE 'utf8mb3_general_ci',
            `storage` LONGTEXT NOT NULL DEFAULT json_object() COLLATE 'utf8mb3_general_ci',
            `group` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
            `public` INT(11) NULL DEFAULT '0',
            PRIMARY KEY (`id`) USING BTREE
        )
        COLLATE='utf8mb3_general_ci'
        ENGINE=InnoDB
        AUTO_INCREMENT=1
        ;
    ]]
}

MySQL.ready(function()
    MySQL.Async.execute(init.query, {}, function()
        print(('Initializing Printers Database Table: ^2%s^0'):format(init.table))
    end)
end)