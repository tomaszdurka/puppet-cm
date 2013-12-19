define cm::webserver::vhost(
  $path,
  $ssl_cert,
  $ssl_key,
  $aliases = [],
 ) {

  $hostnames = concat([$name], $aliases)

  nginx::resource::vhost{"${name}-http":
    listen_port => 80,
    server_name => $hostnames,
    location_cfg_append => [
      'return 301 https://$host$request_uri;',
    ],
  }

  nginx::resource::vhost {"${name}-https":
    server_name => $hostnames,
    ssl => true,
    ssl_port => 443,
    listen_port => 443,
    ssl_cert => $ssl_cert,
    ssl_key => $ssl_key,
    location_cfg_append => [
      'include fastcgi_params;',
      "fastcgi_param SCRIPT_FILENAME ${path}/public/index.php;",
      'fastcgi_keep_conn on;',
      "fastcgi_pass fastcgi-backend;",
      'error_page 502 =503 /maintenance;',
    ],
  }

  nginx::resource::location{"${name}-fpm-status":
    vhost => "${name}-https",
    location => '/fpm-status',
    location_cfg_append => [
      'deny all;',
    ],
  }

  nginx::resource::location{"${name}-maintenance":
    vhost => "${name}-https",
    location => '/maintenance',
    www_root => "${path}/public",
    try_files => ['/maintenance.html', 'something-nonexistent'],
  }
}
