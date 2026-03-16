<?php
// Driver plugins must be included after Adminer loads its helper functions.
// Include them inside adminer_object().

function adminer_object() {
    // Enable MongoDB driver plugin shipped with Adminer
    require_once __DIR__ . '/plugins/drivers/mongo.php';
    // Enable our Firebird PDO driver plugin
    require_once __DIR__ . '/plugins/drivers/firebird-pdo.php';

    // Load regular plugins (instances returned by files in plugins-enabled/)
    $plugins = [];
    foreach (glob(__DIR__ . '/plugins-enabled/*.php') as $pluginFile) {
        $plugin = require $pluginFile;
        if (is_object($plugin)) {
            $plugins[] = $plugin;
        }
    }
    return new \Adminer\Plugins($plugins);
}

require __DIR__ . '/adminer.php';
